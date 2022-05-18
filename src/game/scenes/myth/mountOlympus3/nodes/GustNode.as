package game.scenes.myth.mountOlympus3.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.myth.mountOlympus3.components.Gust;
	
	public class GustNode extends Node
	{
		public var audio:Audio;
		public var display:Display;
		public var gust:Gust;
		public var motion:Motion;
		public var sleep:Sleep;
		public var spatial:Spatial;
	}
}