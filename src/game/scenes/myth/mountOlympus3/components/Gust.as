package game.scenes.myth.mountOlympus3.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
		
	public class Gust extends Component
	{
		static public const SINE:Number = 1;
		static public const SPIRAL:Number = 2;
		static public var duration:Number = 2 * Math.PI;
		
		public var active:Boolean = true;
		public var speed:Number = 400;
		public var rotation:Number = 0;
		public var lifeTime:Number = 0;
		
		public var state:String =		OFF;
		static public const OFF:String =			"off";
		static public const SPAWN:String =			"spawn";
		static public const END:String =			"end";
		static public const BLOW:String =			"blow";
		
		public var whirls:Array = new Array();	// Array of Objects usedto create wind line graphics
		
		public var t:Number;			// Timing variable.
		public var curID:Number;		// Next whirl to update.
		
		public var vx:Number;
		public var stx:Number;
		
		public var owner:Entity;
		public var ownerSpatial:Spatial;
	}
}