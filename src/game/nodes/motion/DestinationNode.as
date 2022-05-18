package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Destination;
	import game.components.animation.FSMControl;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.TargetEntity;
	
	public class DestinationNode extends Node
	{
		public var destination:Destination;
		public var spatial:Spatial;
		public var motion:Motion;
		public var motionTarget:MotionTarget;
		public var motionControl:MotionControl;
		

		public var fsmControl:FSMControl;
		public var navigation:Navigation;
		public var targetEntity:TargetEntity;
		public var optional:Array = [ FSMControl, Navigation, TargetEntity ];
	}
}