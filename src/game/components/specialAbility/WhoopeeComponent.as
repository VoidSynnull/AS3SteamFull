package game.components.specialAbility
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class WhoopeeComponent extends Component
	{
		public var isNewSound:Boolean = false;
		public var isTriggered:Boolean = false;
		public var lastSound:int = 0;
		public var timer:Number = 0;
		public var audioPrefix:String;
		public var numberOfSounds:Number = 0;
		public var emitterEntity:Entity = new Entity;
		public var doAirEffect:Boolean = false;
		public var slip:Boolean = false;
		public var vSpeed:Number = 0;
		public var hSpeed:Number = 0;
		public var spin:Number = 0;
		public var vAccel:Number = 0;
		public var entities:Vector.<Entity> = new Vector.<Entity>();
		public var startYs:Vector.<Number> = new Vector.<Number>();
	}
}