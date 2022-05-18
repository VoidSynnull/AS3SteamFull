package game.data.vehicle
{
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.Edge;
	import game.components.motion.MotionControlBase;
	import game.components.scene.Vehicle;

	public class VehicleData
	{
		public function VehicleData()
		{
		}
		
		public var url:String;
		public var x:Number;
		public var y:Number;
		public var target:Spatial;
		public var isPlayer:Boolean;
		public var id:String;
		public var motion:Motion;
		public var motionControlBase:MotionControlBase;
		public var edge:Edge;
		public var accelerateToTargetRotation:AccelerateToTargetRotation;
		public var vehicle:Vehicle;
		public var addDynamicCollisions:Boolean = true;
	}
}