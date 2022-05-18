package game.scenes.hub.profile.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.hub.profile.components.Sticker;
	
	public class StickerNode extends Node
	{
		public var sticker:Sticker;
		public var display:Display;
		public var spatial:Spatial;
	}
}