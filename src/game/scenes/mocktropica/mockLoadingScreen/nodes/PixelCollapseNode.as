package game.scenes.mocktropica.mockLoadingScreen.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.mockLoadingScreen.components.PixelCollapseComponent;
	
	public class PixelCollapseNode extends Node
	{
		public var pixelCollapseComponent:PixelCollapseComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}
