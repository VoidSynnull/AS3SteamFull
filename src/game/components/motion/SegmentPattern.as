package game.components.motion
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	
	public class SegmentPattern extends Component
	{
		public var obstacleSpatials:Vector.<Spatial> = new Vector.<Spatial>;
		public var obstaclePlacements:Vector.<Point> = new Vector.<Point>;
		public var obstacleSleeps:Vector.<Sleep> = new Vector.<Sleep>;
		public var obstacleDisplays:Vector.<Display> = new Vector.<Display>;
		public var obstacleLoopers:Vector.<Looper> = new Vector.<Looper>;
		
	//	public var followerSleeps:Vector.<Sleep> = new Vector.<Sleep>;
	//	public var nextSegment:Entity;
	//	public var nextSegmentWrap:MotionWrap;
	//	public var nextSegmentSleep:Sleep;
	//	public var nextLoopingSegment:LoopingSegment;
	//	public var nextSegmentSpatial:Spatial;
	}
}