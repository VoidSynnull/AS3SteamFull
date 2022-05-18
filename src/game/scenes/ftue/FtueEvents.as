package game.scenes.ftue
{
	import game.data.island.IslandEvents;
	import game.scenes.ftue.adMixed1.AdMixed1;
	import game.scenes.ftue.beach.Beach;
	import game.scenes.ftue.forest.Forest;
	import game.scenes.ftue.intro.Intro;
	import game.scenes.ftue.mainLand.MainLand;
	import game.scenes.ftue.mainLand.popups.BlimpDrawing;
	import game.scenes.ftue.mainLand.popups.BlimpSchematic;
	import game.scenes.ftue.outro.Outro;
	
	
	public class FtueEvents extends IslandEvents
	{
		public function FtueEvents()
		{
			super();
			super.scenes = [AdMixed1, Beach, Forest, MainLand, Outro, Intro];
			super.popups = [BlimpDrawing, BlimpSchematic];
		}
		
		// sky intro
		public const ARRIVED_IN_PLANE:String		= "arrived_in_plane";
		public const ASK_WHERE_ARE_WE:String        = "ask_where_are_we";
		public const RACE_ENTERED:String			= "race_enter";
		public const SHOW_SAVE_TUTORIAL:String		= "show_save_tutorial";
		public const SKIPPED_SAVE_TUTORIAL:String	= "skipped_save_tutorial";
		public const RACE_ASK_COSTUMES:String		= "race_ask_costumes";
		public const COMPLETE_COSTUMIZE_TUT:String	= "completed_costumize_tutorial";
		public const LEAVE_TUTORIAL:String			= "leave_tutorial";
		public const LEAVE_TUTORIAL_CONFIRM:String  = "leave_tutorial_confirmed";
		public const LEAVE_TUTORIAL_CANCEL:String   = "leave_tutorial_canceled";
		public const RACE_BEGUN:String   			= "race_begun";
		public const ENCOUNTERED_BARON:String   	= "encountered_baron";
		public const GOING_DOWN:String   			= "going_down";
		
		public const WOKE_UP_ON_BEACH:String		= "woke_up_on_beach";
		public const JUMPED_ON_ROCK:String			= "jumped_on_rock";
		public const COMPLETED_TUTORIAL:String		= "control_tutorial_complete";
		
		public const FOUND_AMELIA:String			= "found_amelia";
		public const CLIMBED_ROPE:String			= "climbed_rope";
		public const SAVED_AMELIA:String			= "saved_amelia";
		
		public const FOLLOWED_MONKEY_TO_BEACH:String= "followed_monkey_to_beach";
		public const CORNERED_CRAB:String			= "cornered_crab";		
		
		public const SKIPPED_ITEM_TUTORIAL:String	= "skipped_item_tutorial";
		public const USED_ITEM_TUTORIAL:String		= "used_item_tutorial";
		public const FIX_BROKE_PLANE:String			= "fix_broke_plane";
		
		public const INTERACTIVE_TUTORIAL:String 	= "interactive_tutorial";
		public const DIALOG_TUTORIAL:String			= "dialog_tutorial";
		public const THREE_INGREDIENTS:String		= "three_ingredients";
		public const CRANKED_WHEEL:String			= "cranked_wheel";
		public const DROPPED_IN_FRUIT:String		= "dropped_in_fruit_"; // 1-5
		public const GAVE_CRUSOE_ITEM:String		= "gave_crusoe_item_"; // rope, canvas, drink
		public const SAW_CRUSOE_PLANS:String		= "saw_crusoe_plans";
		public const MADE_BLIMP:String				= "made_blimp";
		
		// outro events
		public const RE_ENTERED_RACE:String			= "re_entered_race";
		public const DROPPED_BALLAST:String			= "dropped_ballast";
		public const CAUGHT_UP_BARON:String			= "caught_up_baron";
		public const CHALLENGED_BARON:String		= "challenged_baron";
		public const FELL_OFF_BLIMP:String			= "fell_off_blimp";
		public const DODGED_BARON_SUCCESS:String    = "dodged_baron_success";
		public const REVEALED_CRUSOE:String			= "revealed_crusoe";
		public const THREW_WRENCH:String			= "threw_wrench";
		public const TALK_TO_CRUSOE:String			= "talk_to_crusoe";
		public const THREW_DRINK:String				= "threw_drink";
		public const FINISHED_RACE:String 			= "finished_race";
		
		// Group Events
		public const GAVE_EVERYTHING:String			= "gave_everything";
		
		// Not Saved
		public const USE:String						= "use_";
		public const NO_USE:String					= "no_use_";
		public const AMELIA_SEES_YOU_FOUND_WRENCH:String = "amelia_sees_you_found_wrench";
		
		// items
		public const WRENCH:String					= "wrench";
		public const ROPE:String					= "rope";
		public const DRINK:String					= "drink";
		public const CANVAS:String					= "canvas";
		public const MEDAL:String					= "medal_ftue";
	}
}