package game.scenes.poptropolis
{

	import game.data.animation.entity.character.poptropolis.DiveAnim;
	import game.data.animation.entity.character.poptropolis.HurdleAnim;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.animation.entity.character.poptropolis.HurdleRun;
	import game.data.animation.entity.character.poptropolis.HurdleStart;
	import game.data.animation.entity.character.poptropolis.HurdleStop;
	import game.data.animation.entity.character.poptropolis.JavelinAnim;
	import game.data.animation.entity.character.poptropolis.LongJumpAnim;
	import game.data.animation.entity.character.poptropolis.LongJumpLand;
	import game.data.animation.entity.character.poptropolis.LongJumpRun;
	import game.data.animation.entity.character.poptropolis.PoleVaultAnim;
	import game.data.animation.entity.character.poptropolis.ShotputAnim;
	import game.data.animation.entity.character.poptropolis.WrestleAnim;
	import game.scenes.poptropolis.adGroundH22.AdGroundH22;
	import game.scenes.poptropolis.archery.Archery;
	import game.scenes.poptropolis.coliseum.Coliseum;
	import game.scenes.poptropolis.common.Common;
	import game.scenes.poptropolis.diving.Diving;
	import game.scenes.poptropolis.hurdles.Hurdles;
	import game.scenes.poptropolis.javelin.Javelin;
	import game.scenes.poptropolis.longJump.LongJump;
	import game.scenes.poptropolis.mainStreet.MainStreet;
	import game.scenes.poptropolis.poleVault.PoleVault;
	import game.scenes.poptropolis.promoDive.PromoDive;
	import game.scenes.poptropolis.promoPlatform.PromoPlatform;
	import game.scenes.poptropolis.shotput.Shotput;
	import game.scenes.poptropolis.skiing.Skiing;
	import game.scenes.poptropolis.tripleJump.TripleJump;
	import game.scenes.poptropolis.volcano.Volcano;
	import game.scenes.poptropolis.volleyball.Volleyball;
	import game.scenes.poptropolis.weightLift.WeightLift;
	import game.scenes.poptropolis.wrestling.Wrestling;
	import game.scenes.poptropolis.adDeadEnd.AdDeadEnd;
	import game.data.island.IslandEvents;
	
	public class PoptropolisEvents extends IslandEvents
	{
		public function PoptropolisEvents()
		{
			super();
			super.scenes = [AdGroundH22, AdDeadEnd, Archery, Coliseum, Common, Diving, Skiing, Hurdles, Javelin, LongJump, MainStreet, PoleVault, Shotput, TripleJump, WeightLift, Wrestling, Volleyball, PromoDive, PromoPlatform, Volcano];
			var animations:Array = [ DiveAnim, HurdleAnim, HurdleJump, HurdleRun, HurdleStart, HurdleStop, JavelinAnim, LongJumpAnim, LongJumpLand, LongJumpRun, PoleVaultAnim, ShotputAnim, WrestleAnim ];
			var overlays:Array = [];
		}
		
		//Events
		public const POPTROPOLIS_STARTED:String 		= "poptropolis_started";
		public const SELECTED_TRIBE:String 				= "selected_tribe";
		public const DUG_IN_PROMO:String				= "dug_in_promo";
		public const PROMO_DIVE_STARTED:String			= "promo_dive_started";
		public const PROMO_DIVE_FINISHED:String			= "promo_dive_finished";
		public const TALKED_TO_MC:String 				= "talked_to_mc";
		public const STARTED_GAMES:String 				= "started_games";
		public const BONUS_STARTED:String 				= "bonus_started";
		public const BLOCKED_FROM_BONUS:String 			= "blocked_from_bonus";
		public const BONUS_COMPLETED:String 			= "bonus_completed";
		
		public const ARCHERY_COMPLETED:String 			= "archery_completed";
		public const DIVING_COMPLETED:String 			= "diving_completed";
		public const HURDLES_COMPLETED:String 			= "hurdles_completed";
		public const JAVELIN_COMPLETED:String 			= "javelin_completed";
		public const LONG_JUMP_COMPLETED:String 		= "long_jump_completed";
		public const POLE_VAULT_COMPLETED:String 		= "pole_vault_completed";
		public const SHOTPUT_COMPLETED:String 			= "shotput_completed";
		public const TRIPLE_JUMP_COMPLETED:String 		= "triple_jump_completed";
		public const WEIGHT_LIFTING_COMPLETED:String 	= "weight_lifting_completed";
		public const SKIING_COMPLETED:String			= "skiing_completed";
		public const VOLLEYBALL_COMPLETED:String		= "volleyball_completed";
		
		public const WRESTLING_COMPLETED:String			= "wrestling_completed"; //Day 2 Bonus
		
		//Temp for Coliseum to determine if an event has been completed. Should be completed by each competition.
		public const EVENT_COMPLETED:String				= "event_completed";
		
		public const ALL_EVENTS_COMPLETED:String		= "all_events_completed";	//Group Event
		
		//Items
		public const TRIBAL_JERSEY:String				= "tribal_jersey";
		public const MEDAL_POPTROPOLIS:String			= "medal_poptropolis";
		public const BONUS_OUTFIT:String				= "ancient_warrior_outfit";
	}
}