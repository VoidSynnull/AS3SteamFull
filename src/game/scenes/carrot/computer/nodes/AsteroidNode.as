package game.scenes.carrot.computer.nodes
{
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Display;
	import game.scenes.carrot.computer.components.Asteroid;
	import ash.core.Node;

	public class AsteroidNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var display:Display;
		public var asteroid:Asteroid;
	}
}