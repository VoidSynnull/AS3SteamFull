package game.scenes.deepDive2.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Wall;
	import game.scenes.deepDive2.shared.components.Breakable;
	
	public class BreakableNode extends Node
	{
		public var breakable:Breakable;
		public var timeline:Timeline;
		public var display:Display;
		public var movieClipHit:MovieClipHit;
		public var wall:Wall;
		
		public var optional:Array = [Wall];
	}
}