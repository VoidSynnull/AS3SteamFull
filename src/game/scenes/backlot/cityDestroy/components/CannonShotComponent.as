package game.scenes.backlot.cityDestroy.components
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class CannonShotComponent extends Component
	{
		public var power:Number = 1;
		public var rad:Number;
		public var explosion:Entity;
		public var shell:Entity;
		
		public var trajectoryX:Number;
		public var trajectoryY:Number;
		
		public var hitBox:MovieClip;
		
		public var state:String = 		"active";
		
		public const ACTIVE:String = 	"active";
		public const HIT:String = 		"hit";
		public const EXPLODE:String = 	"explode";
		public const DESTROYED:String =	"destroyed";
	}
}