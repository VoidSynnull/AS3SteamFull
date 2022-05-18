package game.components.motion
{
	import ash.core.Component;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	
	import flash.geom.Point;
	
	public class FollowEntity extends Component
	{
		public var target:Spatial;         // target entity's spatial
		public var offset:Point;           // offset from target entity's spatial
		public var minDistance:Point;      // how close to follow, if null mindistance is ignored
		public var active:Boolean = true;  // should the entity be following the target?
		public var applyCameraOffset:Boolean = false;
		public var inRange:Boolean = false;
	}
}