package game.scenes.survival3.radioTower
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.transitions.Tween;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.HitTest;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.SeeSaw;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.motion.PulleyConnecter;
	import game.components.motion.PulleyObject;
	import game.components.motion.PulleyRope;
	import game.components.motion.ShakeMotion;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Knock;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Stand;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.ending.Ending;
	import game.scenes.survival3.shared.Survival3Scene;
	import game.scenes.survival3.shared.components.ClimbingZoom;
	import game.scenes.survival3.shared.components.MotionDetection;
	import game.scenes.survival3.shared.components.RadioSignal;
	import game.scenes.survival3.shared.systems.ClimbingZoomSystem;
	import game.scenes.survival3.shared.systems.MotionDetectionSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.SeeSawSystem;
	import game.systems.motion.PulleySystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class RadioTower extends Survival3Scene
	{
		public var survival:Survival3Events;
		
		private const RADIO_STATIC:String = "sos_signal_01_loop.mp3";
		private const RADIO_CHATTER:String = "police_radio_chatter_01.mp3";
		
		private var seeSaw:SeeSaw;
		private const BREAK_DELAY:Number = .5; // time dealy in seconds between standing on shaky ladder and when they fall
		private const SHAKE_VELOCITY:Number = 2;
		private const ROTATE_VELOCITY:Number = 15;
		private const USE_DISTANCE:Number = 500;
		//private var screwDistance:Number = 75;
		
		private var radio:Entity;
		
		private var _usingScrewDriver:Boolean = false;
		
		public function RadioTower()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival3/radioTower/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var _originalQualityLevel:Number;
		
		override protected function addGroups():void
		{
			_originalQualityLevel = PerformanceUtils.qualityLevel;
			
			// minmize bitmap detail for background layer
			if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_LOW)
			{
				PerformanceUtils.qualityLevel = 0;
				
				super.sceneData.cameraLimits.left = 200;
				super.sceneData.cameraLimits.right = 2950;
				super.sceneData.cameraLimits.top = 400;
				
				var interactive:MovieClip = super.getAsset("interactive.swf");
				
				interactive["door1"].x = 2990;
				interactive["door1"].y = 5794;
			}
		
			super.addGroups();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			survival = events as Survival3Events;
			shellApi.eventTriggered.add(onEventTriggered);
			
			setUpPulley();
			setUpTiltFloors();
			setUpDropStep();
			setUpFallZone();
			setUpBreakAwayLadders();
			setUpBranches();
			setUpSoundScape();
			removePickedUpItems();
			
			var camera:Entity = getEntityById("camera");
			
			player.add(new ClimbingZoom(camera.get(Camera),1, .5, .75));
			addSystem(new ClimbingZoomSystem());
			
			if(!shellApi.checkEvent(survival.STARTED_QUEST))
			{
				var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
				introPopup.updateText("you've found an old radio antenna. now find a way to call for help!", "start");
				introPopup.configData("survival3_intro_popup.swf", "scenes/survival3/shared/popups/");
				addChildGroup(introPopup);
				shellApi.completeEvent(survival.STARTED_QUEST);
			}
			
			radio = EntityUtils.createSpatialEntity(this, bitmapToSprite(_hitContainer["radio"], true,true));
			Display(radio.get(Display)).alpha = 0;
			radio.add(new SceneInteraction()).add(new Id("radio"));
			InteractionCreator.addToEntity(radio,["click"],_hitContainer["radio"]);
			
			/*
			var spatial:Spatial = player.get(Spatial);
			spatial.x = shellApi.camera.areaWidth / 2 + 250;
			spatial.y = 0;
			//addChildGroup(new VictoryPopup(overlayContainer));
			//*/
			
			RadioSignal(player.get(RadioSignal)).groundLevel += 5000;
			RadioSignal(player.get(RadioSignal)).maxSignalHeight += 5000;
			
			PerformanceUtils.qualityLevel = _originalQualityLevel;
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(1725, 5600),"minibillboard/minibillboardMedLegs.swf");	

		}
		
		private function setUpSoundScape():void
		{
			var clip:MovieClip = new MovieClip();
			clip.x = 1900;
			clip.y = 0;
			var upperSoundScape:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var range:AudioRange = new AudioRange(6000, 0, 1, Quad.easeIn);
			upperSoundScape.add(new Audio()).add(range).remove(Sleep);
			Audio(upperSoundScape.get(Audio)).play(SoundManager.AMBIENT_PATH + "winter_wind_01_loop.mp3", true, SoundModifier.POSITION, 20);
			
			clip = new MovieClip();
			clip.x = 1900;
			clip.y = 6000;
			var lowerSoundScape:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			lowerSoundScape.add(new Audio()).add(range).remove(Sleep);
			Audio(lowerSoundScape.get(Audio)).play(SoundManager.AMBIENT_PATH + "forest_ambiance_01_loop.mp3", true, SoundModifier.POSITION, 2);
		}
		
		private function removePickedUpItems():void
		{
			if(shellApi.checkHasItem(survival.WIRE) || shellApi.checkItemUsedUp(survival.WIRE))
				removeEntity(getEntityById(survival.WIRE));
			
			if(shellApi.checkHasItem(survival.HARD_HAT))
			{
				removeEntity(getEntityById(survival.HARD_HAT));
			}
			else
			{
				var hat:Entity = getEntityById(survival.HARD_HAT);
				hat.remove(Item);
				var tree:DisplayObjectContainer = EntityUtils.getDisplayObject(getEntityById("treeFront"));
				DisplayUtils.moveToOverUnder(hat.get(Display).displayObject, tree, false);
				SceneInteraction(hat.get(SceneInteraction)).reached.add(commentOnHat);
			}
			
			if(shellApi.checkHasItem(survival.BATTERY_NOTE))
				removeEntity(getEntityById(survival.BATTERY_NOTE));
			else
				Display(getEntityById(survival.BATTERY_NOTE).get(Display)).moveToBack();
		}
		
		private function commentOnHat(...args):void
		{
			Dialog(player.get(Dialog)).sayById("get_hat");
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			if(event == survival.USE_SCREWDRIVER)
			{
				useScrewDriver();
			}
			
			if(event == survival.USE_SAW)
			{
				Dialog(player.get(Dialog)).sayById("no_use");
			}
			
			if(event == survival.RADIO)
			{
				useRadio();
			}
		}
		
		private function returnToPlayer(...args):void
		{
			Motion(player.get(Motion)).pause = false;
			CharUtils.setState(player, CharacterState.LAND);
			FSMControl(player.get(FSMControl)).active = true;
			SceneUtil.setCameraTarget(this, player);
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(player, false, false);
		}
		
		private function lockControl(...args):void
		{
			Spatial(player.get(Spatial)).rotation = 0;
			CharUtils.lockControls(player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		////////////////////////////////////////// WIN SEQUENCE //////////////////////////////////////////
		
		private function useRadio():void
		{
			if(super.signal.hasGoodSignal)
			{
				moveIntoPosition();
			}
			else
			{
				var wrongRadio:Dialog = player.get(Dialog);
				wrongRadio.sayById("radio_wrong");
			}
		}
		
		private function moveIntoPosition():void
		{
			var interaction:SceneInteraction = radio.get(SceneInteraction);
			interaction.activated = true;
			interaction.reached.addOnce(placeRadio);
			interaction.offsetX = -75;
			interaction.autoSwitchOffsets = false;
			CharacterState.STAND
			interaction.validCharStates = new <String>[CharacterState.STAND]
		}
		
		private function placeRadio(...args):void
		{
			lockControl();
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, Place);
			Timeline(player.get(Timeline)).handleLabel("trigger", setUpRadio);
			Timeline(player.get(Timeline)).handleLabel("ending", talkToRadio);
		}
		
		private function setUpRadio():void
		{
			Display(radio.get(Display)).alpha = 1;
			radio.add(new Id("radio")).add(new SceneInteraction());
			CharUtils.assignDialog(radio, this, "radio");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + RADIO_STATIC, .25, true);
		}
		
		private function talkToRadio():void
		{
			//Don't do the end sequence again if you already have the medallion.
			if(!this.shellApi.checkItemEvent(survival.SURVIVAL_MEDAL))
			{
				CharUtils.setAnim(player, Stand);
				removeSystem(getSystem(ClimbingZoomSystem));
				Camera(getEntityById("camera").get(Camera)).scaleTarget = 1;
				var dialog:Dialog = player.get(Dialog);
				dialog.sayById("mayday");
				dialog.complete.addOnce(waitForResponse);
			}
			else
			{
				returnToPlayer();
			}
		}
		
		private function waitForResponse(...args):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, radioResponds));
		}
		
		private function radioResponds():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + RADIO_CHATTER);
			var dialog:Dialog = getEntityById("radio").get(Dialog);
			dialog.sayById("read");
			dialog.complete.addOnce(talkToRadio2);
		}
		
		private function talkToRadio2(...args):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("thanks");
			dialog.complete.addOnce(radioResponds2);
		}
		
		private function radioResponds2(...args):void
		{
			var dialog:Dialog = getEntityById("radio").get(Dialog);
			dialog.sayById("mvb");
			dialog.complete.addOnce(talkToRadio3);
		}
		
		private function talkToRadio3(...args):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("mvb");
			dialog.complete.addOnce(getMedal);
		}
		
		private function getMedal(...args):void
		{
			super.shellApi.getItem( survival.SURVIVAL_MEDAL );
			ItemGroup(super.getGroupById( ItemGroup.GROUP_ID )).showItem( survival.SURVIVAL_MEDAL, "", null, loadCutScene );
			//shellApi.completedIsland();
		}
		
		private function loadCutScene(...args):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,Command.create(shellApi.loadScene, Ending)));
		}
		
		////////////////////////////////////////// BRANCHES //////////////////////////////////////////
		
		private function setUpBranches():void
		{
			addSystem(new TriggerHitSystem());
			
			for (var i:Number = 0; i <= 2; i++)
			{
				var clip:MovieClip = _hitContainer["branch" + i];
				BitmapUtils.convertContainer(clip, bitmapQuailty);
				var bounceEntity:Entity = super.getEntityById( "bounce" + i);
				
				var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
				
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			}
		}
		
		////////////////////////////////////////// LADDERS //////////////////////////////////////////
		
		private function setUpBreakAwayLadders():void
		{
			addSystem(new HitTestSystem());
			addSystem(new ShakeMotionSystem());
			
			for(var i:int = 1; i <= 2; i++)
			{
				var clip:MovieClip = _hitContainer["breakawayLadder"+i];
				var plat:Entity = getEntityById("breakLadder"+i);
				if(shellApi.checkEvent(survival.BROKE_LADDER + i))
					removeEntity(plat);
				else
				{
					var ladder:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(clip, false, true));
					DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(ladder), clip);
					var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-1, -1, 1, 1));
					shake.active = false;
					
					ladder.add(new Id(clip.name)).add(shake).add(new SpatialAddition());
					
					var hitTest:HitTest = new HitTest();
					hitTest.onEnter.add(Command.create(hitLadder, ladder, i));
					plat.add(hitTest);
				}
				_hitContainer.removeChild(clip);
			}
		}
		
		private function hitLadder(ladderHit:Entity, hit:String, ladder:Entity, ladderNumber:int):void
		{
			if(shellApi.checkEvent(survival.BROKE_LADDER+ladderNumber))
				return;
			
			//CharUtils.setAnim(player, Grief);
			// animations are on hold until motionControl, characterStates, and animations work together more choesively ~ Billy
			lockControl();
			ShakeMotion(ladder.get(ShakeMotion)).active = true;
			SceneUtil.addTimedEvent(this, new TimedEvent(BREAK_DELAY, 1, Command.create(breakLadder, ladderHit, ladder, ladderNumber)));
		}
		
		private function breakLadder(ladderHit:Entity, ladder:Entity, ladderNumber:int):void
		{
			if(shellApi.checkEvent(survival.BROKE_LADDER+ladderNumber))
				return;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_impact_21.mp3");
			removeEntity(ladderHit);
			shellApi.completeEvent(survival.BROKE_LADDER+ladderNumber);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, returnToPlayer));
			var ladderSpatial:Spatial = ladder.get(Spatial);
			TweenUtils.entityTo(ladder, Spatial, 1.5, {y:ladderSpatial.y + 1000, rotation:45, ease:Linear.easeIn, onComplete:Command.create( super.removeEntity, ladder)});
		}
		
		////////////////////////////////////////// TILTING FLOORS //////////////////////////////////////////
		
		private function setUpTiltFloors():void
		{
			addSystem(new SeeSawSystem(), SystemPriorities.move);
			addSystem(new WaveMotionSystem());
			addSystem(new MotionDetectionSystem());
			for(var i:int = 1; i <= 2; i ++)
			{
				var displayEntity:Entity = getEntityById("tiltFloor"+i);
				var display:Display = displayEntity.get(Display);
				display.swapDisplayObject(bitmapToSprite(display.displayObject));
				display.disableMouse();
				var seesaw:Entity = getEntityById("seesaw"+i);
				setUpBrackets(i);
				
				if(shellApi.checkEvent("seesaw_"+i+"_loose"))
					seesaw.add( new SeeSaw(20,20,-20,20,displayEntity));
				
				var motionDetection:MotionDetection = new MotionDetection();
				motionDetection.detected.add(Command.create(stressBracket, displayEntity));
				var wave:WaveMotion = new WaveMotion();
				wave.data.push(new WaveMotionData("y",0,.5));
				var edge:Edge = new Edge();
				edge.unscaled = display.displayObject.getBounds(display.displayObject);
				seesaw.add(motionDetection).add(edge);
				displayEntity.add(wave).add(new SpatialAddition());
			}
		}
		
		////////////////////////////////////////// BRACKETS //////////////////////////////////////////
		
		private function setUpBrackets(tiltingFloorNumber:int):void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var bracketNumber:int = (tiltingFloorNumber - 1) * 2 + i;
				var clip:MovieClip = _hitContainer["bracket"+bracketNumber];
				if(shellApi.checkEvent(survival.REMOVED_BRACKET+bracketNumber))
				{
					clip.parent.removeChild(clip);
				}
				else
				{
					BitmapUtils.convertContainer(clip, bitmapQuailty);
					var bracket:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
					
					bracket.add(new Id(clip.name)).add(new SceneInteraction());
					InteractionCreator.addToEntity(bracket, ["click"], clip);
					var interaction:SceneInteraction = bracket.get(SceneInteraction);
					interaction.minTargetDelta.x = 25;
					interaction.minTargetDelta.y = 100;
					interaction.offsetX = 25;
					interaction.validCharStates = new<String>[ CharacterState.STAND, CharacterState.WALK ];
					if(i % 2 == 0)
						interaction.offsetX *= -1;
					interaction.autoSwitchOffsets = false;
					
					ToolTipCreator.addToEntity(bracket);
					
					clip = clip["screwHead"];
					clip.mouseEnabled = false;
					clip.x += clip.parent.x;
					clip.y += clip.parent.y;
					
					var screw:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
					TimelineUtils.convertClip(clip,this, screw, null, false);
					screw.add(new Id("screw"+bracketNumber));
					DisplayUtils.moveToOverUnder(clip, _hitContainer["bracket"+bracketNumber]);
					if(bracketNumber == 2)	// 2nd bracket fall without screwdriver
					{
						interaction.reached.add(Command.create(autoDropBracket, bracketNumber));
						Display(screw.get(Display)).alpha = 0;
						
						var data:WaveMotionData = new WaveMotionData("rotation", 0);
						var wave:WaveMotion = new WaveMotion();
						wave.add(data);
						bracket.add(wave);
					}
					else
						interaction.reached.add(Command.create(unscrewBracket, bracketNumber, false));	
				}
			}
		}
		
		private function stressBracket(beam:Entity, motionDetected:Boolean, display:Entity):void
		{
			var data:WaveMotionData = WaveMotion(display.get(WaveMotion)).data[0];
			var bracket:Entity = getEntityById("bracket2");
			if(motionDetected)
			{
				data.magnitude = SHAKE_VELOCITY;
				if(bracket != null)
				{
					data = WaveMotion(bracket.get(WaveMotion)).data[0];
					data.magnitude = ROTATE_VELOCITY;
					//AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_hit_01.mp3");//doesn't sound good
				}
			}
			else
			{
				var tween:Tween = new Tween(data, "magnitude", Linear.easeNone, SHAKE_VELOCITY / 2, 0, 1, true);
				tween.start();
				if(bracket != null)
				{
					data = WaveMotion(bracket.get(WaveMotion)).data[0];
					tween = new Tween(data, "magnitude", Linear.easeNone, ROTATE_VELOCITY / 2, 0, 1, true);
					tween.start();
				}
			}
		}
		
		private function useScrewDriver():void
		{
			var bracket:Entity;
			var sceneInteraction:SceneInteraction;
			for(var i:int = 1; i <= 4; i++)
			{
				bracket = getEntityById("bracket"+i);
				if( bracket != null )
				{
					if( EntityUtils.distanceBetween( super.player, bracket ) < USE_DISTANCE)
					{
						if(i != 2)
						{
							_usingScrewDriver = true;	// TODO :: need to reset is SceneIntraction is interrupted. - Bard
						}
						
						sceneInteraction = bracket.get(SceneInteraction);
						sceneInteraction.activated = true;
						return;
					}
				}
			}
		}
		
		private function autoDropBracket(player:Entity, bracket:Entity, bracketNumber:int):void
		{
			var screw:Entity = getEntityById("screw"+bracketNumber);
			CharUtils.setAnim(player, Push);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(dropBracket, screw, bracket, bracketNumber )));
			lockControl()
		}
		
		private function unscrewBracket(player:Entity, bracket:Entity, bracketNumber:int, usingScrewDriver:Boolean):void
		{
			if(!_usingScrewDriver)
			{
				Dialog(player.get(Dialog)).sayById("on_tight");
			}
			else
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rusty_valve_01.mp3");
				_usingScrewDriver = false;	// reset flag
				SkinUtils.setSkinPart(player, SkinUtils.ITEM2, "armyknife", false);
				
				// TODO :: this should be set up at interaction creation?
				if(bracketNumber % 2 == 0)
					CharUtils.setDirection(player, true);
				else
					CharUtils.setDirection(player, false);
				
				SceneUtil.lockInput(this);
				CharUtils.setAnim(player, Knock);
				var screw:Entity = getEntityById("screw"+bracketNumber);
				TweenUtils.entityTo(screw, Spatial, 1, {rotation:-360, scale:1.5, ease:Linear.easeNone, onComplete:Command.create(dropBracket, screw, bracket, bracketNumber)});
			}
		}
		
		private function dropBracket(screw:Entity, bracket:Entity, bracketNumber:int):void
		{
			var oppositeBracket:int = bracketNumber + 1;
			if(bracketNumber % 2 == 0)
				oppositeBracket = bracketNumber - 1;
			if(shellApi.checkEvent(survival.REMOVED_BRACKET+oppositeBracket))
			{
				var seesawNumber:int = 1;
				if(bracketNumber > 2)
					seesawNumber = 2;
				getEntityById("seesaw"+seesawNumber).add( new SeeSaw(20,20,-20,20,getEntityById("tiltFloor"+seesawNumber)));
			}
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_hit_01.mp3");
			
			CharUtils.setState(player,CharacterState.STAND);
			
			Timeline(screw.get(Timeline)).gotoAndStop("side");
			var screwSpatial:Spatial = screw.get(Spatial);
			var bracketSpatial:Spatial = bracket.get(Spatial);
			SceneInteraction(bracket.get(SceneInteraction)).reached.removeAll();
			
			TweenUtils.entityTo(screw, Spatial, 1, {rotation:360, x:screwSpatial.x + 100, y:screwSpatial.y + 750, ease:Linear.easeIn});
			TweenUtils.entityTo(bracket, Spatial, 1.5, {rotation:360, x:bracketSpatial.x + 100, y:bracketSpatial.y + 750, ease:Linear.easeIn, onComplete:Command.create(removeBracket, screw, bracket, bracketNumber)});
		}
		
		private function removeBracket(screw:Entity, bracket:Entity, bracketNumber:int):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_impact_06.mp3");
			removeEntity(screw);
			removeEntity(bracket);
			shellApi.completeEvent(survival.REMOVED_BRACKET+bracketNumber);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM2, true);
			returnToPlayer()
		}
		
		////////////////////////////////////////// HOLLOW TREE //////////////////////////////////////////
		
		private function setUpFallZone():void
		{
			var fallZone:Zone = getEntityById("fallInTreeZone").get(Zone);
			fallZone.pointHit = true;
			fallZone.entered.add(fallInTree);
			
			var clip:MovieClip = _hitContainer["hollowTreeFront"];
			var treeFront:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(clip, true, true));
			treeFront.add(new Id("treeFront"));
			
			clip = _hitContainer["treeMask"];
			var treeMask:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(clip, true, true));
			treeMask.add(new Id("treeMask"));
		}
		
		private function fallInTree(zoneId:String, charId:String):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "chute_01.mp3");
			
			lockControl();
			var tree:DisplayObjectContainer = EntityUtils.getDisplayObject(getEntityById("treeFront"));
			var playerDisplay:DisplayObjectContainer = player.get(Display).displayObject;
			playerDisplay.mask = EntityUtils.getDisplayObject(getEntityById("treeMask"));
			DisplayUtils.moveToOverUnder(playerDisplay, tree, false);
			var destination:MovieClip = _hitContainer["destination"];
			TweenUtils.entityTo(player, Spatial, 1, {x:destination.x, y:destination.y, rotation:0, ease:Linear.easeOut, onComplete:fallOutOfTree});
			MotionUtils.zeroMotion(player);
			Motion(player.get(Motion)).pause = true;
			var hat:Entity = getEntityById(survival.HARD_HAT);
			if(hat != null)
				hat.add(new Item());
		}
		
		private function fallOutOfTree():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "sand_bag_01.mp3");
			
			var display:Display = player.get(Display);
			display.moveToFront();
			display.displayObject.mask = null;
			
			CharUtils.setAnim(player, Dizzy);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, returnToPlayer));
			MotionUtils.zeroMotion(player);
		}
		
		////////////////////////////////////////// LEVER STAIRS //////////////////////////////////////////
		
		private function setUpDropStep():void
		{
			var clip:MovieClip = _hitContainer["dropstep"];
			var dropSteps:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(clip, true, true));
			dropSteps.add(new Id("dropStep"));
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(dropSteps), clip);
			
			clip = _hitContainer["smallgear"];
			var stepGear:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(clip, true, true));
			stepGear.add(new Id("stepGear"));
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(stepGear), clip);
			
			clip = _hitContainer["Lever"];
			BitmapUtils.convertContainer(clip, bitmapQuailty);
			var lever:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			lever.add(new Id("leverBase")).add(new SceneInteraction());
			InteractionCreator.addToEntity(lever, ["click"], clip);
			var interaction:SceneInteraction = lever.get(SceneInteraction);
			interaction.minTargetDelta = new Point(10, 25);
			interaction.reached.add(pullLever);
			ToolTipCreator.addToEntity(lever);
			
			if(!shellApi.checkEvent(survival.DROPPED_STAIRS))
			{
				var stairs:Entity = getEntityById("dropLadder");
				stairs.remove(Platform);
				Spatial(dropSteps.get(Spatial)).rotation = 120;
				Spatial(stepGear.get(Spatial)).rotation = -90;
			}
			else
				Spatial(stepGear.get(Spatial)).rotation = 90;
			
			clip = clip["lever"];
			lever = EntityUtils.createSpatialEntity(this, clip, clip.parent);
			lever.add(new Id("lever"));
		}
		
		private function pullLever(player:Entity, base:Entity):void
		{
			lockControl();
			var drop:Boolean = !shellApi.checkEvent(survival.DROPPED_STAIRS);
			var baseSpatial:Spatial = base.get(Spatial);
			var playerSpatial:Spatial = player.get(Spatial);
			
			CharUtils.setDirection(player,!drop);
			CharUtils.setAnim(player, Pull);
			
			var direction:int = -1;
			if(drop)
				direction = 1;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_16.mp3");
			
			TweenUtils.entityTo(player, Spatial, 1, {x:baseSpatial.x + 50 * direction});
			var lever:Entity = getEntityById("lever");
			TweenUtils.entityTo(lever, Spatial, 1, {rotation:60 * direction, onComplete:Command.create(resetLever, lever, drop)});
		}
		
		private function resetLever(lever:Entity, drop:Boolean):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_17.mp3");
			CharUtils.setState(player, CharacterState.STAND);
			TweenUtils.entityTo(lever, Spatial, 1, {rotation:0, onComplete:Command.create(dropStairs, drop)})
		}
		
		private const STAIR_GEARS:String = "gears_heavy_01_loop.mp3";
		
		private function dropStairs(dropSteps:Boolean):void
		{
			var stairs:Entity = getEntityById("dropStep");
			var gear:Entity = getEntityById("stepGear");
			var platforms:Entity = getEntityById("dropLadder");
			SceneUtil.setCameraTarget(this, stairs);
			if(dropSteps)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "creaky_metal_11.mp3");
				platforms.add(new Platform());
				shellApi.completeEvent(survival.DROPPED_STAIRS);
				TweenUtils.entityTo(stairs, Spatial, 3, {rotation:0, ease:Bounce.easeOut, onComplete:stairsDropped});
				TweenUtils.entityTo(gear, Spatial, 3, {rotation:90, ease:Bounce.easeOut});
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 2, bounceLadder));
				SceneUtil.addTimedEvent(this, new TimedEvent(2.5, 1, bounceLadder));
			}
			else
			{
				platforms.remove(Platform);
				shellApi.removeEvent(survival.DROPPED_STAIRS);
				TweenUtils.entityTo(stairs, Spatial, 3, {rotation:120, ease:Linear.easeNone, onComplete:stairsDropped});
				TweenUtils.entityTo(gear, Spatial, 3, {rotation:-90, ease:Linear.easeNone});
			}
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + STAIR_GEARS,1, true);
		}
		
		private function bounceLadder():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + STAIR_GEARS);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_impact_03.mp3");
		}
		
		private function stairsDropped():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + STAIR_GEARS);
			returnToPlayer();
		}
		
		////////////////////////////////////////// PULLEY //////////////////////////////////////////
		
		private function setUpPulley():void
		{
			this.player.add(new Mass(30));
			
			var pulleyConnector:PulleyConnecter = new PulleyConnecter();
			var leftPlatform:Entity = getEntityById("leftPlatform");
			var rightPlatform:Entity = getEntityById("rightPlatform");
			leftPlatform.add(pulleyConnector);
			rightPlatform.add(pulleyConnector);
			
			rightPlatform.add(new Mass(80));
			leftPlatform.add(new Mass(80));
			
			var leftPulleyObject:PulleyObject = new PulleyObject(rightPlatform, 4200);
			leftPulleyObject.startMoving.add(pulleyStartMoving);
			leftPulleyObject.stopMoving.add(pulleyStopMoving);
			leftPulleyObject.wheel = bitmapToSprite(_hitContainer["pulleywheel1"], true, true);
			leftPulleyObject.wheelSpeedMultiplier = -.35;
			leftPlatform.add(leftPulleyObject);
			leftPlatform.add(new Audio());
			leftPlatform.add(new AudioRange(600));
			
			var rightPulleyObject:PulleyObject = new PulleyObject(leftPlatform, 4200);
			rightPulleyObject.startMoving.add(pulleyStartMoving);
			rightPulleyObject.stopMoving.add(pulleyStopMoving);
			rightPulleyObject.wheel = bitmapToSprite(_hitContainer["pulleywheel2"], true, true);
			rightPulleyObject.wheelSpeedMultiplier = .35;
			rightPlatform.add(rightPulleyObject);	
			rightPlatform.add(new Audio());
			rightPlatform.add(new AudioRange(600));
			
			var displayEntity:Entity = getEntityById("pulleyFloorLeft");
			var display:Display = displayEntity.get(Display);
			display.swapDisplayObject(bitmapToSprite(display.displayObject));
			display.disableMouse();
			var leftSpatial:Spatial = displayEntity.get(Spatial);
			var rope1:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(_hitContainer["cableLeft"], true, true));
			rope1.add(new PulleyRope(rope1.get(Spatial), leftSpatial));
			
			displayEntity = getEntityById("pulleyFloorRight");
			display = displayEntity.get(Display);
			display.swapDisplayObject(bitmapToSprite(display.displayObject));
			display.disableMouse();
			var rightSpatial:Spatial = displayEntity.get(Spatial);
			var rope2:Entity = EntityUtils.createSpatialEntity(this, bitmapToSprite(_hitContainer["cableRight"], true, true));
			rope2.add(new PulleyRope(rope2.get(Spatial), rightSpatial));
			this.addSystem(new PulleySystem(), SystemPriorities.checkCollisions);
		}
		
		private function bitmapToSprite(display:DisplayObjectContainer, remove:Boolean = false, add:Boolean = false):Sprite
		{
			var sprite:Sprite = BitmapUtils.createBitmapSprite(display, bitmapQuailty);
			if(add)
				_hitContainer.addChild(sprite);
			DisplayUtils.moveToOverUnder(sprite, display);
			if(remove)
				_hitContainer.removeChild(display);
			
			return sprite;
		}
		
		private function pulleyStartMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "wheel_squeak_04_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function pulleyStopMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.stop(SoundManager.EFFECTS_PATH + "wheel_squeak_04_loop.mp3");
		}
	}
}