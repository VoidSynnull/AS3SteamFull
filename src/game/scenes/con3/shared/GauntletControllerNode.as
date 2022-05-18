package game.scenes.con3.shared
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	
	public class GauntletControllerNode extends Node
	{
		public var gauntletController:GauntletControllerComponent;
		public var display:Display;
		public var spatial:Spatial;
		public var timeline:Timeline;
	}
}