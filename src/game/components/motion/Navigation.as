package game.components.motion
{	
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Navigation extends Component
	{
		public function Navigation( minTargetDelta:Point = null )
		{
			this.minTargetDelta = ( minTargetDelta != null ) ? minTargetDelta : new Point( MIN_X_DEFAULT, MIN_Y_DEFAULT);
		}
		
		public var active:Boolean = false;
		public var activate:Boolean = false;
		private var _path:Vector.<Point>;
		public function get path():Vector.<Point>	{ return _path; }
		public function set path( pointPath:Vector.<Point>):void
		{
			if( _path != pointPath )
			{
				_path = pointPath;
				if( active )	// if already active, reactivate with new path
				{
					activate = true;
					index = Number.NaN;
				}
			}
		}
		public var minTargetDelta:Point;			// Point holding minimum distances necessary to trigger a reached path point.
		public var index:Number = Number.NaN;
		public var loop:Boolean;				// if true path will loop
	
		public const MIN_X_DEFAULT:Number = 25;
		public const MIN_Y_DEFAULT:Number = 100;
	}
}
