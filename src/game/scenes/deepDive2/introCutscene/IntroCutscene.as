package game.scenes.deepDive2.introCutscene
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scene.template.GameScene;
	import game.scenes.deepDive1.shared.emitters.SubTrail;
	import game.scenes.deepDive2.alienDoor.AlienDoor;
	import game.systems.SystemPriorities;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	public class IntroCutscene extends Scene
	{
		
		private var backdropClip:MovieClip;
		private var backgroundClip:MovieClip;
		private var hits:MovieClip;
		private var backdrop:Entity;
		private var background:Entity;
		private var rock:Entity;
		
		private var sub:Entity;
		
		private var pContainer:Sprite;
		private var offset:Number;
		
		public function IntroCutscene()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive2/introCutscene/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["backdrop.swf", "background.swf", "interactive.swf", GameScene.SCENE_FILE_NAME]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			backdropClip = super.groupContainer.addChild(super.getAsset("backdrop.swf", true)) as MovieClip;
			hits = super.groupContainer.addChild(super.getAsset("interactive.swf", true)) as MovieClip;
			backgroundClip = super.groupContainer.addChild(super.getAsset("background.swf", true)) as MovieClip;
			
			// for basic motion only render system and motion system are required.
			super.addSystem(new RenderSystem(), SystemPriorities.render);             // syncs an entity's Display component with its Spatial component
			super.addSystem(new MotionSystem(), SystemPriorities.move);	      // updates velocity based on acceleration, friction, and other forces acting on the entity.
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			super.addSystem(new TweenSystem(), SystemPriorities.update);              // provides standard Tweening functionality through system updates.
			super.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			super.addSystem(new TimelineClipSystem(), SystemPriorities.timelineControl);
			
			super.loaded();
			
			setupSub();
			setupBackgrounds();
			
			runAnimation();
			startMusic();
		}
		
		private function startMusic():void {
			AudioUtils.play(this, SoundManager.MUSIC_PATH + "atlantis_2_intro_cutscene.mp3");
		}
		
		private function runAnimation():void {
			sub.get(Tween).to(sub.get(Spatial), 30, { x: 700, y:430, scaleX:.025, scaleY:.025, ease:Sine.easeOut/*, onComplete:gotoAlienDoor*/ });
			sub.get(Tween).to(sub.get(SpatialOffset), 10, { x:-150, y:200, ease:Sine.easeInOut, onUpdate:moveBubbles, onComplete:goUp });
			sub.get(Tween).to(sub.get(Display), 15, { delay:15, alpha:0.5, ease:Sine.easeInOut });
			
			var bgTargX:Number = background.get(Spatial).x - 90;
			var bgTargY:Number = background.get(Spatial).y + 20;
			var bdTargX:Number = backdrop.get(Spatial).x - 40;
			var bdTargY:Number = backdrop.get(Spatial).y - 60;
			var rockTargX:Number = rock.get(Spatial).x;
			var rockTargY:Number = rock.get(Spatial).y - 42;
			
			background.get(Tween).to(background.get(Spatial), 30, { x:bgTargX, y:bgTargY, scaleX:1.25, scaleY:1.25, ease:Sine.easeOut });
			backdrop.get(Tween).to(backdrop.get(Spatial), 30, { x:bdTargX, y:bdTargY, scaleX:1.1, scaleY:1.1, ease:Sine.easeOut });
			rock.get(Tween).to(rock.get(Spatial), 30, { x:rockTargX, y:rockTargY, scaleX:1.1, scaleY:1.1, ease:Sine.easeOut });
			
			SceneUtil.addTimedEvent(this, new TimedEvent(15, 1, gotoAlienDoor, true));
		}
		
		private function setupBackgrounds():void
		{
			//setup backdrop
			var bdClip:MovieClip = backdropClip;
			backdrop = new Entity();
			var bdSpatial:Spatial = new Spatial();
			bdSpatial.x = bdClip.x;
			bdSpatial.y = bdClip.y;
			
			backdrop.add(bdSpatial);
			backdrop.add(new Display(bdClip));
			backdrop.add(new Tween());
			
			super.addEntity(backdrop);
			
			//setup background
			var bgClip:MovieClip = backgroundClip;
			background = new Entity();
			var bgSpatial:Spatial = new Spatial();
			bgSpatial.x = bgClip.x;
			bgSpatial.y = bgClip.y;
			
			background.add(bgSpatial);
			background.add(new Display(bgClip));
			background.add(new Tween());
			
			super.addEntity(background);
			
			//setup rock
			var rockClip:MovieClip = hits["rock"];;
			rock = new Entity();
			var rockSpatial:Spatial = new Spatial();
			rockSpatial.x = rockClip.x;
			rockSpatial.y = rockClip.y;
			
			rock.add(rockSpatial);
			rock.add(new Display(rockClip));
			rock.add(new Tween());
			
			super.addEntity(rock);
		}
		
		private function setupSub():void {
			var clip:MovieClip = hits.bubbleSub;
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			
			pContainer = new Sprite();
			clip.addChild(pContainer);
			pContainer.x = 0;
			pContainer.y = 0;
			
			sub = new Entity();
			var vSpatial:Spatial = new Spatial();
			vSpatial.x = clip.x;
			vSpatial.y = clip.y;
			
			sub.add(vSpatial);
			sub.add(new Display(clip));
			sub.add(new Tween());
			sub.add(new SpatialOffset());
			
			super.addEntity(sub);
			sub.get(Spatial).scale = .3;
			sub.get(Spatial).rotation += 4;
			
			var emitter:SubTrail = new SubTrail();
			emitter.init();
			EmitterCreator.create(this, pContainer, emitter, 0, 40, sub, "exhaust");
		}
		
		private function goUp():void {
			sub.get(Tween).to(sub.get(SpatialOffset), 10, { x:0, y:60, ease:Sine.easeInOut, onUpdate:moveBubbles });
		}
		
		private function moveBubbles():void {
			//pContainer.x = sub.get(SpatialOffset).x;
			//pContainer.y = sub.get(SpatialOffset).y;
			//trace(pContainer.x);
		}
		
		private function gotoAlienDoor():void {
			super.shellApi.loadScene(AlienDoor);
		}
	}
}