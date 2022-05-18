package game.scenes.prison.cellBlock
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.ValidHit;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.PointPistol;
	import game.data.animation.entity.character.Salute;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.particles.emitter.WaterStream;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.cellBlock.popups.GuardUITimer;
	import game.scenes.prison.cellBlock.popups.VentChiselPopup;
	import game.scenes.prison.yard.Yard;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class CellBlock extends PrisonScene
	{
		public function CellBlock()
		{
			this.mergeFiles = true;
			super();			
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/cellBlock/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{			
			super.load();
		}
		
		override public function destroy():void
		{
			if(_door1Signal)
			{
				_door1Signal.removeAll();
				_door1Signal = null;
			}
			
			if(_door2Signal)
			{
				_door2Signal.removeAll();
				_door2Signal = null;
			}
			
			super.destroy();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_lightOverlay = EntityUtils.createSpatialEntity(this, _hitContainer["light_overlay"]);
			_lightOverlay = TimelineUtils.convertClip(_hitContainer["light_overlay"], this, _lightOverlay, null, false);
			DisplayUtils.moveToTop(_hitContainer["chains"]);			
			_validHit = new ValidHit("clip_pipe", "baseGround", "pipe", "corridor_concrete", "cell_concrete", "cell_bed", "climb1", "climb2");
			player.add(_validHit);
			
			_nightingale = getEntityById("nightingale");
			setupRadio();
			setupGrateAndBed();
			setupSink();
			
			if(shellApi.checkEvent(_events.SHOWN_CELL_INTRO))
			{
				DisplayUtils.moveToTop(_hitContainer["foreground_cell"]);
				DisplayUtils.moveToTop(_hitContainer["backToCellVent"]);
				// to be placed in the cell
				if(player.get(Spatial).y > 700)
				{
					_inCell = false; // gets changed in switch view
					setupGuard();
				}
				switchView();
				
				if(shellApi.checkEvent(_events.TRICKED_GUARD_FIRST) && !shellApi.checkHasItem(_events.PAINTED_DUMMY_HEAD))
					shellApi.getItem(_events.PAINTED_DUMMY_HEAD, shellApi.island, false);
			}			
			else
			{
				showIntro();
			}
			
			super.loaded();
		}
		
		override protected function eventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == "lock_up")
			{
				var screenEffects:ScreenEffects = new ScreenEffects(overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight);
				screenEffects.fadeToBlack(2, putInJail, new Array(screenEffects));
			}			
			else if(event == "goto_sleep")
			{
				SceneUtil.lockInput(this, true);
				var fx:ScreenEffects = new ScreenEffects(overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight);
				fx.fadeToBlack(2, wakeUp);
			}			
			else if(event == "use_spoon")
			{
				EntityUtils.removeAllWordBalloons(this, player);
				player.get(Dialog).sayById("regular_spoon");
				return;
			}
			else if(event == "use_metal_cup" || event == "use_plaster_cup" || event == "use_water_cup")
			{
				var playerSpatial:Spatial = player.get(Spatial);
				if(_inCell && _sinkOn && event != "use_water_cup")
				{
					if(playerSpatial.x >= 700 && playerSpatial.x <= 740) pullOutCup();
					CharUtils.moveToTarget(player, 720, 970, false, pullOutCup, new Point(20, 30)).setDirectionOnReached("left");
					return;
				}
				else if(!_inCell && playerSpatial.y > 770 && event != "use_plaster_cup")
				{
					if(playerSpatial.x >= 640 && playerSpatial.x <= 680) pullOutCup();
					CharUtils.moveToTarget(player, 660, 970, false, pullOutCup, new Point(20,40)).setDirectionOnReached("right");
					return;
				}				
			}
			else if(event == "use_painted_head")
			{
				// check if the guard is gone
				if(!_guardHere && _inCell)
				{
					CharUtils.moveToTarget(player, 500, 970, false, placeHead).setDirectionOnReached("left");
					return;
				}
				else
				{
					EntityUtils.removeAllWordBalloons(this, player);
					player.get(Dialog).sayById("guard_here");
					return;
				}				
			}
			
			super.eventTriggered(event, makeCurrent, init, removeEvent);
		}
		
		private function switchView():void
		{
			_inCell = !_inCell;
			
			if(_nightingale) _nightingale.get(Display).visible = _inCell;
			getEntityById("background0").get(Display).visible = _inCell;
			_hitContainer["backToCellVent"].visible = !_inCell;
			_hitContainer["foreground_cell"].visible = _inCell;
			_hitContainer["sinkFront"].visible = _inCell;
			
			_validHit.setHitValidState("cell_concrete", _inCell);
			_validHit.setHitValidState("cell_bed", _inCell);
			_validHit.setHitValidState("cell_wall", _inCell);
			_validHit.setHitValidState("cell_ceiling", _inCell);
			_validHit.setHitValidState("clip_pipe", !_inCell);
			_lightOverlay.get(Display).visible = _inCell;
			
			if(_head)
			{
				_head.get(Display).visible = _inCell;
			}
			
			EntityUtils.lockSceneInteraction(_plaster, _inCell);
			EntityUtils.lockSceneInteraction(getEntityById("sinkInteraction"), !_inCell);
			EntityUtils.lockSceneInteraction(getEntityById("radioInteraction"), !_inCell);
			EntityUtils.lockSceneInteraction(getEntityById("bedInteraction"), !_inCell);
			getEntityById("radioInteraction").get(Display).visible = _inCell;
			_sinkOn = true;
			sinkChange();
			
			var motionBounds:MotionBounds = player.get(MotionBounds);		
			if(_inCell)
			{
				shellApi.triggerEvent("in_the_cell");
				motionBounds.box = new Rectangle(350, 700, 645, 1113);
				shellApi.camera.camera.resize(shellApi.viewportWidth, shellApi.viewportHeight, 1358, 662, 0, 460);
			}
			else
			{
				shellApi.triggerEvent("behind_cell");
				motionBounds.box = new Rectangle(0, 0, 1358, 970);
				shellApi.camera.camera.resize(shellApi.viewportWidth, shellApi.viewportHeight, 1358, 980, 0, 0);
			}
		}
		
		private function setupGuard():void
		{		
			EntityUtils.turnOffSleep(_nightingale);
			EntityUtils.position(_nightingale, 1040, 1045);
			DisplayUtils.moveToTop(_nightingale.get(Display).displayObject);
			
			_nightingale.add(new ValidHit("baseGround"));
			SkinUtils.setSkinPart(_nightingale, SkinUtils.ITEM, "flashlight");
			
			SceneUtil.lockInput(this, true);
			var dialog:Dialog = _nightingale.get(Dialog);
			dialog.sayById("lights_out");
			dialog.complete.addOnce(guardWalk);
		}
		
		private function setupGrateAndBed():void
		{
			var grate:Entity = getEntityById("grateInteraction");
			var sceneInteraction:SceneInteraction = new SceneInteraction();			
			grate.add(sceneInteraction);
			sceneInteraction.minTargetDelta = new Point(30, 100);
			sceneInteraction.reached.add(reachedGrate);
			grate.get(Interaction).click.add(clickedGrate);
			
			var bed:Entity = getEntityById("bedInteraction");
			var bedInteraction:SceneInteraction = new SceneInteraction();
			bed.add(bedInteraction);
			bedInteraction.minTargetDelta = new Point(20, 50);
			bedInteraction.reached.add(reachedBed);
			
			if(!shellApi.checkEvent(_events.TRICKED_GUARD_FIRST))
			{
				var door1Int:Interaction = getEntityById("door1").get(Interaction);
				var door2Int:Interaction = getEntityById("door2").get(Interaction);
				
				_door1Signal = door1Int.click;
				door1Int.click = new Signal();
				door1Int.click.add(doorLocked);
				
				_door2Signal = door2Int.click;
				door2Int.click = new Signal();
				door2Int.click.add(doorLocked);
			}
		}
		
		private function setupSink():void
		{
			var sink:Entity = getEntityById("sinkInteraction");
			var sceneInt:SceneInteraction = new SceneInteraction();
			sceneInt.reached.add(sinkChange);
			sink.add(sceneInt);
			
			_waterStream = new WaterStream();
			_waterStream.init(new Rectangle(-2.5, 0, 5, 15), 15, 4, 0x3399CC, .7, 50);
			
			_waterFaucet = EntityUtils.createSpatialEntity(this, _hitContainer["faucet"]);
			_waterFaucet.add(new Audio()).add(new AudioRange(300, 0, .4, Quad.easeOut));
			EmitterCreator.create(this, _hitContainer["faucet"], _waterStream, 0, 0, _waterFaucet, null, null, false);
		}
		
		private function setupRadio():void
		{
			_radio = getEntityById("radioInteraction");
			TimelineUtils.convertClip(_radio.get(Display).displayObject, this, _radio, null, false);
			var sceneInt:SceneInteraction = new SceneInteraction();
			sceneInt.reached.add(radioClicked);
			_radio.add(sceneInt);
			
			_radio.add(new Audio());
			_radio.add(new AudioRange(600, 0, 1));
			
			_plaster = getEntityById("plasterInteraction");
			_plaster.get(Interaction).click.add(clickedPlasterPile);
			
			var plasterGlint:Entity = TimelineUtils.convertClip(_hitContainer["plasterSparkle"], this, null, null, false);
			randomGlint(plasterGlint);
		}
		
		private function randomGlint(glint:Entity):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(GeomUtils.randomInRange(2,3), 1, Command.create(playGlint, glint)));
		}
		
		private function playGlint(glint:Entity):void
		{
			if(!_inCell)
			{
				glint.get(Timeline).gotoAndPlay("glint");
			}
			randomGlint(glint);
		}
		
		private function sinkChange(...args):void
		{
			_sinkOn = !_sinkOn;
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wheel_squeak_02.mp3");
			var audio:Audio = _waterFaucet.get(Audio);
			
			if(_sinkOn)
			{
				// start water particle effect & Audio
				audio.play(WATER_FAUCET, true, [SoundModifier.POSITION, SoundModifier.FADE]);
				_waterStream.start();
			}
			else
			{
				audio.stop(WATER_FAUCET, SoundType.EFFECTS);
				_waterStream.counter.stop();
			}
		}
			
		private function showIntro():void
		{
			SceneUtil.lockInput(this, true);
			DisplayUtils.moveToTop(Display(this.player.get(Display)).displayObject);
			EntityUtils.position(player, 1430, 1070);
			
			var cmc:CharacterMotionControl = player.get(CharacterMotionControl);
			cmc.maxVelocityX = 100;
			
			_nightingale.get(Dialog).sayById("start_intro");
			var ratchet:Entity = getEntityById("ratchet");
			
			CharUtils.moveToTarget(player, 665, 1100, false);
			CharUtils.moveToTarget(_nightingale, 580, 1100, true);
			CharUtils.moveToTarget(ratchet, 750, 1100, true);
			_nightingale.get(CharacterMotionControl).maxVelocityX = 100;
			ratchet.get(CharacterMotionControl).maxVelocityX = 100;
		}
		
		private function putInJail(screenEffects:ScreenEffects):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "door_prison_01.mp3");
			player.get(Spatial).y = 980;
			_inCell = false;
			switchView();
			removeEntity(getEntityById("ratchet"));
			DisplayUtils.moveToTop(_hitContainer["foreground_cell"]);
			player.get(CharacterMotionControl).maxVelocityX = 800;		
			
			setupGuard();			
			screenEffects.fadeFromBlack(1, introDone);
		}
		
		private function introDone():void
		{
			SceneUtil.lockInput(this, false, false);
			shellApi.completeEvent(_events.SHOWN_CELL_INTRO);
		}
		
		private function reachedGrate(...args):void
		{			
			if(_inCell)
			{				
				// Check to see if they've chiseled the grate
				if(shellApi.checkEvent(_events.CELL_GRATE_OPEN))
				{
					if(_guardHere)
					{
						EntityUtils.removeAllWordBalloons(this, player);
						player.get(Dialog).sayById("vent_locked");
						return;
					}		
					
					switchView();
				}
				else
				{
					if(_guardHere)
					{
						EntityUtils.removeAllWordBalloons(this, player);
						player.get(Dialog).sayById("guard_here");
						return;
					}
					
					_ventChisel = new VentChiselPopup(overlayContainer);
					_ventChisel.removed.addOnce(chiselPopupClosed);
					addChildGroup(_ventChisel);
					DisplayUtils.moveToTop(_guardTimer.groupContainer);
				}				
			}
			else
			{
				if(shellApi.checkEvent(_events.TRICKED_GUARD_FIRST))
				{
					if(shellApi.checkEvent(_events.ESCAPED_BIG_TUNA))
					{
						EntityUtils.removeAllWordBalloons(this, player);
						player.get(Dialog).sayById("busting_out");
					}
					else
					{
						EntityUtils.removeAllWordBalloons(this, player);
						player.get(Dialog).sayById("sleep");
					}
				}
				else
				{
					switchView();
				}
			}
		}
		
		private function clickedGrate(...args):void
		{
			if(shellApi.checkEvent(_events.TRICKED_GUARD_FIRST) && _inCell && !_guardHere)
			{
				CharUtils.moveToTarget(player, 500, 970, true, placeHead).setDirectionOnReached("left");
			}
		}
		
		private function chiselPopupClosed(popup:VentChiselPopup):void
		{
			DisplayUtils.moveToBack(_guardTimer.groupContainer);
			_guardTimer.showFull();
			EntityUtils.removeAllWordBalloons(this, player);
			
			// run guard over
			if(_ventChisel.caught)
			{
				SceneUtil.lockInput(this, true);
				CharUtils.moveToTarget(_nightingale, player.get(Spatial).x - 50, 1080, false, guardCaughtPlayer, new Point(20, 50));
				_nightingale.get(CharacterMotionControl).maxVelocityX = 400;
			}
			
			_ventChisel = null;			
			if(shellApi.checkHasItem(_events.SHARPENED_SPOON))
			{
				// finished
				if(shellApi.checkEvent(_events.CELL_GRATE_OPEN)) 
				{
					CharUtils.lockControls(player, false, false);
					player.get(Dialog).sayById("finished_chisel");
					shellApi.takePhotoByEvent("chiseled_vent_photo");
				}
			}
			else if(shellApi.checkHasItem(_events.SPOON))
			{
				player.get(Dialog).sayById("regular_spoon");
			}
			else
			{
				player.get(Dialog).sayById("no_spoon");
			}
		}
		
		private function clickedPlasterPile(...args):void
		{
			EntityUtils.removeAllWordBalloons(this, player);
			player.get(Dialog).sayById("plaster");
		}
		
		private function reachedBed(...args):void
		{
			EntityUtils.removeAllWordBalloons(this, player);
			if(shellApi.checkEvent(_events.ESCAPED_BIG_TUNA))
			{
				player.get(Dialog).sayById("busting_out");
			}
			else
			{
				player.get(Dialog).sayById("sleep");
			}
		}
		
		private function wakeUp():void
		{			
			if(currentDay == 0)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "alarm_03.mp3", 1, true);
				SceneUtil.delay(this, 2, Command.create(shellApi.loadScene, Yard));
			}
			else
			{					
				openSchedule(this);
			}
			
			if(shellApi.checkEvent(_events.TRICKED_GUARD_FIRST))
				shellApi.getItem(_events.PAINTED_DUMMY_HEAD, shellApi.island, false);
			
			currentDay++;
			shellApi.setUserField(_events.DAYS_IN_PRISON_FIELD, currentDay.toString(), shellApi.island, true);
		}
		
		/**
		 * Start guard walk and add the UI
		 */
		private function guardWalk(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "switch_03_verb.mp3");
			SceneUtil.lockInput(this, false, false);
			_lightOverlay.get(Timeline).gotoAndStop("off");
			
			_nightingale.add(new PlatformDepthCollider(1));
			CharUtils.moveToTarget(_nightingale, -50, 1080, false, addGuardUI);
			_nightingale.get(CharacterMotionControl).maxVelocityX = 170;
			
			var motionBounds:MotionBounds = _nightingale.get(MotionBounds);
			motionBounds.box = new Rectangle(-100, 0, 1600, 1080);
		}
		
		private function pullOutCup(...args):void
		{
			SceneUtil.lockInput(this, true);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "prison_cup", false);
			CharUtils.setAnim(player, PointPistol);
			CharUtils.getTimeline(player).handleLabel("ending", giveCup);
		}
		
		private function giveCup(...args):void
		{
			var cup:String = _inCell ? _events.CUP_OF_WATER : _events.CUP_OF_PLASTER;		
			var removeCup:String = _inCell ? _events.CUP_OF_PLASTER : _events.CUP_OF_WATER;
			
			shellApi.getItem(cup, null, true);
			shellApi.removeItem(_events.METAL_CUP);
			shellApi.removeItem(removeCup);
			
			shellApi.saveGame();
			SceneUtil.lockInput(this, false);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM);
		}
		
		private function addGuardUI(...args):void
		{			
			_guardHere = false;
			
			// if vent open and player has used the painted dummy head
			if(shellApi.checkEvent(_events.CELL_GRATE_OPEN) && shellApi.checkEvent(_events.TRICKED_GUARD_FIRST))
			{
				// this makes it so I can take control and put the painted head in bed
				getEntityById("grateInteraction").get(SceneInteraction).approach = false;
			}
			
			if(shellApi.checkEvent(_events.ESCAPED_BIG_TUNA))
				return;
			
			_guardTimer = new GuardUITimer(overlayContainer);
			this.addChildGroup(_guardTimer);
			DisplayUtils.moveToBack(_guardTimer.groupContainer);
			_guardTimer.completed.addOnce(bringGuardBackIn);	
			_guardTimer.removed.addOnce(guardUIGone);			
		}
		
		private function bringGuardBackIn():void
		{			
			if(!_ventChisel)
			{
				if(!_inCell)
				{
					EntityUtils.removeAllWordBalloons(this, player);
					player.get(Dialog).sayById("back_to_bed");
					var screenEffects:ScreenEffects = new ScreenEffects(overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight);
					screenEffects.fadeToBlack(4, wakeUp);
					return;
				}
				_guardHere = true;
				CharUtils.moveToTarget(_nightingale, 1100, 1080).setDirectionOnReached("left");
			}			
		}
		
		private function guardCaughtPlayer(...args):void
		{
			var dialog:Dialog = _nightingale.get(Dialog);
			dialog.sayById("caught");
			dialog.complete.add(giveGum);
		}
		
		private function giveGum(data:DialogData):void
		{
			if(data.id == "caught2")
			{
				_nightingale.get(Dialog).complete.removeAll();
				this.removePlayerGum(5, "nightingale");
				SceneUtil.delay(this, 1, caughtFadeOut);				
			}
		}
		
		private function caughtFadeOut(...args):void
		{
			var screenEffects:ScreenEffects = new ScreenEffects(overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight);
			screenEffects.fadeToBlack(2, wakeUp);
		}
		
		private function guardUIGone(...args):void
		{
			_guardTimer = null;
		}
		
		private function radioClicked(...args):void
		{
			CharUtils.setAnim(player, Salute);
			var audio:Audio = _radio.get(Audio);
			audio.stopAll();
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "button_03.mp3");
			
			_currentRadioNum++;
			if(_currentRadioNum > 4)
			{
				_currentRadioNum = 0;
				_radio.get(Timeline).gotoAndStop(0);
				return;
			}
			
			_radio.get(Timeline).gotoAndStop(1);
			var randInt:int = GeomUtils.randomInt(1, 4);
			var wrapper:AudioWrapper = audio.play(RADIO_FX + randInt + ".mp3");
			wrapper.complete.addOnce(nextRadioAudio);
		}
		
		private function nextRadioAudio(...args):void
		{			
			var audio:Audio = _radio.get(Audio);			
			audio.play(RADIO_MUSIC + _currentRadioNum + ".mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function placeHead(...args):void
		{
			CharUtils.lockControls(player, true);
			
			if(!shellApi.checkEvent(_events.TRICKED_GUARD_FIRST))
			{								
				if(_door1Signal && _door2Signal)
				{
					var door1Int:Interaction = getEntityById("door1").get(Interaction);
					door1Int.click.removeAll();
					door1Int.click = _door1Signal;
					
					var door2Int:Interaction = getEntityById("door2").get(Interaction);
					door2Int.click.removeAll();
					door2Int.click = _door1Signal;
				}
				SceneUtil.lockInput(this, true);
			}
			
			_itemGroup.takeItem(_events.PAINTED_DUMMY_HEAD, "bedInteraction");
			shellApi.removeItem(_events.PAINTED_DUMMY_HEAD);
			CharUtils.setAnim(player, PointItem);
			CharUtils.getTimeline(player).handleLabel("ending", putPaintedHeadInBed);
		}
		
		private function putPaintedHeadInBed():void
		{
			var playerLook:LookData = SkinUtils.getLook(player).duplicate();
			playerLook.setValue(SkinUtils.EYE_STATE, "closed");
			
			_head = _characterGroup.createDummy("player_head", playerLook, "right", CharacterCreator.VARIANT_HEAD, _hitContainer, null, null, false, .3, "dummy", new Point( 420, 930));
			var spatial:Spatial = _head.get(Spatial);
			spatial.rotation = -90;
			DisplayUtils.moveToBack(_head.get(Display).displayObject);
			
			this.removeGroup(_guardTimer);
			_guardTimer = null;
			CharUtils.moveToTarget(player, 800, 970, true, playerAtVent);
		}
		
		private function playerAtVent(entity:Entity):void
		{
			if(!shellApi.checkEvent(_events.TRICKED_GUARD_FIRST))
			{
				player.get(Display).visible = false;
				CharUtils.moveToTarget(_nightingale, 1040, 1045, true);				
				SceneUtil.delay(this, 4, sayEveryoneSleep);		
			}
			else
			{
				playerSuccessfullyThrough();
			}
		}
		
		private function sayEveryoneSleep():void
		{
			var dialog:Dialog = _nightingale.get(Dialog);
			dialog.sayById("painted_head");
			dialog.complete.addOnce(playerSuccessfullyThrough);
			shellApi.completeEvent(_events.TRICKED_GUARD_FIRST);
		}
		
		private function playerSuccessfullyThrough(...args):void
		{
			SceneUtil.lockInput(this, false, false);
			player.get(Display).visible = true;
			switchView();
			CharUtils.lockControls(player, false, false);
			EntityUtils.position(_nightingale, 1040, 1045);
			getEntityById("grateInteraction").get(SceneInteraction).approach = true;
		}
		
		private function doorLocked(...args):void
		{
			EntityUtils.removeAllWordBalloons(this, player);
			player.get(Dialog).sayById("door_locked");
		}
		
		private var _validHit:ValidHit;
		private var _inCell:Boolean = true;
		private var _grate:Entity;
		private var _lightOverlay:Entity;
		
		private const RADIO_FX:String = SoundManager.EFFECTS_PATH + "prison_radio_";
		private const RADIO_MUSIC:String = SoundManager.MUSIC_PATH + "PrisonRadio_";
		private var _radio:Entity;
		private var _radioOn:Boolean = false;
		private var _currentRadioNum:int = 0;
		
		private var _plaster:Entity;
		
		private const WATER_FAUCET:String = SoundManager.EFFECTS_PATH + "water_fountain_large_01_loop.mp3";
		private var _sinkOn:Boolean = false;
		private var _waterStream:WaterStream;
		private var _waterFaucet:Entity;
		
		private var _nightingale:Entity;
		private var _guardHere:Boolean = true;
		private var _ventChisel:VentChiselPopup;
		private var _guardTimer:GuardUITimer;
		
		private var _door1Signal:Signal;
		private var _door2Signal:Signal;
		
		private var _head:Entity;
	}
}