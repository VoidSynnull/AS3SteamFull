package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.render.DynamicWire;
	
	public class DynamicWireNode extends Node
	{
		public var wire:DynamicWire;
		public var spatial:Spatial;
		public var target:TargetSpatial;
		public var display:Display;
	}
}