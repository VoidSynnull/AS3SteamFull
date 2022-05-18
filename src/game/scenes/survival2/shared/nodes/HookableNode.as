package game.scenes.survival2.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.survival2.shared.components.Hookable;
	
	public class HookableNode extends Node
	{
		public var hookable:Hookable;
		public var display:Display;
		public var spatial:Spatial;
	}
}