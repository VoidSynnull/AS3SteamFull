package game.scenes.myth.shared.components
{
	import ash.core.Component;
	
	public class Cloud extends Component
	{
		public var state:String = 				SPAWN;
		public var gatherRadius:Number = 60;
		public var attractRadius:Number = 200;	
		public var driftSpeed:Number = 4;	
		public var swirlSpeed:Number = 10;	
		public var attached:Boolean = false;
		
		public const SPAWN:String = 			"spawn";
		public const DRIFT:String = 			"drift";
		public const ATTRACT:String = 			"attract";
		public const GATHER:String = 			"gather";
		public const GATHERED:String = 			"gathered";
		public const KILL:String =				"kill";
		public const KILLED:String = 			"killed";
	}
}