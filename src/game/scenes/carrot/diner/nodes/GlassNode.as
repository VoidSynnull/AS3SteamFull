package game.scenes.carrot.diner.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.scenes.carrot.diner.components.Glass;
	
	public class GlassNode extends Node
	{
		public var glass:Glass;
		public var display:Display;
		public var spatial:Spatial;
		public var targetSpatial:TargetSpatial;
	}
}