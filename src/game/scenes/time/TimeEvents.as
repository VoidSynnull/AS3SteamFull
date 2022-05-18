package game.scenes.time
{
	import game.data.specialAbility.islands.time.SlowFall;
	import game.scenes.time.adStreet.AdStreet;
	import game.scenes.time.adDeadEnd.AdDeadEnd;
	import game.scenes.time.aztec.Aztec;
	import game.scenes.time.china.China;
	import game.scenes.time.china.MemoryGame;
	import game.scenes.time.common.Common;
	import game.scenes.time.desolation.Desolation;
	import game.scenes.time.edison.Edison;
	import game.scenes.time.edison2.Edison2;
	import game.scenes.time.everest.Everest;
	import game.scenes.time.everest2.Everest2;
	import game.scenes.time.everest3.Everest3;
	import game.scenes.time.france.France;
	import game.scenes.time.france2.France2;
	import game.scenes.time.future.Future;
	import game.scenes.time.future2.Future2;
	import game.scenes.time.graff.Graff;
	import game.scenes.time.graff2.Graff2;
	import game.scenes.time.greece.Greece;
	import game.scenes.time.greece2.Greece2;
	import game.scenes.time.lab.Lab;
	import game.scenes.time.lewis.Lewis;
	import game.scenes.time.mainStreet.MainStreet;
	import game.scenes.time.mainStreet.popups.TimeNews;
	import game.scenes.time.mali.Mali;
	import game.scenes.time.mali2.Mali2;
	import game.scenes.time.mali2.MaliDocs;
	import game.scenes.time.renaissance.Renaissance;
	import game.scenes.time.renaissance2.Renaissance2;
	import game.scenes.time.shared.TimeDeviceView;
	import game.scenes.time.viking.Viking;
	import game.scenes.time.viking2.Viking2;
	import game.data.island.IslandEvents;
	
	public class TimeEvents extends IslandEvents
	{
		public function TimeEvents()
		{
			super();
			super.scenes = [AdStreet, AdDeadEnd, Aztec, China, Common, Desolation, Edison, Edison2, Everest, Everest2, Everest3, France, France2, Future, Future2, Graff, Graff2, Greece, Greece2, Lab, Lewis, MainStreet, Mali, Mali2, Renaissance, Renaissance2, Viking, Viking2, TimeDeviceView];
			var overlays:Array = [TimeDeviceView, MaliDocs, TimeNews, MemoryGame];
			var abilities:Array = [SlowFall];
		}
		
		// events
		public const ENTERED_LAB:String			= "enter_lab";
		public const VICTORY:String 			= "victory";
		public const TIME_REPAIRED:String 		= "time_repaired";
		public const CAVE_OPEN:String 			= "cave_open";
		
		// Returned Items
		public const RETURNED:String 			= "returned_"; // add item name when checking
		
		// temporary events
		public const ITEM_DELIVERED:String 		= "item_delivered";// temp event for the time device button flashing
		public const TIMEMACHINE_POWERED:String = "timeMachine_poweredUp";
		public const WARRIOR_MASK_ON:String 	= "warriorMaskOn";
		public const WARRIOR_MASK_OFF:String 	= "warriorMaskOff";
		public const GLIDER_ON:String 			= "gliderOn";
		public const MOVE_WOOD_TIPPER:String 	= "move_wood_tipper";
		public const PORCPINE_HIT:String 		= "porcupine_hit";
		public const QUEST_START:String 		= "time_quest_start";
		
		public const ITEM_RETURNED_SOUND:String	= "item_returned_sound";
		public const TELEPORT:String			= "teleport";
		public const LIFT_MOVING:String 		= "lift_activated";
		public const LIFT_STOPPED:String		= "lift_deactivated";
		public const MEMORY_GAME:String 		= "memory_game";
		public const MEMORY_GAME_LOSS:String 	= "memory_game_loss";
		public const MEMORY_GAME_WIN:String 	= "memory_game_win";
		
		public const GUNPOWDER_PLACED:String	= "gunpowder_placed";
		public const GUNPOWDER_EXPLODE:String	= "gunpowder_explode";
		public const THUNDER_CLAP:String		= "thunder_clap";
		
		public const SNAKE_BITE:String 			= "snake_bite";
		
		public const MALIDOCS_START:String		= "maliDocs_start";
		public const MALIDOCS_COMPLETE:String	= "maliDocs_complete";
		public const MALIDOCS_OPENPUZZLE:String	= "maliDocs_openPuzzle";
		public const MALIDOCS_EXIT:String		= "maliDocs_exitPuzzle";
		
		// items
		public const PRINTOUT:String			= "printout";
		public const TIME_DEVICE:String			= "timeDevice";
		public const SUNSTONE:String			= "sunstone";
		public const WARRIOR_MASK:String		= "warriorMask";
		public const GLIDER:String				= "ability_glider";
		public const VIKINGSUIT:String			= "vikingSuit";
		public const AMULET:String				= "amulet";
		public const GOGGLES:String				= "goggles";
		public const GUNPOWDER:String			= "gunpowder";
		public const PHONOGRAPH:String			= "phonograph";
		public const DECLARATION:String			= "declaration";
		public const STATUETTE:String			= "statuette";
		public const GOLDEN_VASE:String			= "goldenVase";
		public const SALT_ROCKS:String			= "saltRocks";
		public const SILVER_MEDAL:String		= "silverMedal";
		public const STONE_BOWL:String			= "stoneBowl";
		public const NOTEBOOK:String			= "notebook";
		public const MEDAL_TIME:String			= "medalTime";
	}
}