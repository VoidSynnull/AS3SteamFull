package game.scenes.virusHunter.shipTutorial.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.backRoom.BackRoom;
	
	public class SceneState extends Component
	{
		public function SceneState(state:String = "weaponTutorial")
		{
			this.state = state;
		}
		
		public var state:String;
		public var wait:Number;
		public var nextScene:Class = BackRoom;
		
		public const WEAPON_TUTORIAL:String = "weaponTutorial";
		public const SPAWN_VIRUS:String = "spawnVirus";
		public const ELIMINATE_VIRUS:String = "eliminateVirus";
		public const LEAVE_TUTORIAL:String = "leaveTutorial";
		public const FINAL_DIALOG:String = "finalDialog";
		public const TOTAL_VIRUS:int = 4;
		public const LEAVE_SCENE_WAIT:Number = .5;
	}
}