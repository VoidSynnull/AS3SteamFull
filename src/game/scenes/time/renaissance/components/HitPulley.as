package game.scenes.time.renaissance.components
{
	import flash.geom.Point;
	
	
	import ash.core.Component;
	
	public class HitPulley extends Component
	{
		public var pointOne:Point;
		public var pointTwo:Point;
		
		public var acceleration:Number = 100;
		public var hitSource:Boolean = false;
		
	}
}