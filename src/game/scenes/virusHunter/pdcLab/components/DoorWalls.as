package game.scenes.virusHunter.pdcLab.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class DoorWalls extends Component
	{
		public var doorWalls:Vector.<Entity>;
		
		public function DoorWalls($doorWalls:Vector.<Entity>):void{
			doorWalls = $doorWalls;
		}
	}
}