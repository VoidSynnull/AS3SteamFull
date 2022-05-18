package game.scenes.myth.cerberus.components
{
	import ash.core.Component;
	
	public class CerberusSnoreComponent extends Component
	{
		public var active:Boolean = false;
		public var headNumber:int;
		public var zeeStarterX:Number = 0;
		public var zeeStarterY:Number = 0;
		public var state:String =   			START_DRIFT;
		
		public var waitTimer:Number = 220;
		public var counter:Number = 0;
		
		public const START_DRIFT:String =		"start_drift";
		public const DRIFT:String =				"drift";
	}
}