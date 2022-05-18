package game.scenes.poptropolis.promoPlatform{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.motion.TargetSpatial;
	import game.components.motion.RotateControl;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.data.profile.TribeData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scenes.poptropolis.mainStreet.MainStreet;
	import game.scenes.poptropolis.shared.TribeSelectPopup;
	import game.systems.motion.RotateToTargetSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	
	public class PromoPlatform extends PlatformerGameScene
	{
		public var eyeLeft:Entity;
		public var eyeRight:Entity;
		private var master:Entity;
		private var windSpeed:Entity;
		
		private var popEvents:PoptropolisEvents;
		private var tribeSelectPopup:TribeSelectPopup;
		
		private var door1:Entity;
		
		public function PromoPlatform()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/promoPlatform/";
			
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
			super.shellApi.eventTriggered.add(handleEventTriggered);
			popEvents = super.events as PoptropolisEvents;
			this.master = this.getEntityById("master");
			this.door1 = this.getEntityById("door1");
			
			setupEyes();
			setupWindSpeed();
			setupBirds();
			setupDialog();
			
			var tribe:TribeData = TribeUtils.getTribeOfPlayer( super.shellApi );
			if( tribe == null )
			{
				this.tribeSelectPopup = super.addChildGroup( new TribeSelectPopup( "scenes/poptropolis/shared/tribeSelectPopup.swf", super.overlayContainer ) ) as TribeSelectPopup;
				this.tribeSelectPopup.onTribeSelected.add( tribeSelected );
			}else{
				//Replace the Dialog [tribe] tag with the player's correct tribe name.
				var dialog:Dialog = master.get(Dialog);
				var data:DialogData = dialog.getDialog("anotherPoint");
				data.dialog = data.dialog.replace("[tribe]", tribe.name);
			}
		}
		
		private function tribeSelected( tribeData:TribeData ):void
		{
			// do what you will, assign jersey?
			//Replace the Dialog [tribe] tag with the player's correct tribe name.
			var dialog:Dialog = master.get(Dialog);
			var data:DialogData = dialog.getDialog("anotherPoint");
			data.dialog = data.dialog.replace("[tribe]", tribeData.name);
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "dug_promo") {
				//do nothing during promo period
				//var _startTimer:Timer = new Timer(2000,1.5);
				//_startTimer.addEventListener(TimerEvent.TIMER_COMPLETE, gotoMainStreet);
				//_startTimer.start();
			}
		}
		
		protected function gotoMainStreet(event:TimerEvent):void {
			super.shellApi.loadScene(MainStreet);
		}
		
		private function setupDialog():void {
			if(this.shellApi.checkEvent(popEvents.PROMO_DIVE_FINISHED)){
				Dialog(master.get(Dialog)).setCurrentById("anotherPoint");
				super.shellApi.removeEvent(popEvents.PROMO_DIVE_FINISHED);
				CharUtils.moveToTarget(player, master.get(Spatial).x+100, master.get(Spatial).y, false);
				Dialog(master.get(Dialog)).sayById("anotherPoint");
				//setupClosedDoor();
				
			}else if(this.shellApi.checkEvent(popEvents.PROMO_DIVE_STARTED)){
				Dialog(master.get(Dialog)).setCurrentById("dontGiveUp");
				CharUtils.moveToTarget(player, master.get(Spatial).x+100, master.get(Spatial).y, false);
				Dialog(master.get(Dialog)).sayById("dontGiveUp");
				
			}else if(this.shellApi.checkEvent(popEvents.DUG_IN_PROMO)){
				Dialog(master.get(Dialog)).setCurrentById("backAgain");
				
			}
		}
		
		//removed to allow continuous dives
		/*private function setupClosedDoor():void	{
			var diveDoor:Entity = super.getEntityById("door1");
			var diveDoorInteraction:SceneInteraction = diveDoor.get(SceneInteraction);
			var diveDoorInt:Interaction = diveDoor.get(Interaction);
			diveDoorInteraction.offsetX = 0;
			diveDoorInt.click = new Signal();
			diveDoorInt.click.add(clickClosedDoor);
			
		}
		
		private function clickClosedDoor(door:Entity):void {
			Dialog(player.get(Dialog)).sayById("enough");
			trace("closed door");
		}*/
		
		private function setupBirds():void {
			//setup birds
			var birds1:Entity;
			var bClip1:MovieClip = _hitContainer["birds1"];
			birds1 = new Entity();
			birds1 = TimelineUtils.convertClip( bClip1, this, birds1 );
			
			var bSpatial1:Spatial = new Spatial();
			bSpatial1.x = bClip1.x;
			bSpatial1.y = bClip1.y;
			
			birds1.add(bSpatial1);
			birds1.add(new Display(bClip1)); 
			
			super.addEntity(birds1);
			
			var birds2:Entity;
			var bClip2:MovieClip = _hitContainer["birds2"];
			birds2 = new Entity();
			birds2 = TimelineUtils.convertClip( bClip2, this, birds2 );
			
			var bSpatial2:Spatial = new Spatial();
			bSpatial2.x = bClip2.x;
			bSpatial2.y = bClip2.y;
			
			birds1.add(bSpatial2);
			birds1.add(new Display(bClip2)); 
			
			super.addEntity(birds2);		
		}
		
		private function setupWindSpeed():void
		{			
			var clip:MovieClip = _hitContainer["windspeed"];
			windSpeed = new Entity();
			windSpeed = TimelineUtils.convertClip( clip, this, windSpeed );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			windSpeed.add(spatial);
			windSpeed.add(new Display(clip));
			
			var audio:Audio = new Audio();
			windSpeed.add(audio);
			
			audio.play(SoundManager.AMBIENT_PATH + "spinning_weathervane_01.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			windSpeed.add(new AudioRange(400));
			
			super.addEntity(windSpeed);
		}
		
		private function setupEyes():void
		{	
			eyeLeft = EntityUtils.createSpatialEntity( this, _hitContainer["eyeLeft"] ); 
			eyeRight = EntityUtils.createSpatialEntity( this, _hitContainer["eyeRight"] ); 
			
			//rotate eyes
			var targetSpatial:TargetSpatial =  new TargetSpatial( player.get( Spatial ) );
			eyeRight.add( targetSpatial );
			eyeLeft.add(targetSpatial);
			
			var rotateControl:RotateControl = new RotateControl();
			eyeRight.add( rotateControl );
			eyeLeft.add(rotateControl);
			
			this.addSystem( new RotateToTargetSystem );
		}
	}
}