package game.scenes.tutorial
{
	import game.data.island.IslandEvents;
	import game.scenes.tutorial.tutorial.Tutorial;
	import game.scenes.tutorial.tutorial2.Tutorial2;
	
	public class TutorialEvents extends IslandEvents
	{
		public function TutorialEvents()
		{
			super();
			super.scenes = [Tutorial, Tutorial2];		
			var overlays:Array = [];
			this.island = "tutorial";
			
			this.canReset = true;
			this.accessible = true;
		}
		
		// PERMANENT EVENTS
		static public const FOUND_ALL_COINS:String	= "found_all_coins";
		
		// USER FIELDS
		public const SHARDS_FOUND:String 			= "shards_found";
	}
}