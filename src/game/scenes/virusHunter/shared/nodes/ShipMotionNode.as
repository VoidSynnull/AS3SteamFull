package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.motion.MotionControlBase;
	import game.scenes.virusHunter.shared.components.Ship;
	
	public class ShipMotionNode extends Node
	{
		public var ship:Ship;
		public var motion:Motion;
		public var motionControlBase:MotionControlBase;
		public var display:Display;
		public var audio:Audio;
	}
}