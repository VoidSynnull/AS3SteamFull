package game.scenes.timmy.chase.trashTruck
{
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	
	public class TrashTruckNode extends Node
	{
		public var trashTruck:TrashTruck;
		public var motion:Motion;
		public var spatial:Spatial;
		public var timeline:Timeline;
	}
}