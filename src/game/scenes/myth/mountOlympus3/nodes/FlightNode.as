package game.scenes.myth.mountOlympus3.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.scenes.myth.mountOlympus3.components.FlightComponent;
	
	public class FlightNode extends Node
	{
		public var motion:Motion;
		public var spatial:Spatial;
		public var motionTarget:MotionTarget;
		public var motionControl:MotionControl;
		public var flight:FlightComponent;
	}
}