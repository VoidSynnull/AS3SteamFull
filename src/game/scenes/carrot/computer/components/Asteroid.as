package game.scenes.carrot.computer.components
{
	import ash.core.Component;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	import org.osflash.signals.Signal;
	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	public class Asteroid extends Component
	{
		public function Asteroid()
		{
			hitSignal = new Signal();
		}
		
		public var hitSignal:Signal
		
		public var target:DisplayObjectContainer
		
		public var active:Boolean = false;
		public var paused:Boolean = false;
	
		public var bounds:Rectangle;
		
		public var velYMin:int;
		public var velYRange:int;
		
		public var waitTime:Number;
		public var minWaitTime:Number;
		public var rangeWaitTime:Number;
	}
}