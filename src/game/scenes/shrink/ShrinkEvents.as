package game.scenes.shrink
{
	import game.data.island.IslandEvents;
	import game.scenes.shrink.adMixed.AdMixed;
	import game.scenes.shrink.adStreet2.AdStreet2;
	import game.scenes.shrink.adStreet3.AdStreet3;
	import game.scenes.shrink.adStreet4.AdStreet4;
	import game.scenes.shrink.apartmentNormal.ApartmentNormal;
	import game.scenes.shrink.avenueA.AvenueA;
	import game.scenes.shrink.bathroomNormal.BathroomNormal;
	import game.scenes.shrink.bathroomShrunk01.BathroomShrunk01;
	import game.scenes.shrink.bathroomShrunk02.BathroomShrunk02;
	import game.scenes.shrink.bedroomShrunk01.BedroomShrunk01;
	import game.scenes.shrink.bedroomShrunk01.Popups.DiaryPagePopup;
	import game.scenes.shrink.bedroomShrunk02.BedroomShrunk02;
	import game.scenes.shrink.carGame.CarGame;
	import game.scenes.shrink.common.Common;
	import game.scenes.shrink.kitchenShrunk01.KitchenShrunk01;
	import game.scenes.shrink.kitchenShrunk02.KitchenShrunk02;
	import game.scenes.shrink.livingRoomShrunk.LivingRoomShrunk;
	import game.scenes.shrink.mainStreet.MainStreet;
	import game.scenes.shrink.promo.Promo;
	import game.scenes.shrink.schoolCafetorium.SchoolCafetorium;
	import game.scenes.shrink.schoolInterior.SchoolInterior;
	import game.scenes.shrink.shared.popups.Jump;
	import game.scenes.shrink.shared.popups.MicroscopeMessage;
	import game.scenes.shrink.shared.popups.Ramp;
	import game.scenes.shrink.silvaOfficeShrunk01.SilvaOfficeShrunk01;
	import game.scenes.shrink.silvaOfficeShrunk02.SilvaOfficeShrunk02;
	import game.scenes.shrink.trashCan.TrashCan;
	
	public class ShrinkEvents extends IslandEvents
	{
		public function ShrinkEvents()
		{
			super();
			super.scenes = [AdMixed, AdStreet2, AdStreet3, AdStreet4, ApartmentNormal, AvenueA, BathroomNormal, BathroomShrunk01, BathroomShrunk02, BedroomShrunk01, BedroomShrunk02, CarGame, Common, KitchenShrunk01, KitchenShrunk02, LivingRoomShrunk, MainStreet, Promo, SchoolCafetorium, SchoolInterior, SilvaOfficeShrunk01, SilvaOfficeShrunk02, TrashCan];
			super.popups = [DiaryPagePopup, Jump, Ramp, MicroscopeMessage];
			
			this.earlyAccess = false;
		}

		// events
		
		public const CAPTURED_SILVA:String 			= "captured_silva";
		public const ENTERED_APARTMENT:String 		= "entered_apartment";
		public const CHASED_CAT:String 				= "chased_cat";
		public const CAT_IN_BATH:String 			= "cat_in_bath";
		public const GOT_ADDRESS:String 			= "got_address";
		public const LOOK_AWAY_MICROSCOPE:String 	= "look_away_microscope";
		public const FIND_CJ:String 				= "find_cj";
		public const SHRUNK:String 					= "shrunk";
		
		public const GOT_SHRUNKEN:String 			= "got_shrunken";
		public const FAN_ON:String 					= "fan_on";
		public const FAN_DOWN:String 				= "fan_down";
		public const TIPPED_TRASH:String			= "tipped_trash";
		public const VENT_ON:String					= "vent_on";
		
		public const BATHROOM_LIGHTS_OFF:String 	= "bathroom_lights_off";
		public const BATHROOM_VENTS_OFF:String 		= "bathroom_vents_off";
		
		public const CJ_AT_SCHOOL:String			= "cj_at_school";
		public const GOT_CJS_MESSAGE_01:String 		= "got_cjs_message_01";
		public const BACKED_UP_THUMB_DRIVE:String 	= "backed_up_thumb_drive";
		public const THUMB_DIRVE_IN_TOILET:String   = "thumb_drive_in_toilet";
		public const FLUSHED_THUMB_DRIVE:String 	= "flushed_thumb_drive";
		public const GOT_CJS_MESSAGE_02:String 		= "got_cjs_message_02";
		
		public const KNOCKED_DOWN_BOOK:String		= "knocked_down_book";
		public const LOGGED_ON:String				= "logged_on";
		public const DIARY_UNLOCKED:String			= "diary_unlocked";
		public const DIARY_RESTORED:String			= "diary_restored";
		public const PLACED_PAPER:String 			= "placed_paper";
		public const PAPER_ON_TABLE:String			= "paper_on_table";
		public const LEMON_PAPER_LIGHT:String		= "lemon_paper_light";
		public const DONT_KNOW_WHAT_TO_DO_WITH_PAPER_YET:String = "dont_know_what_to_do_with_paper_yet";
		public const LAMP_ON:String 				= "lamp_on";
		public const LAMP_DOWN:String				= "lamp_down";
		public const PAPER_MESSAGE_VISIBLE:String	= "paper_message_visible";
		
		public const CAR_HAS_BATTERY:String			= "car_has_battery";
		public const REMOTE_HAS_BATTERY:String		= "remote_has_battery";
		public const IN_CAR:String					= "in_car";
		public const TV_ON:String					= "tv_on";
		
		public const HOT_ON:String					= "hot_on";
		public const COLD_ON:String					= "cold_on";
		
		public const FAUCET_ON:String 				= "faucet_on";
		
		public const TIPPED_OIL:String 				= "tipped_oil";
		public const ROLLED_PIN:String				= "rolled_pin";
		public const GRAPE_DROPPED:String 			= "grape_dropped";
		public const HAS_GRAPE:String 				= "has_grape";
		
		public const IN_SILVAS_OFFICE:String		= "in_silvas_office";
		
		public const SHRUNK_SILVA:String			= "shrunk_silva";
		
		public const GIVE_MEDALLION:String 			= "give_medallion";
		
		//// NEW EVENTS
		
		public const INTRO_PLAYED:String			= "intro_played";
		public const WON_CAR_GAME:String 			= "won_car_game";
		
		// USERFIELDS
		
		public const CAR_FIELD:String				="car";
		public const GRAPE_FIELD:String				="grape";
		
		// temporary events (not saved on server)
		
		public const GET_CAT:String 				= "get_cat";
		public const SNOOPED_TOO_MUCH:String 		= "snooped_too_much";
		public const CHASE_PLAYER:String 			= "chase_player";
		public const LOOK_AWAY_TELESCOPE:String		= "look_away_telescope";
		
		//dialog constants
		public const NO_POINT:String 				= "no_point_";
		public const NEEDS:String 					= "needs_";
		
		// items
		public const MEDALLION:String 				= "medal_shrink";
		public const MORSE_CODE:String 				= "morse_code";
		public const THUMB_DRIVE:String 			= "thumb_drive";
		public const TORN_PAGE:String 				= "torn_page";
		public const BLANK_PAPER:String 			= "blank_paper";
		public const SCREW_DRIVER:String 			= "screw_driver";
		public const REMOTE_CONTROL:String 			= "remote_control";
		public const DIARY_KEY:String 				= "diary_key";
		public const BATTERY:String 				= "battery";
	}
}