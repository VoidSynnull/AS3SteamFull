package game.scenes.deepDive1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.motion.RotateToVelocity;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.FishPath;
	
	public class FishPathNode extends Node
	{
		public var path:FishPath;
		public var filmable:Filmable;
		public var spatial:Spatial;
		public var motion:Motion;
		public var timeline:Timeline;
		public var display:Display;
		
		public var rotateToVelocity:RotateToVelocity;
		public var optional:Array = [RotateToVelocity];
	}
	
}