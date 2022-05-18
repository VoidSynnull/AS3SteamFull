package game.scenes.survival4.banquetRoom
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Viewport;
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.Dialog;
	import game.components.entity.NPCDetector;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.item.ItemMotion;
	import game.components.hit.CurrentHit;
	import game.components.motion.Destination;
	import game.components.motion.Navigation;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.SitSleepLoop;
	import game.data.animation.entity.character.SleepingSitUp;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.WaterStream;
	import game.scene.template.CharacterGroup;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival4.guestRoom.GuestRoom;
	import game.scenes.survival4.shared.Survival4Scene;
	import game.systems.SystemPriorities;
	import game.systems.entity.NPCDetectionSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class BanquetRoom extends Survival4Scene
	{
		public function BanquetRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival4/banquetRoom/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_events = super.events as Survival4Events;
			shellApi.eventTriggered.add(handleEventTrigger);
			
			var characterGroup:CharacterGroup = getGroupById("characterGroup") as CharacterGroup;
			var cook:Entity = this.getEntityById("cook");
			cook.get(Dialog).start.add(cookDialogStarted);
			characterGroup.addAudio(cook);
			
			player.get(Dialog).start.add(playerDialogStarted);
			
			if(shellApi.checkEvent(_events.DINNER_SEQUENCE))
			{
				showDinnerSequence();
			}
			else if(shellApi.checkEvent(_events.ATE_MEAT))
			{
				_hitContainer.removeChild(_hitContainer["meat1"]);
				_hitContainer.removeChild(_hitContainer["meat2"]);
				setupFaucet();
				var detector:NPCDetector = new NPCDetector(340, 50);
				detector.detected.addOnce(Command.create(cookDetectedPlayer, cook));
				cook.add(detector);
				
				EntityUtils.removeInteraction(cook);
				
				var sleep:Sleep = cook.get(Sleep);
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = true;
				
				var audio:Audio = new Audio();
				cook.add(audio);
				cook.add(new AudioRange(1200, 0, 1, Sine.easeIn));
				audio.play(SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				
				this.addSystem(new NPCDetectionSystem(), SystemPriorities.resolveCollisions);
			}
			else
			{				
				_hitContainer.removeChild(_hitContainer["meat1"]);
				_hitContainer.removeChild(_hitContainer["meat2"]);
				setupFaucet(false);
				
				var threshold:Threshold = new Threshold("x", "<");
				threshold.threshold = 350;
				threshold.entered.addOnce(reachedCook);
				player.add(threshold);
				
				this.addSystem(new ThresholdSystem());
			}
			
			// MOVE SCENE ITEMS BEHIND NPCs AND PLAYER
			var itemEntity:Entity = getEntityById( "emptyPitcher" );
			var display:Display;
			if( itemEntity )
			{
				display = itemEntity.get( Display );
				_hitContainer.setChildIndex( display.displayObject, 0 );
			}
			
			itemEntity = getEntityById( "taintedMeat" );
			if( itemEntity )
			{
				display = itemEntity.get( Display );
				_hitContainer.setChildIndex( display.displayObject, 0 );
			}
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.USE_EMPTY_PITCHER)
			{
				if(_waterOn)
				{
					var playerSpatial:Spatial = player.get(Spatial);
					if(playerSpatial.x > 2000 && playerSpatial.x < 2400 && playerSpatial.y > 400)
					{
						// move to sink and give full pitcher
						CharUtils.moveToTarget(player, 2200, 660, true, giveFullPitcher);
						return;
					}
				}
				
				player.get(Dialog).sayById("no_use");
			}
			else if(event == _events.USE_FULL_PITCHER || event == _events.USE_ARMORY_KEY || event == _events.USE_SPEAR || event == _events.USE_TAINTED_MEAT || event == _events.USE_TROPHY_ROOM_KEY )
			{
				player.get(Dialog).sayById("no_use");
			}
			else if(event == _events.BUTLER_POPUP)
			{
				SceneUtil.lockInput(this, false);
				var butlerPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
				butlerPopup.updateText("You were caught sneaking around! Back to your room...", "Try Again");
				butlerPopup.configData("butlerPopup.swf", "scenes/survival4/shared/butlerPopup/");
				butlerPopup.popupRemoved.addOnce(butlerPopupClosed);
				addChildGroup(butlerPopup);
			}
		}
		
		private function reachedCook():void
		{
			this.removeSystemByClass(ThresholdSystem);
			this.getEntityById("cook").get(Dialog).sayCurrent();
		}
		
		private function butlerPopupClosed():void
		{
			shellApi.loadScene(GuestRoom);
		}
		
		private function giveFullPitcher(player:Entity):void
		{
			shellApi.removeItem(_events.EMPTY_PITCHER);
			shellApi.getItem(_events.FULL_PITCHER, null, true);
		}
		
		private function showDinnerSequence():void
		{
			SceneUtil.lockInput(this, true, true);
			
			// Move player to right spot
			CharUtils.setAnim(player, Sit);
			CharUtils.setDirection(player, true);
			var playerSpatial:Spatial = this.player.get(Spatial);
			playerSpatial.x = 850;
			playerSpatial.y = 593;
			player.get(Motion).zeroMotion();
			
			SceneUtil.setCameraTarget(this, player, true);
			var currentMouth:* = SkinUtils.getSkinPart(player, SkinUtils.MOUTH).value;
			SkinUtils.setSkinPart(player, SkinUtils.MOUTH, "gum", false);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, Command.create(doneChewing, currentMouth)));
		}
		
		private function doneChewing(mouth:*):void
		{
			SkinUtils.setSkinPart(player, SkinUtils.MOUTH, mouth, true);
			var playerDialog:Dialog = player.get(Dialog);
			playerDialog.sayById("taste");
			playerDialog.complete.addOnce(panToBuren);
		}
		
		private function panToBuren(data:DialogData):void
		{			
			var vanBuren:Entity = getEntityById("vanburen");
			
			SceneUtil.setCameraTarget(this, vanBuren);
			var burenDialog:Dialog = vanBuren.get(Dialog);
			burenDialog.sayById("eat_up");
			burenDialog.complete.addOnce(playerFeelBad);
		}
		
		private function playerFeelBad(data:DialogData):void
		{
			SceneUtil.setCameraTarget(this, player);
			
			var playerDialog:Dialog = player.get(Dialog);
			playerDialog.sayById("bad_meat");
			playerDialog.complete.addOnce(playerSleep);
			shellApi.completeEvent(_events.ATE_MEAT);
		}
		
		private function playerSleep(data:DialogData):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "stunned_01_loop.mp3", 1, true);
			CharUtils.setAnim(player, SitSleepLoop);
			this.player.get(Spatial).y = 575;
			shellApi.completeEvent(_events.GUEST_ROOM_INTRO);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(shellApi.loadScene, GuestRoom, NaN, NaN, null, 3, 4)));
		}
		
		private function setupFaucet(attractCook:Boolean = true):void
		{
			_faucet = EntityUtils.createSpatialEntity(this, _hitContainer["faucetClick"], _hitContainer);
			
			InteractionCreator.addToEntity(_faucet, [InteractionCreator.CLICK]);
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			
			if(attractCook)
				sceneInteraction.reached.addOnce(faucetAttractCook);
			else
				sceneInteraction.reached.add(faucetClick);
			
			_faucet.add(sceneInteraction);
			_faucet.add(new Audio());
			_faucet.add(new AudioRange(1000, 0, 1, Sine.easeIn));
			
			ToolTipCreator.addToEntity(_faucet);
			
			_waterStream = new WaterStream();
			_waterStream.init(new Rectangle(-2, 0, 2, 24), 30, 5, 0x3399CC, .8);
			EmitterCreator.create(this, this._hitContainer["faucet"], _waterStream, 0, 0, null, null, null, false);
		}
		
		private function faucetClick(clicker:Entity, faucet:Entity):void
		{
			_faucet.get(Audio).play(SoundManager.EFFECTS_PATH + "wheel_squeak_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			if(_waterOn)
			{
				Audio(_faucet.get(Audio)).stop(SoundManager.EFFECTS_PATH + "water_flow_01_loop.mp3");
				_waterStream.stop();
				_waterOn = false;
			}
			else
			{
				_faucet.get(Audio).play(SoundManager.EFFECTS_PATH + "water_flow_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				_waterStream.start();
				_waterOn = true;
			}
		}
		
		private function faucetAttractCook(clicker:Entity, faucet:Entity):void
		{
			EntityUtils.removeInteraction(faucet);
			_waterStream.start();
			_faucet.get(Audio).play(SoundManager.EFFECTS_PATH + "wheel_squeak_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			_faucet.get(Audio).play(SoundManager.EFFECTS_PATH + "water_flow_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
			_waterOn = true;
			
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, moveCameraToCook));
		}
		
		private function moveCameraToCook():void
		{
			var cook:Entity = getEntityById("cook");
			SceneUtil.setCameraTarget(this, cook, false, .05);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, Command.create(faucetWakeUpCook, cook)));			
		}
		
		private function faucetWakeUpCook(cook:Entity):void
		{
			cook.get(Audio).stop(SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3");
			if(!_cookWalking)
			{
				cook.get(RigAnimation).manualEnd = true;				
				CharUtils.setAnim(cook, SleepingSitUp, true);
				cook.get(Spatial).y = 605
				cook.get(Spatial).rotation += 25;
				CharUtils.getTimeline(cook).handleLabel("ending", Command.create(whatWasThat, cook));
			}
			else
			{
				var dialog:Dialog = cook.get(Dialog);
				dialog.allowOverwrite = true;
				dialog.complete.removeAll();
				whatWasThat(cook);
			}
		}
		
		private function whatWasThat(cook:Entity):void
		{
			var dialog:Dialog = cook.get(Dialog);
			if(_cookWalking)
			{
				cook.get(Destination).interrupt = true;
				var fsmControl:FSMControl = cook.get(FSMControl);
				fsmControl.stateChange = new Signal();
				fsmControl.stateChange.add(cookInterrupted);
				
				if(dialog.speaking)
				{
					dialog.complete.addOnce(Command.create(killNothingDialog, cook));
				}
			}
			else
			{
				dialog.sayById("woken");
				dialog.complete.addOnce(Command.create(cookAlerted, cook));
			}
		}
		
		private function killNothingDialog(dialogData:DialogData, cook:Entity):void
		{
			sendCookBack(cook);
		}
		
		private function cookInterrupted(type:String, cook:Entity):void
		{
			if(type == CharacterState.STAND)
			{
				sendCookBack(cook);
			}
		}
		
		private function sendCookBack(cook:Entity):void
		{
			cook.get(FSMControl).stateChange.removeAll();
			
			CharUtils.setDirection(cook, true);
			var dialog:Dialog = cook.get(Dialog);
			dialog.sayById("woken");
			dialog.complete.addOnce(Command.create(cookAlerted, cook));
		}		
		
		private function cookAlerted(dialog:DialogData, cook:Entity):void
		{
			if(!_cookWalking) 
			{
				cook.get(Spatial).rotation -= 25;
				CharUtils.setAnim(cook, Stand);
			}					
			
			CharUtils.moveToTarget(cook, 2200, 655, true, stopAtSink);
			var motionControl:CharacterMotionControl = cook.get(CharacterMotionControl);
			motionControl.maxVelocityX = 135;			
			_cookWalking = true;	
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, backToPlayer));
		}
		
		private function backToPlayer():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player, false, .1);
		}
		
		private function stopAtSink(cook:Entity):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, Command.create(cookAtSink, cook)));
		}
		
		private function cookAtSink(cook:Entity):void
		{
			Audio(_faucet.get(Audio)).stop(SoundManager.EFFECTS_PATH + "water_flow_01_loop.mp3");
			_faucet.get(Audio).play(SoundManager.EFFECTS_PATH + "wheel_squeak_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			_waterStream.stop();
			_waterOn = false;
			
			InteractionCreator.addToEntity(_faucet, [InteractionCreator.CLICK]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.addOnce(faucetAttractCook);
			_faucet.add(sceneInteraction);
			
			ToolTipCreator.addToEntity(_faucet);
			CharUtils.moveToTarget(cook, 420, 620, true, cookAtChair);
		}
		
		private function cookAtChair(cook:Entity):void
		{
			var dialog:Dialog = cook.get(Dialog);
			dialog.sayById("nothing");
			dialog.complete.addOnce(Command.create(sitCook, cook));
		}
		
		private function sitCook(dialogData:DialogData, cook:Entity):void
		{
			CharUtils.setDirection(cook, true);
			CharUtils.setAnim(cook, SitSleepLoop);
			cook.get(Audio).play(SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
			
			var spatial:Spatial = cook.get(Spatial);
			spatial.x = 395;
			spatial.y = 590;
			
			CharUtils.removeCollisions(cook);
			cook.remove(Motion);
			cook.remove(MotionBounds);
			cook.remove(FSMControl);
			cook.remove(FSMMaster);
			cook.remove(CharacterMotionControl);
			cook.remove(Destination);
			cook.remove(Navigation);
			cook.remove(CurrentHit);
			cook.remove(Viewport);
			
			_cookWalking = false;
		}
		
		private function cookDetectedPlayer(hider:Entity, cook:Entity):void
		{
			SceneUtil.lockInput(this, true);
			
			if(!_cookWalking)
			{
				cook.get(Audio).stop(SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3");
				cook.get(RigAnimation).manualEnd = true;
				CharUtils.setAnim(cook, SleepingSitUp, true);
				cook.get(Spatial).y = 605
				cook.get(Spatial).rotation += 25;
				CharUtils.getTimeline(cook).handleLabel("ending", Command.create(cookAwake, cook));
			}
			else
			{
				cookAwake(cook);
			}
		}
		
		private function cookAwake(cook:Entity):void
		{
			// figure out what side the player is on
			if(!_cookWalking) cook.get(Spatial).rotation -= 25;
			
			CharUtils.setAnim(cook, Stand);
			CharUtils.stateDrivenOn(cook);
			var moveToSpot:Number = player.get(Spatial).x - cook.get(Spatial).x < 0 ? 150 : -150;			
			CharUtils.moveToTarget(cook, player.get(Spatial).x + moveToSpot, 660, true, cookAtPlayer)
		}
		
		private function cookAtPlayer(cook:Entity):void
		{
			if(shellApi.checkHasItem(_events.TAINTED_MEAT))
			{
				var dialog:Dialog = cook.get(Dialog);
				dialog.sayById("meat");
				dialog.complete.addOnce(Command.create(backToRoom, cook));
				return;
			}
			
			backToRoom(null, cook);
		}
		
		private function backToRoom(dialogData:DialogData = null, cook:Entity = null):void
		{
			shellApi.removeEvent(GameEvent.GOT_ITEM + _events.TAINTED_MEAT);
			cook.get(Dialog).sayById("goodnight");	
		}
		
		private function playerDialogStarted(dialogData:DialogData):void
		{
			if(dialogData.event == "player_scared" || dialogData.event == "bloody_scared")
			{
				CharUtils.setAnim(player, Tremble);
			}
			else if(dialogData.event == "jumpy")
			{
				SceneUtil.lockInput(this, false);
				CharUtils.lockControls(player, false, false);
				CharUtils.setAnim(player, Stand);
				CharUtils.stateDrivenOn(player);
			}
		}
		
		private function cookDialogStarted(dialogData:DialogData):void
		{
			var cook:Entity = getEntityById("cook");
			
			if(dialogData.event == "open_kitchen" || dialogData.id == "goodnight")
			{
				SceneUtil.lockInput(this, true);
				var knife:Entity = CharUtils.getPart(cook, CharUtils.ITEM);
				var itemMotion:ItemMotion = knife.get(ItemMotion);				
				CharUtils.setAnim(cook, Salute);
				var cookTimeline:Timeline = cook.get(Timeline);
				cookTimeline.handleLabel("raised", Command.create(pauseCook, cookTimeline));
			}
			else if(dialogData.event == "phrased_better" || dialogData.event == "back_to_bed")
			{
				CharUtils.setAnim(cook, Stand);
			}
		}
		
		private function pauseCook(timeline:Timeline):void
		{
			timeline.stop();
		}
		
		private var _waterStream:WaterStream;
		private var _waterOn:Boolean = false;
		private var _cookWalking:Boolean = false;
		private var _faucet:Entity;
	}
}