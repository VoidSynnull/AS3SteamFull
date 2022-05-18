package game.components.animation.procedural
{
	import ash.core.Component;
	import game.data.animation.procedural.PerspectiveAnimationLayerData;
	
	public class PerspectiveAnimation extends Component
	{
		public function PerspectiveAnimation()
		{
			this.layers = new Vector.<PerspectiveAnimationLayerData>();
		}
		
		public var layers:Vector.<PerspectiveAnimationLayerData>;
		public var frame:Number = 0;    // The current 'frame' of the animation, advanced by step.
		public var step:Number = 0;     // The rate to advance the frame.  Can be a steady tick or impacted by velocity.
		public var baseStep:Number = 0; // The base step, should be unmodified.
		public var velocityMultiplier:Number = 1/60;  // Determines the impact of velocity on the step rate.
	}
}