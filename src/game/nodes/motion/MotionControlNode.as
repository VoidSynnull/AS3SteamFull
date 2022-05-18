package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Destination;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.TargetEntity;
	
	public class MotionControlNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var motionControl:MotionControl;
		public var motionTarget:MotionTarget;
		public var motionControlBase:MotionControlBase;
		
		public var navigation:Navigation;
		public var target:TargetEntity;
		public var destination:Destination;
		public var optional:Array = [Navigation, TargetEntity, Destination];

	}
}