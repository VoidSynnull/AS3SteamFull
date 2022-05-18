package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Magnet;
	import game.components.motion.Mass;
	
	public class MagnetNode extends Node
	{
		public var magnet:Magnet;
		public var mass:Mass;
		public var spatial:Spatial;
		
		public var motion:Motion;
		
		public var optional:Array = [Motion];
	}
}