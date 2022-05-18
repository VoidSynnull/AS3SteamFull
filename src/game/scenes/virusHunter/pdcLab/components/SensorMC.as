package game.scenes.virusHunter.pdcLab.components
{
	import flash.display.MovieClip;
	
	import ash.core.Component;

	public class SensorMC extends Component
	{
		public var tripped:Boolean = false; // entity within bounds of mc
		public var mc:MovieClip; // mc that is serving as the sensor
		public var locked:Boolean;
		
		public function SensorMC($mc:MovieClip, $locked:Boolean = false):void{
			mc = $mc;
			locked = $locked;
		}
	}
}