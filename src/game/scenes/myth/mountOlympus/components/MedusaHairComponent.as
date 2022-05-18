package game.scenes.myth.mountOlympus.components
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class MedusaHairComponent extends Component
	{
		public var radius:int;// = 16;
		public var magnitute:int = 30;
		public var thickness:int = 24;
		
		//Used to determine whether the snakes should be drawn once and then be static. For mobile.
		public var drawOnce:Boolean = false;
		
		//Used to determine whether the snakes have already been drawn once. For mobile.
		public var drawnOnce:Boolean = false;
		
		public var state:Vector.<String> = new Vector.<String>;
		public var speeds:Vector.<Number> = new Vector.<Number>;
		public var timers:Vector.<Number> = new Vector.<Number>;
		public var snake:Vector.<Vector.<Spatial>> = new Vector.<Vector.<Spatial>>;
		public var head:Vector.<MovieClip> = new Vector.<MovieClip>;
		
		public const IDLE:String = 				"idle";
		public const LICK:String = 				"lick";
		public const RETURN:String = 		"return";
	}
}