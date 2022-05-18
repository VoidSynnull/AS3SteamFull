package game.scenes.virusHunter.mouth.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.mouth.components.Bubble;
	
	public class BubbleNode extends Node
	{
		public var bubble:Bubble;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}