package game.scenes.map
{
	import game.data.island.IslandEvents;
	import game.scenes.map.map.Map;
	import game.scenes.map.map.groups.AdIslandPage;
	import game.scenes.map.map.groups.GenericPage;
	import game.scenes.map.map.groups.IslandPage;
	
	public class MapEvents extends IslandEvents
	{
		public function MapEvents()
		{
			super();
			scenes = [Map];
			
			//These are all dynamically created through XML specifically for the Map and need a place to live.
			var classes:Array = [
				IslandPage,
				GenericPage,
				AdIslandPage
			];
		}
	}
}