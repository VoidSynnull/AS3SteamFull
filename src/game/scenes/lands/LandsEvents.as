package game.scenes.lands
{
	import game.data.island.IslandEvents;
	import game.scenes.lands.adMixed1.AdMixed1;
	import game.scenes.lands.lab1.Lab1;
	import game.scenes.lands.lab2.Lab2;
	import game.scenes.lands.review.Review;
	import game.scenes.lands.shared.JournalPopup;
	import game.scenes.lands.shared.popups.worldManagementPopup.WorldManagementPopup;

	public class LandsEvents extends IslandEvents
	{
		public function LandsEvents()
		{
			super();
			super.scenes = [ Lab1, Lab2, Review, AdMixed1 ];
			super.popups = [ JournalPopup, WorldManagementPopup ];
			super.canReset = false;
		}
		
		//Events (permanent events that need to be saved to DB)
		public const SAID_START_DIALOG:String = "said_start_dialog";
		public const TOOK_SURVEY:String = "took_survey";
		public const SAW_INSTRUCTIONS:String = "saw_instructions";
		public const REACHED_TREASURE:String = "reached_treasure";
		public const GOT_REALMS_HINT:String = "got_realms_hint";
		public const GOT_SOME_POPTANIUM:String = "got_some_poptanium";
		public const SAW_MASTER_GHOST:String = "saw_master_ghost";
		public const FINISHED_MASTER_GHOST:String = "finished_master_ghost";
		public const SAW_INTRO_VIDEO:String = "saw_intro_video";
	}
}