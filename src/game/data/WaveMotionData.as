package game.data
{
	public class WaveMotionData
	{	
	/**
	 * WaveMotionData formalizes the configuration data for <code>WaveMotion</code> components. It can be used for sin/cos/tan or any other math ops that are applied to an incrementing value
	 * @param	property : property to apply wave to (e.g., "x", "y", "rotation")
	 * @param	radians : Initial angle sets the point in the wave.  Alternate between values (ex : 0, Math.PI, Math.PI / 2) to stagger motion.
	 * @param	magnitude : magnitude of movement.  Bigger values here make larger wave ranges.
	 * @param	rate : size of steps between updates.  Bigger values make bigger movements, smaller values for smoother movement.
	 * @param	type : any Math operation can go here (cos, sin, tan2, etc.)
	 */
		public function WaveMotionData( property:String = "", magnitude:Number = 0, rate:Number = 1, type:String = "sin", radians:Number = 0, useTimeStep:Boolean = false)
		{
			this.property = property;
			this.magnitude = magnitude;
			this.rate = rate;
			this.type = type;
			this.radians = radians;
			this.useTime = useTimeStep;
		}

		/**
		 * Creates a copy of this <code>WaveMotionData</code> object.
		 * @return A new instance of <code>WaveMotionData</code> initialized with this object's properties.
		 * 
		 */		
		public function clone():WaveMotionData {
			return new WaveMotionData(this.property, this.magnitude, this.rate, this.type, this.radians, this.useTime);
		}

		/**
		 * The value of <code>property</code> before applying wave motion. When a <code>WaveMotion</code> is set to subside, motion will cease when this value is reached. 
		 */		
		public var normalValue:Number;
		public var property:String;
		public var magnitude:Number;        
		public var rate:Number;            
		public var type:String = "sin";
		public var radians:Number = 0;	
		public var useTime:Boolean = false;
	}
}