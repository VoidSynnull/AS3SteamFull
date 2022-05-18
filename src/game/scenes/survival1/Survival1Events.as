package game.scenes.survival1
{
	import game.data.island.IslandEvents;
	import game.scenes.survival1.adMixed1.AdMixed1;
	import game.scenes.survival1.adMixed2.AdMixed2;
	import game.scenes.survival1.adStreet3.AdStreet3;
	import game.scenes.survival1.cave.Cave;
	import game.scenes.survival1.cliffside.Cliffside;
	import game.scenes.survival1.crashLanding.CrashLanding;
	import game.scenes.survival1.hillside.Hillside;
	import game.scenes.survival1.knollside.Knollside;
	import game.scenes.survival1.morningAfter.MorningAfter;
	import game.scenes.survival1.shared.popups.FirePopup;
	import game.scenes.survival1.shared.popups.FreezePopup;
	import game.scenes.survival1.shared.popups.VictoryPopup;
	import game.scenes.survival1.woods.Woods;
	import game.scenes.survival2.Survival2Events;
	import game.util.CharUtils;
	

	public class Survival1Events extends IslandEvents
	{
		public function Survival1Events()
		{
			super();
			scenes = [AdMixed1, AdMixed2, AdStreet3, Cave, Cliffside, CrashLanding, Hillside, Knollside, MorningAfter, Woods];
			popups = [ FirePopup, FreezePopup, VictoryPopup ];
			removeIslandParts.push(new<String>[CharUtils.ITEM, "ax_handle", null], new<String>[CharUtils.HAND_BACK, "mitten_back", "hand"], new<String>[CharUtils.HAND_FRONT, "mitten_front", "hand"]);
			
			this.island = "survival1";
			this.nextEpisodeEvents = Survival2Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		//Events (permanent events that need to be saved to DB)
		public const BOULDER_IN_POSITION:String = "boulder_in_position";	// no wind from right -- boulder in final position
		public const CRASH_LANDING:String 		= "crash_landing";
		public const CAVE_OPEN:String 			= "cave_open";  		// boulder in first position
		public const BEGIN_LANDING:String		= "beginning_landing";
		public const BRANCH_BROKEN:String		= "branch_broken";
		public const PULLED_CORD:String 		= "pulled_cord";
		public const PUSHED_STUMP:String		= "pushed_stump";
//		public const HAS_PAGE_:String 			= "has_page_"; // 1 through 6 pages
		public const DROPPED_STRIKER:String		= "dropped_striker";
		public const RETRIEVED_STRIKER:String	= "retrieved_striker";
		public const WEARING_MITTENS:String		= "wearing_mittens";
//		public const FOUND_HANDBOOK_BINDING:String 	= "found_handbook_binding";
		public const FIRE_COMPLETED:String		= "fire_completed";
		public const FROZE:String 				= "froze";
		
		//I've added the above events to the CMS. Add any new ones below here so I can find them. -Jordan
		
		
		// group events (NOT COMPLETED MANUALLY, completed automatically based on combinations of standard events).
		public const FOUND_ONE_PAGE:String 		= "found_one_page";
		public const FOUND_TWO_PAGES:String 	= "found_two_pages";
		
		//Temporary / Triggered Events
		public const FIRE_COLD_HANDS:String		= "fire_cold_hands";
		public const FIRE_TOO_WINDY:String		= "fire_too_windy";
		public const FIRE_TOO_WET:String		= "fire_too_wet";
		public const FIRE_DIED:String			= "fire_died";
		public const FIRE_BUILT_WRONG:String	= "fire_built_wrong";
		public const FIRE_AWAKENED_BEAR:String	= "fire_awakened_bear";
		public const IN_FIRE_ZONE:String 		= "in_fire_zone";    // no wind from left
		
		// USER FIELDS
		public const TEMPERATURE_FIELD:String 	='temperature'
		
		
		//********************************************************************************************
		//Items	
		public const AX_HANDLE:String 			= "axHandle";
		public const DRY_KINDLING:String 		= "dryKindling";
		public const FLINT:String				= "flint";
		public const HANDBOOK_PAGE_:String 		= "handbookPage";    // 1 -6 pages
		public const LOGS:String				= "logs";
		public const MITTENS:String				= "mittens";
		public const NEST:String				= "nest";
		public const STRIKER:String				= "striker";
		public const SURVIVAL_HANDBOOK:String 	= "handbook";		// survival book binding
		public const WET_KINDLING:String	 	= "wetKindling";
		
		
		
		// new item tracking for jordan - needed two handbook page items on some scenes
		public const HANDBOOK_PAGES:String		= "handbookPages";  // used for the item that launches the popup
		public const SURVIVAL_MEDAL:String 		= "medal_survival1"; 
	}
}