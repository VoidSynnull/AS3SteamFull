package game.scenes.carrot.sewer.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.hit.Hazard;
	import game.scenes.carrot.sewer.components.Rat;
	
	public class RatNode extends Node
	{
		public var rat:Rat;
		public var display:Display;
		public var hit:Hazard;
	}
}