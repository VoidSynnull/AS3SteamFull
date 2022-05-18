package game.creators.scene
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.audio.HitAudio;
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.CircularCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.SceneObjectHit;
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.TargetEntity;
	import game.components.scene.Vehicle;
	import game.data.vehicle.VehicleData;
	import game.scene.template.AudioGroup;
	
	public class VehicleCreator
	{
		public function VehicleCreator(audioGroup:AudioGroup = null)
		{
			_audioGroup = audioGroup;
		}
		
		public function createFromVehicleData(container:DisplayObjectContainer, sceneBounds:Rectangle, data:VehicleData):Entity
		{
			return(create(container, 
						  data.x, data.y, 
						  sceneBounds, 
						  data.target, 
						  data.isPlayer, 
						  data.id, 
						  data.motion, 
						  data.motionControlBase, 
						  data.edge, 
						  data.accelerateToTargetRotation, 
						  data.vehicle, 
						  data.addDynamicCollisions));
		}
		
		/**
		 * Creates a new vehicle with the more standard components.
		 * @container : The parent of the entity display object (usually hitContainer).
		 * @clip : The entity display object.
		 * @x,y : The initial position of the entity.
		 * @sceneBounds : The rectangle that specifies scene limits.
		 * @target : The spatial target that the entity should move towards.  For the player this is usually the cursor.
		 * [@id] : An id for this entity.
		 * [@motion] : An optional preconfigured Motion component to set velocity limits.  If left out one will be created with sensible defaults.
		 * [@motionControlBase] : An optional preconfigured MotionControlBase component to configure various motion characteristics.  If left out one will be created with sensible defaults.
		 * [@edge] : Optionally specify the dimensions of the Entity.  A default component will be created if this is left out.
		 * [@accelerateToTargetRotation] : An optional component to configure turning motion for the entity.  A default will be created if left out.
		 */
		public function create(container:DisplayObjectContainer, 
							   x:Number, y:Number, 
							   sceneBounds:Rectangle, 
							   target:Spatial = null,
							   isPlayer:Boolean = false,
							   id:String = null,
							   motion:Motion = null,
							   motionControlBase:MotionControlBase = null,
							   edge:Edge = null,
							   accelerateToTargetRotation:AccelerateToTargetRotation = null,
							   vehicle:Vehicle = null,
							   addDynamicCollisions:Boolean = true):Entity
		{
			var entity:Entity = new Entity();		
			
			if(id != null) 
			{ 
				entity.add(new Id(id)); 
			}
			
			if(accelerateToTargetRotation == null)
			{
				accelerateToTargetRotation = new AccelerateToTargetRotation();
				accelerateToTargetRotation.rotationAcceleration = 250;
				accelerateToTargetRotation.deadZone = 10;
			}
			entity.add(accelerateToTargetRotation);
			
			if(edge == null)
			{
				edge = new Edge(-20, -20, 40, 40);
			}
			entity.add(edge);
			
			var spatial:Spatial = new Spatial(x, y);	
			entity.add(spatial);
			
			// clip will be added after loading
			var display:Display = new Display(null, container);
			entity.add(display);
			
			if(motion == null)
			{
				motion = new Motion();
				motion.maxVelocity 	= new Point(150, 150);
				motion.rotationFriction = 150;
				motion.rotationMaxVelocity = 150;
			}
			entity.add(motion);
			
			var bitmapCollider:BitmapCollider = new BitmapCollider();
			bitmapCollider.addAccelerationToVelocityVector = true;
			entity.add(bitmapCollider);
			
			if(motionControlBase == null)
			{
				motionControlBase = new MotionControlBase();
				motionControlBase.acceleration = 400;
				motionControlBase.stoppingFriction = 100;
				motionControlBase.accelerationFriction = 200;
				motionControlBase.freeMovement = true;
				motionControlBase.rotationDeterminesAcceleration = true;
				motionControlBase.moveFactorMultiplier = .1;
			}
			entity.add(motionControlBase);
			
			if(vehicle == null)
			{
				vehicle = new Vehicle();
				vehicle.onlyRotateOnAccelerate = false;
			}
			entity.add(vehicle);
			
			var motionControl:MotionControl = new MotionControl();
			if(isPlayer)
			{
				entity.add(new Player());
			}
			else
			{
				motionControl.forceTarget = true;
			}
			entity.add(motionControl);
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			entity.add(sleep);
			
			var targetEntity:TargetEntity = new TargetEntity();
			targetEntity.target = target;
			targetEntity.applyCameraOffset = true;
			
			if(!isPlayer)
			{
				targetEntity.applyCameraOffset = false;
			}
			entity.add(targetEntity);
			
			if(addDynamicCollisions)
			{
				addDynamicCollisionComponents(entity);
			}
			
			entity.add(new MotionTarget());
			entity.add(new Navigation());
			entity.add(new RadialCollider());
			entity.add(new SceneCollider());
			entity.add(new ZoneCollider());
			entity.add(new MotionBounds(sceneBounds));
			entity.add(new Audio());
			entity.add(new HitAudio());
			entity.add(new CurrentHit());
						
			if(_audioGroup) { _audioGroup.addAudioToEntity(entity); }
			
			return(entity);
		}
		
		public function addDynamicCollisionComponents(entity:Entity, mass:Number = 1):void
		{
			entity.add(new SceneObjectCollider());
			entity.add(new CircularCollider());
			entity.add(new Mass(mass));
			entity.add(new SceneObjectHit());
		}
		
		private var _audioGroup:AudioGroup;
	}
}
