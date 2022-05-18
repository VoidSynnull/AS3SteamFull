package game.scenes.survival5.sawmill.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import org.osflash.signals.Signal;
	
	public class RotatingStep extends Component
	{
		public function RotatingStep(maxRotation:Number, speed:Number, platform:Entity, direction:String = CLOCKWISE)
		{
			this.maxRotation = maxRotation;
			this.speed = speed;
			this.platform = platform;
			
			if(direction == COUNTER)
				speed *= -1;
			
			trapSet = new Signal();
		}
		
		public var maxRotation:Number;
		public var speed:Number;
		public var platform:Entity;
		public var saw:Motion;
		public var gear1:Motion;
		public var gear2:Motion;
		public var attachedGear:Motion;
		public var gearAttached:Boolean = false;
		public var trapSet:Signal;
		
		public static const CLOCKWISE:String 	= "clockwise";
		public static const COUNTER:String		= "counter";
	}
}