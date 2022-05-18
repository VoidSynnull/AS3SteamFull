package game.scenes.time.viking.components
{
	import flash.geom.ColorTransform;
	
	import ash.core.Component;
	
	public class LightningFlash extends Component
	{
		public var delay:Number = 1;
		public var flashDelayRange:Number = 10;
		public var flashCount:Number = 0;
		public var soundEvent:String;
		public var startColorTrans:ColorTransform;
		public var flashingColorTrans:ColorTransform;
		public var flashing:Boolean = false;
		public var stopped:Boolean = false;
	}
}