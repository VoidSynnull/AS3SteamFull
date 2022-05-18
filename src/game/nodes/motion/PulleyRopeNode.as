package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.PulleyRope;
	
	public class PulleyRopeNode extends Node
	{
		public var display:Display;
		public var spatial:Spatial;
		public var pulleyRope:PulleyRope;
	}
}