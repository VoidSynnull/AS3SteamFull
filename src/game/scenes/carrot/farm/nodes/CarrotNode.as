package game.scenes.carrot.farm.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.carrot.farm.components.Carrot;
	
	public class CarrotNode extends Node
	{
		public var carrot:Carrot;
		public var display:Display;
		public var spatial:Spatial;
		public var timeline:Timeline;
//		public var audio:Audio;
	}
}