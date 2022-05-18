package game.components.motion
{
	import ash.core.Component;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;

	public class LoopingSegment extends Component
	{		
		public var patternNumber:Number = 0;
		public var staticHitPattern:SegmentPattern;
		public var obstaclePattern:Vector.<SegmentPattern> = new Vector.<SegmentPattern>;
		
		public var nextWrap:Vector.<MotionWrap> = new Vector.<MotionWrap>;
		public var nextSleep:Vector.<Sleep> = new Vector.<Sleep>;
		public var nextSegment:Vector.<LoopingSegment> = new Vector.<LoopingSegment>;
		public var nextSpatial:Vector.<Spatial> = new Vector.<Spatial>;
		public var nextMotion:Vector.<Motion> = new Vector.<Motion>;
	}
}