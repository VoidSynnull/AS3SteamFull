package game.scenes.backlot.cityDestroy.components
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	
	public class CannonComponent extends Component
	{
		public var barrel:Entity;
		public var base:Entity;
		public var explosion:Entity;
		
		public var hit:MovieClip;
		
		public var angle:Number;
		public var shellUrl:String;

		public var timer:Number = 0;
		public var state:String = "idle";
		
		public var shotEmpty:MovieClip;
	}
}