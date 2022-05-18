package game.scenes.survival2.beaverDen.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.scenes.survival2.beaverDen.components.BeaverComponent;
	
	public class BeaverNode extends Node
	{
		public var audio:Audio;
		public var beaver:BeaverComponent;
		public var display:Display;
		public var id:Id;
		public var motion:Motion;
		public var sleep:Sleep;
		public var spatial:Spatial;
		public var timeline:Timeline;
		public var tween:Tween;
	}
}