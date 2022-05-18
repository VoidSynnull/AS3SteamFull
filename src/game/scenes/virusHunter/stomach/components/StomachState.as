package game.scenes.virusHunter.stomach.components
{
	import ash.core.Component;
	
	public class StomachState extends Component
	{
		public var state:String;
		public const STOMACH:String = "stomach";
		public const SPAWN_VIRUS:String = "spawn_virus";
		
		public function StomachState(state:String = "stomach")
		{
			this.state = state;
		}
	}
}