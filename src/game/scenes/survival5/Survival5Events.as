package game.scenes.survival5
{
	import game.data.island.IslandEvents;
	import game.scenes.survival5.adMixed1.AdMixed1;
	import game.scenes.survival5.adMixed2.AdMixed2;
	import game.scenes.survival5.adStreet2.AdStreet2;
	import game.scenes.survival5.baseCamp.BaseCamp;
	import game.scenes.survival5.chase.Chase;
	import game.scenes.survival5.ending.Ending;
	import game.scenes.survival5.sawmill.Sawmill;
	import game.scenes.survival5.traps.Traps;
	import game.scenes.survival5.underground.Underground;
	import game.scenes.survival5.waterEdge.WaterEdge;

	public class Survival5Events extends IslandEvents
	{
		public function Survival5Events()
		{
			super();
			var scenes:Array = [AdMixed2, AdStreet2, AdMixed1, Ending, Sawmill, Chase, Traps, BaseCamp, Underground, WaterEdge];
			var overlays:Array = [];
			
			this.island = "survival5";
			this.nextEpisodeEvents;
			this.accessible = true;
			this.earlyAccess = false;
		}
	
		public const TREE_TIPPED:String				= "tree_tipped";
		public const RELEASED_BEAR:String			= "released_bear";
		public const RELEASED_BEAVER:String			= "released_beaver";
		public const ATTACHED_GEAR:String			= "attached_gear";
		public const ATTACHED_ROPE:String			= "attached_rope";
		public const HOOKED_CRATE:String			= "hooked_crate";
		public const SHOW_ENDING:String				= "show_ending";
		public const JOINED_THE_FIGHT:String		= "joined_the_fight";
		
		// Temp Events
		public const USE_GEAR:String				= "use_gear";
		public const USE_ROPE:String				= "use_rope";
		public const USE_WHISTLE:String				= "use_whistle";
		public const TRAPPED_SELF:String			= "trapped_self";
		public const REPOSITION_COVER:String 		= "reposition_pit_cover";
		
		// Event Groups
		public const ISLAND_INCOMPLETE:String		= "island_incomplete";
		public const READY_TO_FIGHT:String			= "ready_to_fight";
		
		// items
		public const GEAR:String					= "gear";
		public const WHISTLE:String					= "whistle";
		public const FISHING_POLE:String 			= "fishing_pole";
		public const ROPE:String 					= "rope";
		public const SURVIVAL_MEDAL:String			= "medal_survival5";	
	}
}