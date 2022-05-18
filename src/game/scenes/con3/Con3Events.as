package game.scenes.con3
{
	import game.data.island.IslandEvents;
	import game.scenes.con2.shared.cardGame.CardGame;
	import game.scenes.con2.shared.popups.CardDeck;
	import game.scenes.con3.adMixed1.AdMixed1;
	import game.scenes.con3.adMixed2.AdMixed2;
	import game.scenes.con3.adStreet.AdStreet;
	import game.scenes.con3.common.Common;
	import game.scenes.con3.ending.Ending;
	import game.scenes.con3.expo.EndingPopup;
	import game.scenes.con3.expo.Expo;
	import game.scenes.con3.hq.Hq;
	import game.scenes.con3.intro.Intro;
	import game.scenes.con3.menagerie.Menagerie;
	import game.scenes.con3.omegon.Omegon;
	import game.scenes.con3.portal.Portal;
	import game.scenes.con3.processing.Processing;
	import game.scenes.con3.shared.Comic178Popup;
	import game.scenes.con3.shared.Comic367Popup;
	import game.scenes.con3.throneRoom.ThroneRoom;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	public class Con3Events extends IslandEvents
	{
		public function Con3Events() 
		{
			super();
			super.scenes = [ AdMixed1, AdMixed2, AdStreet, Common, Ending, Expo, Hq, Menagerie, Portal, ThroneRoom, Processing, Omegon, Intro ];
			super.popups = [ CardGame, EndingPopup, Comic178Popup, Comic367Popup, CardDeck ];
			
			//listed parts that need to be removed on restart
			removeIslandParts.push(new<String>[CharUtils.ITEM, "bow"],
				new<String>[CharUtils.ITEM, "poptropicon_goldface_front"],
				new<String>[SkinUtils.ITEM2, "poptropicon_goldface_back"],
				new<String>[CharUtils.ITEM, "poptropicon_worldguy"],
				new<String>[CharUtils.ITEM, "poptropicon_saworldguy"]);
			
			
			this.island = "con3";
			// this.nextEpisodeEvents = Con4Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		//Events
		public const POWER_BOX_DESTROYED_:String 		= "power_box_destroyed_"; //1-3 in Menagerie, 4 in processing, 5-6 in ThroneRoom
		
		public const FUSE_DESTROYED_:String 			= "fuse_destroyed_"; //1-3 in processing, 4-5 in ThroneRoom
		
		public const GOLD_FACE_RESCUED:String			= "gold_face_rescued";
		public const ELF_ARCHER_RESCUED:String 			= "elf_archer_rescued";
		public const WORLD_GUY_RESCUED:String			= "world_guy_rescued";
		
		public const GOLD_FACE_SPOTTED:String			= "goldface_spotted";
		public const WORLD_GUY_SPOTTED:String			= "world_guy_spotted";
		public const ELF_ARCHER_SPOTTED:String			= "elf_archer_spotted";
		public const MACHINE_BROKEN:String				= "machine_broken";
		public const WIZARD_FREED:String				= "wizard_freed";
		
		public const GAUNTLETS_CHARGED:String			= "gauntlets_charged";
		
		public const STARTER_DECK:String				= "starter_deck";
		public const DEFEATED:String					= "defeated_";// expert, dealer, hippie, card2
		
		public const GOT_SODA:String					= "got_soda_"; // 1-3 for in scene soda placement
		public const HAS_SODA:String					= "has_soda_"; // 1-3 for item card	
		public const SODA_PLACED:String					= "soda_placed_";	// 1-3
		public const HIT_CRYSTAL:String					= "hit_crystal";
		public const PLAYER_THROUGH_PORTAL:String		= "player_through_portal";
		
		public const OMEGON_DEFEATED:String 			= "omegon_defeated";
		public const HQ_DESTROYED:String 				= "hq_destroyed";
		public const WEAPONS_POWERED_UP:String			= "weapons_powered_up";		
		
		public const FIRST_SODA:String					= "first_soda";
		public const INTRO_COMPLETE:String				= "intro_complete";
		
		public const PLAYED_INTRO_CUTSCENE:String		= "played_intro_cutscene";
		
		// temp events
		public const PLAY:String					= "play_";// expert, dealer, hippie, card2
		public const WON_CARD:String 				= "won_card";
		
		public const USE_GAUNTLETS:String			= "use_gauntlets";
		public const USE_SODA:String				= "use_soda";
		public const USE_ELECTRON:String			= "use_electron";
		public const START_INTRO:String				= "start_intro";
		
		// event groups
		public const ONE_SODA:String			= "one_soda";
		public const TWO_SODA:String			= "two_soda";
		public const THREE_SODA:String			= "three_soda";
		
		public const GOT_ALL_WEAPONS:String			= "got_all_weapons";
		
		public const CRYSTAL_READY_TO_BLOW:String	= "crystal_ready_to_blow";
		
		//Items
		public const CARD_DECK:String		= "card_deck";
		public const COMIC178:String 		= "comic178";
		public const COMIC367:String 		= "comic367";
		public const BOW:String 			= "bow";
		public const GAUNTLETS:String 		= "gauntlets";
		public const OLD_SHIELD:String 		= "old_shield";
		public const SHIELD:String 			= "shield";
		public const SODA:String 			= "soda"; // 1-3 soda cans
		public const MEDAL_CON3:String 		= "medal_con3";
	}
}