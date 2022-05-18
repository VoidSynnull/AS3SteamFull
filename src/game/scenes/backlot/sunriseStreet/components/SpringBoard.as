package game.scenes.backlot.sunriseStreet.components
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class SpringBoard extends Component
	{
		public function SpringBoard(springVelocity:Number = 10, dampening:Number = 1, restingRotation:Number = 0):void
		{
			this.springVelocity = springVelocity;
			this.dampening = dampening;
			this.restingRotation = restingRotation;
			spring = new Signal();
		}
		public var springVelocity:Number;
		public var restingRotation:Number;
		public var dampening:Number;
		public var spring:Signal;
	}
}