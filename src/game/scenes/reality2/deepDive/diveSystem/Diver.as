package game.scenes.reality2.deepDive.diveSystem
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Diver extends Component
	{
		public var air:Number;
		public var maxAir:Number;
		public var rate:Number;
		public var ranOutOfAir:Signal;
		public var signaled:Boolean = false;
		public var ui:MovieClip;
		public var place:int;
		public var depth:int;
		
		public function Diver(air:Number = 30, rate:Number = 1)
		{
			this.air = maxAir = air;
			this.rate = rate;
			ranOutOfAir = new Signal(Entity);
		}
	}
}