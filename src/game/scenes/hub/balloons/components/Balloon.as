package game.scenes.hub.balloons.components
{
	import ash.core.Component;
	
	public class Balloon extends Component
	{
		public function Balloon($column:int, $row:int):void{
			column = $column;
			row = $row;
		}
		
		public var column:int;
		public var row:int;
	}
}