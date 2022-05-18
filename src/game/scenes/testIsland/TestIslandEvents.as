package game.scenes.testIsland
{
	import game.data.island.IslandEvents;
	import game.scenes.testIsland.characterReplay.CharacterReplay;
	import game.scenes.testIsland.comicBookTest.ComicBookTest;
	import game.scenes.testIsland.drewTest.DrewTest;
	import game.scenes.testIsland.physicsTest.PhysicsTest;
	import game.scenes.testIsland.rickTest.RickTest;
	import game.scenes.testIsland.scottTest.ScottTest;
	import game.scenes.testIsland.zomCatapult.ZomCatapult;
	import game.scenes.testIsland.wheelOfFortune.WheelOfFortune;
	
	public class TestIslandEvents extends IslandEvents
	{
		public function TestIslandEvents()
		{
			super();
			super.scenes = [ComicBookTest, PhysicsTest, RickTest, DrewTest, ScottTest, ZomCatapult,CharacterReplay, WheelOfFortune];
		}
	}
}
