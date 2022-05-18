package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.backlot.cityDestroy.components.CannonShotComponent;
	
	public class CannonShotNode extends Node
	{
		public var shot:CannonShotComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}