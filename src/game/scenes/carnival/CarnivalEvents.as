package game.scenes.carnival
{
	import game.data.island.IslandEvents;
	import game.scenes.carnival.adStreet.AdStreet;
	import game.scenes.carnival.adStreet2.AdStreet2;
	import game.scenes.carnival.apothecary.Apothecary;
	import game.scenes.carnival.autoRepair.AutoRepair;
	import game.scenes.carnival.balloonPop.BalloonPop;
	import game.scenes.carnival.clearing.Clearing;
	import game.scenes.carnival.common.Common;
	import game.scenes.carnival.hauntedLab.HauntedLab;
	import game.scenes.carnival.mainStreet.MainStreet;
	import game.scenes.carnival.midwayDay.MidwayDay;
	import game.scenes.carnival.midwayEmpty.MidwayEmpty;
	import game.scenes.carnival.midwayEvening.MidwayEvening;
	import game.scenes.carnival.midwayNight.MidwayNight;
	import game.scenes.carnival.mirrorMaze.MirrorMaze;
	import game.scenes.carnival.ridesDay.RidesDay;
	import game.scenes.carnival.ridesEmpty.BonusQuestPopup;
	import game.scenes.carnival.ridesEmpty.RidesEmpty;
	import game.scenes.carnival.ridesEvening.RidesEvening;
	import game.scenes.carnival.ridesNight.RidesNight;
	import game.scenes.carnival.ringmastersTent.RingmastersTent;
	import game.scenes.carnival.rollerCoaster.RollerCoaster;
	import game.scenes.carnival.shared.UseBlackLightBulbGroup;
	import game.scenes.carnival.tunnelLove.TunnelLove;
	import game.scenes.carnival.woods.Woods;
	import game.scenes.carnival.woodsMaze.WoodsMaze;
	
	
	public class CarnivalEvents extends IslandEvents
	{
		public const SET_DAY:String 						 			= "set_day";
		public const SET_NIGHT:String 						 			= "set_night";
		public const SET_EVENING:String 						 		= "set_evening";
		public const SET_MORNING:String 						 		= "set_morning";
		
		
		public const ASKED_SUGAR:String									= "asked_sugar"; 
		public const ASKED_WATER:String									= "asked_water";
		public const SUGAR_GIVEN:String									= "gave_sugar";
		
		public const WATER_FIXED:String									= "water_fixed";
		
		public const NEED_WEIGHT:String									= "need_weight"; // player tasked to rig weight game by finding something heavy (found in apothecary)
		public const WON_WEIGHT:String									= "won_weight";
		public const GOT_FRY_OIL:String									= "got_fry_oil";
		public const GOT_BLUNTED_DART:String							= "got_blunted_dart";
		
		public const SPOKE_EDGAR_FORMULA:String							= "spoke_edgar_formula";
		public const ESCAPED_RINGMASTER_TENT:String						= "escaped_ringmaster_tent";
		
		public const SAW_DUCK_MONSTER:String							= "saw_duck_monster";
		
		public const SPOKE_WITH_FERRIS_WORKER:String					= "spoke_with_ferris_worker"; //had first conversation with ferris worker in RidesDay
		public const SPOKE_ABOUT_GREASE:String							= "spoke_about_grease"; //had conversation with ferris worker in RidesEvening about Grease
		public const REPLACED_LEVER:String								= "replaced_lever"; //replaced the ferris wheel lever in RidesDay
		public const USED_BALL:String									= "used_ball"; //used the ball on the strength game in RidesEvening
		public const USED_BLUNT_DART:String								= "used_blunt_dart";
		public const USED_BLACK_LIGHTBULB:String						= "used_black_lightbulb"; 
		
		public const WON_STRENGTH_GAME:String							= "won_strength_game"; //won the strength game in RidesEvening
		public const WON_BALLOON_POP:String								= "won_balloon_pop";
		public const USED_COTTON_CANDY:String							= "used_cotton_candy"; //used cotton candy in RidesNight
		public const ENSLAVED_RINGMASTER:String							= "enslaved_ringmaster"; //captured the ringmaster in mirrorMaze
		
		public const FERRIS_WHEEL_STOPPED:String						="ferris_wheel_stopped";

		public const BEAT_FERRIS_MONSTER:String							= "beat_ferris_monster";

		//these two events will get turned on and off in woods maze
		public const CLUES_FLAG1:String									="clues_flag1";
		public const CLUES_FLAG2:String									="clues_flag2";
		
		public const TALKED_TO_DUCK_GAME_WORKER:String					="talked_to_duck_game_worker";
		public const SPOKE_MARNIE_HOSE:String							="spoke_marnie_hose";
		
		// tunnel of love events
		public const TEENS_IN_TUNNEL:String 							="teens_in_tunnel"; //activated when the player gets the task from the tunnel operator
		public const TEENS_FRIGHTENED:String							="teens_frightened"; //when the player successfully scares off the teens
		public const FELL_IN_WATER:String 								="fell_in_water"; // after the player falls in the tunnel water for the first time
		
		// apothecary events
		public const SALT_GIVEN:String 									= "gave_salt"; // gave salt to drDan
		public const OPENED_VENT:String									= "opened_vent"; // player has removed newspapers and opened the vent
		
		public const EDGAR_LUNGE:String									= "edgar_lunge";
		
		// clearing scene monster events
		public const MONSTERS_UNLEASHED:String							="monsters_unleashed";
		
		// packed up carnival scene events
		public const REVEAL_CHICKEN_MAN:String							="reveal_chicken_man";
		
		//used for early access and bonus quest tracking
		public const STARTED_BONUS_QUEST:String							= "started_bonus_quest";
		public const BLOCKED_FROM_BONUS:String							= "blocked_from_bonus";
		public const STARTED_EA_DEMO:String								= "started_ea_demo"; //started playing the island as a non member during early access
		public const STARTED_EA:String									= "started_ea"; //got past the early access block as a member
		public const BLOCKED_FROM_EA:String								= "blocked_from_ea"; //blocked at early access block point as non member
		
		
		//additional events to be added
		public const DAN_SHOW_TAIL:String								= "dan_show_tail";
		public const INTRO_DAY_2:String									= "introduce_day_2";
		public const DAY_2_COMPLETE:String        						= "day_2_complete";
		public const DAN_RAN_AWAY:String								= "dan_ran_away";
		
		
		public const SPOKE_EDGAR_CARNIVAL:String							= "spoke_edgar_carnival";  //new - meet edgar on main street in day
		public const SPOKE_RINGMASTER_FORMULA:String						= "spoke_ringmaster_formula"; //new - ringmaster tells you about the formula
		public const EDGAR_RAN_TENT:String									= "edgar_ran_tent"; //new - edgar runs in tent after telling about ringmaster
		
		
		//**************************************************************************************
		// ITEMS - Following are constant references for items. These are NOT events.
		//**************************************************************************************
		
		public const SUPER_BOUNCY_BALL:String 				 			= "ball";
		public const BLACK_LIGHTBULB:String 						 	= "black_lightbulb";
		public const COTTON_CANDY:String 							 	= "cotton_candy";
		public const SOUVENIR_CUP:String 							 	= "cup_empty";
		public const FRY_OIL:String 								 	= "cup_oil";
		public const BLUNTED_DART:String 							 	= "dart_blunt";
		public const SHARPENED_DART:String 							 	= "dart_sharp";
		public const FRIED_DOUGH:String 							 	= "dough";
		public const FLASHLIGHT:String 								 	= "flashlight";
		public const FLASHLIGHT_BLACK:String 						 	= "flashlight_black";
		public const HUMAN_FLY_MASK:String 							 	= "fly_mask";
		public const HAMMER:String 									 	= "hammer";
		public const HOSE:String 							 			= "hose";
		public const LEVER:String 									 	= "lever";
		public const MEDAL_CARNIVAL:String 							 	= "medal_carnival";
		public const SECRET_MESSAGE:String 							 	= "secret_message";
		
		// apothecary items
		public const SUGAR:String 							 			= "sugar"; // player successfully makes sugar
		public const SUGAR_FORMULA:String 							 	= "sugar_formula"; // player receives sugar formula
		public const SALT:String 							 			= "salt"; // player successfully makes table salt
		public const SALT_FORMULA:String 							 	= "salt_formula"; // player recieves salt formula
		public const FORMULA:String 				 					= "hypnotize_formula"; // player receives the formula for sodiumThiopental
		public const SODIUM_THIOPENTAL:String 						 	= "hypnotize_powder"; // player successfully makes sodiumThiopental
		public const VIAL_OSMIUM:String 							 	= "vial"; // player receives a vial of osmium
		
		//bonus quest items
		public const CHEMICAL_X:String 							 		= "chemical_x";
		public const CHEMICAL_X_AWARD:String 							= "chemical_x_award";
		public const CHEMICAL_X_FORMULA:String 							= "chemical_x_formula";
		public const COLA:String 									 	= "cola";
		public const MUSHROOMS:String 								 	= "mushrooms";
		public const PICKLE_JUICE:String 							 	= "pickle_juice";
		
		
		public function CarnivalEvents()
		{
			super();
			super.scenes = [BalloonPop,AdStreet,AdStreet2,Apothecary,AutoRepair,Clearing,Common,HauntedLab,MainStreet,MidwayDay,MidwayEvening,MidwayNight,MidwayEmpty,MirrorMaze,RidesDay,RidesEvening,RidesNight,RingmastersTent,TunnelLove,Woods,WoodsMaze, RidesEmpty, RollerCoaster];
			var overlays:Array = [BonusQuestPopup];
			var specials:Array = [UseBlackLightBulbGroup];
		}
	}
}