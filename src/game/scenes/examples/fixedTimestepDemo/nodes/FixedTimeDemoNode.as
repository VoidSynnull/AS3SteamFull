package game.scenes.examples.fixedTimestepDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.scenes.examples.fixedTimestepDemo.components.FixedTimeDemo;
	
	public class FixedTimeDemoNode extends Node
	{
		public var display:Display;
		public var fixedTime:FixedTimeDemo;
	}
}