package game.scenes.virusHunter.brain.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class BrainDoor extends Component
	{
		
		public function BrainDoor($brainDoorNerve:Entity, $brainDoor:Entity){
			brainDoorNerve = $brainDoorNerve;
			brainDoor = $brainDoor;
		}
		
		public var brainDoorNerve:Entity;
		public var brainDoor:Entity;
	}
}