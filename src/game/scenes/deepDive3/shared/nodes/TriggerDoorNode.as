package game.scenes.deepDive3.shared.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive3.shared.components.TriggerDoor;
	
	public class TriggerDoorNode extends Node
	{
		public var triggerDoor:TriggerDoor;
		public var display:Display;
		public var spatial:Spatial;
		public var timeline:Timeline;
	}
}