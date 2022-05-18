package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.motion.Mass;
	
	public class MassNode extends Node
	{
		public var spatial:Spatial;
		public var mass:Mass;
		public var id:Id;
		
		public var optional:Array = []
	}
}