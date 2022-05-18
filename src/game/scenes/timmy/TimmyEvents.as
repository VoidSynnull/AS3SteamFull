package game.scenes.timmy
{
	import game.data.island.IslandEvents;
	import game.data.specialAbility.islands.timmy.ThrowTreat;
	import game.scenes.timmy.adMixed1.AdMixed1;
	import game.scenes.timmy.adMixed2.AdMixed2;
	import game.scenes.timmy.adStreet3.AdStreet3;
	import game.scenes.timmy.alley.Alley;
	import game.scenes.timmy.alley.popup.BowlingPopup;
	import game.scenes.timmy.chase.Chase;
	import game.scenes.timmy.commonRoom.CommonRoom;
	import game.scenes.timmy.mainStreet.MainStreet;
	import game.scenes.timmy.mainStreetPromo.MainStreetPromo;
	import game.scenes.timmy.mansion.Mansion;
	import game.scenes.timmy.school.School;
	import game.scenes.timmy.shared.TotalImpactResponse;
	import game.scenes.timmy.shared.popups.DetectiveLogPopup;
	import game.scenes.timmy.skyScraper.SkyScraper;
	import game.scenes.timmy.store.Store;
	import game.scenes.timmy.timmysHouse.TimmysHouse;
	import game.scenes.timmy.timmysStreet.TimmysStreet;
	import game.scenes.timmy.zoo.Zoo;
	import game.util.CharUtils;
	
	public class TimmyEvents extends IslandEvents
	{
		public function TimmyEvents()
		{
			super();
			super.scenes = [AdMixed1, AdMixed2, AdStreet3, Alley, Chase, CommonRoom, MainStreet, MainStreetPromo, Mansion, School, SkyScraper, Store, TimmysHouse, TimmysStreet, Zoo];
			super.popups = [DetectiveLogPopup, BowlingPopup];
			var specials:Array = [TotalImpactResponse,ThrowTreat];
			this.island = "timmy";
			
			removeIslandParts.push(
			new<String>[CharUtils.ITEM, "crispy_rice_treats"],
			new<String>[CharUtils.ITEM, "bonbons"],
			new<String>[CharUtils.FACIAL_PART, "tf_garbanzo_man_head"]);
			
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		// events
		public const INTRO_COMPLETE:String 				=	"intro_complete";
		public const OPENED_OFFICE:String				=	"opened_office";
		public const UNLOCKED_CABINET:String			=	"unlocked_cabinet";
		public const GARBANZO_DROPPED:String			=	"garbanzo_dropped";
		public const KEY_EATEN:String					=	"key_eaten"; // roomba broken in house
		public const PLACED_LAZY_BEAR:String			=	"placed_lazy_bear";	
		public const WATCHED_LAZY_BEAR:String			=	"watched_lazy_bear"; // seen roomba video
		public const ATTEMPTED_BOWLING_GAME:String		=	"attempted_bowling_game";
		public const CRASHED_CAR:String 				=	"crashed_car";
		public const GOT_DETECTIVE_LOG_PAGE:String		=	"got_detective_log_page_"; // 2 - 9		
		public const TOTAL_IN_HOUSE:String				=	"total_in_house";
		public const TOTAL_FOLLOWING:String				=	"total_following";
		public const FREED_ROLLO:String 				=	"freed_rollo";
		public const FREED_TOTAL:String 				=	"freed_total";
		public const SAW_GARBAGE_TRUCK:String 			=	"saw_garbage_truck";
		public const SAW_TIMMY_ON_TOWER:String			=	"saw_timmy_on_tower";
		public const MOLLYS_ONTO_YOU:String 			=	"mollys_onto_you";
		public const RETURNED_CAT:String 				=	"returned_cat";
		public const SCARED_ROLLO:String 				=	"scared_rollo_";	// 1-3 for scaring his pants off
		public const NOSE_FELL_OFF:String				=	"nose_fell_off"; //nose fell off of elephant topiary
		public const CROCUS_MAD:String 					=	"crocus_mad";
		
		public const CHASE_COMPLETE:String				=	"chase_complete"; //garbage chase finished
		public const DROPPED_CAMERA:String 				=	"dropped_camera";
		public const KNOCKED_BOX_DOWN:String 			=	"knocked_box_down";
		public const SAW_TIMMY_MAINSTREET:String 		=	"saw_timmy_mainstreet";
		public const REMINISCE:String 					=	"reminisce";
		
		// group events
		public const GOT_ALL_LAZYBEAR_PARTS:String		=	"got_all_lazybear_parts";
		public const GOT_ALL_TOTALMOBILE_PARTS:String	=	"got_all_totalmobile_parts";

		// trigger caption for each new character met
		public const MET_TOTAL:String					=	"met_total";
		public const MET_TIMMY:String					=	"met_timmy";
		
		// temp events
		public const EXIT_CORRINA:String 				= 	"exit_corrina";
		public const HANDBOOK_PAGE:String 				=	"handbookPage";
		public const GET_DETECTIVE_LOG:String 			=	"get_detective_log";
		public const SUCH_RELIEF:String 				=	"such_relief";
		
		public const USE_TREATS_SCHOOL:String			=	"use_treats_school";
		public const USE_CAT:String 					=	"use_cat"
		public const USE_CHANGE:String					=	"use_change";
		public const USE_MONEY:String					=	"use_money";
		public const USE_SCREWDRIVER:String				=	"use_screwdriver";
		public const USE_GARDEN_SHEARS:String			=	"use_gardening_shears";
		public const USE_OFFICE_KEY:String				=	"use_office_key";
		public const USE_TREATS:String					=	"use_treats";
		public const USE_BEACH_BALL:String				=	"use_beach_ball";
		public const USE_POLE:String 					=	"use_pole";
		public const USE_SHOES:String 					=	"use_shoes";
		public const TRADE_SHOES:String 				=	"trade_shoes";
		public const USE_BONBONS:String					=	"use_bonbons";
		public const USE_CAMERA:String					=	"use_camera";
		public const USE_BOX:String						=	"use_box";
		public const USE_MARKER:String					=	"use_marker";
		public const USE_CAR_KEYS:String				=	"use_car_keys";
		public const TOTAL_PRESENT:String				= 	"total_present";
		public const CALL_TOTAL:String					=	"call_total";

		//items
		public const BEACH_BALL:String 					= 	"beach_ball";
		public const BONBONS:String						=	"bonbons";
		public const BOX:String 						=	"box";
		public const BUCKET:String 						=	"bucket";
		public const CAMERA:String 						=	"camera";
		public const CAR_KEY:String 					= 	"car_key";
		public const CAT:String 						=	"cat";
		public const CHANGE:String 						= 	"change";
		public const CHICKEN_NUGGETS:String				=	"chicken_nuggets";
		public const CRISPY_RICE_TREATS:String			=	"crispy_rice_treats";
		public const DETECTIVE_LOG:String				=	"detective_log";
		public const GARBANZO_MAN_HEAD:String 			=	"garbanzo_man_head";
		public const GARDENING_SHEARS:String 			= 	"gardening_shears";
		public const MEDAL_TIMMY:String 				=	"medal_timmy";
		public const MONEY:String 						= 	"money";
		public const OFFICE_KEY:String 					= 	"office_key";
		public const PERMANENT_MARKER:String 			=	"permanent_marker";
		public const POLE:String 						=	"pole";
		public const ROPE:String 						=	"rope";
		public const SCREWDRIVER:String 				=	"screwdriver";
		public const SHOES:String 						=	"shoes";
		public const WAGON:String 						=	"wagon";
	}
}