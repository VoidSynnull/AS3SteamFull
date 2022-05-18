package game.scenes.virusHunter.stomach.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.stomach.components.Food;

	public class FoodNode extends Node
	{
		public var food:Food;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}