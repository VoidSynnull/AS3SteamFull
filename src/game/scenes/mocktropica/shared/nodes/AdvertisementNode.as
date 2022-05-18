package game.scenes.mocktropica.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.shared.components.AdvertisementComponent;
	
	public class AdvertisementNode extends Node
	{
		public var audio:Audio;
		public var ad:AdvertisementComponent;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}