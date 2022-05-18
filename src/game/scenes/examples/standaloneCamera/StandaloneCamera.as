package game.scenes.examples.standaloneCamera
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetSpatial;
	import game.data.scene.SceneParser;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	
	public class StandaloneCamera extends Scene
	{
		public function StandaloneCamera()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/standaloneCamera/";
			
			super.init(container);
			
			load();
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
			var cameraGroup:CameraGroup = new CameraGroup();
			
			// This method of cameraGroup does all setup needed to add a camera to this scene.  After calling this method you just need to assign cameraGroup.target to the spatial component of the Entity you want to follow.
			// NOTE : The scene width/height MUST be bigger than the viewport when at the minimum scale.
			cameraGroup.setupScene(this, .75);
			
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = Display(super.getEntityById("hits").get(Display)).displayObject;
			
			// Choose either a simple distance-based mouse follower or a physics-based follower that accelerates on mouse click.  NOTE that these aren't required for base camera functionality.
			//setupSimpleTarget();
			setupMotionTarget();
			
			super.loaded();
		}
				
		protected function loadAssets():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);
			
			super.sceneData = parser.parse(sceneXml);			
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(super.sceneData.assets);
		}
		
		// ****************** OPTIONAL METHODS FOR CREATING A MOTION-BASED TARGET AND A DISTANCE BASED TARGET.  A camera can follow any spatial component, these aren't required.  *********************** //
		
		// This method builds an entity that follows another entity (the mouse in this case) simply my moving the distance between its position and the mouse multiplied by the movement rate.
		private function setupSimpleTarget():void
		{
			// create an entity with a display component that refers to a movieclip in the hits camera layer.
			_target = new Entity();
			_target.add(new Display(_hitContainer["target"]));
			_target.add(new Spatial());

			// The follow target system has a 'config' method that adds the necessary components to this entity so it follows another entity.  In this case
			//  the follower target is the 'input' entity referred to in the shellApi.  This input entity is automatically mapped to the mouse position.
			var followTargetSystem:FollowTargetSystem = new FollowTargetSystem();
			EntityUtils.followTarget( _target, super.shellApi.inputEntity, .02, null, true);
			super.addSystem(followTargetSystem, SystemPriorities.move);
			
			// set the camera to use the new target entity's Spatial as its target.
			var cameraEntity:Entity = super.getEntityById("camera");
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			cameraTarget.target = _target.get(Spatial);
			super.addEntity(_target);
		}
		
		// adding a target with this method creates a more complex entity that uses a motion component with acceleration and velocity to follow another entity (the mouse).
		private function setupMotionTarget():void
		{
			_target = new Entity();
			
			// setup the motion component with a min / max velocity and friction values.
			var motion:Motion = new Motion();
			motion.friction 	= new Point(100, 100);
			motion.maxVelocity 	= new Point(12 * 60, 16 * 60);
			motion.minVelocity 	= new Point(.5 * 60, 0);
			
			// used for non-character movement of entities like top down vehicles.
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.freeMovement = true;
			motionControlBase.acceleration = 400;
			_target.add(motionControlBase);  
			
			_target.add(new MotionTarget());
			_target.add(motion);
			_target.add(new Display(_hitContainer["target"]));   // Add a display component that refers to a movieclip in the hits camera layer.
			_target.add(new Spatial());						     // Set the position of the entity with the Spatial component.  The RenderSystem moves the display position to match the Spatial properties.
			_target.add(new MotionControl());                    // This component allows the entity's motion to be set based on input.  The distance from its target determines its acceleration.
			              
			super.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);  // maps control input position to motion components.
			super.addSystem(new MotionSystem(), SystemPriorities.move);						// updates velocity based on acceleration and friction.
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			super.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);    // maps input button presses to acceleration.
			super.addSystem(new TargetEntitySystem(), SystemPriorities.update);				// This system turns on and off the 'MotionControl.accelerate' flag depending on distance from another entity.
			super.addSystem(new MotionControlBaseSystem(), SystemPriorities.moveControl);
			super.addSystem(new MotionTargetSystem(), SystemPriorities.moveControl);
			
			MotionUtils.followInputEntity(_target, super.shellApi.inputEntity, true);			// This util function adds the necessary components to this entity so it follows another entity (the mouse).
			
			// set the camera to use the new target entity's Spatial as its target.
			var cameraEntity:Entity = super.getEntityById("camera");
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			cameraTarget.target = _target.get(Spatial);
			
			// use the target entity's motion to set the zoom level.
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleMotionTarget = motion;
			camera.scaleByMotion = true;

			super.addEntity(_target);
		}
				
		private var _hitContainer:DisplayObjectContainer;
		private var _target:Entity;
	}
}