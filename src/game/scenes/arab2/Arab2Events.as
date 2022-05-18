package game.scenes.arab2
{
	import game.data.island.IslandEvents;
	import game.data.specialAbility.islands.arab.ThrowMagicSand;
	import game.scenes.arab2.adMixed1.AdMixed1;
	import game.scenes.arab2.adMixed2.AdMixed2;
	import game.scenes.arab2.adStreet3.AdStreet3;
	import game.scenes.arab2.cells.Cells;
	import game.scenes.arab2.common.Common;
	import game.scenes.arab2.entrance.Entrance;
	import game.scenes.arab2.sanctum.Sanctum;
	import game.scenes.arab2.shared.FormulaPopup;
	import game.scenes.arab2.treasureKeep.TreasureKeep;
	import game.scenes.arab3.Arab3Events;
	
	public class Arab2Events extends IslandEvents
	{
		public function Arab2Events()
		{
			super();
			var scenes:Array = [Cells, Common, Sanctum, Entrance, TreasureKeep, AdMixed1, AdMixed2, AdStreet3];
			var overlays:Array = [FormulaPopup];
			var specialAbilities:Array = [ThrowMagicSand];
			
			this.island = "arab2";
			this.nextEpisodeEvents = Arab3Events;
			this.accessible = true;
			this.earlyAccess = false;
			
		}
		// permanent events
		public const INTRO_COMPLETE:String			= "intro_complete";
		public const QUEST_ACCEPTED:String			= "questAccepted";
		
		public const VIZIER_RESCUED:String			= "vizier_rescued";
		public const VIZIER_FOLLOWING:String		= "vizier_following";
		public const PLAYER_ESCAPED_CELL:String		= "player_escaped_cells";
		public const TALKED_TO_VIZIER:String 		= "talked_to_vizier";
		public const PLAYER_DISGUISED:String 		= "player_disguised";
		public const CELL_GUARD_1_DOWN:String		= "cell_guard_1_down";
		public const CELL_GUARD_2_DOWN:String		= "cell_guard_2_down";
		public const CELL_JAILER_DOWN:String		= "cell_jailer_down";
		public const PLAYER_ESCAPED_WLAMP:String	= "player_escaped_wlamp";
		public const PLAYER_CAUGHT_WLAMP:String		= "player_caught_wlamp";
		public const DROPPED_COINS:String			= "dropped_coins";
		
		
		public const STORE_ROOM_BURNED:String 		= "store_room_burned";
		
		// group events
		public const GOT_ALL_INGREDIENTS:String		= "got_all_ingredients";
		
		// temp events
		public const PLAYER_CAUGHT_CELLS:String		= "player_caught_cells";
		
		// items
		public const MAGIC_SAND:String = "magic_sand";
		public const FORMULA:String = "formula";
		public const VIPER_SKIN:String = "viper_skin";
		public const GUNPOWDER:String = "gunpowder";
		public const QUICKSILVER:String = "quicksilver";
		public const BORAX:String = "borax";
		public const CELL_KEY:String = "cell_key";
		public const WHITE_ROBE:String = "white_robe";
		public const THIEVES_GARB:String = "thieves_garb";
		public const MEDAL:String = "medal_arabian2";
		
	}
}