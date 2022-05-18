package game.scenes.deepDive1
{
	import game.data.island.IslandEvents;
	import game.scenes.deepDive1.adMixed1.AdMixed1;
	import game.scenes.deepDive1.adMixed2.AdMixed2;
	import game.scenes.deepDive1.adStreet3.AdStreet3;
	import game.scenes.deepDive1.deepestOcean.DeepestOcean;
	import game.scenes.deepDive1.deepestOcean.VictoryPopup;
	import game.scenes.deepDive1.ledge.Ledge;
	import game.scenes.deepDive1.maze.Maze;
	import game.scenes.deepDive1.reef.Reef;
	import game.scenes.deepDive1.shared.FishPopup;
	import game.scenes.deepDive1.ship.IntroPopup;
	import game.scenes.deepDive1.ship.Ship;
	import game.scenes.deepDive1.shipUnderside.ShipUnderside;
	import game.scenes.deepDive2.DeepDive2Events;
	
	public class DeepDive1Events extends IslandEvents
	{
		//////////// Permanent Events
		public const DUMPED_WATER:String	 		= "dumped_water";
		public const DUMPED_INK:String 				= "dumped_ink";
		public const USED_BUCKET_FULL:String	 	= "used_bucket_full";
		public const USED_KEY:String	 			= "used_key";
		public const PLAYER_SAID_WHATS_GOING_ON:String 	= "player_said_whats_going_on";
		public const SAILOR_REACTED_TO_INK:String 	= "sailor_reacted_to_ink";
		public const SUB_OPENED:String	 			= "sub_opened";
		public const TUTORIAL_COMPLETE:String	 	= "tutorial_complete";
		
		public const ANGLER_CAPTURED:String			= "angler_captured";
		public const BARRELEYE_CAPTURED:String		= "barreleye_captured";
		public const CUTTLEFISH_CAPTURED:String 	= "cuttlefish_captured";
		public const SEADRAGON_CAPTURED:String		= "seadragon_captured";
		public const STONEFISH_CAPTURED:String		= "stonefish_captured";
		public const CAPTURED:String				= "_captured";
		
		public const ANGLER:String		= "anglerfish";
		public const BARRELEYE:String	= "barreleye";
		public const CUTTLEFISH:String	= "cuttlefish";
		public const SEADRAGON:String	= "seadragon";
		public const STONEFISH:String	= "stonefish";

		// group events not added to CMS
		public const CAPTURED_ALL_FISH:String 	= "captured_all_fish";
		
		
		//***************** Items
		public const BUCKET_EMPTY:String 		= "bucket_empty";
		public const BUCKET_FULL:String 		= "bucket_full";
		public const FISH_FILES:String 			= "fish_files";
		public const KEY:String 				= "key";
		public const MEDAL_DEEPDIVE1:String 	= "medal_atlantis1";
		public const SAW_HYDROMEDUSA:String 	= "saw_hydromedusa";
		
		public function DeepDive1Events()
		{
			super();
			super.scenes = [DeepestOcean,Ledge,Ship,ShipUnderside,Reef,Maze,AdMixed1,AdMixed2,AdStreet3];
			super.popups = [FishPopup,VictoryPopup,IntroPopup];
			
			this.island = "deepDive1";
			this.nextEpisodeEvents = DeepDive2Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
	}
}