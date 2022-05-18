package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.motion.MotionWrap;
	import game.components.motion.LoopingSegment;

	public class MotionWrapNode extends Node
	{
		public var motion:Motion;
		public var motionWrap:MotionWrap;
		public var sleep:Sleep;
		public var spatial:Spatial;
		
		public var loopingSegment:LoopingSegment;
		public var optional:Array = [ LoopingSegment ];
		//		public var id:Id;
	}
}

