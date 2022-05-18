package game.scenes.examples.standaloneCollision
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.hit.CurrentHit;
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.data.scene.SceneParser;
	import game.scene.template.CollisionGroup;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	
	public class StandaloneCollision extends Scene
	{
		public function StandaloneCollision()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/standaloneCollision/";
			
			super.init(container);
			
			load();
		}
		
		protected function loadAssets():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);
			
			super.sceneData = parser.parse(sceneXml);			
			super.shellApi.fileLoadComplete.addOnce(loaded);
			
			var allFiles:Array = super.sceneData.assets.concat(super.sceneData.data);
			
			super.loadFiles(allFiles);
		}
		
		// initiate asset load of scene configuration.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loadAssets);
			super.loadFiles([GameScene.SCENE_FILE_NAME]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			_hitContainer = super.groupContainer.addChild(super.getAsset("interactive.swf", true)) as MovieClip;
						
			// for basic motion only render system and motion system are required.
			super.addSystem(new RenderSystem(), SystemPriorities.render);             // syncs an entity's Display component with its Spatial component
			super.addSystem(new MotionSystem(), SystemPriorities.move);	              // updates velocity based on acceleration, friction, and other forces acting on the entity.
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			super.addSystem(new SceneObjectMotionSystem(), SystemPriorities.update);         // this is a simple custom system made for this demo scene to demonstate modifying the ball physics based on its other components.

			// create velocity example where the mouse is clicked.  shellApi.input is defined for every scene and serves as the input reference for mobile, tablet and desktop environments.
			Input(super.shellApi.inputEntity.get(Input)).inputDown.add(handleInputDown);
			
			var collisionGroup:CollisionGroup = new CollisionGroup();
			collisionGroup.setupScene(this, super.getData(GameScene.HITS_FILE_NAME, true), _hitContainer, null, true);
			
			super.loaded();
		}
		
		// loaded callback gets the loaded file as its first parameter, followed by any extra arguments passed in.
		private function ballLoaded(clip:MovieClip, x:Number, y:Number, motionType:String, wildcard:Number = 0):void
		{
			var entity:Entity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = x;
			spatial.y = y;
			entity.add(spatial);
			
			_hitContainer.addChild(clip);
			entity.add(new Display(clip));
			
			// setup the motion component with a min / max velocity, friction and acceleration values.
			var motion:Motion = new Motion();
			motion.friction 	= new Point(.1, 0);
			motion.maxVelocity 	= new Point(12 * 60, 16 * 60);
			motion.minVelocity 	= new Point(.5 * 60, 0);
			motion.acceleration = new Point(0, 700);
			motion.velocity = new Point(Math.random() * 600 - 300, -200 + Math.random() * -200);
			entity.add(motion);
			
			// this component defines an edge from the registration point of this entity.  This prevents the ball from going all the way to its center point when hitting bounds.
			var edge:Edge = new Edge();
			edge.unscaled.setTo(-25, -25, 50, 50);
			entity.add(edge);
			
			// this is a custom component used in the new system built for this scene.  It handles simple bounding box collision reactions and rotates the ball based on its x velocity.
			entity.add(new SceneObjectMotion());
			
			// add all standard collider components to this entity
			entity.add(new BitmapCollider());
			entity.add(new RadialCollider());
			entity.add(new PlatformCollider());
			entity.add(new SceneCollider());
			entity.add(new CurrentHit());
			
			entity.add(new MotionBounds(super.sceneData.bounds));
			
			super.addEntity(entity);
		}
				
		private function handleInputDown(input:Input):void
		{
			super.loadFile("ball2.swf", ballLoaded, input.target.x, input.target.y, "velocity");
		}
		
		private var _hitContainer:DisplayObjectContainer;
	}
}