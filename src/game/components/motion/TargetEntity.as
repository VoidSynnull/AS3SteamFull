package game.components.motion
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class TargetEntity extends Component
	{
		private const DEFAULT_MIN:int = 100;

		public function TargetEntity( minX:int = DEFAULT_MIN, minY:int = DEFAULT_MIN, target:Spatial = null, applyCameraOffset:Boolean = false )
		{
			minTargetDelta = new Point(minX, minY);
			this.target = target;
			this.applyCameraOffset = applyCameraOffset;
		}
		
		public var active:Boolean = true;  		// currently active
		public var forceTarget:Boolean = false; // entity is always forced towards target
		public var minTargetDelta:Point;      	// how close to follow, if null mindistance is ignored
		
		public var target:Spatial;         		// target entity's spatial
		public var offset:Point;           		// offset from target entity's spatial
		public var applyCameraOffset:Boolean = false;
	}
}