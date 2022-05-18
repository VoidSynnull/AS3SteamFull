package game.scenes.survival1.shared.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class MicBlow extends Component
	{
		public var time:Number = 0;
		public var waitTime:Number;
		public var minActivityLevel:Number;
		
		public var hasBlown:Boolean = false;
		public var blown:Signal = new Signal(Entity);
		
		public function MicBlow(waitTime:Number = 0.5, minActivityLevel:Number = 40)
		{
			this.waitTime 			= waitTime;
			this.minActivityLevel 	= minActivityLevel;
		}
	}
}