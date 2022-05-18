package game.scenes.deepDive2
{
	import game.data.island.IslandEvents;
	import game.scenes.deepDive2.adMixed1.AdMixed1;
	import game.scenes.deepDive2.adMixed2.AdMixed2;
	import game.scenes.deepDive2.adStreet3.AdStreet3;
	import game.scenes.deepDive2.alienDoor.AlienDoor;
	import game.scenes.deepDive2.introCutscene.IntroCutscene;
	import game.scenes.deepDive2.medusaArea.MedusaArea;
	import game.scenes.deepDive2.pipeRoom.PipeRoom;
	import game.scenes.deepDive2.predatorArea.PredatorArea;
	import game.scenes.deepDive2.shared.PuzzleKeyCardView;
	import game.scenes.deepDive2.shared.popups.PuzzleKey1Popup;
	import game.scenes.deepDive2.shared.popups.PuzzleKey2Popup;
	import game.scenes.deepDive3.DeepDive3Events;
	
	public class DeepDive2Events extends IslandEvents
	{
		public function DeepDive2Events()
		{
			super();
			super.scenes = [AlienDoor, MedusaArea, PipeRoom, PredatorArea, IntroCutscene, AdMixed1, AdMixed2, AdStreet3];
			super.popups = [PuzzleKey1Popup, PuzzleKey2Popup];
			var cardViews:Array = [PuzzleKeyCardView];
			
			this.island = "deepDive2";
			this.nextEpisodeEvents = DeepDive3Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		//////////// Permanent Events
		
		public const COMPLETED_PIPES:String 		= "completed_pipes";
		public const PLAYED_INTRO:String			= "played_intro";
		public const ALIEN_WALL_BROKEN:String		= "alien_wall_broken";
		
		public const GOT_PUZZLE_PIECE_:String 		= "got_puzzle_piece_"; // 1-6
		public const PUZZLE_ASSEMBLED:String 		= "puzzle_assembled";
		public const USED_PUZZLE_KEY:String			= "used_puzzle_key";
		public const GOT_ALL_PUZZLE_PIECES:String 	= "got_all_puzzle_pieces";
		public const SOLVED_PUZZLE:String			= "solved_puzzle";
		
		public const SAW_BUTTON:String				= "saw_button";
		public const USED_PIPES:String				= "used_pipes";
		
		// predator area
		public const TRAPPED_SHARK:String			= "trapped_shark";
		
		// medusa area
		public const TRAPPED_MEDUSA:String			= "trapped_medusa";
		public const ENTERED_MEDUSA_AREA:String		= "entered_medusa_area";
		public const MEDUSA_OPENED_DOOR:String		= "medusa_opened_door";
		
		public const GLYPH_:String					= "glyph_" // 1-6
		
		
		// group events not added to CMS
		
		//***************** Items
		public const GLYPH_FILES:String				= "glyph_files";
		//public const GLYPH_:String					= "glyph_" // 1-6 (moved to events, since not saved as items in CMS -Jordan)
		public const PUZZLE_KEY:String 				= "puzzle_key";
		public const MEDAL:String					= "medal_atlantis2";
		
		
	}
}