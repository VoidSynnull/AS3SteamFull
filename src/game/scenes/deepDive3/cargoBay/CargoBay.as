package game.scenes.deepDive3.cargoBay
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.render.Light;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.outro.Outro;
	import game.scenes.deepDive3.shared.DroneGroup;
	import game.scenes.deepDive3.shared.SubsceneLightingGroup;
	import game.scenes.deepDive3.shared.drone.states.DroneState;
	import game.scenes.deepDive3.shared.groups.ShipTakeOffGroup;
	import game.scenes.deepDive3.shared.popups.IntroPopup;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class CargoBay extends SubScene
	{
		private var _events:DeepDive3Events;
		private var _lightOverlay:Entity;
		
		private var teleporter:Entity;
		public var player:Entity;
		private var mainDeckDoor:Entity;
		private var savedClick:Signal;
		
		private var _drone1:Entity;
		private var _drone2:Entity;
		private var _drone3:Entity;
		private var _droneGroup:DroneGroup;
		
		private var exitDoor:Entity;
		private var exitDoorInteraction:Interaction;
		private var _lightingGroup:SubsceneLightingGroup;
		
		public function CargoBay()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/cargoBay/";
			
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
			_events = DeepDive3Events(events);
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			player = shellApi.player;
						
			_lightingGroup = super.addChildGroup(new SubsceneLightingGroup(this)) as SubsceneLightingGroup;
			
			if(this.shellApi.checkEvent(_events.STAGE_3_ACTIVE) || this.shellApi.checkEvent(_events.SPOKE_WITH_AI)){
				_hitContainer["doorLights"].visible = true;
			}else{
				_hitContainer["doorLights"].visible = false;
			}
			
			setupTeleporter();
			
			if(!this.shellApi.checkEvent(_events.SPOKE_WITH_AI)){
				_hitContainer["drone1"].visible = false;
				_hitContainer["drone2"].visible = false;
				_hitContainer["drone3"].visible = false;
				_hitContainer["teleporter"].gotoAndStop(1);
			}else{
				setupDrones();
				setupExitDoor();
				addChildGroup( new ShipTakeOffGroup( this, _lightingGroup.lightOverlayEntity ));
//				this.addSystem(new ShipTakingOffSystem(this, _lightingGroup.lightOverlayEntity));
			}
			
			if(!this.shellApi.checkEvent(_events.ENTERED_CARGO_BAY)){
				SceneUtil.lockInput(this, true);
				teleporter.get(Timeline).gotoAndStop("open");
				var lightOverlayEntity:Entity = super.getEntityById("lightOverlay");
				//trace(player.getAll());
				player.get(Spatial).scale = .7;
				var startX:Number = teleporter.get(Spatial).x - 30;
				player.get(Spatial).x = startX;
				player.get(Spatial).y = teleporter.get(Spatial).y;
				player.get(Tween).to(player.get(Spatial), 5, { scale:1, x:startX+60, ease:Sine.easeInOut});
				Light(player.get(Light)).radius = 75;
				TweenUtils.globalTo(this, player.get(Light), 3, {radius:400}, "test", 2);
				
				SceneUtil.addTimedEvent(this, new TimedEvent(4, 1, closeDoor, true));
			}
		}
		
		private function closeDoor():void {
			teleporter.get(Timeline).play();
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, callCam, true));
		}
		
		private function callCam():void {
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("comeIn");
		}
		
		private function sayLine():void {
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("guess");
		}
		
		private function endOpening():void {
			SceneUtil.lockInput(this, false);
			this.shellApi.completeEvent(_events.ENTERED_CARGO_BAY);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			if( event == "waitOver" ) {
				SceneUtil.lockInput(this, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, playMsg, true));
			}else if( event == "comeInOver" ) {
				playStaticMessage("static", sayLine);
			}else if( event == "guessOver" ) {
				SceneUtil.lockInput(this, false);
				var popup:IntroPopup = super.addChildGroup( new IntroPopup( super.overlayContainer )) as IntroPopup;
				popup.id = "introPopup";
			}else if( event == "triggerCloseIntro" ) {
				endOpening();
			}
		}
		
		private function endScene():void {
			//super.shellApi.loadScene( Ship, 1037, 1936, "right" );
			shellApi.loadScene( Outro );
		}
		
		private function sayFinalLine(entity:Entity=null):void {
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("wait");
		}
		
		private function setupExitDoor():void {
			exitDoor = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["doorClick"]), this);
			//exitDoor.remove(Timeline);
			
			exitDoorInteraction = exitDoor.get(Interaction);
			exitDoorInteraction.downNative.add( Command.create( onExitDoorDown ));
		}
		
		private function onExitDoorDown(event:Event):void {
			SceneUtil.lockInput(this, true);
			sayFinalLine();
		}
		
		public function playMsg():void{
			this.playAlienMessage("this", "that", 3, endAlienTransmission);
		}
		
		private function endAlienTransmission():void{
			var xTarg:Number = teleporter.get(Spatial).x;
			var yTarg:Number = teleporter.get(Spatial).y;
			player.get(Tween).to(player.get(Spatial), 2, { x:xTarg, y:yTarg, ease:Sine.easeInOut });
			player.get(Tween).to(player.get(Display), 1, { delay:3, alpha:0, ease:Sine.easeInOut, onComplete:endScene});
			teleporter.get(Timeline).play();
			playDoorSound();
			teleporter.get(Timeline).handleLabel("doorClosing", playDoorSound, true);
			teleporter.get(Timeline).handleLabel("startHum", playHumSound, true);
			teleporter.get(Timeline).handleLabel("teleport", playTeleportSound, true);
		}
		
		private function playDoorSound():void {
			super.shellApi.triggerEvent("hatchSound");
		}
		private function playHumSound():void {
			super.shellApi.triggerEvent("teleporterSound");
		}
		private function playTeleportSound():void {
			super.shellApi.triggerEvent("teleporterSound2");
		}
		
		private function setupDrones():void {
			_droneGroup = new DroneGroup(this, super._hitContainer);
			this.addChildGroup(_droneGroup);
				
			_drone1 = _droneGroup.makeDrone(super._hitContainer["drone1"], DroneState.IDLE);
			var fsmControl:FSMControl = _drone1.get(FSMControl);
			fsmControl.setState("neander");
			Display(_drone1.get(Display)).displayObject["language"].visible = true;
			
			_drone2 = _droneGroup.makeDrone(super._hitContainer["drone2"], DroneState.IDLE);
			var fsmControl2:FSMControl = _drone2.get(FSMControl);
			fsmControl2.setState("neander");
			Display(_drone2.get(Display)).displayObject["language"].visible = true;
			
			_drone3 = _droneGroup.makeDrone(super._hitContainer["drone3"], DroneState.IDLE);
			var fsmControl3:FSMControl = _drone3.get(FSMControl);
			fsmControl3.setState("neander");
			Display(_drone3.get(Display)).displayObject["language"].visible = true;			
		}
		
		private function setupTeleporter():void {
			var clip:MovieClip = _hitContainer["teleporter"];
			
			teleporter = new Entity();
			teleporter = TimelineUtils.convertClip( clip, this, teleporter );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			teleporter.add(spatial);
			teleporter.add(new Display(clip));
			teleporter.add(new Id("teleporter"));
			
			super.addEntity(teleporter);
			teleporter.get(Timeline).gotoAndStop(0);
		}
	}
}