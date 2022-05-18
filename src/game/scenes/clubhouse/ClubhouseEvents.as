package game.scenes.clubhouse
{
	import game.data.island.IslandEvents;
	import game.scenes.clubhouse.castle.Castle;
	import game.scenes.clubhouse.clubhouse.Clubhouse;
	import game.scenes.clubhouse.diner.Diner;
	import game.scenes.clubhouse.fairytale.Fairytale;
	
	public class ClubhouseEvents extends IslandEvents
	{
		public function ClubhouseEvents()
		{
			super();
			super.scenes = [Clubhouse, Castle, Diner, Fairytale];			
			var overlays:Array = [];
			this.island = "clubhouse";
			
			this.canReset = false;
			this.accessible = true;
		}
	}
}