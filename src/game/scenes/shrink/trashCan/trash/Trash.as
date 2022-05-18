package game.scenes.shrink.trashCan.trash
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Trash extends Component
	{
		public var shakeIntensity:Number;
		public var shakeTime:Number;
		public var time:Number;
		public var falling:Boolean;
		public var shaking:Boolean;
		public var squash:Signal;
		public function Trash(shakeIntensity:Number = 5, shakeTime:Number = 1)
		{
			this.shakeIntensity = shakeIntensity;
			this.shakeTime = shakeTime;
			time = 0;
			falling = shaking = false;
		}
	}
}