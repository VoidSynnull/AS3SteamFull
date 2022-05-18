package game.scenes.virusHunter.intestine.components
{
	import ash.core.Component;
	
	public class IntestineState extends Component
	{
		public function IntestineState(state:String = "intestine")
		{
			this.state = state;
		}
		
		public var state:String;
		
		public const INTESTINE:String = "intestine";
		public const SPAWN_VIRUS_1:String = "spawn_virus_1";
		public const SPAWN_VIRUS_2:String = "spawn_virus_2";
		public const SPAWN_VIRUS_3:String = "spawn_virus_3";
	}
}