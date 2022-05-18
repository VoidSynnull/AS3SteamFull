package game.scenes.start
{
	import game.data.island.IslandEvents;
	import game.scenes.start.login.Login;
	
	public class StartEvents extends IslandEvents
	{
		public function StartEvents()
		{
			super();
			scenes = [Login];
		}
	}
}