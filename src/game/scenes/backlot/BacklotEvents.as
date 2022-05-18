package game.scenes.backlot
{
	import game.data.island.IslandEvents;
	import game.scenes.backlot.adGroundH29.AdGroundH29;
	import game.scenes.backlot.backlotCommon.BacklotCommon;
	import game.scenes.backlot.backlotTopDown.BacklotTopDown;
	import game.scenes.backlot.cityDestroy.CityDestroy;
	import game.scenes.backlot.coffeeShopLeft.CoffeeShopLeft;
	import game.scenes.backlot.coffeeShopRight.CoffeeShopRight;
	import game.scenes.backlot.digitalDreamScapes.DigitalDreamScapes;
	import game.scenes.backlot.extPostProduction.ExtPostProduction;
	import game.scenes.backlot.extSoundStage1.ExtSoundStage1;
	import game.scenes.backlot.extSoundStage2.ExtSoundStage2;
	import game.scenes.backlot.extSoundStage3.ExtSoundStage3;
	import game.scenes.backlot.extSoundStage4.ExtSoundStage4;
	import game.scenes.backlot.kirkTrailer.KirkTrailer;
	import game.scenes.backlot.kirkTrailerInterior.KirkTrailerInterior;
	import game.scenes.backlot.mainStreet.MainStreet;
	import game.scenes.backlot.postProduction.PostProduction;
	import game.scenes.backlot.screeningRoom.ScreeningRoom;
	import game.scenes.backlot.shared.popups.CarsonPrints;
	import game.scenes.backlot.shared.popups.FilmEditorPopup;
	import game.scenes.backlot.shared.popups.FoleyGamePopup;
	import game.scenes.backlot.shared.popups.MixCoffeePopup;
	import game.scenes.backlot.shared.popups.MovieScript;
	import game.scenes.backlot.shared.popups.TrainConstruction;
	import game.scenes.backlot.soundStage1.SoundStage1;
	import game.scenes.backlot.soundStage2.SoundStage2;
	import game.scenes.backlot.soundStage3.SoundStage3;
	import game.scenes.backlot.soundStage3Chase.SoundStage3Chase;
	import game.scenes.backlot.soundStage4.SoundStage4;
	import game.scenes.backlot.sunriseStreet.SunriseStreet;
	import game.scenes.backlot.talent.Talent;
	import game.scenes.shrink.shared.popups.MicroscopeMessage;
	
	
	public class BacklotEvents extends IslandEvents
	{
		public function BacklotEvents()
		{
			super();
			super.scenes =  [MainStreet, BacklotCommon, AdGroundH29, BacklotTopDown, CoffeeShopLeft, CoffeeShopRight, DigitalDreamScapes, Talent, CityDestroy, ExtPostProduction, ExtSoundStage1, ExtSoundStage2, ExtSoundStage3, ExtSoundStage4, KirkTrailer, KirkTrailerInterior, PostProduction, ScreeningRoom, SoundStage1, SoundStage2, SoundStage3, SoundStage3Chase, SoundStage4, SunriseStreet];
			super.popups = [CarsonPrints];
			var overlays:Array = [MovieScript, TrainConstruction, FilmEditorPopup, FoleyGamePopup, MixCoffeePopup, MicroscopeMessage];

		}
		
		//events
		public const ARRIVE_AT_BACKLOT:String	= "arrive_at_backlot";
		
		public const TALKED_TO_WILLY:String	    = "talked_to_willy";
		
		public const TALK_TO_HARVEY:String		= "talk_to_harvey";
		
		public const GIVE_CAMERA:String 		= "give_camera";
		public const SAW_SIDEWALK:String		= "saw_sidewalk";
		
		public const ENTERED_BACKLOT:String		= "entered_backlot";
		
		public const OPENED_BACKLOT_GATE:String	= "opened_backlot_gate";
		public const TRY_TO_ENTER_SS1:String    = "try_to_enter_ss1";
		public const MET_SOPHIA:String	   		= "met_sophia";
		public const DISRUPTED_KIRK:String		= "disrupted_kirk";
		
		public const CAN_USE_CART:String		= "can_use_cart";
		public const KIRK_CUP_FILLED:String		= "kirk_cup_filled";
		public const MADE_TO_ORDER:String		= "made_to_order";
		public const GAVE_KIRK_COFFEE:String	= "gave_kirk_coffee";
		public const KIRK_RETURNS_STAGE_1:String	= "kirk_returns_stage_1";
		public const CARSON_RETURNS_STAGE_1:String	= "carson_returns_stage_1";
		public const CAMERA_CHAT:String	   		= "camera_chat";
		public const CONRAD_LEFT:String	    	= "conrad_left";
		public const COMPLETE_STAGE_1:String	= "complete_stage1";
		
		public const GET_THE_SCRIPT:String 		= "get_the_script";
		public const PAGES_BLEW_AWAY:String	    = "pages_blew_away";
		public const SCREENPLAY_MISSING:String	= "screenplay_missing";
		public const GOT_PAGE_1:String	    	= "got_page_1";
		public const GOT_PAGE_2:String	    	= "got_page_2";
		public const GOT_PAGE_3:String	    	= "got_page_3";
		public const GOT_PAGE_4:String	    	= "got_page_4";
		public const ORDERED_PAGES:String	    = "ordered_pages";
		public const FOUND_GRACIE:String	    = "found_gracie";
		public const COMPLETE_STAGE_2:String	= "complete_stage2";
		
		public const MADE_TRAIN_PROP:String	    = "made_train_prop";
		public const FOUND_HERO:String			= "found_hero";
		public const FOUND_VILLAIN:String		= "found_villain";
		public const DID_WESTERN_FILM:String	= "did_western_film";
		public const COMPLETE_STAGE_3:String	= "complete_stage3";
		
		public const OFFERED_PART_STAGE_4:String	= "offered_part_stage_4";
		public const COMPLETE_STAGE_4:String	= "complete_stage4";
		
		public const COMPLETE_EDITING:String	= "complete_editing";
		public const COMPLETE_FOLEY:String	    = "complete_foley";
		
		public const SAW_MOVIE:String	    	= "saw_movie";
		public const SUGGEST_BONUS:String 		= "suggest_bonus";
		public const BLOCKED_FROM_BONUS:String  = "blocked_from_bonus";
		public const DAY_2_STARTED:String		= "day_2_started";
		public const DAY_2_COMPLETED:String	    = "day_2_completed";
		public const DAY_2_ESCAPED_LOT:String	= "day_2_escaped_lot";
			
		// group events (NOT COMPLETED MANUALLY, completed automatically based on combinations of standard events).
		public const COMPLETE_MOVIE_EDITING:String 	= "complete_movie_editing";
		public const READY_TO_ACT:String 			= "ready_to_act";
		public const COLLECTED_SCRIPT:String		= "found_pages";
		public const COMPLETED_ALL_STAGES:String	= "completed_all_stages";
		public const GET_KIRK_COFFEE:String 		= "get_kirk_coffee";
		public const DISPLAY_HARVEY:String			= "display_harvey";
		public const TOOK_PICTURE:String 			= "took_picture";
		public const TAKE_PICTURE:String 			= "take_picture";
		public const KIRK_IN_SOUND_STAGE_4:String  	= "kirk_in_sound_stage_4";
		
		// temporary events (not saved on server)
		public const YOUR_NOT_FAMOUS:String	    = "your_not_famous";
		public const LOOK_OVER_THERE:String	    = "look_over_there";
		public const MOVE_OVER_THERE:String	    = "move_over_there";
		public const LIGHT_CHANGE:String 		= "light_change";
		public const PHOTO_SHOOT:String 		= "photo_shoot";
		
		public const CRY:String					= "cry";
		
		public const POUR:String 				= "pour";
		public const POUR_COFFEE_LEFT:String    = "pour_coffee_left";
		public const POUR_COFFEE_RIGHT:String   = "pour_coffee_right";
		public const MACHINE_WORKING:String 	= "machine_working";
		public const PRESS_OPTION_BUTTON:String	= "press_option_button";
		public const PRESS_BUY_BUTTON:String 	= "press_buy_button";
		
		public const LOOK_AT_SIDEWALK:String 	= "look_at_sidewalk";
		public const LOOK_AWAY_FROM_SIDEWALK:String = "look_away_from_sidewalk";
		public const WELL_HE_WAS:String 		= "well_he_was";
		public const SPRING:String 				= "spring";
		
		public const ARF_1:String 				= "arf1";
		public const ARF_2:String 				= "arf2";
		
		public const KIRK_LEAVES:String 		= "kirk_leaves";
		public const KIRK_QUITS:String			= "kirk_quits";
		public const KIRK_THREW_CUP:String	    = "kirk_threw_cup";
		public const ACTIVATE_COSTUME:String 	= "activate_costume";
		public const IN_COSTUME:String 			= "in_costume";
		public const READY_TO_DESTROY_CITY:String = 	"ready_to_destroy_city";
		
		public const BLOW_AWAY_PAGES:String		= "blow_away_pages";
		
		public const CHANGE_INTO_STAR:String 	= "change_into_star";
		
		public const ORDERED_QUESTION:String	= "ordered_question";
		public const FINISHED_TALKING:String	= "finished_talking";
		public const DIALOG_OPTION:String 		= "dialog_option";
		public const CONTINUE_SCENE:String 		= "continue_scene";
		public const WRONG_LINE:String			= "wrong_line";
		public const WRONG_ACTION:String		= "wrong_action";
		public const ACTION:String				= "action";
		public const AGAIN:String				= "again";
		public const STOP:String				= "stop";
		public const PRINT:String				= "print";
		public const WRAP_IT_UP:String			= "wrap_it_up";
		public const EXCLAIM:String 			= "exclaim";
		public const START_RAIN:String 			= "start_rain";
		public const OFFER_COMPASS:String		= "offer_compass";
		public const OFFER_KISS:String			= "offer_kiss";
		public const OFFER_FLOWER:String		= "offer_flower";
		public const BALLOON_ARRIVES:String		= "balloon_arrives";
		public const ENTER_BALLOON:String 		= "enter_balloon";
		public const FLY_AWAY:String			= "fly_away";
		public const DARN_IT:String				= "darn_it";
		public const GOTCHA:String				= "gotcha";
		public const NOOOOOO:String				= "noooooo";
		
		public const THATS_A_TRAIN:String 		= "thats_a_train";
		public const PAINT_TRAIN:String 		= "paint_train";
		public const PAINTED_TRAIN:String 		= "painted_train";
		public const START_WESTERN_FILM:String  = "start_western_film";
		public const END_OF_THE_LINE:String  	= "end_of_the_line";
		
		public const MOVE_TO_EDITING:String 	= "move_to_editing";
		public const MOVE_TO_FOLEY:String 		= "move_to_foley";
		
		public const GO_SEE_MOVIE:String 		= "go_see_movie";
		
		public const NO_GOOD_MOVIES:String 		= "no_good_movies";
		public const NO_MOVIES:String 			= "no_movies";
		public const FREE_POPCORN:String 		= "free_popcorn";
		
		public const WATCH_NEXT_MOVIE:String	= "watch_next_movie";
		
		public const CRITICS_REVIEW:String		= "critics_review";
		public const TALK_TO_SOPHIA:String 		= "talk_to_sophia";
		
		public const BEGIN_CHASE:String 		= "begin_chase";
		
		// items
		public const CAMERA:String 				= "camera";
		public const FILM:String 				= "film";
		public const CAMERA_AND_FILM:String 	= "cameraAndFilm";
		public const SCREENPLAY_PAGES:String	= "screenplayPages";
		public const HEAD_SHOT:String 			= "headShot";
		public const WHITE_HAT:String 			= "whiteHat";
		public const BLACK_HAT:String 			= "blackHat";
		public const COFFEE_CUP_LEFT:String 	= "coffeeCupLeft";
		public const COFFEE_CUP_RIGHT:String 	= "coffeeCupRight";
		public const KIRK_COFFEE_CUP:String 	= "kirkCoffeeCup";
		public const REELS:String 				= "reels";
		public const MOVIE_CAMERA:String        = "movieCamera";
		public const MEDALLION:String 			= "medallion";
	}
}