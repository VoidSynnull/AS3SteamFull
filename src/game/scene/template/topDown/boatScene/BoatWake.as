package game.scene.template.topDown.boatScene
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Component;
	
	public class BoatWake extends Component
	{
		public function BoatWake(container:DisplayObjectContainer = null, url:String = "")
		{
			this.container = container;
			this.url = url;
		}
		
		public var container:DisplayObjectContainer;
		public var url:String;
		public var baseWaitTime:Number = .1;
		public var motionBasedWaitTime:Number = .9;
		public var velocityMultiplier:Number = .5;
		public var waitTime:Number = 0;
		public var rippleScaleX:Number = 1;
		public var rippleScaleY:Number = 1;
	}
}