package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Swarmer;
	
	public class SwarmNode extends Node
	{
		public var swarmer:Swarmer;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;		
	}
}