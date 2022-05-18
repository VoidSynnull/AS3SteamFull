package game.scenes.photoBoothIsland
{
	import game.data.island.IslandEvents;
	import game.scenes.photoBoothIsland.photoBoothScene.PhotoBoothScene;

	public class PhotoBoothIslandEvents extends IslandEvents
	{
		public function PhotoBoothIslandEvents()
		{
			super();
			super.scenes = [PhotoBoothScene];
			super.popups = [];
		}
	}
}