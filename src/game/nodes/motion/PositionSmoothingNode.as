package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	public class PositionSmoothingNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var display:Display;
	}
}