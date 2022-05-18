package game.scenes.mocktropica.mountain.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.motion.Edge;
	import game.scenes.mocktropica.mountain.components.BoulderComponent;
	
	public class BoulderNode extends Node
	{
		public var audio:Audio;
		public var boulder:BoulderComponent;
		public var display:Display;
		public var motion:Motion;
		public var edge:Edge;
	}
}