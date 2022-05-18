package game.scenes.survival4.guestRoom
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Bounce;
	import game.components.hit.Platform;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.PointPistol;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Tremble;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival4.shared.Survival4Scene;
	import game.components.entity.Detector;
	import game.systems.entity.DetectionSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class GuestRoom extends Survival4Scene
	{
		public function GuestRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival4/guestRoom/";
			
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
			
			shellApi.eventTriggered.add(handleEventTrigger);
			_events = super.events as Survival4Events;
			
			setupDoor();
			setupCameras();
			setupLightGame();
			setupWindow();
			
			if(shellApi.checkEvent(_events.GUEST_ROOM_INTRO))
			{
				showIntro();
			}
			
			if(!shellApi.checkItemEvent(_events.BEAR_CLAW))
			{
				_bearClaw = EntityUtils.createSpatialEntity(this, _hitContainer["bearClaw"]);
				InteractionCreator.addToEntity(_bearClaw, [InteractionCreator.CLICK]);
				ToolTipCreator.addToEntity(_bearClaw);
				
				_glint = TimelineUtils.convertClip(_hitContainer["clawSparkle"], this, null, null, false);
				randomGlint(_glint);
				
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.addOnce(reachedBearClaw);
				_bearClaw.add(sceneInteraction);
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["bearClaw"]);
				_hitContainer.removeChild(_hitContainer["clawSparkle"]);
			}
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.USE_BEAR_CLAW)
			{				
				CharUtils.moveToTarget(player, 850, 690, true, Command.create(playerAtDoor, null, true), new Point(30, 100)).validCharStates = new <String>[CharacterState.STAND];
			}
			else if( event == _events.USE_EMPTY_PITCHER || event == _events.USE_FULL_PITCHER || event == _events.USE_ARMORY_KEY || event == _events.USE_SPEAR || event == _events.USE_TAINTED_MEAT || event == _events.USE_TROPHY_ROOM_KEY )
			{
				player.get(Dialog).sayById("no_use");
			}
		}
		
		private function randomGlint(glint:Entity):void
		{
			_randomGlint = SceneUtil.addTimedEvent(this, new TimedEvent(Math.random() * 4 + 2, 1, Command.create(playGlint, glint)));
		}
		
		private function playGlint(glint:Entity):void
		{
			glint.get(Timeline).gotoAndPlay("glint");
			randomGlint(glint);
		}
		
		private function reachedBearClaw(clicker:Entity, claw:Entity):void
		{
			SceneUtil.lockInput(this, true);
			CharUtils.moveToTarget(player, 565, 680, true, pickUpClaw, new Point(20, 80)).validCharStates = new <String>[CharacterState.STAND];
			_randomGlint.stop();
			_randomGlint = null;
		}
		
		private function pickUpClaw(player:Entity):void
		{
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, Place);
			CharUtils.getTimeline(player).handleLabel("trigger", pickedUpClaw);
			CharUtils.getTimeline(player).handleLabel("ending", giveBearClaw);
		}
		
		private function pickedUpClaw():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "flint_strike_03.mp3");
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "bearclaw", false);
			this.removeEntity(_bearClaw);
			this.removeEntity(_glint);
		}
		
		private function giveBearClaw():void
		{
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "empty");
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.BEAR_CLAW, null);
			SceneUtil.lockInput(this, false);
		}
		
		// If first time in the guest room, show the butler locking the door
		private function showIntro():void
		{
			var playerSpatial:Spatial = player.get(Spatial);
			playerSpatial.x = 150;
			playerSpatial.y = 580;
			CharUtils.setAnim(player, Sleep);
			
			var bounce:Entity = getEntityById("bounce");
			bounce.remove(Bounce);
			bounce.add(new Platform());
			
			SceneUtil.lockInput(this, true);
			var butler:Entity = getEntityById("butler");
			var characterGroup:CharacterGroup = getGroupById("characterGroup") as CharacterGroup;
			characterGroup.addAudio(butler);
			SceneUtil.setCameraTarget(this, butler);
			CharUtils.setAnim(butler, PointPistol);
			CharUtils.getTimeline(butler).handleLabel("ending", Command.create(butlerLockedDoor, butler));
		}
		
		// Butler animation done, now walk away
		private function butlerLockedDoor(butler:Entity):void
		{
			var motionControl:CharacterMotionControl = new CharacterMotionControl();
			motionControl.maxVelocityX = 300;
			butler.add(motionControl);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, Command.create(butlerGone, butler)));
			CharUtils.moveToTarget(butler, 2500, 920, true, null, new Point(10, 100));
		}
		
		// Once the butler is gone, go back to the player sleeping
		private function butlerGone(butler:Entity):void
		{
			SceneUtil.setCameraTarget(this, player, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, playerAwake));
			var camera:Camera = shellApi.camera.camera;
			camera.resize(camera.viewport.width, camera.viewport.height, shellApi.viewportWidth, shellApi.viewportHeight, 0, 100);
			
			this.removeEntity(butler, true);
			shellApi.removeEvent(_events.GUEST_ROOM_INTRO);
		}
		
		private function playerAwake():void
		{
			CharUtils.setAnim(player, Dizzy);
			CharUtils.getTimeline(player).gotoAndPlay("loop");
			SkinUtils.setEyeStates(player, EyeSystem.SQUINT);
			
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("wake_up");
			dialog.complete.addOnce(moveOffBed);
		}
		
		private function moveOffBed(dialogData:DialogData):void
		{
			CharUtils.stateDrivenOn(player);
			CharUtils.moveToTarget(player, 385, 690, false, awakeAndUp).validCharStates = new <String>[CharacterState.STAND];
		}
		
		private function awakeAndUp(entity:Entity):void
		{
			SceneUtil.lockInput(this, false);
			var bounce:Entity = getEntityById("bounce");
			var bounceComponent:Bounce = new Bounce();
			bounceComponent.velocity = new Point(0, -1100);
			bounce.add(bounceComponent);
			bounce.remove(Platform);
		}
		
		private function playerAtDoor(entity:Entity, other:Entity, claw:Boolean):void
		{
			CharUtils.setDirection(player, true);
			
			if(claw)
			{
				SkinUtils.setSkinPart(player, SkinUtils.ITEM, "bearclaw", false);			
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "lock_jiggle_01.mp3");
			}
			CharUtils.setAnim(player, PointPistol);
			CharUtils.getTimeline(player).handleLabel("ending", Command.create(breakClaw, claw));
		}
		
		private function breakClaw(claw:Boolean):void
		{
			if(claw)
			{
				SkinUtils.setSkinPart(player, SkinUtils.ITEM, "empty");
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "lock_click_01.mp3");
			}
			else
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "door_light_open_creak_03.mp3");
			}
				
			EntityUtils.removeInteraction(_roomDoor);
			var doorTimeline:Timeline = _roomDoor.get(Timeline);
			doorTimeline.gotoAndPlay("open");
			doorTimeline.handleLabel("opened", Command.create(doorOpened, claw));
		}
		
		private function doorOpened(claw:Boolean):void
		{
			var doorDisplay:* = _roomDoor.get(Display).displayObject;
			doorDisplay.mouseEnabled = false;
			doorDisplay.mouseChildren = false;
			
			if(claw)
			{
				var dialog:Dialog = player.get(Dialog);
				dialog.sayById("picked_lock");
				dialog.complete.addOnce(doorDialogDone);
				shellApi.removeItem(_events.BEAR_CLAW);
				shellApi.completeEvent(_events.OPENED_GUEST_DOOR);
			}
			
			var camera:Camera = shellApi.camera.camera;
			camera.resize(camera.viewport.width, camera.viewport.height, 2880, 740, 0, 0);
			
			// turn cameras on
			if(!shellApi.checkEvent(_events.CAMERAS_DISABLED))
			{
				this.addSystem(new DetectionSystem(), SystemPriorities.resolveCollisions);
				this.addSystem(new WaveMotionSystem());
				for(var i:int = 0; i < _cameras.length; i++)
				{
					_cameras[i].get(Timeline).gotoAndStop("on");
					_cameras[i].get(Audio).play(SoundManager.EFFECTS_PATH + "robot_move_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				}
			}
			
			removeEntity(getEntityById("doorWall"));
			CharUtils.stateDrivenOn(player, true);
		}
		
		private function doorDialogDone(dialogData:DialogData):void
		{
			SceneUtil.lockInput(this, false, false);
		}
		
		private function setupWindow():void
		{
			var window:Entity = ButtonCreator.createButtonEntity(_hitContainer["windowButton"], this, windowClicked, _hitContainer, [InteractionCreator.CLICK], ToolTipType.CLICK);
		}
		
		private function windowClicked(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("window_bars");
		}
		
		private function setupDoor():void
		{
			_roomDoor = EntityUtils.createSpatialEntity(this, _hitContainer["roomDoor"]);
			_roomDoor = TimelineUtils.convertClip(_hitContainer["roomDoor"], this, _roomDoor);
		
			if(shellApi.player.get(Spatial).x < 600)
			{
				if(!shellApi.checkEvent(_events.GUEST_ROOM_INTRO))
				{
					var camera:Camera = shellApi.camera.camera;
					camera.resize(camera.viewport.width, camera.viewport.height, shellApi.viewportWidth, shellApi.viewportHeight, 0, 100 * 640/shellApi.viewportHeight);
				}
				
				_roomDoor.get(Timeline).gotoAndStop("closed");
				InteractionCreator.addToEntity(_roomDoor, [InteractionCreator.CLICK]);
				ToolTipCreator.addToEntity(_roomDoor);
				
				if(!shellApi.checkEvent(_events.OPENED_GUEST_DOOR))
				{
					Interaction(_roomDoor.get(Interaction)).click.add(roomDoorClicked);
				}
				else
				{
					var sceneInter:SceneInteraction = new SceneInteraction();
					sceneInter.reached.addOnce(Command.create(playerAtDoor, false));
					_roomDoor.add(sceneInter);
				}
			}
			else
			{
				_roomDoor.get(Timeline).gotoAndStop("opened");
				removeEntity(getEntityById("doorWall"));
			}			
		}
		
		private function roomDoorClicked(entity:Entity):void
		{
			player.get(Dialog).sayById("door_locked");
		}
		
		private function setupCameras():void
		{			
			_cameras = new Vector.<Entity>();
			for(var i:int = 1; i <= 2; i++)
			{
				_hitContainer["camera" + i].mouseEnabled = false;
				_hitContainer["camera" + i].mouseChildren = false;
				DisplayUtils.moveToTop(_hitContainer["camera" + i]);
				var camera:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["camera" + i]);
				BitmapTimelineCreator.convertToBitmapTimeline(camera);
				camera.get(Timeline).gotoAndStop("off");
				
				if(shellApi.checkEvent(_events.CAMERAS_DISABLED))
				{
					_cameras = null;
				}
				else
				{
					var detector:Detector = new Detector(16, 715, 90);
					detector.detectorHit.addOnce(playerDetected);
					camera.add(detector);
					
					camera.add(new SpatialAddition());
					var waveMotion:WaveMotion = new WaveMotion();
					camera.add(waveMotion);
					
					var start:Number = i == 1 ? -1 : 1;
					waveMotion.data.push(new WaveMotionData("rotation", 32 * start, .012, "sin", 0));
					_cameras.push(camera);
					
					var cameraAudio:Audio = new Audio();
					camera.add(cameraAudio);
					camera.add(new AudioRange(800, 0, 1, Sine.easeIn));
					
					if(shellApi.checkEvent(_events.OPENED_GUEST_DOOR))
					{
						this.addSystem(new WaveMotionSystem());
						camera.get(Timeline).gotoAndStop("on");
						cameraAudio.play(SoundManager.EFFECTS_PATH + "robot_move_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
					}
				}				
			}			
					
			var doorLight:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["doorLight"]);
			BitmapTimelineCreator.convertToBitmapTimeline(doorLight);
			
			var securityPanel:Entity = getEntityById("securityPanelInteraction");
			securityPanel = TimelineUtils.convertClip(_hitContainer["securityPanelInteraction"], this, securityPanel);
			SceneInteraction(securityPanel.get(SceneInteraction)).reached.addOnce(Command.create(securityPanelClicked, doorLight));
			
			if(shellApi.checkEvent(_events.CAMERAS_DISABLED))
			{
				doorLight.get(Timeline).gotoAndStop("off");
				EntityUtils.removeInteraction(securityPanel);
				securityPanel.get(Timeline).gotoAndStop("off");
			}
			else if(shellApi.checkEvent(_events.OPENED_GUEST_DOOR))
			{
				this.addSystem(new DetectionSystem(), SystemPriorities.resolveCollisions);
			}
		}
		
		// When the security camera is clicked, switch the state of the system
		private function securityPanelClicked(clicker:Entity, panel:Entity, doorLight:Entity):void
		{
			shellApi.triggerEvent(_events.CAMERAS_DISABLED, true);
			panel.get(Timeline).gotoAndStop("off");
			EntityUtils.removeInteraction(panel);
			
			doorLight.get(Timeline).gotoAndStop("off");
			this.removeSystemByClass(DetectionSystem);
			this.removeSystemByClass(WaveMotionSystem);
			
			for each(var cam:Entity in _cameras)
			{
				cam.get(Timeline).gotoAndPlay("turnOff");
				cam.get(Audio).stop(SoundManager.EFFECTS_PATH + "robot_move_01_L.mp3");
			}			
		}
		
		private function setupLightGame():void
		{
			_tapestry = EntityUtils.createSpatialEntity(this, _hitContainer["tapestry"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(_tapestry);
			_tapestry.get(Timeline).gotoAndStop("yellow");
			yellowOn = true;
			
			var redLight:Entity = getEntityById("interactionRed");
			SceneInteraction(redLight.get(SceneInteraction)).reached.add(lightClicked);
			
			var yellowLight:Entity = getEntityById("interactionYellow");
			SceneInteraction(yellowLight.get(SceneInteraction)).reached.add(lightClicked);
			
			var blueLight:Entity = getEntityById("interactionBlue");
			SceneInteraction(blueLight.get(SceneInteraction)).reached.add(lightClicked);
		}
		
		private function playerDetected(player:Entity):void
		{
			CharUtils.lockControls(player);
			SceneUtil.lockInput(this, true);
			this.removeSystemByClass(WaveMotionSystem);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "alarm_06.mp3", 1, true);
			var control:FSMControl = player.get(FSMControl);
			if(control.state.type == CharacterState.STAND)
			{
				caught(CharacterState.STAND, player);
			}
			else
			{
				control.stateChange = new Signal();
				control.stateChange.add(caught);
			}
		}
		
		private function caught(state:String, player:Entity):void
		{
			if(state == CharacterState.STAND)
			{
				CharUtils.setAnim(player, Tremble);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, showButlerPopup));
			}
		}
		
		private function showButlerPopup():void
		{
			SceneUtil.lockInput(this, false);
			var butlerPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			butlerPopup.updateText("You were caught sneaking around! Back to your room...", "Try Again");
			butlerPopup.configData("butlerPopup.swf", "scenes/survival4/shared/butlerPopup/");
			butlerPopup.popupRemoved.addOnce(butlerPopupClosed);
			addChildGroup(butlerPopup);
		}
		
		private function butlerPopupClosed():void
		{
			shellApi.loadScene(GuestRoom);
		}
		
		private function lightClicked(clicker:Entity, light:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "button_01.mp3");
			var id:Id = light.get(Id);
			switch(id.id)
			{
				case "interactionRed":
					redOn = !redOn;
					break;
				
				case "interactionBlue":
					blueOn = !blueOn;
					break;
				
				case "interactionYellow":
					yellowOn = !yellowOn;
					break;
			}				
			
			// Check which lights are on now
			var tapestryTimeline:Timeline = _tapestry.get(Timeline);
			if(redOn && blueOn && yellowOn)
				tapestryTimeline.gotoAndStop("all");
			else if(!redOn && !blueOn && !yellowOn)
				tapestryTimeline.gotoAndStop("none");
			else if(redOn && blueOn && !yellowOn)
			{
				if(!shellApi.checkItemEvent(_events.SECURITY_CODE))
					tapestryTimeline.handleLabel("purple", waitForCard);
				tapestryTimeline.gotoAndStop("purple");
			}
			else if(redOn && !blueOn && !yellowOn)
				tapestryTimeline.gotoAndStop("red");
			else if(blueOn && yellowOn && !redOn)
				tapestryTimeline.gotoAndStop("green");
			else if(blueOn && !yellowOn && !redOn)
				tapestryTimeline.gotoAndStop("blue");
			else if(yellowOn && redOn && !blueOn)
				tapestryTimeline.gotoAndStop("orange");
			else if(yellowOn && !redOn && !blueOn)
				tapestryTimeline.gotoAndStop("yellow");
		}
		
		private function waitForCard():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, Command.create(Dialog(player.get(Dialog)).sayById, "code")));
			SceneUtil.addTimedEvent(this, new TimedEvent(4, 1, Command.create(shellApi.getItem, _events.SECURITY_CODE, null, true)));
		}
		
		private var _tapestry:Entity;
		private var redOn:Boolean = false;
		private var yellowOn:Boolean = false;
		private var blueOn:Boolean = false;
		private var _camerasOn:Boolean = true;
		private var _bearClaw:Entity;
		private var _randomGlint:TimedEvent;
		private var _glint:Entity;
		
		private var _roomDoor:Entity;
		private var _cameras:Vector.<Entity>;		
	}
}
