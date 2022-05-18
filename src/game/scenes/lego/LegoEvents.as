package game.scenes.lego
{
	import game.scenes.lego.mainStreet.MainStreet;
	import game.data.island.IslandEvents;
	
	public class LegoEvents extends IslandEvents
	{
		public function LegoEvents()
		{
			super();
			super.scenes = [MainStreet];
			super.popups = [];
		}	
	}
}