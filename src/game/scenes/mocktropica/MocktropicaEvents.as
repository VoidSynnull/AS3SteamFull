package game.scenes.mocktropica
{
	import game.data.island.IslandEvents;
	import game.scenes.mocktropica.adStreet.AdStreet;
	import game.scenes.mocktropica.basement.Basement;
	import game.scenes.mocktropica.basement.DesignComputerPopup;
	import game.scenes.mocktropica.basement.DeveloperComputerPopup;
	import game.scenes.mocktropica.chasm.Chasm;
	import game.scenes.mocktropica.cheeseExterior.CheeseExterior;
	import game.scenes.mocktropica.cheeseInterior.CheeseInterior;
	import game.scenes.mocktropica.classroom.Classroom;
	import game.scenes.mocktropica.common.Common;
	import game.scenes.mocktropica.hangar.Hangar;
	import game.scenes.mocktropica.mainStreet.MainStreet;
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;
	import game.scenes.mocktropica.mockLoadingScreen.MockLoadingScreen;
	import game.scenes.mocktropica.mountain.Mountain;
	import game.scenes.mocktropica.mountain.popups.Mancala;
	import game.scenes.mocktropica.poptropicaHQ.PoptropicaHQ;
	import game.scenes.mocktropica.robotBossBattle.RobotBossBattle;
	import game.scenes.mocktropica.server.Server;
	import game.scenes.mocktropica.shared.popups.Script;
	import game.scenes.mocktropica.university.University;
	
	public class MocktropicaEvents extends IslandEvents
	{
		public const SPOKE_WITH_FOCUS_TESTER:String				= "spoke_with_focus_tester"; //first conversation in popHQ  - boy on street now has pet
		public const SPOKE_WITH_SAFETY_INSPECTOR:String			= "spoke_with_safety_inspector"; //first conversation in popHQ
		public const SPOKE_WITH_SAFETY_INSPECTOR_CHASM:String	= "spoke_with_safety_inspector_chasm"; // Second conversation in chasm
		public const SPOKE_WITH_SALES_MANAGER:String			= "spoke_with_sales_manager"; //first conversation in popHQ
		public const SPOKE_WITH_COST_CUTTER:String				= "spoke_with_cost_cutter"; //first conversation in popHQ
		public const BASEMENT_OPEN:String						= "basement_open"; //basement is open in popHQ
		public const USED_DEV_COMPUTER:String					= "used_dev_computer";
		public const USED_DES_COMPUTER:String					= "used_des_computer";
		public const BOUGHT_ADS:String							= "bought_ads";//all ad space has been bought up with coins
		public const ELIMINATED_SERVERS:String					= "eliminated_servers";//cost cutter eliminated most servers - triggers loading error scene
		public const GOT_BADGES:String							= "got_badges";//got employee id badges in basement
		public const CRITICAL_BUG_OCCURRED:String				= "critical_bug_occurred";//critical bug in basement
		public const INVENTORY_FIXED:String						= "inventory_fixed";//inventory fixed in basement
		public const TWO_DEEP_STARTED:String					= "two_deep_started";//cost cutter implemented two-deep program in basement
		public const SPOKE_WITH_SLEEPER:String					= "spoke_with_sleeper";//spoke with sleeping programmer in basement
		public const RESCUED_DESIGNER:String 					= "rescued_designer";
		public const POEM_BURNED:String 						= "poem_burned"; //ad has set the writer's poem on fire
		public const BOY_LEFT_MAIN_STREET_CHASM:String			= "boy_left_main_street_chasm";
		public const BOY_LEFT_MAIN_STREET_CHEESE:String			= "boy_left_main_street_cheese";
		public const BOY_LEFT_CHEESE_EXTERIOR:String			= "boy_left_cheese_exterior"; // boy leaves farmland scene after pets are multiplying
		public const NARF_WALL_COMPLETE:String					= "narf_wall_complete"; // the player has successfully made the wall of pets to walk across the chasm
		
		public const ACHIEVEMENT_ACHIEVER:String 				= "achievement_achiever";
		public const ACHIEVEMENT_DOORK:String 					= "achievement_doork";
		public const ACHIEVEMENT_CHEESE_BALL:String 			= "achievement_cheese_ball";
		public const ACHIEVEMENT_MIC_SQUEAK:String 				= "achievement_mic_squeak";
		public const ACHIEVEMENT_SCENE_STEALER:String 			= "achievement_scene_stealer";
		public const ACHIEVEMENT_JUST_FOCUS:String 				= "achievement_just_focus";
		public const ACHIEVEMENT_CURD_BURGLAR:String 			= "achievement_curd_burglar";
		public const ACHIEVEMENT_MANCALA_MASTER:String 			= "achievement_mancala_master";
		public const ACHIEVEMENT_COLLECTOR:String 				= "achievement_collector";
		public const ACHIEVEMENT_CLASSIC:String 				= "achievement_classic";
		public const ACHIEVEMENT_POPTROPICA_MASTER:String 		= "achievement_poptropica_master";
		public const ACHIEVEMENT_ULTIMATE_ACHIEVER:String 		= "achievement_ultimate_achiever";
		public const CURD_LANDED:String							= "curd_landed";
		
		public const ADVERTISEMENT_BOSS_1:String 			 	= "advertisement_boss_1";
		public const ADVERTISEMENT_BOSS_2:String 			 	= "advertisement_boss_2";
		public const ADVERTISEMENT_BOSS_3:String 			 	= "advertisement_boss_3";
		public const START_POPUP_BURN:String					= "start_popup_burn";
		
		public const REACHED_SUMMIT:String						= "reached_summit";
		public const INVENTORY_BROKEN:String 					= "inventory_broken";
		public const NEW_AD_UNIT:String 						= "new_ad_unit";
		public const SAW_INVENTORY_FIXED:String 				= "saw_inventory_fixed";
		
		public const IS_HAPPY:String 							= "is_happy"; //man on main street and guard at cheese factory are happy
		public const DEVELOPER_RETURNED:String 					= "developer_returned"; //all glitchiness is now gone from scenes
		public const MAINSTREET_FINISHED:String 				= "mainstreet_finished"; //main street is finished (painted in)
		public const MAINSTREET_REARRANGED:String 				= "mainstreet_rearranged";
		public const MOUNTAIN_FINISHED:String 				 	= "mountain_finished";
		public const SET_NIGHT:String 						 	= "set_night";
		public const SET_RAIN:String							= "set_rain";
		public const SERVER_REPAIRED:String						= "server_repaired";
		
		public const SPOKE_SALES_MANAGER_AD:String 				= "spoke_sales_manager_ad";
		public const WRITER_LEFT_CLASSROOM:String 				= "writer_left_classroom";		
		public const COMPLETED_POPUPAD2:String 					= "completed_popupad2";
		public const WRITER_ASKED_SODA:String 					= "writer_asked_soda";
		public const GAVE_WRITER_SODA:String 					= "gave_writer_soda";
		public const WRITER_ASKED_SCRIPT:String 				= "writer_asked_script";
		public const POEM_GIVEN:String 							= "poem_given";
		
		public const BOSS_ESCAPED:String						= "boss_escaped";
		public const DEFEATED_BOSS:String 						= "defeated_boss";
		public const BOSS_FIGHT_START:String 					= "boss_fight_start";
		public const SPOKE_WITH_MOUNTAIN_CLIMBER:String			= "spoke_with_mountain_climber";
		
		public const FOCUS_POP_COINS:String						= "focus_pop_coins";
		public const PAYED_COIN:String							= "payed_coin";
		public const FOCUS_COLLECTIBLES:String					= "focus_collectibles";
		public const SMASHED_CRATE:String						= "smashed_crate";
		public const FOCUS_HAS_CRATE:String						= "focus_has_crate";
		
		public const DONE_CLIMBING:String 					 	= "done_climbing";		
		public const MANCALA_STARTED:String					 	= "mancala_started";
		public const MANCALA_VICTORY:String						= "mancala_victory";
		public const CHIRP_CHAIR_LIFT:String 					= "chirp_chair_lift";
		
		public const STARTED_BONUS_QUEST:String					= "started_bonus_quest";
		public const BLOCKED_FROM_BONUS:String					= "blocked_from_bonus";
		public const STARTED_EA_DEMO:String						= "started_ea_demo"; //started playing the island as a non member during early access
		public const STARTED_EA:String							= "started_ea"; //got past the early access block as a member
		public const BLOCKED_FROM_EA:String						= "blocked_from_ea"; //blocked at early access block point as non member
		public const DEFEATED_MFB:String 						= "defeated_mfb";
		public const HERTZ_REJOINED:String						= "hertz_rejoined";
		
		////////////////////
		// group events (NOT COMPLETED MANUALLY, completed automatically based on combinations of standard events).
		public const MAINSTREET_UNFINISHED:String 				= "mainstreet_unfinished";
		public const MOUNTAIN_UNFINISHED:String 				= "mountain_unfinished";
		public const SET_DAY:String 							= "set_day";
		public const SET_CLEAR:String 							= "set_clear";
		public const SHOW_COIN_DEALER:String 					= "show_coin_dealer";
		public const STAFF_MEMBERS_RETURNED:String				= "staff_members_returned";
		public const USED_COMPUTERS:String						= "used_computers";
		public const START_POP_COINS:String						= "start_pop_coins";
		public const START_COLLECTIBLES:String 					= "start_collectibles";
		public const START_CRATE:String							= "start_crate";

		// items
		public const AXE:String 							 	= "axe";
		public const BUCKET_BOT_COSTUME:String					= "bucket_bot_costume";
		public const CAKE:String 								= "cake";
		public const COINS:String 								= "coins";
		public const CURDS:String								= "curds";
		public const DESIGNER_ID:String							= "designer_id";
		public const DEVELOPER_ID:String 						= "developer_id";
		public const HELMET:String								= "helmet";
		public const POP:String									= "pop";
		public const SCRIPT:String								= "script";
		public const WRITER_ID:String							= "writer_id";
		public const MEDAL_MOCKTROPICA:String					= "medal_mocktropica";

		
		public function MocktropicaEvents()
		{
			super();
			super.scenes = [Basement, Chasm, CheeseInterior, CheeseExterior, Classroom, Common, Hangar, MainStreet, Mountain, PoptropicaHQ, Server, University, MegaFightingBots, DesignComputerPopup, DeveloperComputerPopup, MockLoadingScreen, AdStreet, RobotBossBattle];
			var overlays:Array = [Mancala,Script];
			var specials:Array = [];
		}
		
	}
}