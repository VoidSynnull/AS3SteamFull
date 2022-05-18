package game.scenes.virusHunter.bloodStream
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.RenderSystem;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.anteArm.AnteArm;
	import game.scenes.virusHunter.brain.Brain;
	import game.scenes.virusHunter.hand.Hand;
	import game.scenes.virusHunter.heart.Heart;
	import game.scenes.virusHunter.mouthShip.MouthShip;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.systems.input.InteractionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.ui.ButtonSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	public class BloodStream extends Scene
	{
		private var sceneNames:Array = [ "mouth", "heart", "brain", "stomach", "hand", "arm" ];
		private var display:MovieClip;
		private var bloodStreamUpdate:BloodStreamUpdate;

		//private var navPane:VirusNavigationPane;

		public function BloodStream()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			this.groupPrefix = "scenes/virusHunter/bloodStream/";
			super.init(container);
			
			this.load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// only need a list of npcs and the background asset for this scene.  Not using scene.xml as we don't need the camera here.
			super.loadFiles(["ship_controls.swf" ], false, true, this.loaded);
		}
				
		// all assets ready
		override public function loaded():void
		{
			this.display = this.getAsset("ship_controls.swf", true);
			this.groupContainer.addChild(this.display);
			
			//Add needed systems
			this.addSystem(new RenderSystem());
			this.addSystem(new InteractionSystem());
			this.addSystem(new ButtonSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new BloodStreamUpdateSystem());
			
			//Resize the display to fit the viewport
			//var scaleX:Number = this.shellApi.viewportWidth / 960;
			//var scaleY:Number = this.shellApi.viewportHeight / 640;
			//this.display.scaleX = this.display.scaleY = Math.max(scaleX, scaleY);
			
			this.display.scaleX = this.shellApi.viewportWidth / 960;
			this.display.scaleY = this.shellApi.viewportHeight / 640;
			
			this.convertToBitmap(this.display["content"]["console"]);
			
			/**
			 * Recurring problem with Scenes being ready before the new Loading Screen gets finished (or something...).
			 * Add a wait before firing this.ready();
			 */
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, finished));
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heart_beat_02_L.mp3", 1, true);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "engine_high_01_L.mp3", 1, true);
			
			this.setupBloodStream();
			this.setupButtons();
			
			super.loaded();
		}
		
		private function finished():void
		{
			this.groupReady();
		}
		
		private function setupBloodStream():void
		{
			var window:DisplayObjectContainer = this.display["content"]["window"]["movingWindow"];
			
			var pp:PerspectiveProjection = new PerspectiveProjection();
			pp.fieldOfView = 130;
			pp.projectionCenter = new Point(0, 0);
			window.transform.perspectiveProjection = pp;
			
			var entity:Entity = new Entity();
			entity.add(new Display(window));
			
			this.bloodStreamUpdate = new BloodStreamUpdate(this.display["content"]["segment"], this.display["content"]["bloodCell"]);
			entity.add(bloodStreamUpdate);
			
			this.addEntity(entity);
		}
		
		private function setupButtons():void
		{
			var content:DisplayObjectContainer = this.display["content"];
			
			var sceneClasses:Dictionary = new Dictionary();
			sceneClasses[ "mouth" ] 	= MouthShip;
			sceneClasses[ "heart" ] 	= Heart;
			sceneClasses[ "arm" ] 		= AnteArm;
			sceneClasses[ "brain" ] 	= Brain;
			sceneClasses[ "stomach" ] 	= Stomach;
			sceneClasses[ "hand" ] 		= Hand;
			
			var onlyHand:Boolean 	= false;
			var noMouth:Boolean 	= false;
			
			var virusEvents:VirusHunterEvents = this.events as VirusHunterEvents;
			if(!this.shellApi.checkEvent(virusEvents.ATTACKED_BY_WBC)) onlyHand 	= true;
			if(!this.shellApi.checkEvent(virusEvents.GOT_ANTIGRAV)) 	noMouth 	= true;
			
			for each(var sceneName:String in this.sceneNames)
			{
				var clip:MovieClip = content[sceneName];
				
				if(onlyHand && sceneName != "hand") 		clip.parent.removeChild(clip);
				else if(noMouth && sceneName == "mouth") 	clip.parent.removeChild(clip);
				else
				{
					var entity:Entity = ButtonCreator.createButtonEntity(clip, this, onClick);
					entity.add(new Id(sceneName));
					
					entity.get(Button).value = sceneClasses[sceneName];
					
					var interaction:Interaction = entity.get(Interaction);
					interaction.over.add(playPing);
				}
			}
		}
		
		private function playPing(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_04.mp3");
		}
		
		private function onClick(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "engine_speedup.mp3");
			
			this.bloodStreamUpdate.engaged = true;
			
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 0, Command.create(this.blink, entity)));
			
			for each(var sceneName:String in this.sceneNames)
			{
				var bodyPart:Entity = this.getEntityById(sceneName);
				if(bodyPart)
				{
					Interaction(bodyPart.get(Interaction)).lock = true;
				}
			}
			
			var sceneClass:Class = entity.get(Button).value;
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, Command.create(this.shellApi.loadScene, sceneClass)));
		}
		
		private function blink(entity:Entity):void
		{
			var timeline:Timeline = entity.get(Timeline);
			if(timeline.currentFrameData.label == "up")
			{
				timeline.gotoAndStop("over");
			}
			else
			{
				timeline.gotoAndStop("up");
			}
		}

		/**
		 * OLD, HAS BEEN REVISED
		 */
		/*private function initNavPane():void {

			var paneClip:MovieClip = super.getAsset( "ship_controls.swf", true );
			navPane = new VirusNavigationPane( paneClip, this );

			this.overlayContainer.addChild( paneClip );

			//var popup:VirusNavigationPopup = super.addChildGroup( new VirusNavigationPopup(super.overlayContainer)) as VirusNavigationPopup;
			//popup.id = "virusNavPopup";
		
			navPane.onSceneSelected.addOnce( sceneSelected );

		} //

		private function sceneSelected( sceneName:String, sceneClass:*, loadPt:Point=null ):void {

			//var wait:WaitAction = new WaitAction( 4 );
			//wait.run( this, waitDone );

			// action calls waitDone with sceneName as argument.
			var func:CallFunctionAction = new CallFunctionAction( this.waitDone, [ sceneClass, loadPt ] );
			func.startDelay = 3;				// 3 second start delay.
			func.run( this, null );				// don't need a callback because the action calls waitDone()
			
			var bloodSystem:BloodStreamUpdateSystem = this.getSystem(BloodStreamUpdateSystem) as BloodStreamUpdateSystem
			bloodSystem.engaged = true;

		} //

		private function waitDone( sceneClass:*, loadPt:Point=null ):void {

			if ( loadPt == null ) {
				shellApi.loadScene( sceneClass );
			} else {
				shellApi.loadScene( sceneClass, loadPt.x, loadPt.y );
			} //

		}*/
	}
}
