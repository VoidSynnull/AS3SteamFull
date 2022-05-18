package game.scenes.gameJam.dancingZombie.components
{
	import ash.core.Component;
	
	public class DiscoTile extends Component
	{
		public function DiscoTile()
		{
			super();
		}
		
		public var row:int = 0;
		public var column:int = 0;
		public var beatMeasure:int = 0;
		public var colorIndex:int = 0;
		public var ignoreColor:Boolean = false;
		public var lit:Boolean = false;
	}
}