package game.scenes.americanGirl
{
	import game.data.island.IslandEvents;
	import game.scenes.americanGirl.mainStreet.MainStreet;
	import game.scenes.americanGirl.mainStreetKira.MainStreetKira;
	
	public class AmericanGirlEvents extends IslandEvents
	{
		public function AmericanGirlEvents()
		{
			super();
			super.scenes = [MainStreet, MainStreetKira];
			super.popups = [];
		}	
	}
}


