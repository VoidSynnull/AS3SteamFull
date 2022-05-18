package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.backlot.cityDestroy.components.SearchLightComponent;

	
	public class SearchLightNode extends Node
	{
		public var light:SearchLightComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}