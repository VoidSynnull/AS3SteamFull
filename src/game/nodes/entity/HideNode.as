package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Hide;
	
	public class HideNode extends Node
	{
		public var hide:Hide;
		public var spatial:Spatial;
		public var display:Display;
	}
}