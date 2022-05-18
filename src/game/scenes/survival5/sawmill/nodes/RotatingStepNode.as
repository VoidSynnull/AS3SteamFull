package game.scenes.survival5.sawmill.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.survival5.sawmill.components.RotatingStep;
	
	public class RotatingStepNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var rotatingStep:RotatingStep;
	}
}