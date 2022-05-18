package game.scenes.myth.hydra.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.scenes.myth.hydra.components.HydraHeadComponent;
	import game.scenes.myth.hydra.components.HydraNeckComponent;
	
	public class HydraHeadNode extends Node
	{
		public var headComponent:HydraHeadComponent;
		public var neckComponent:HydraNeckComponent;
		public var audio:Audio;
		public var id:Id;
		public var spatial:Spatial;
		public var display:Display;
	}
}