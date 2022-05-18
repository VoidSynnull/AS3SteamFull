package game.scenes.hub.balloons.components
{
	import flash.geom.Point;
	
	import ash.core.Entity;

	public class BalloonCell
	{
		public function BalloonCell($column:int, $row:int, $coords:Point)
		{
			column = $column;
			row = $row;
			coords = $coords;
		}
		
		public function clear():void{
			playerId = 0;
			if(balloon){
				balloon.group.removeEntity(balloon);
			}
		}
		
		public var column:int;
		public var row:int;
		public var coords:Point;
		public var playerId:int;
		public var balloon:Entity;
	}
}