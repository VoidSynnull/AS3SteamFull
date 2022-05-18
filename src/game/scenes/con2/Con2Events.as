package game.scenes.con2
{
	import game.data.island.IslandEvents;
	import game.scenes.con2.adMixed.AdMixed;
	import game.scenes.con2.adMixed2.AdMixed2;
	import game.scenes.con2.adStreet3.AdStreet3;
	import game.scenes.con2.adStreet4.AdStreet4;
	import game.scenes.con2.common.Common;
	import game.scenes.con2.demo.Demo;
	import game.scenes.con2.exhibit.Exhibit;
	import game.scenes.con2.expo.Expo;
	import game.scenes.con2.hallways.Hallways;
	import game.scenes.con2.intro.Intro;
	import game.scenes.con2.lobby.Lobby;
	import game.scenes.con2.shared.popups.CardDeck;
	import game.scenes.con2.shared.popups.ComicBook;
	import game.scenes.con2.shared.popups.Phone;
	import game.scenes.con2.theater.Theater;
	import game.scenes.con3.Con3Events;
	import game.util.CharUtils;

	public class Con2Events extends IslandEvents
	{
		public function Con2Events()
		{
			super();
			super.scenes = [Common, Demo, Expo, Lobby, Theater, Exhibit, Hallways, Intro, AdMixed, AdMixed2, AdStreet3, AdStreet4];
			super.popups = [CardDeck, ComicBook, Phone];

			removeIslandParts.push(new<String>[CharUtils.FACIAL_PART, "poptropicon_omegon"]
				, new<String>[CharUtils.HAIR, "poptropicon_omegon"]
				, new<String>[CharUtils.MARKS_PART, "poptropicon_omegon2"]
				, new<String>[CharUtils.PACK, "poptropicon_omegon2"]
				, new<String>[CharUtils.OVERSHIRT_PART, "poptropicon_omegon2"]
				, new<String>[CharUtils.MARKS_PART, "poptropicon_elfarcher2"]
				, new<String>[CharUtils.HAIR, "poptropicon_elfarcher2"]
				, new<String>[CharUtils.PACK, "poptropicon_elfarcher2"]
				, new<String>[CharUtils.OVERSHIRT_PART, "poptropicon_elfarcher2"]);
			
			this.island = "con2";
			this.nextEpisodeEvents = Con3Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		// saved events
		public const PLAYED_INTRO:String			= "played_intro";
		public const SAW_START_POPUP:String			= "saw_start_popup";
		public const SAW_TUTORIAL:String			= "saw_tutorial";
		
		public const HALLWAY_CLEARED:String 		= "hallway_cleared";
		public const HALLWAY_STARTED:String 		= "hallway_started";
		public const SASHA_LEFT_EXPO:String 		= "sasha_left_expo";
		public const SASHA_LEFT_LOBBY:String 		= "sasha_left_lobby";
		public const PHONE_IN_BOX:String 			= "phone_in_box";
		public const STARTER_DECK:String			= "starter_deck";
		public const TIPPED_SODA_MACHINE:String 	= "tipped_soda_machine";
		public const DEFEATED:String				= "defeated_";// expert, dealer, hippie, card2
		public const PUT_ON_COSTUME:String			= "put_on_costume";
		
		public const ARCHER_COSPLAY_STARTED:String 	= "archer_cosplay_started";
		public const EXHIBIT_OPEN:String			= "exhibit_open";
		public const FASHION_NINJA_FELL:String 		= "fashion_ninja_fell";
		
		//omegon part photo events
		public const OMEGON_BODY_PHOTO:String 		= "omegon_body_photo";
		public const OMEGON_CAPE_PHOTO:String 		= "omegon_cape_photo";
		public const OMEGON_MASK_PHOTO:String 		= "omegon_mask_photo";
		
		// temp events
		public const PLAY:String					= "play_";// expert, dealer, hippie, card2
		public const WON_CARD:String 				= "won_card";

		// eventGroups
		public const COSPLAY_ON:String				= "cosplay_on";

		// items
		public const CARD_DECK:String				= "card_deck";
		public const COMIC:String					= "comic";
		public const CELL_PHONE:String				= "cell_phone";	
		public const OMEGON_COSTUME:String			= "omegon_costume";	
		public const SASHA_CARD:String				= "sasha_card";
		public const MEDAL_CON2:String				= "medal_con2";
		
		// collectable cards (not events just helpful constants)
		public const DIRT_CLAUDE:String				= "dirt_claude";
		public const FASHION_NINJA:String			= "fashion_ninja";
		public const PONY_GIRL:String				= "pony_girl";
		public const TEEN_ARACHNID:String			= "teen_arachnid";
		public const TRASH_COLLECTOR:String			= "trash_collector"
	}
}