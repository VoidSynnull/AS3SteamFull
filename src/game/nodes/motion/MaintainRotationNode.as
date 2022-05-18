package game.nodes.motion
{	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.MaintainRotation;
	
	public class MaintainRotationNode extends Node
	{
		public var maintainRotation:MaintainRotation;
		public var spatial:Spatial;
		public var display:Display;
	}
}