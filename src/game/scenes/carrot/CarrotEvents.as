package game.scenes.carrot
{
	import game.data.island.IslandEvents;
	import game.scenes.carrot.adGroundH3.AdGroundH3;
	import game.scenes.carrot.adGroundH3R.AdGroundH3R;
	import game.scenes.carrot.common.Common;
	import game.scenes.carrot.computer.Computer;
	import game.scenes.carrot.diner.Diner;
	import game.scenes.carrot.engine.Engine;
	import game.scenes.carrot.factory.Factory;
	import game.scenes.carrot.farm.Farm;
	import game.scenes.carrot.farmHouse.FarmHouse;
	import game.scenes.carrot.freezer.Freezer;
	import game.scenes.carrot.freezer.SecurityConsole;
	import game.scenes.carrot.loading.Loading;
	import game.scenes.carrot.mainStreet.MainStreet;
	import game.scenes.carrot.processing.Processing;
	import game.scenes.carrot.robot.Robot;
	import game.scenes.carrot.sewer.Sewer;
	import game.scenes.carrot.shared.VentMap;
	import game.scenes.carrot.shared.rabbotEars.RabbotEars;
	import game.scenes.carrot.smelter.Smelter;
	import game.scenes.carrot.surplus.Surplus;
	import game.scenes.carrot.vent.Vent;
	
	public class CarrotEvents extends IslandEvents
	{
		public function CarrotEvents()
		{
			super();
			super.scenes = [AdGroundH3,AdGroundH3R,Computer,Diner,Engine,Factory,Farm,FarmHouse,Freezer,Loading,game.scenes.carrot.mainStreet.MainStreet,Processing,Robot,Sewer,Smelter,Surplus,Vent,game.scenes.carrot.common.Common];
			super.popups = [VentMap, Robot, SecurityConsole, RabbotEars, Computer];
			
		}
		// events
		public const ALL_DRONES_FREE:String		= "all_drones_free";
		public const CAT_RETURNED:String 		= "cat_returned";
		public const DESTROYED_RABBOT:String 	= "destroyed_rabbot";
		public const DRONE_FREED_:String 		= "drone_freed_";		// add number to end of string (total of 4 drones)
		public const ENGINE_ON:String 			= "engine_on";
		public const MILK_GIVEN:String 			= "milk_given";
		public const SECURITY_DISABLED:String 	= "security_disabled";
		public const SEWER_OPENED:String 		= "sewer_opened";	
		public static const CARROTBETA_STARTED:String = "beta_started";
				
		// group events (NOT COMPLETED MANUALLY, completed automatically based on combinations of standard events).
		public const CAT_FOLLOWING:String 		= "cat_following";
		
		// temporary events (not saved on server)
		
		public const AWARD_MEDAL:String 		= "award_medal";
		public const CAT_HIDING:String 			= "cat_hiding";
		public const HOLY_CRAP_A_BETA:String	= "holy_crap_a_beta";
		public const DRONE_CONGRATS:String 		= "carrot_drone_congrats";
		public const DRHARE_TALK_TO:String 		= "carrot_drhare_talk_to";
		public const MILK_PLACED:String 		= "milk_placed";
		public const WIRE_CUT_:String 			= "wire_cut_";			// add number to end of string (total of 3 wires)
		public const GRATE_OPEN:String			= "grate_open";
		public const GRATE_OPENNING:String 		= "grate_openning";
		public const BELL_RING:String 			= "bell_ring";
		public const BUCKET_EMPTY_:String 		= "bucket_empty_";		// add number to end of string (total of 2 buckets)
		public const BUCKET_FULL_:String		= "bucket_full_";		// add number to end of string (total of 2 buckets)
		public const CAM_ACTIVE:String 			= "cam_active";
		public const CARROT_DISAPPEAR_:String	= "carrot_disappear_";	// add number to end of string (total of 2 carrots)
		public const CAT_MEOW:String			= "cat_meow";
		public const CAT_PURR:String			= "cat_purr";
		public const CAT_DRINK:String			= "cat_drink";
		public const CONVEYOR_START:String		= "conveyor_start";
		public const CONVEYOR_STOP:String		= "conveyor_stop";
		public const CRATE_DROP_:String			= "crate_drop_";		// add number to end of string (total of 3 crates)
		public const DR_HARE_TALK:String	 	= "dr_hare_talk";
		public const DRONE_DENIAL:String 		= "drone_denial";
		public const DRONE_FREE:String 			= "drone_free";
		public const DRONE_TRICKED_:String		= "drone_tricked_";  	// add number to end of string (total of 4 drones)
		public const DROP_MOLTEN_:String		= "drop_molten_";		// add number to end of string (total of 2 squirters)
		public const ENTER_PRESS:String		 	= "enter_press";
		public const FELL_IN_TRAP:String		= "fell_in_trap";
		public const LEVER_CORRECT:String 		= "lever_correct"
		public const LEVER_MOVE:String			= "lever_move";
		public const KEYBOARD_PRESS_:String 	= "keyboard_press_";	// add number to end of string (total of 3 sounds)
		public const MOVE_LEFT_HAND:String 		= "move_left_hand";
		public const MOVE_RIGHT_HAND:String		= "move_right_hand";
		public const PLACE_BOWL:String			= "place_bowl";
		public const PLATFORM_OPEN_:String		= "platform_open_"; 	// add number to end of string (total of 4 traps)
		public const PLATFORM_CLOSE_:String		= "platform_close_"; 	// add number to end of string (total of 4 traps)	
		public const PLAYER_CAUGHT:String		= "player_caught";
		public const PLAYER_SURRENDER:String	= "player_surrender";
		public const POUR_DRINK_:String			= "pour_drink_";		// add number to end of string (total of 5 handles)
		public const PRINTER_REACHED:String 	= "reached_printer";
		public const PRINTING_PAPER:String		= "printing_paper";	
		public const RABBOT_HIT:String 			= "rabbot_hit";
		public const RABBOT_LAUNCH:String		= "rabbot_launch";
		public const RAISE_PLATFORM:String		= "raise_platform";
		public const RAT_SQUEEK:String			= "rat_squeek";
		public const SECURITY_OPEN_CLOSE:String	= "security_open_close";
		public const SET_OFF:String				= "set_off";
		public const SET_TO_BLEND:String		= "set_to_blend";
		public const SET_TO_LIQUIFY:String		= "set_to_liquify";
		public const SET_TO_MIX:String 			= "set_to_mix";
		public const SET_TO_VAPORIZE:String		= "set_to_vaporize";	
		public const SEWER_ATTEMPT_OPEN:String 	= "sewer_attempt_open";
		public const SHOOT_SPARKS:String		= "shoot_sparks";
		public const SHOWER_KNOB_TURNED:String 	= "shower_knob_turned";
		public const SHOWER_STARTED:String 		= "shower_started";
		public const SMASHER_HIT:String			= "smasher_hit";
		public const SQUISHED:String			= "squished";
		public const TELEPORT:String			= "teleport";
		public const VICTORY:String				= "victory";
		public const WALKED:String			 	= "walked";
			
		// items
		public const BETA_COSTUME:String 		= "betaCostume";
		public const BOWL_EMPTY:String 			= "emptyBowl";
		public const BOWL_OF_MILK:String 		= "bowlOfMilk";
		public const CROWBAR:String 			= "crowbar";
		public const CUTTERS:String 			= "wireCutters";
		public const DRONE_EARS:String 			= "droneEars";
		public const MEDAL_CARROT:String		= "medalCarrot";
		public const SYSTEM_PASSWORD:String 	= "systemPassword";
	}
}