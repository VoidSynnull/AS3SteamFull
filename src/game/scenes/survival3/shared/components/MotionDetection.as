package game.scenes.survival3.shared.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class MotionDetection extends Component
	{
		public var minVelDectection:Point;
		public var motionDetected:Boolean;
		public var detected:Signal;
		// can set values to be negative so that standing still will still result in detection
		public function MotionDetection(minDetectX:Number = 0, minDetectY:Number = 0)
		{
			detected = new Signal(Entity, Boolean);
			minVelDectection = new Point(minDetectX, minDetectY);
		}
	}
}