package game.scenes.gameJam.dancingZombie.components
{
	import ash.core.Component;
	
	public class BeatDriven extends Component
	{
		public function BeatDriven()
		{
			super();
		}
		
		public var beatHit:Boolean = false;
		public var measure:int = 0;
		public var maxMeasure:int = 4;
	}
}