package game.scenes.poptropolis.volcano
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.scene.template.GameScene;
	import game.scenes.poptropolis.mainStreet.MainStreet;
	import game.scenes.poptropolis.volcano.components.Island;
	import game.scenes.poptropolis.volcano.systems.VolcanoSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Volcano extends Scene

	{
		private var backdropClip:MovieClip;
		private var backgroundClip:MovieClip;
		private var volcanoClip:MovieClip;
		private var rollingClouds1Clip:MovieClip;
		
		private var inputEntity:Entity;
		private var island:Entity;
		private var volcano:Entity;
		private var backdrop:Entity;
		private var background:Entity;
		private var rollingClouds1:Entity;
		private var rollingClouds2:Entity;
		
		public function Volcano()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/volcano/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			// only need a list of npcs and the background asset for this scene.  Not using scene.xml as we don't need the camera here.
			super.loadFiles(["backdrop.swf", "volcano.swf", "background.swf", GameScene.SCENE_FILE_NAME]);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			backdropClip = super.groupContainer.addChild(super.getAsset("backdrop.swf", true)) as MovieClip;
			volcanoClip = super.groupContainer.addChild(super.getAsset("volcano.swf", true)) as MovieClip;
			backgroundClip = super.groupContainer.addChild(super.getAsset("background.swf", true)) as MovieClip;
			
			// for basic motion only render system and motion system are required.
			super.addSystem(new RenderSystem(), SystemPriorities.render);             // syncs an entity's Display component with its Spatial component
			super.addSystem(new MotionSystem(), SystemPriorities.move);	      // updates velocity based on acceleration, friction, and other forces acting on the entity.
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			super.addSystem(new TweenSystem(), SystemPriorities.update);              // provides standard Tweening functionality through system updates.
			super.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			super.addSystem(new TimelineClipSystem(), SystemPriorities.timelineControl);
			super.addSystem(new VolcanoSystem());
			
			super.loaded();
			
			setupIsland();
			setupBackgrounds();
			
			//change tooltip to "target"
			inputEntity = shellApi.inputEntity;
			ToolTipCreator.addToEntity(inputEntity, ToolTipType.TARGET);
			
			var te:TimedEvent = new TimedEvent(1, 1, startRise, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function startRise():void
		{
			//raise island
			island.get(Tween).to(island.get(Spatial), 20, { y:300, scaleX:.9, scaleY:.9, ease:Sine.easeInOut, onComplete:stopShake });
			//raise clouds
			rollingClouds1.get(Tween).to(rollingClouds1.get(Spatial), 24, { x:0, y:1020, delay:3, ease:Sine.easeInOut });
			rollingClouds2.get(Tween).to(rollingClouds2.get(Spatial), 24, { x:2050, y:1025, delay:3, ease:Sine.easeInOut });
			var te:TimedEvent = new TimedEvent(5, 1, startEruption, true);
			SceneUtil.addTimedEvent(this, te);
			var te1:TimedEvent = new TimedEvent(3, 1, startMusic, true);
			SceneUtil.addTimedEvent(this, te1);
		}
		
		private function startMusic():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "poptropolis_rises.mp3");
		}
		
		private function startEruption():void
		{
			volcano.get(Timeline).gotoAndPlay(1);
		}
		
		private function stopShake():void {
			Island(island.get(Island)).shake = false;
			var te1:TimedEvent = new TimedEvent(3, 1, gotoMainStreet, true);
			SceneUtil.addTimedEvent(this, te1);
			//gotoMainStreet();
		}
		
		protected function gotoMainStreet():void {
			super.shellApi.loadScene(MainStreet);
		}
		
		private function setupBackgrounds():void
		{
			//setup backdrop
			var bdClip:MovieClip = backdropClip;
			backdrop = new Entity();
			var bdSpatial:Spatial = new Spatial();
			bdSpatial.x = bdClip.x;
			bdSpatial.y = bdClip.y - 570;
			
			backdrop.add(bdSpatial);
			backdrop.add(new Display(bdClip));
			backdrop.add(new Tween());
			
			super.addEntity(backdrop);
			
			//setup background
			var bgClip:MovieClip = backgroundClip;
			background = new Entity();
			var bgSpatial:Spatial = new Spatial();
			bgSpatial.x = bgClip.x;
			bgSpatial.y = bgClip.y - 570;
			
			background.add(bgSpatial);
			background.add(new Display(bgClip));
			background.add(new Tween());
			
			super.addEntity(background);
			
			//setup rollingClouds1
			var rc1Clip:MovieClip = bgClip["rollingClouds1"];
			rollingClouds1 = new Entity();
			var rc1Spatial:Spatial = new Spatial();
			rc1Spatial.x = rc1Clip.x;
			rc1Spatial.y = rc1Clip.y;
			
			rollingClouds1.add(rc1Spatial);
			rollingClouds1.add(new Display(rc1Clip));
			rollingClouds1.add(new Tween());
			rollingClouds1.get(Display).alpha = .2;
			
			super.addEntity(rollingClouds1);
			
			//setup rollingClouds2
			var rc2Clip:MovieClip = bgClip["rollingClouds2"];
			rollingClouds2 = new Entity();
			var rc2Spatial:Spatial = new Spatial();
			rc2Spatial.x = rc2Clip.x;
			rc2Spatial.y = rc2Clip.y;
			
			rollingClouds2.add(rc2Spatial);
			rollingClouds2.add(new Display(rc2Clip));
			rollingClouds2.add(new Tween());
			rollingClouds2.get(Display).alpha = .15;
			
			super.addEntity(rollingClouds2);
		}
		
		private function setupIsland():void
		{			
			//setup island
			var iClip:MovieClip = volcanoClip.island;
			island = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = iClip.x - 400;
			spatial.y = iClip.y + 400;
			spatial.scaleX = .8;
			spatial.scaleY = .8;
			
			island.add(spatial);
			island.add(new Display(iClip));
			island.add(new Tween());
			island.add(new Island(spatial.x, spatial.y));
			
			super.addEntity(island);
			
			//setup volcano
			var vClip:MovieClip = volcanoClip.island.island.volcano;
			volcano = new Entity();
			volcano = TimelineUtils.convertClip( vClip, this, volcano, null, false );
			
			var vSpatial:Spatial = new Spatial();
			vSpatial.x = vClip.x;
			vSpatial.y = vClip.y;
			
			volcano.add(vSpatial);
			volcano.add(new Display(vClip)); 
			
			super.addEntity(volcano);
		}
	}
}




