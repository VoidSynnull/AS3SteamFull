package game.components.motion
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Spatial;

	public class MotionTarget extends Component
	{
		public function MotionTarget()
		{
			//this.onTargetReached = new Signal( Entity );
		}
		
		public var targetOffset:Point;	
		public var targetDeltaX:Number;			// distance from target ( camera offsets accounted for )
		public var targetDeltaY:Number; 		// distance from target ( camera offsets accounted for )
		
		public var _targetX:Number = 0;
		public var _targetY:Number = 0;
		
		public function set targetX(targetX:Number):void
		{
			_targetX =  targetX;
			this.useSpatial = false;
		}
		
		public function get targetX():Number 
		{ 
			if(this.useSpatial) 
			{ 
				return(targetSpatial.x); 
			}
			else
			{
				return(_targetX);
			}
		}
		
		public function set targetY(targetY:Number):void
		{
			_targetY =  targetY;
			this.useSpatial = false;
		}
		
		public function get targetY():Number 
		{ 
			if(this.useSpatial) 
			{ 
				return(targetSpatial.y); 
			}
			else
			{
				return(_targetY);
			}
		}
		
		public function set targetSpatial(spatial:Spatial):void
		{
			useSpatial = spatial != null;
			_targetSpatial = spatial;
		}
		
		public function get targetSpatial():Spatial { return(_targetSpatial); }
		
		// target reached
		public var checkReached:Boolean = false;		// if should the target being reached should be check 
		public var targetReached:Boolean = false;		// whether entity is in range of target ( minXDistance & minYDistance or minPreciseTargetDistance used to determine range )
		public var hasNextTarget:Boolean = false;		// whether there is an additional target
		
		public var minTargetDelta:Point;
		public var minTargetPreciseDelta:Number;		// If set a radial distance check is used to determine path point reached, otherwise minDistance is used in a rectangular check.
		
		private var _targetSpatial:Spatial;
		public var useSpatial:Boolean = false;
	}
}