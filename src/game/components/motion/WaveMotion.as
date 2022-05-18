package game.components.motion
{	
	import ash.core.Component;
	
	import game.data.WaveMotionData;
	
	public class WaveMotion extends Component
	{
		public var data:Vector.<WaveMotionData> = new Vector.<WaveMotionData>;

		/**
		 * This flag indicates to the <code>WaveMotionSystem</code> that motion should be discontinued once a normal value has been reached.
		 */		
		public var subside:Boolean;

		/**
		 * Appends a new <code>WaveMotionData</code> to this component's <code>data</code> Vector.
		 * @param newData	An instance of <code>WaveMotionData</code>
		 * 
		 */		
		public function add(newData:WaveMotionData):void
		{
			data.push(newData);
		}

		/**
		 * Iterates over this component's <code>data</code> Vector and return the first <code>WaveMotionData</code> which controls the given property.
		 *  
		 * @param prop	The property assigned to the <code>WaveMotionData</code>
		 * @return 		The <code>WaveMotionData</code> for the given property, or null if no <code>WaveMotionData</code> exists for that property.
		 * 
		 */		
		public function dataForProperty(prop:String):WaveMotionData {
			for (var i:int=0; i<data.length; i++) {
				if (data[i].property == prop) {
					return data[i];
				}
			}
			return null;
		}
	}
}