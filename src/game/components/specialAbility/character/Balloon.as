package game.components.specialAbility.character
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	
	public class Balloon extends Component
	{
		public var player:Entity;
		public var colorIndex:Number = 0;
		public var colorCounter:Number = 0;
		public var string:Sprite;
		public var stringColor:uint = 0xFFFFFF;
		public var stringThickness:Number = 1;
		public var knotPosition:Point = new Point();
		public var restingPosition:Point= new Point(5, -200);
		public var directional:Boolean = false;
		
		public function Balloon(_player:Entity)
		{
			player = _player;
		}
	}
}