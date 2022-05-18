package game.scenes.viking
{
	import game.data.island.IslandEvents;
	import game.scenes.viking.adStreet1.AdStreet1;
	import game.scenes.viking.adStreet2.AdStreet2;
	import game.scenes.viking.beach.Beach;
	import game.scenes.viking.common.Common;
	import game.scenes.viking.diningHall.DiningHall;
	import game.scenes.viking.dodoHabitat.DodoHabitat;
	import game.scenes.viking.embedsCamp.EmbedsCamp;
	import game.scenes.viking.falls.Falls;
	import game.scenes.viking.fortress.Fortress;
	import game.scenes.viking.jungle.Jungle;
	import game.scenes.viking.peak.Peak;
	import game.scenes.viking.pen.Pen;
	import game.scenes.viking.river.River;
	import game.scenes.viking.shared.popups.MapPopup;
	import game.scenes.viking.throneRoom.ThroneRoom;
	import game.scenes.viking.waterfall.Waterfall;
	import game.scenes.viking.waterfall2.Waterfall2;
	
	public class VikingEvents extends IslandEvents
	{
		public function VikingEvents()
		{
			super();
			super.scenes = [ AdStreet1, AdStreet2, Common, Jungle, Beach, Peak, DodoHabitat, EmbedsCamp, ThroneRoom, River, Pen, Fortress, DiningHall, Waterfall, Waterfall2, Falls];
			super.popups = [MapPopup];
			
			this.island = "viking";
			this.earlyAccess = false;
		}
		
		//Events
		public const OCTAVIAN_FREED:String 			= "octavian_freed";
		public const GOBLET_DROPPED:String 			= "goblet_dropped";
		public const LOG_CUT_DOWN:String 			= "log_cut_down"; //log cut down in fortress
		
		public const CAUGHT_FISH:String				= "caught_fish";
		public const PLACED_FISH:String				= "placed_fish";
		public const PEAK_EXPLODED:String			= "peak_exploded";
		public const PLACED_GUNPOWDER:String		= "placed_gunpowder";
		public const PLACED_ROPE:String				= "placed_rope";
		public const SAW_RIVER_CHANGE:String		= "saw_river_change";

		
		public const START_SERVE_DRINKS:String		= "start_serve_drinks";
		public const HOLDING_TRAY:String			= "holding_tray";
		public const HAS_DRINK:String				= "has_drink_"; 	// 1-3 for the 3 chalices
		public const GOBLET_PLACED:String			= "goblet_placed";
		public const PIGS_FREED:String				= "pigs_freed";
		public const DRIPPINGS_FLUNG:String 		= "drippings_flung";
		public const DONE_SPYING:String				= "done_spying";
		public const GUARD_COVERED:String 			= "guard_covered";
		public const PIG_PEN_OPEN:String   			= "pig_pen_open";
		public const GAVE_FURS:String  				= "gave_furs";
		public const GAVE_HELMET:String  			= "gave_helmet";
		
		public const BALANCE_GAME_STARTED:String	= "balance_game_started";
		public const BALANCE_GAME_COMPLETE:String	= "balance_game_complete";
		public const OCTAVIAN_RAN_AWAY:String		= "octavian_ran_away"; //octavian ran away in jungle
		
		public const LOOKING_FOR_GOBLET:String		= "looking_for_goblet";
		public const THORLAK_FRAMED:String			= "thorlak_framed";
		public const SERVED_UNDERLING:String		= "served_underling_"; // 1-2 for dining hall
		public const SERVED_GIANT:String			= "served_giant";
		
		public const RIVER_COMPLETED:String			= "river_completed";
		
		// TEMP_EVENTS
		public const TURN_BLIND_EYE:String			= "turn_blind_eye";
		public const ERIK_TURNS:String				= "erik_turns";
		public const FLIP_A_LID:String				= "flip_a_lid";
		public const HAND_MAP:String 				= "hand_map";
		public const DRIPPINGS_USED:String 			= "drippings_used";
		public const CANT_USE_DRIPPINGS:String   	= "cant_use_drippings";
		public const AXE_USED:String 				= "axe_used";
		public const CANT_USE_AXE:String 			= "cant_use_axe";
		public const USE_HELMET:String 				= "use_helmet";
		public const CANT_USE_HELMET:String 		= "cant_use_helmet";
		public const USE_FURS:String 				= "use_furs";
		public const CANT_USE_FURS:String 			= "cant_use_furs";
		public const USE_GOBLET:String   			= "use_goblet";
		public const BLOCK_MAP:String				= "block_map";
		
		//Items
		public const AXE:String						= "axe";
		public const CANDYBAR:String				= "candybar";
		public const DRIPPINGS:String				= "drippings";
		//public const FISH:String					= "fish";
		public const FURS:String					= "furs";
		public const GOBLET:String					= "goblet";
		public const GUNPOWDER:String 				= "gunpowder";
		public const HELMET:String					= "helmet";
		public const LENS:String					= "lens";
		public const MAP:String						= "map";
		public const MEDAL_VIKING:String			= "medal_viking";
		public const ROPE:String					= "rope";
		public const SHOVEL:String					= "shovel";
		
	}
}