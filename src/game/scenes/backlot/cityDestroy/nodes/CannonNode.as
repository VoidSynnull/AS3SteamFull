package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.backlot.cityDestroy.components.CannonComponent;
	
	public class CannonNode extends Node
	{
		public var cannon:CannonComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}