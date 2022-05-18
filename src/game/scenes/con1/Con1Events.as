package game.scenes.con1
{
	import game.data.island.IslandEvents;
	import game.data.specialAbility.islands.poptropicon.Mjolnir;
	import game.scenes.con1.adMixed.AdMixed;
	import game.scenes.con1.adMixed2.AdMixed2;
	import game.scenes.con1.adStreet3.AdStreet3;
	import game.scenes.con1.alley.Alley;
	import game.scenes.con1.bathrooms.Bathrooms;
	import game.scenes.con1.center.Center;
	import game.scenes.con1.common.Common;
	import game.scenes.con1.parking.Parking;
	import game.scenes.con1.roofRace.RoofRace;
	import game.scenes.con1.shared.popups.Booth;
	import game.scenes.con1.shared.popups.Instructions;
	import game.scenes.con1.shared.popups.Pamphlet;
	import game.scenes.con2.Con2Events;
	import game.util.CharUtils;

			// move file location to parkinglot scene

	public class Con1Events extends IslandEvents
	{
		public function Con1Events()
		{
			super();
			super.scenes = [ AdMixed, AdMixed2, AdStreet3, Alley, Center, Common, RoofRace,Bathrooms, Parking ];
			super.popups = [ Pamphlet, Booth, Instructions ];
			removeIslandParts.push(new<String>[CharUtils.FACIAL_PART, "poptropicon_wizard"]
				, new<String>[CharUtils.HAIR, "poptropicon_wizard"]
				, new<String>[CharUtils.PACK, "poptropicon_wizard"]
				, new<String>[CharUtils.OVERSHIRT_PART, "poptropicon_wizard"]
				, new<String>[CharUtils.MARKS_PART, "poptropicon_thor"]
				, new<String>[CharUtils.HAIR, "poptropicon_thor"]
				, new<String>[CharUtils.PACK, "poptropicon_thor"]
				, new<String>[CharUtils.OVERSHIRT_PART, "poptropicon_thor"]
				, new<String>[CharUtils.OVERSHIRT_PART, "poptropicon_hero2"]
				, new<String>[CharUtils.ITEM, "poptropicon_mjolnir"]);
			var specials:Array = [ Mjolnir ];
			
			this.island = "con1";
			this.nextEpisodeEvents = Con2Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		//***************** Permanent Events
		public const BOUNCER_OUT:String				= "bouncer_out";
		
		public const QUEST_ACCEPTED:String			= "_quest_accepted";// friend, viking1, viking2, sfFan, shFan, spFan
		//example: "friend_quest_accepted";
		public const QUEST_COMPLETE:String			= "_quest_complete";// friend, viking1, viking2, sfFan, shFan, spFan
		//example: "viking1_quest_complete";
		public const PASSED:String					= "_passed";// friend, viking1, viking2, sfFan, shFan, spFan
		//example: "sfFan_passed"; // this refers to passed in line
		public const FRIEND_GOES_HOME:String		= "friend_goes_home";
		public const JERK_LEAVES_BATHROOMS:String	= "jerk_leaves_bathrooms";
		
		public const SKIP_INTRO:String				= "skip_intro";		
		public const SKIP_PREVIEW:String			= "skip_preview";
		
		public const DRESSED_AS_WIZARD:String		= "dressed_as_wizard";
		public const SOME_WIZARD_PARTS:String		= "some_wizard_parts";
		
		//***************** Temporary Events
		
		public const GIVE:String					= "give_"
		public const SAVE_COSTUME:String			= "save_costume";
		public const START_TUTORIAL:String			= "start_tutorial";
		public const NO_TUTORIAL:String				= "no_tutorial";
		
		public const BEHOND_MJOLNIR:String 			= "behold_mjolnir";
		public const DAT_CATAPULT:String			= "dat_catapult";
		public const FLASH_HAMMER:String			= "flash_hammer";
		public const INQUIRE_FURTHER:String			= "inquire_further";
		public const REGAIN_CONTROL:String			= "regain_control";
		public const FOR_GLORY:String				= "for_glory";
		
		public const PLAY_RACE:String				= "play_race";
		public const VIEW_RACE:String 				= "view_race";
		public const HEAD_START:String 				= "head_start";
		public const START_RACE:String 				= "start_race";	
		public const WON_RACE:String				= "won_race";
		
		public const PANIC:String 					= "panic";
		public const THOR_ALMIGHTY:String			= "thor_almighty";		
		
		//***************** Event Groups
		public const BOUNCER_ON:String				= "bouncer_on";
		public const TAKE_TICKET:String 			= "take_ticket";
		public const RACER_NOT_BEAT:String 			= "racer_not_beat";
		public const RACER_BEAT:String				= "racer_beat";
		
		//***************** Items
		public const BACKPACK_STRAPS:String 		= "backpack_straps";
		public const BOTTLES:String					= "bottles";
		public const FREMULON_MASK:String			= "fremulon_mask";
		public const JETPACK:String					= "jetpack";
		public const JETPACK_INSTRUCTIONS:String	= "jetpack_instructions";
		public const MEDAL_CON_1:String 			= "medal_con1";
		public const MJOLNIR:String 				= "mjolnir";
		public const PAMPHLET:String				= "pamphlet";
		public const POWER_GEM:String				= "power_gem";
		public const WATCH_PARTS:String	 			= "watch_parts";
	}
}