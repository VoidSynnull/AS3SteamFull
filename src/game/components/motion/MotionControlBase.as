package game.components.motion
{
	import ash.core.Component;
	
	public class MotionControlBase extends Component
	{
		public var acceleration:Number = 0;
		public var stoppingFriction:Number = 0;
		public var accelerationFriction:Number = 0;
		public var maxVelocityByTargetDistance:Number = 0;  // if defined the max velocity will be set based on distance from target.
		public var freeMovement:Boolean = false;			// if true movement is along both x & y axises, if false movement is only along x axis
		public var accelerate:Boolean = false;
		public var rotationDeterminesAcceleration:Boolean = false;  // if true, the rotation will determine the x and y acceleration.
		public var lockAxis:String = "";
		
		// for independent axis movement...this is set AUTOMATICALLY based on viewport size...to modify, adjust the multipliers below
		public var moveFactorX:Number;
		public var moveFactorY:Number;
		public var minDistanceX:Number;
		public var minDistanceY:Number;
		
		// for free movement along both axis...this is set AUTOMATICALLY based on viewport size...to modify, adjust the multipliers below
		public var moveFactor:Number;
		public var minDistance:Number;
		
		/**
		 * The percentage of half of the viewport height (from the center) which is used to scale movement rate.  A value of .5 would mean 100% of the viewport size
		 * is used to determine acceleration rate (meaning you wouldn't have 100% acceleration rate unless you were at the furthest
		 *  extent of the screen.)  The default of .25 means that anywhere past 25% of the viewport size gives you full acceleration.
		 */
		public var moveFactorMultiplier:Number = .25;  
		
		/**
		 * The percentage of half of the viewport height (from the center) which is used to calculate deadzone.  
		 */
		public var minDistanceMultiplier:Number = .05;  
		
		public static const X:String = "X";
		public static const Y:String = "Y";
	}
}