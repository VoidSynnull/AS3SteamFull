package game.scenes.survival3
{
	import game.data.island.IslandEvents;
	import game.scenes.survival3.adMixed1.AdMixed1;
	import game.scenes.survival3.adMixed2.AdMixed2;
	import game.scenes.survival3.adStreet3.AdStreet3;
	import game.scenes.survival3.ending.Ending;
	import game.scenes.survival3.intro.Intro;
	import game.scenes.survival3.radioTower.RadioTower;
	import game.scenes.survival3.riverBed.RiverBed;
	import game.scenes.survival3.shared.popups.BatteryNotePopup;
	import game.scenes.survival3.shared.popups.ManifestPopup;
	import game.scenes.survival3.shared.popups.RadioPopup;
	import game.scenes.survival3.valleyLeft.ValleyLeft;
	import game.scenes.survival3.valleyRight.ValleyRight;
	import game.scenes.survival4.Survival4Events;
	import game.util.CharUtils;
	
	public class Survival3Events extends IslandEvents
	{
		public function Survival3Events()
		{
			super();
			scenes = [ValleyRight, ValleyLeft, RadioTower, RiverBed, Intro, Ending, AdMixed1, AdMixed2, AdStreet3];
			popups = [BatteryNotePopup, RadioPopup, ManifestPopup];
			removeIslandParts.push(new<String>[CharUtils.FACIAL_PART, "hard_hat"]);
			
			this.island = "survival3";
			this.nextEpisodeEvents = Survival4Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		
		// Event groups
		
		public const SEESAW_1_LOOSE:String		= "seesaw_1_loose";
		public const SEESAW_2_LOOSE:String		= "seesaw_2_loose";
		
		//Permanent Events
		
		public const PLAYED_INTRO:String		= "played_intro";
		public const STARTED_QUEST:String		= "started_quest";
		
		public const POWERED_RADIO:String 		= "powered_radio";
		public const DROPPED_STAIRS:String 		= "dropped_stairs";
		
		public const REMOVED_BRACKET:String		= "removed_bracket_";// 1 - 4
		public const BROKE_LADDER:String 		= "broke_ladder_";//1-2
		
		public const TIPPED_WING:String			= "tipped_wing";
		public const CUT_DOWN_TREE:String		= "cut_down_tree";
		
		public const PLANE_PIECE_FELL:String	= "plane_piece_fell";
		public const PLANE_FELL_1:String		= "plane_fell_1";
		public const PLANE_FELL_2:String		= "plane_fell_2";
		public const PLANE_FELL_3:String		= "plane_fell_3";
		public const PLANE_FELL_4:String		= "plane_fell_4";
		
		public const PULLEY_BRANCH_BROKE:String = "pulley_branch_broke";
		public const CRATE_SMASHED:String		= "crate_smashed";
		
		public const USE_SAW:String				= "use_saw";
		public const USE_SCREWDRIVER:String		= "use_screwdriver";
		public const USE_CORK:String			= "use_cork";
		
		//above events were added to cms on 4/17/14 -Jordan
		
		//Items
		public const HARD_HAT:String			= "hardHat";
		public const WIRE:String				= "wire";
		public const NAIL:String				= "nail";
		public const PENNY:String				= "penny";
		public const POCKET_KNIFE:String		= "pocketKnife";
		public const LEMON:String				= "lemon";
		public const RADIO:String				= "radio";
		public const BATTERY_NOTE:String		= "batteryNote";
		public const MANIFEST:String			= "manifest";
		public const SURVIVAL_MEDAL:String		= "medal_survival3";
	}
}