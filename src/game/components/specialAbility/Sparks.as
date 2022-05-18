package game.components.specialAbility
{
	import flash.display.Shape;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class Sparks extends Component
	{
		public var sparks:Vector.<Shape> = new Vector.<Shape>();
		public var elapsedTime:Number = 0;
		public var bounds:Rectangle = new Rectangle();
		
		public function Sparks()
		{
			super();
		}
	}
}