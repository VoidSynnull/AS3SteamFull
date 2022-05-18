package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class Weapon extends Component
	{
 		public var offsetX:Number = 0;
		public var offsetY:Number = 0;
		public var projectileLifespan:Number = 0;
		public var damage:Number = .25;
		public var type:String;
		public var projectileColor:uint;
		public var projectileSize:uint = 4;
		public var timeSinceLastShot:Number = 0;
		public var minimumShotInterval:Number = .5;
		public var velocity:Number = 0;
		public var selectionRotation:Number = 0;
		public var activeX:Number = 0;
		public var activeY:Number = 0;
		public var gunBarrels:Number = 1;
		public var gunBarrelSeparation:Number = 0;
		public var gunBarrelAngleSeparation:Number = 0;
		//public var gunBarrelAngle:Number = 0;
		public var level:uint = 0;
		public var maxLevel:uint = 4;
		public var invalidate:Boolean = false;
		
		public var state:String = "active";
		public const EXPAND:String = "expand";
		public const SELECTION:String = "selection";
		public const RETRACT:String = "retract";
		public const ACTIVE:String = "active";
		public const INACTIVE:String = "inactive";
	}
}