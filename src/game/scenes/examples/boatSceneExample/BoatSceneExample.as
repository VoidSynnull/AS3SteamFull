package game.scenes.examples.boatSceneExample
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.Edge;
	import game.components.motion.MotionControlBase;
	import game.components.motion.TargetEntity;
	import game.components.scene.Vehicle;
	import game.data.vehicle.VehicleData;
	import game.scene.template.topDown.boatScene.BoatScene;
	
	public class BoatSceneExample extends BoatScene
	{
		public function BoatSceneExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.init(container);
			// the asset for the randomly placed waves that animate over the water.
			super._waveAsset = super.groupPrefix + "wave.swf"
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addGroups():void
		{
			super.addGroups();
			
			// Create a new vehicle by creating a VehicleData instance...
			var playerData:VehicleData = new VehicleData();
			playerData.url = super.groupPrefix + "boat.swf";
			playerData.x = super.shellApi.profileManager.active.lastX;
			playerData.y = super.shellApi.profileManager.active.lastY;
			playerData.target = super.shellApi.inputEntity.get(Spatial);
			playerData.isPlayer = true;
			playerData.id = "player";
			
			playerData.accelerateToTargetRotation = new AccelerateToTargetRotation();
			playerData.accelerateToTargetRotation.rotationAcceleration = 250;
			playerData.accelerateToTargetRotation.deadZone = 10;
			
			playerData.edge = new Edge(-20, -20, 40, 40);
			
			playerData.motion = new Motion();
			playerData.motion.maxVelocity = new Point(150, 150);
			playerData.motion.rotationFriction = 150;
			playerData.motion.rotationMaxVelocity = 150;
			
			playerData.motionControlBase = new MotionControlBase();
			playerData.motionControlBase.acceleration = 400;
			playerData.motionControlBase.stoppingFriction = 100;
			playerData.motionControlBase.accelerationFriction = 200;
			playerData.motionControlBase.freeMovement = true;
			playerData.motionControlBase.rotationDeterminesAcceleration = true;
			playerData.motionControlBase.moveFactorMultiplier = .1;
			
			playerData.vehicle = new Vehicle();
			playerData.vehicle.onlyRotateOnAccelerate = false;
			
			playerData.addDynamicCollisions = true;  // whether this can hit other vehicles...
			
			super.loadVehicle(playerData);
			
			// or through a template group created in xml...
			super.loadVehicleFromTemplateId("npcBoat", 500, 500, "sam");
			
			// the player can be created with xml as well by uncommenting the code below and commenting out the 'super.loadVehicle(playerData);' code above.
			//super.loadVehicleFromTemplateId("playerBoat");
		}
		
		override protected function vehicleLoaded(entity:Entity):void
		{
			super.addWake(entity, super.groupPrefix + "waterRipple.swf");
			super.addPerspectiveAnimation(entity, "boat_animation.xml");
		}
		
		override protected function allVehiclesLoaded():void
		{
			var player:Entity = super.getEntityById("player");
			var npc:Entity = super.getEntityById("sam");
			var npcTarget:TargetEntity = npc.get(TargetEntity);
			npcTarget.target = player.get(Spatial);
			
			super.allVehiclesLoaded();
		}
	}
}