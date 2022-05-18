package game.scenes.examples.scenePhysics
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Id;
	import engine.components.Motion;
	
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.SceneObjectHit;
	import game.components.input.Input;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.creators.motion.SceneObjectCreator;
	import game.scene.template.PlatformerGameScene;
	import game.systems.hit.SceneObjectHitCircleSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.util.Utils;
	
	public class ScenePhysics extends PlatformerGameScene
	{
		private const MAX_OBJECTS:int = 10;
		private var _totalObjects:int;
		
		public function ScenePhysics()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/scenePhysics/";
			
			// This will override a scene's default scale of '1'.
			super.initialScale = 1;
			// This value should hold whatever the smallest scale of a scene will be.  Adjusts layer positioning.
			super.minCameraScale = .5;
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
	
			_sceneObjectCreator = new SceneObjectCreator();
			
			// create 'ball' scene motion object where the mouse is clicked.  shellApi.input is defined for every scene and serves as the input reference for mobile, tablet and desktop environments.
			Input(super.shellApi.inputEntity.get(Input)).inputUp.add(createSceneObject);
			
			super.addSystem(new SceneObjectHitRectSystem());
			super.addSystem(new SceneObjectHitCircleSystem());
			
			super.player.add(new SceneObjectCollider());	// allows entity to collide with entities owning SceneObjectHit
			super.player.add(new RectangularCollider());	// specifies that collider is rectangular
			super.player.add( new Mass(100) );
		}
		
		// NOTE : Used for testing boxes only.
		private function createBox(input:Input):void
		{
			_totalObjects++;
			if( _totalObjects == MAX_OBJECTS )
			{
				Input(super.shellApi.inputEntity.get(Input)).inputUp.remove(createBox);
			}

			var entity:Entity;
			var targetX:Number = super.shellApi.globalToScene(input.target.x, "x");
			var targetY:Number = super.shellApi.globalToScene(input.target.y, "y");
			
			var sceneObjectMotion:SceneObjectMotion;
			sceneObjectMotion = new SceneObjectMotion();
			sceneObjectMotion.rotateByPlatform = true;
			sceneObjectMotion.rotateByVelocity = false;
			sceneObjectMotion.platformFriction = 500;
			
			entity = _sceneObjectCreator.createBox("scenes/examples/scenePhysics/box.swf",
				0,	// NOTE :: if bounce is zero, then object will not rotate along platforms
				super.hitContainer,
				targetX, targetY,
				null,
				null,
				super.sceneData.bounds,
				this,
				objectLoaded,
				null,
				200,
				true);
		
			/**
			 * If you want boxes to collider with each other or other scene objects, add a SceneObjectCollider & RectangularCollider
			 */
			entity.add(new SceneObjectCollider());
			entity.add(new RectangularCollider());
		}

		private function createSceneObject(input:Input):void
		{
			_totalObjects++;
			if( _totalObjects == MAX_OBJECTS )
			{
				Input(super.shellApi.inputEntity.get(Input)).inputUp.remove(createSceneObject);
			}
			
			var motion:Motion;
			var sceneObjectMotion:SceneObjectMotion;
			var rand:Number = Utils.randInRange(0, 2);
			var entity:Entity;
			var targetX:Number = super.shellApi.globalToScene(input.target.x, "x");
			var targetY:Number = super.shellApi.globalToScene(input.target.y, "y");
			
			if(rand == 0)
			{
				/**
				 * Create a new scene object with mostly default options.
				 */
				entity = _sceneObjectCreator.create("scenes/examples/standaloneMotion/ball2.swf",
										   .7,
										   super.hitContainer,
										   targetX, targetY,
										   null,
										   null,
										   super.sceneData.bounds,
										   this,
										   objectLoaded);
				
				entity.add(new SceneObjectHit());
				entity.add(new Id("ball"));
			}
			else if(rand == 1)
			{
				/**
				 * Create a new scene object with custom motion and sceneObjectMotion.  It will be a ball with extra bounce.  Bounce should not be greater than 1.
				 */
				entity = _sceneObjectCreator.createCircle("scenes/examples/standaloneMotion/ball3.swf",
											.9,
											super.hitContainer,
											targetX, targetY,
											motion,
											null,
											super.sceneData.bounds,
											this,
											objectLoaded);
			}
			else
			{
				/**
				 * Create a new scene object with custom motion and sceneObjectMotion.  It will be a box that follows the contours of the platform with very little 'bounce'.
				 */
				entity = _sceneObjectCreator.createBox("scenes/examples/scenePhysics/box.swf",
											.1,
											super.hitContainer,
											targetX, targetY,
											motion,
											null,
											super.sceneData.bounds,
											this,
											objectLoaded,
											null,
											200);
				/**
				 * If you want boxes to collider with each other or other scene objects, add a SceneObjectCollider & RectangularCollider
				 */
				//entity.add(new SceneObjectCollider());
				//entity.add(new RectangularCollider());
			}
			
			// to limit the hits that this object can collide with.
			//entity.add(new ValidHit("floor", "radial0", "radial1", "radial2", "radial3"));
		}
		
		// additional setup can occur after asset is loaded if needed.
		private function objectLoaded(entity:Entity):void
		{
			trace("object loaded!");
		}
		
		public function cycleZoom():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			
			if(camera.scaleTarget == .5)
			{
				camera.scaleTarget = 2;
			}
			else if(camera.scaleTarget == 2)
			{
				camera.scaleTarget = 1;
			}
			else
			{
				camera.scaleTarget = .5;
			}
		}
		
		private var _sceneObjectCreator:SceneObjectCreator;
	}
}