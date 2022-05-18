package game.scenes.gameJam
{
	import game.data.island.IslandEvents;
	import game.scenes.gameJam.dancingZombie.DanceGamePopup;
	import game.scenes.gameJam.dancingZombie.DancingZombie;
	import game.scenes.gameJam.zombieDefense.ZombieDefense;

	public class GameJamEvents extends IslandEvents
	{
		public function GameJamEvents()
		{
			super();
			super.scenes = [DancingZombie,ZombieDefense];
			super.popups = [DanceGamePopup];
		}
	}
}