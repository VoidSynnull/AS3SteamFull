package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.entity.character.JumpTargetIndicator;
	
	public class JumpTargetIndicatorNode extends Node
	{
		public var display:Display;
		public var spatial:Spatial;
		public var jumpTargetIndicator:JumpTargetIndicator;
		public var timeline:Timeline;
	}
}