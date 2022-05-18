package game.scenes.timmy.zoo.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.timmy.zoo.components.Ball;
	
	public class BallNode extends Node
	{
		public var ball:Ball;
		public var display:Display;
		public var spatial:Spatial;
	}
}