package game.components.motion
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class PulleyRope extends Component
	{
		public function PulleyRope(start:Spatial, end:Spatial, offset:Number = 0)
		{
			startSpatial = start;
			endSpatial = end;
			offsetConnection = offset;
		}
		
		public var startSpatial:Spatial; // where the top of the rope should be
		public var endSpatial:Spatial; // where the bottom of the rope should be
		public var originalHeight:Number; // set once the system starts
		public var lastEndY:Number = -100000;
		public var offsetConnection:Number;
	}
}