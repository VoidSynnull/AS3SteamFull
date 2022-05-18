package game.scenes.survival2
{
	import game.data.island.IslandEvents;
	import game.scenes.survival2.adMixed1.AdMixed1;
	import game.scenes.survival2.adMixed2.AdMixed2;
	import game.scenes.survival2.adStreet3.AdStreet3;
	import game.scenes.survival2.beaverDen.BeaverDen;
	import game.scenes.survival2.caughtFish.CaughtFish;
	import game.scenes.survival2.fishingHole.FishingHole;
	import game.scenes.survival2.intro.Intro;
	import game.scenes.survival2.shared.FishingPoleContentView;
	import game.scenes.survival2.trees.Trees;
	import game.scenes.survival2.unfrozenLake.UnfrozenLake;
	import game.scenes.survival3.Survival3Events;
	import game.util.CharUtils;
	
	public class Survival2Events extends IslandEvents
	{
		public function Survival2Events()
		{
			super();
			scenes = [BeaverDen, FishingHole, Trees, Intro, UnfrozenLake, AdMixed1, AdMixed2, AdStreet3, CaughtFish];
			var cardViews:Array = [FishingPoleContentView];
			removeIslandParts.push(new<String>[CharUtils.ITEM, "fishing_pole"]);
			
			this.island = "survival2";
			this.nextEpisodeEvents = Survival3Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		public const UPDATE_POLE:String 				= "update_pole";
		
		//Permanent Events
		public const ENGRAVED_NAME:String 				= "engraved_name";
		public const DAM_DRAINED:String					= "dam_drained";
		
		public const PLAYED_INTRO:String				= "played_intro";
		public const FELL_AFTER_INTRO:String			= "fell_after_intro";
		
		public const GOT_PAGE:String					= "got_page"; //I'm assuming this is 1-3 -Jordan
		public const GOT_JOURNAL:String					= "got_journal";
		
		public const FISHING_HOLE_TREE_PUSHED:String 	= "fishing_hole_tree_pushed";
		public const ICE_BROKEN:String					= "ice_broken";
		
		public const LAKE_TREE1_DOWN:String 			= "lake_tree1_down";
		public const LAKE_TREE2_DOWN:String 			= "lake_tree2_down";
		public const LAKE_RAFT_DOWN:String 				= "lake_raft_down";
		
		// Event groups
		public const FOUND_1_PAGE:String				= "found_one_page";
		public const FOUND_2_PAGES:String				= "found_two_pages";
		
		// USER FIELDS
		public const TEMPERATURE_FIELD:String 			="temperature";
		public const BAIT_FIELD:String 					="bait";
		
		
		//*********************************************************************
		//Items
		public const SHOELACE1:String 					= "shoelace1";
		public const SHOELACE2:String 					= "shoelace2";
		public const HOOK:String						= "hook";
		public const GRUBS:String						= "grubs";
		public const PILL_BUGS:String					= "pillbugs";
		public const WORMS:String						= "worms";
		public const HAND_BOOK:String					= "handbook";
		public const HAND_BOOK_PAGE:String				= "handbookPage";
		public const MEDAL_SURVIVAL2:String				= "medal_survival2";
		public const FISHING_POLE:String				= "fishingPole";
		public const FISHING_COSTUME:String				= "fishing_costume";
	}
}