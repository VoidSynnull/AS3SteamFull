package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.hit.Mover;
	import game.components.motion.DirectionalMover;
	
	public class DirectionalMoverNode extends Node
	{
		public var directionalMover:DirectionalMover;
		public var spatial:Spatial;
		public var mover:Mover;		
	}
}