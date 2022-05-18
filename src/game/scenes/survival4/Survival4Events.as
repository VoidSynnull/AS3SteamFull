package game.scenes.survival4
{
	import game.data.island.IslandEvents;
	import game.scenes.survival4.adMixed1.AdMixed1;
	import game.scenes.survival4.adMixed2.AdMixed2;
	import game.scenes.survival4.adStreet1.AdStreet1;
	import game.scenes.survival4.adStreet2.AdStreet2;
	import game.scenes.survival4.banquetRoom.BanquetRoom;
	import game.scenes.survival4.grounds.Grounds;
	import game.scenes.survival4.guestRoom.GuestRoom;
	import game.scenes.survival4.mainHall.MainHall;
	import game.scenes.survival4.touchDown.TouchDown;
	import game.scenes.survival4.trophyRoom.TrophyRoom;
	import game.scenes.survival4.vanBurenRoom.VanBurenRoom;
	import game.scenes.survival5.Survival5Events;
	import game.util.CharUtils;

	public class Survival4Events extends IslandEvents
	{
		public function Survival4Events()
		{
			super();
			scenes = [BanquetRoom, Grounds, GuestRoom, MainHall, TouchDown, TrophyRoom, VanBurenRoom, AdMixed1, AdMixed2, AdStreet1, AdStreet2];
			popups = [];
			removeIslandParts.push(new<String>[CharUtils.FACIAL_PART, "survival_nightvision"]);
			
			this.island = "survival4";
			this.nextEpisodeEvents = Survival5Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		// Permanent Events
		public const TOUCHED_DOWN:String			= "touched_down";
		
		public const TOUR_COMPLETE:String			= "tour_complete_";// 1 - 3
		public const SPEAR_FELL:String 				= "spear_fell";
		public const ALLIGATOR_FELL:String			= "alligator_fell";
		public const HYENA_FELL:String				= "hyena_fell";
		public const STATUE_FELL:String				= "statue_fell";
		public const UNLOCKED_ARMORY:String			= "unlocked_armory";
		public const ATE_MEAT:String				= "ate_meat";
		public const GUEST_ROOM_INTRO:String 		= "guest_room_intro";
		public const OPENED_GUEST_DOOR:String 		= "opened_guest_door";
		public const CAMERAS_DISABLED:String		= "cameras_disabled";
		public const OPENED_VAN_BURENS_DOOR:String	= "opened_van_burens_door";
		public const NIGHT_VISION_ON:String			= "night_vision_on";
		public const NIGHT_VISION_OFF:String		= "night_vision_off";
		public const DOG_ATE_MEAT:String			= "dog_ate_meat";
		
		public const WELCOME:String				 	= "welcome";
		public const MOOSE_FACING_:String			= "moose_facing_"; // 1-3
		public const TROPHY_ROOM_UNLOCKED:String	= "trophy_room_unlocked";
		public const CODE_ENTERED:String			= "code_entered";
		public const TALLY_HO_DOWN:String			= "tally_ho_down";
		
		//above events added to CMS on 6/19/14 -Jordan
		
		// Event groups
		public const WINSTON_IN_HALL:String			= "winston_in_hall"
		
		// Not Permenant;
		public const DINNER_SEQUENCE:String			= "dinner_sequence";
		public const OPEN_KITCHEN:String			= "open_kitchen";
		public const USE_EMPTY_PITCHER:String		= "use_empty_pitcher";
		public const USE_FULL_PITCHER:String		= "use_full_pitcher";
		public const USE_BEAR_CLAW:String			= "use_bear_claw";		
		public const BUTLER_POPUP:String			= "butler_popup";
		public const USE_TAINTED_MEAT:String		= "use_tainted_meat";
		public const USE_VOICE_RECORDING:String		= "use_voice_recording";
		public const USE_SPEAR:String				= "use_spear";
		public const USE_ARMORY_KEY:String			= "use_armory_key";
		public const USE_TROPHY_ROOM_KEY:String		= "use_trophy_room_key";
		public const PLAY_HORN:String				= "play_horn";
		public const USE_TALLY_HO:String			= "use_tally_ho";
		
		public const TO_THE_TROPHIES:String			= "to_the_trophies";
		public const NONSENSE_BOY:String			= "nonsense_boy";
		public const VOICE_AUTHORIZATION:String		= "voice_authorization";
		
		public const TROPHY_LIT:String				= "trophy_lit_";// 1 -3
		public const MEET_WINSTON:String			= "meet_winston";
		public const HIDDEN_PATH_OPEN:String		= "hidden_path_open";
		public const FIRE_PUT_OUT:String			= "fire_put_out";
		public const PAINTING_DISTURBED:String		= "painting_disturbed";
		
		// Items
		public const ARMORY_KEY:String				= "armoryKey";
		public const BEAR_CLAW:String				= "bearClaw";
		public const EMPTY_PITCHER:String			= "emptyPitcher";
		public const FULL_PITCHER:String			= "fullPitcher";
		public const SURVIVAL_MEDAL:String			= "medal_survival4";
		public const NIGHT_VISION:String			= "nightVision";
		public const SECURITY_CODE:String			= "securityCode";
		public const SPEAR:String					= "spear";
		public const TAINTED_MEAT:String			= "taintedMeat";
		public const TROPHY_ROOM_KEY:String			= "trophyRoomKey";
		public const VOICE_RECORDING:String			= "voiceRecording";
	}
}