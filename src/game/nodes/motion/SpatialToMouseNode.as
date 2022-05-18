package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.motion.SpatialToMouse;
	
	public class SpatialToMouseNode extends Node
	{
		public var mouse:SpatialToMouse;
		public var spatial:Spatial;
	}
}