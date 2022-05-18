package game.components.hit
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class GravityWell extends Component
	{
		public function GravityWell(rad:Number, mass:Number, hitRng:Number = 0, reverse:Boolean = false)
		{
			this.hitRange = hitRng;
			radius = rad;
			this.mass = mass;
			reversed = reverse;
		}
		
		public var radius:Number;
		public var mass:Number;
		public var reversed:Boolean;
		public var hitRange:Number;
		public var hitSignal:Signal = new Signal();
	}
}