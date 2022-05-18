package game.scenes.prison
{
	import game.data.island.IslandEvents;
	import game.scenes.prison.adMixed2.AdMixed2;
	import game.scenes.prison.adStreet1.AdStreet1;
	import game.scenes.prison.adStreet3.AdStreet3;
	import game.scenes.prison.cellBlock.CellBlock;
	import game.scenes.prison.common.Common;
	import game.scenes.prison.cellBlock.popups.VentChiselPopup;
	import game.scenes.prison.escape.Escape;
	import game.scenes.prison.hill.Hill;
	import game.scenes.prison.mainStreet.MainStreet;
	import game.scenes.prison.messHall.MessHall;
	import game.scenes.prison.messHall.popups.PotatoSculptPopup;
	import game.scenes.prison.metalShop.MetalShop;
	import game.scenes.prison.metalShop.popups.LicensePlateGame;
	import game.scenes.prison.metalShop.popups.LicensePlateGuide;
	import game.scenes.prison.prisonPromo.PrisonPromo;
	import game.scenes.prison.roof1.Roof1;
	import game.scenes.prison.roof2.Roof2;
	import game.scenes.prison.roof3.Roof3;
	import game.scenes.prison.shared.GumContentView;
	import game.scenes.prison.shared.popups.PrisonFilesPopup;
	import game.scenes.prison.tower.Tower;
	import game.scenes.prison.tower.popups.HeadshotsPopup;
	import game.scenes.prison.tower.popups.NewspaperPopup;
	import game.scenes.prison.tower.popups.PaintingPopup;
	import game.scenes.prison.tower.popups.SafePopup;
	import game.scenes.prison.yard.Yard;
	
	public class PrisonEvents extends IslandEvents
	{
		public function PrisonEvents()
		{
			super();
			super.scenes = [AdMixed2, AdStreet1, AdStreet3, Common, MainStreet, Hill, Tower, CellBlock, Yard, MetalShop, MessHall, Roof1, Roof2, Roof3, PrisonPromo, Escape];
			super.popups = [VentChiselPopup,LicensePlateGame,LicensePlateGuide,PaintingPopup,NewspaperPopup,SafePopup,PrisonFilesPopup,PotatoSculptPopup,HeadshotsPopup];
			var cardViews:Array = [GumContentView];
			var specials:Array = [];
			this.island = "prison";
			
			this.accessible = true;
			this.earlyAccess = true;
		}
		
		//events
		public const SPOKE_WITH_LADY:String				= 	"spoke_with_lady";			//spoke with lady on main street
		public const SPOKE_WITH_SKATER:String			= 	"spoke_with_skater";		//spoke with skater on main street
		public const SPOKE_WITH_MUSCLES:String			= 	"spoke_with_muscles";		//spoke with muscle man on main street
		public const SAW_BANDIT:String					= 	"saw_bandit";				//saw bandit on main street
		public const CAPTURED_PLAYER:String				=	"captured_player";			//captured player on hill
		public const SAW_DISCREPANCY:String				=	"saw_discrepancy";			//saw discrepancy in paintin - tower
		public const BANDIT_CAPTURED:String				=	"bandit_captured";			//captured bandit in tower
	
		public const PLAYER_ESCAPED:String				=	"player_escaped";			//player escaped prison (Not currently set anywhere but should be when player is sent back to Hill)
		public const SAW_LES_SAL:String					=	"saw_les_sal";				//saw Les and Sal after the escape in Hill	
		
		public const SHOWN_CELL_INTRO:String			= 	"shown_cell_intro";
		public const CELL_GRATE_OPEN:String				= 	"cell_grate_open";
		
		public const YARD_INTRO_SHOWN:String			= 	"yard_intro_shown";
		public const FLORIAN_SIZE:String				= 	"florian_size";
		public const EGGS_COLLECTED:String				= 	"eggs_collected_"; 			// 1-3 eggs collected
		public const NEED_EGGS:String					=	"need_eggs";
		public const TAKE_AWAY_PAINT:String				= 	"take_away_paint";
		
		public const METAL_DAY_1_COMPLETE:String 		=	"metal_day_1_complete"; 	
		public const SMUGGLED_DRILL_BIT:String			=	"smuggled_drill_bit"; 		// keeps drill from being taken after bait and switch
		public const BORROWED_TOOL:String				=	"borrowed_tool";			// initial drill bit conversation only happens once
		public const SHOP_STEAM_REDIRECTED:String		=	"shop_steam_redirected";
		
		// change output location of potatos in vent
		public const MESS_VENT_OPEN_1:String			=	"mess_vent_open_1";
		public const MESS_VENT_OPEN_2:String			=	"mess_vent_open_2";
		public const MESS_VENT_OPEN_3:String			=	"mess_vent_open_3";			// potatos will land on florian, when fan used
		
		public const MESS_DAY_1_COMPLETE:String 		=	"mess_day_1_complete";
		public const SPOON_DISTRACTION:String			=	"spoon_distraction"; 		// distraction to get 2 spoons
		public const SMUGGLED_SPOON:String				=	"smuggled_spoon"; 			// keeps spoon from being taken after distraction
		public const RUINED_POTATOS:String				=	"ruined_potatos"; 			// created hard block of potatos
		public const USED_PLASTER:String				=	"used_plaster"; 				
		public const STARTED_FOOD_FIGHT:String			=	"started_food_fight"; 		// hit florian, start food fight
		public const ENDED_FOOD_FIGHT:String			=	"ended_food_fight"; 		
		public const DRILLED_PLATE:String				=	"drilled_plate";			// ready to escape the next night
		public const ESCAPED_BIG_TUNA:String			= 	"escaped_big_tuna";
		public const COMBINED_DRILL_BIT:String			=	"combined_drill_bit"; 		// assembled drill + mixer 

		public const TRICKED_GUARD_FIRST:String			= 	"tricked_guard_first";

		// Doesn't need to be saved
		public const PAROLE_PASSED:String				= 	"parole_passed_"			// add character name at end, patches, nostrand, marion
		public const PAROLE_NEXT_DAY:String				= 	"parole_next_day_";
			
		//temp events
		public const USE_GUM:String						=	"use_gum";
		
		//event groups
		public const PLANTED_SEEDS:String				= "planted_seeds";
		public const GOT_ALL_EGGS:String				= "got_all_eggs";
		public const TRADED_EGGS:String					= "traded_eggs";
		
		//user fields
		public const GUM_FIELD:String 					= "prisonGum";
		public const DAYS_IN_PRISON_FIELD:String 		= "prisonDaysInPrison";
		public const SUNFLOWER_FIELD:String 			= "prisonSunflower";
		public const VENT_CHISELS:String				= "prisonChisels";
		public const VENTS_FIELD_METAL:String			= "prisonVentsMetal";
		public const VENTS_FIELD_MESS:String			= "prisonVentsMess";
		public const LICENSE_PLATES_MADE_FIELD:String 	= "license_plates_made_field";
		
		//items
		public const CUP_OF_PLASTER:String			=	"cup_of_plaster";
		public const CUP_OF_WATER:String			= 	"cup_of_water";
		public const DRILL_BIT:String 				=	"drill_bit";
		public const DUMMY_HEAD:String				=	"dummy_head";
		public const EGGS:String 					=	"eggs";
		public const MEDAL_PRISON:String 			=	"medal_prison";	
		public const METAL_CUP:String 				=	"metal_cup";
		public const MIXER:String					=	"mixer";
		public const PAINTING:String				=	"painting";
		public const PAINTED_DUMMY_HEAD:String		=	"painted_dummy_head";
		public const PAINTED_PASTA:String 			=	"painted_pasta"; 				// made this item, for consistancy
		public const PRISON_FILES:String			= 	"prison_files";
		public const SHARPENED_SPOON:String 		=	"sharpened_spoon";
		public const SPOON:String 					=	"spoon";						// normal spoon gets smuggled out
		public const CAFE_SPOON:String 				=	"cafe_spoon";					// spoon that never leaves the mess hall
		public const STICK_OF_GUM:String			=	"stick_of_gum";					// needs to reference user field and display gum count
		public const SUNFLOWER:String 				=	"sunflower";
		public const SUNFLOWER_SEEDS:String 		=	"sunflower_seeds";
		public const UNCOOKED_PASTA:String			=	"uncooked_pasta";
		
		// promo items
		public const BIRD_FOLLOWER:String			=	"bird_follower";
		public const DOG_FOLLOWER:String			=	"dog_follower";
		
		// promo events
		public const PROMO_GUARD_LEFT:String		=	"promo_guard_left";
		
		// Days for the parole hearings
		public const DAYS_FOR_PATCHES:Number		=	10;
		public const DAYS_FOR_NOSTRAND:Number		=	20;
		public const DAYS_FOR_MARION:Number			= 	15;
	}
}
