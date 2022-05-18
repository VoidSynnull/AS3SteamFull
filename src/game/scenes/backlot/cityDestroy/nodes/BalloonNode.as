package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.backlot.cityDestroy.components.BalloonComponent;
	
	public class BalloonNode extends Node
	{
		public var balloon:BalloonComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}