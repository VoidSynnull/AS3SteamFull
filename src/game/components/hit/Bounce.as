package game.components.hit
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Bounce extends Component
	{
		public var velocity:Point;
		public var animate:Boolean = false;
		public var timeline:Entity;
	}
}
