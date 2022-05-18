package engine.components 
{
	import ash.core.Component;

	public class AudioRange extends Component 
	{
		public var radius:Number;
		public var minVolume:Number;
		public var maxVolume:Number;
		public var tween:Function;
		
		/**
		 * A component to control panning and volume for a sound based on the entities spatial relative to the camera center.
		 * @param radius : The radius of the effect area
		 * @param min/maxVolume : The range of this sfx's volume.  Even outside of the range it will not go lower than the minimum.
		 * @param tween : The transition used to fade the sfx.
		 */
		public function AudioRange(radius:Number, minVolume:Number = 0, maxVolume:Number = 1, tween:Function = null)
		{
			this.radius = radius;
			this.minVolume = Math.max(0, minVolume);
			this.maxVolume = Math.min(1, maxVolume);
			
			this.tween = tween;
		}
	}
	
}