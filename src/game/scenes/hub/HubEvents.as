package game.scenes.hub
{
	import game.data.island.IslandEvents;
	import game.scenes.hub.avatarShop.AvatarShop;
	import game.scenes.hub.balloons.Balloons;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.scenes.hub.petBarn.PetBarn;
	import game.scenes.hub.profile.Profile;
	import game.scenes.hub.profile.popups.ChatPopup;
	import game.scenes.hub.profile.popups.MoodPopup;
	import game.scenes.hub.profile.popups.PhotoBoardPopup;
	import game.scenes.hub.profile.popups.ProfileMemberPopup;
	import game.scenes.hub.profile.popups.StickerWallPopup;
	import game.scenes.hub.race.Race;
	import game.scenes.hub.skydive.Skydive;
	import game.scenes.hub.starLink.StarLink;
	import game.scenes.hub.starcade.Starcade;
	import game.scenes.hub.store.Store;
	import game.scenes.hub.theater.Theater;
	import game.scenes.hub.town.Town;

	
	public class HubEvents extends IslandEvents
	{
		public function HubEvents()
		{
			super();
			super.scenes = [AvatarShop, PetBarn, Town, Theater, Starcade, StarLink, Skydive, Balloons, Race, ChooseGame, Profile, ChatPopup, MoodPopup, PhotoBoardPopup, StickerWallPopup, ProfileMemberPopup, Store];			
			var overlays:Array = [];
			this.island = "hub";
			
			this.canReset = false;
			this.accessible = true;
		}
		
		// PERMANENT EVENTS
		public const TALKED_TO_TAILOR:String 		= "talked_to_tailor";
		public const TALKED_TO_SHOP_OWNER:String 	= "talked_to_shop_owner";
		public const TALKED_TO_DJ:String 			= "talked_to_dj";
		public const GOGGLES_COSTUMIZED:String		= "goggles_costumized";
		public const INTRO_STARTED:String			= "intro_started";
		public const TUTORIAL_STARTED:String		= "tutorial_started";
		public const FOUND_ALL_SHARDS:String		= "found_all_shards";
		//public const TALKED_TO_REPORTER:String 		= "talked_to_reporter"; //Not currently used.
		//public const WRENCH_RETURNED:String			= "wrench_returned"; //Not currently saving this. It's only used in XML to trigger Crash's default dialog.
		
		public const MORE_ADVENTURE:String			= "more_adventure"; // said yes to adventurer
		public const NO_TO_ADVENTURE:String			= "no_to_adventure"; // said no to adventurer
		public const SHOW_MAP_TUTORIAL:String		= "show_map_tutorial";
		public const TAKE_TO_ISLAND:String			= "take_to_island";
		public const NO_TO_ISLAND:String			= "no_to_island";
		public const SPOKE_WITH_ADVENTURER:String	= "spoke_with_adventurer";
		
		public const AGREED_RACE:String				= "agreed_race";
		public const AGREED_RECORD_RACE:String		= "agreed_record_race";
		public const AGREED_MORE_RACE:String		= "agreed_more_race";
		
		public const DECLINED_RACE:String			= "declined_race";
		public const DECLINED_RECORD_RACE:String	= "declined_record_race";
		public const DECLINED_MORE_RACE:String		= "declined_more_race";
		
		// TEMP EVENT
		public const SHOW_BLIMP:String				= "show_blimp";
		public const SHOW_ARCADE:String				= "show_arcade";
		public const SHOW_SHOP:String				= "show_shop";
		public const ISLAND_COMPETED:String			= "island_completed";
		public const SHARDS_RETURNED:String			= "shards_returned";
		public const PILOT_LEAVES:String			= "pilot_leaves";
		
		public const SPOKE_TO_AMELIA:String			= "spoke_to_amelia";
		
		// new added for FTUE
		public const SHOW_FTUE_ENDING:String		= "show_ftue_ending";
		public const TUTORIAL_COMPLETED:String		= "ftue_tutorial_completed";
		public const START_RACE:String				= "start_race";
		public const EXPLORE_MAP:String				= "explore_map";
		public const EXPLORE_HOME_ISLAND:String     = "explore_home_island";
		
		// USER FIELDS
		public const SHARDS_FOUND:String 			= "shards_found";
		
		//Items
		public const WRENCH:String 					= "wrench";
		public const MEDAL_SHARDS:String 			= "medalShards";
		public const MEDAL:String 					= "medalHub";
	}
}