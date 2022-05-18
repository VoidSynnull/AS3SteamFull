package game.scenes.myth.mountOlympus3.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.myth.mountOlympus3.components.Bolt;
	
	public class BoltNode extends Node
	{
		public var audio:Audio;
		public var bolt:Bolt;
		public var display:Display;
		public var id:Id;
		public var motion:Motion;
		public var spatial:Spatial;
		public var sleep:Sleep;
	}
}