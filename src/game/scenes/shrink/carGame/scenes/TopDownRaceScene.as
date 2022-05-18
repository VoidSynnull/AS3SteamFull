package game.scenes.shrink.carGame.scenes
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.CameraLayerCreator;
	import engine.systems.CameraSystem;
	import engine.systems.MotionSystem;
	import engine.systems.TweenSystem;
	
	import game.components.audio.HitAudio;
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.entity.collider.ItemCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.scenes.survival5.chase.scenes.EndlessRunnerScene;
	import game.systems.SystemPriorities;
	import game.systems.animation.FSMSystem;
	import game.systems.entity.SleepSystem;
	import game.systems.entity.character.DialogInteractionSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.EdgeSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.scene.SceneInteractionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	public class TopDownRaceScene extends EndlessRunnerScene
	{
		protected var vehicleURL:String;
		
		private var _loading:Number = 0;
		private var _waitingOnCameraUpdate:Boolean = false;
		
		public function TopDownRaceScene()
		{
			super();
			cameraStationary = false;
		}
		
		override protected function addCollisions( audioGroup:AudioGroup ):void
		{
			super.addCollisions( audioGroup );
			addLoopers();
		}
		
		protected function addLoopers():void
		{
			var raceObstacleCreator:RaceSegmentCreator = new RaceSegmentCreator();
			var data:XML = SceneUtil.mergeSharedData( this, "segmentPatterns.xml", "ignore" );
			
			raceObstacleCreator.createSegments( this, data, _hitContainer, _audioGroup, addVehicles );
		}

		protected function addVehicles():void
		{
			loadVehicle( shellApi.profileManager.active.lastX, shellApi.profileManager.active.lastY, true, "player" );
			super.addSystem( new DialogInteractionSystem(), SystemPriorities.lowest );
		}
		
		
		protected function loadVehicle( x:Number, y:Number, isPlayer:Boolean = false, id:String = null ):void
		{
			super.shellApi.loadFile( super.shellApi.assetPrefix + vehicleURL, vehicleLoaded, x, y, isPlayer, id );
			_loading++;
		}
		
		private function vehicleLoaded( clip:MovieClip, x:Number, y:Number, isPlayer:Boolean = false, id:String = null ):void
		{
			var charContainer:DisplayObjectContainer = ( _hitContainer ) ? _hitContainer : super.groupContainer;
			
			var entity:Entity = createVehicle( charContainer, clip, x, y, this.sceneData.bounds, id );
			this.addEntity( entity );
					
			if( isPlayer )
			{
				entity.add( new ItemCollider());
				entity.add( new Player());
			}
			
			_loading--;
			
			if(_loading == 0)
			{
				allVehiclesLoaded();
			}
		}
		
		override protected function addItems():void
		{}
		
		override protected function addBaseSystems():void
		{
			addSystem(new SceneInteractionSystem(), SystemPriorities.sceneInteraction);
			addSystem(new InteractionSystem(), SystemPriorities.update);	
			addSystem( new RotateToTargetSystem(), SystemPriorities.move );
			addSystem( new FollowTargetSystem());
			addSystem( new TweenSystem(), SystemPriorities.update );
			addSystem( new MoveToTargetSystem( super.shellApi.viewportWidth, super.shellApi.viewportHeight ), SystemPriorities.moveControl );  // maps control input position to motion components.
			addSystem( new MotionSystem(), SystemPriorities.move );						// updates velocity based on acceleration and friction.
			addSystem( new PositionSmoothingSystem(), SystemPriorities.preRender );
			addSystem( new MotionControlInputMapSystem(), SystemPriorities.update );    // maps input button presses to acceleration.
			addSystem( new MotionTargetSystem(), SystemPriorities.move );
			addSystem( new MotionControlBaseSystem(), SystemPriorities.move );
			addSystem( new NavigationSystem(), SystemPriorities.update );			    // This system moves an entity through a series of points for autopilot.
			addSystem( new DestinationSystem(), SystemPriorities.update );	
			addSystem( new TargetEntitySystem(), SystemPriorities.update );	
			addSystem( new TimelineClipSystem(), SystemPriorities.timelineEvent );
			addSystem( new TimelineControlSystem(), SystemPriorities.timelineControl );
			addSystem( new EdgeSystem(), SystemPriorities.postRender );
			addSystem( new FSMSystem(), SystemPriorities.autoAnim );
		}
		
		private function createVehicle( container:DisplayObjectContainer, clip:MovieClip, x:Number, y:Number, bounds:Rectangle, id:String = null ):Entity
		{
			var entity:Entity 	= new Entity;
			var spatial:Spatial = new Spatial( x, y );
			var display:Display = new Display( clip, container );
			var motion:Motion 	= new Motion();
			motion.friction 	= new Point(0, 0);
			motion.minVelocity 	= new Point(0, 0);
			motion.maxVelocity 	= new Point( 400, 400 );
			
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.acceleration = 1200;
			motionControlBase.stoppingFriction = 500;
			motionControlBase.accelerationFriction = 200;
			motionControlBase.freeMovement = true;
			
			var edge:Edge = new Edge();
			var rectangle:Rectangle = display.displayObject.getBounds( display.displayObject );
			edge.unscaled = rectangle;	
			
			clip.mouseEnabled = false;			
			entity.add( edge );
			entity.add( spatial );
			entity.add( display );
			entity.add( motion );
			entity.add( new MotionControl());
			entity.add( new MotionTarget());
			entity.add( new Navigation());
			entity.add( new SceneCollider());
			entity.add( new ZoneCollider());
			entity.add( new MotionBounds( bounds ));
			entity.add( new Audio());
			entity.add( new HitAudio());
			entity.add( new CurrentHit());
			entity.add( motionControlBase );
			entity.add( new Tween());
			
			if( id != null ) { entity.add( new Id( id )); }
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			entity.add( sleep );
			
			container.addChild( clip );
			return( entity );
		}
		
		protected function allVehiclesLoaded():void
		{
			// Make the player follow input (the mouse or touch input).
			player = super.shellApi.player = super.getEntityById( "player" );
						
			MotionUtils.followInputEntity( super.shellApi.player, super.shellApi.inputEntity, true );
			updateCameraTarget();
		}
		
		private function updateCameraTarget():void
		{
			// Set the initial camera target.
			var cameraGroup:CameraGroup = super.getGroupById( "cameraGroup" ) as CameraGroup;
			cameraGroup.setTarget( super.shellApi.player.get( Spatial ), true );
			var camera:CameraSystem = super.getSystem( CameraSystem ) as CameraSystem;
			
			camera.startUpdateCheck();
			waitForCameraUpdate();
		}
		
		private function waitForCameraUpdate():void
		{
			// This triggers the 'ready' signal in the superclass 'DisplayGroup' that shows this scene.
			_waitingOnCameraUpdate = true;
			var cameraGroup:CameraGroup = super.getGroupById( "cameraGroup" ) as CameraGroup;
		
			var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
			this.uiLayer = new Sprite();
			this.uiLayer.name = 'uiLayer';
			
			// add the ui layer above all the other camera layers.
			super.addEntity(cameraLayerCreator.create(this.uiLayer, 1, "uiLayer"));
			super.groupContainer.addChild(this.uiLayer);
		
			cameraGroup.ready.addOnce( cameraReady );
		}
		
		private function cameraReady( ...args ):void
		{
			var sleep:SleepSystem = new SleepSystem();
			sleep.awakeArea = super.shellApi.camera.viewport;                           // for entities that sleep but don't have a display component to hittest against
			sleep.visibleArea = super.shellApi.backgroundContainer;                     // for entities that have a display component to be used with hitTestObject.
			super.addSystem( sleep, SystemPriorities.update );
	
			loaded();
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
		
		protected function addFSM():void
		{}
	}
}