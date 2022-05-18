package game.scenes.myth
{
	import game.scenes.myth.adGroundH9.AdGroundH9;
	import game.scenes.myth.adGroundH9R.AdGroundH9R;
	import game.scenes.myth.apollo.Apollo;
	import game.scenes.myth.cerberus.Cerberus;
	import game.scenes.myth.grove.Grove;
	import game.scenes.myth.hadesPit1.HadesPit1;
	import game.scenes.myth.hadesPit2.HadesPit2;
	import game.scenes.myth.hadesTemple.HadesTemple;
	import game.scenes.myth.hadesThrone.HadesThrone;
	import game.scenes.myth.hercsHut.HercsHut;
	import game.scenes.myth.hydra.Hydra;
	import game.scenes.myth.labyrinth.Labyrinth;
	import game.scenes.myth.labyrinth.popups.Bones;
	import game.scenes.myth.labyrinthRoom.LabyrinthRoom;
	import game.scenes.myth.labyrinthSnake.LabyrinthSnake;
	import game.scenes.myth.labyrinthSnake.popups.Snake;
	import game.scenes.myth.mainStreet.MainStreet;
	import game.scenes.myth.midasGym.MidasGym;
	import game.scenes.myth.mountOlympus.MountOlympus;
	import game.scenes.myth.mountOlympus2.MountOlympus2;
	import game.scenes.myth.mountOlympus3.MountOlympus3;
	import game.scenes.myth.mountOlympus3.popups.LoseZeus;
	import game.scenes.myth.olympusMuseum.OlympusMuseum;
	import game.scenes.myth.poseidonBeach.PoseidonBeach;
	import game.scenes.myth.poseidonBeach.popups.Hangman;
	import game.scenes.myth.poseidonTemple.PoseidonTemple;
	import game.scenes.myth.poseidonThrone.PoseidonThrone;
	import game.scenes.myth.poseidonWater.PoseidonWater;
	import game.scenes.myth.riverStyx.RiverStyx;
	import game.scenes.myth.riverStyx.popups.LoseStyx;
	import game.scenes.myth.shared.Athena;
	import game.scenes.myth.shared.Flute;
	import game.scenes.myth.shared.Mirror;
	import game.scenes.myth.shared.Scroll;
	import game.scenes.myth.shared.abilities.Electrify;
	import game.scenes.myth.shared.abilities.Grow;
	import game.scenes.myth.sphinx.Sphinx;
	import game.scenes.myth.treeBottom.TreeBottom;
	import game.scenes.myth.treeBottom.popups.Scramble;
	import game.scenes.myth.treeTop.TreeTop;
	import game.scenes.myth.adStreet.AdStreet;
	import game.data.island.IslandEvents;
	
	public class MythEvents extends IslandEvents
	{
		public function MythEvents()
		{
			super();
			super.scenes = [AdGroundH9, AdGroundH9R, AdStreet, Apollo, Cerberus, Grove, HadesPit1, HadesPit2, HadesTemple, HadesThrone, HercsHut, Hydra, Labyrinth, LabyrinthRoom, LabyrinthSnake, MainStreet, MidasGym, MountOlympus,MountOlympus2,MountOlympus3, PoseidonBeach, PoseidonTemple, PoseidonThrone, PoseidonWater, OlympusMuseum, RiverStyx, Sphinx, TreeBottom, TreeTop ];
			super.popups = [Athena, Bones, Flute, Hangman, LoseZeus, LoseStyx, Mirror, Scramble, Scroll, Snake];
			var specials:Array = [ Electrify, Grow ];
		}
		
		//perm events
		public const SAW_CERBERUS:String =			"saw_cerberus";
		public const SAW_POSEIDON_BLOCK:String = 	"saw_poseidon_block";
		
		public const POSEIDON_THRONE_OPEN:String =	"poseidon_throne_open";
		public const HADES_THRONE_OPEN:String = 	"hades_throne_open";
		
		public const ATHENA_TRANSFORM:String =		"athena_transform";
		public const CLEANED_GRAFFITI_:String = 	"cleaned_graffiti_"; // 0 - 2 grafs
		
		public const APHRODITE_TEST_PASSED:String = "aphrodite_test_passed";
		public const SIMON_SAYS_PASSED:String = 	"simon_says_passed";
		
		public const COMPLETED_BONES:String = 		"completed_bones";
		public const COMPLETED_LABYRINTH:String = 	"completed_labyrinth";
		public const POSEIDON_TEMPLE_OPEN:String = 	"poseidon_temple_open";
		public const HADES_TEMPLE_OPEN:String = 	"hades_temple_open";
		public const ZEUS_GATE_OPEN:String = 		"zeus_gate_open";
		
		public const SPHINX_FLOODED:String = 		"sphinx_flooded";
		public const SPHINX_AWAKE:String = 			"sphinx_awake";
		
		public const HERCULES_FOLLOWING:String = 	"hercules_following";
		public const HERCULES_LOST:String = 		"hercules_lost";
		
		public const HONEY_CHASE_PASSED:String = 	"honey_chase_passed";
		public const HONEY_CHASE_FAILED:String = 	"honey_chase_failed";
		public const HONEY_CHASE_STARTED:String = 	"honey_chase_started";
		
		public const ZEUS_APPEARS_TREE:String = 	"zeus_appears_tree";
		public const ZEUS_APPEARS_STEAL:String = 	"zeus_appears_steal";
		public const ZEUS_APPEARS_THRONE:String = 	"zeus_appears_throne";
		public const RETURNED_ITEMS:String =		"returned_items";
		
		public const PLAYER_BECOME_GOD:String = 	"player_become_god";
		public const QUEST_STARTED:String =         "quest_started";
		
		public const HERCULES_UNDERWATER:String =	"hercules_underwater";
		public const HERCULES_UNDERGROUND:String = 	"hercules_underground";
		public const HERCULES_MAIN_STREET:String = 	"hercules_mainStreet";
		
		// group events (NOT COMPLETED MANUALLY, completed automatically based on combinations of standard events).
		public const PRE_CALL_TO_ACTION:String = 	"pre_call_to_action";
		public const CALL_TO_ACTION:String = 		"call_to_action";
		public const CLEANED_ALL_GRAFFITI:String = 	"cleaned_all_graffiti";
		public const ATHENA_IN_DISGUISE:String =	"athena_in_disguise";
		public const GOT_ALL_ITEMS:String = 		"got_all_items";
		public const CAN_TRANSPORT_HERCULES:String = "can_transport_hercules";
		public const READY_TO_FACE_ZEUS:String = 	"ready_to_face_zeus";
		public const HERCULES_ALIVE:String = 		"hercules_alive";
		public const HERCULES_CHILLING:String = 	"hercules_chilling";
		public const HERCULES_SWIMMING:String = 	"hercules_swimming";
		public const HERCULES_MINING:String = 		"hercules_mining";
		public const PRE_MEDUSA_STRIKE:String = 	"pre_medusa_strike";
		
		// temp events
		public const ZEUS_DOWNED:String = 			"zeus_downed";
		public const ZEUS_DEFEAT:String = 			"zeus_defeat";
		public const ZEUS_LOSE:String = 			"lose_zeus";
		public const RETURN_ITEMS:String =			"return_items";
		
		public const THUNDER_CLAP:String =			"thunder_clap";
		public const AQUADUCT_COMPLETE:String = 	"aquaduct_complete";
		public const APHRODITE_TEST:String =		"aphrodite_test";
		public const APHRODITE_TEST_FAILED:String = "aphrodite_test_failed";
		public const SIMON_SAYS_FAILED:String = 	"simon_says_failed";
		public const SIMON_SAYS_QUIT:String = 		"simon_says_quit";
		
		public const SOOTHING_MELODY:String = 		"soothing_melody";
		public const DOOR_JAM:String = 				"door_jam";
		public const SLEEPING_CERBERUS:String = 	"sleeping_cerberus";
		public const LABYRINTH_OPEN:String = 		"labyrinth_open";
		public const HYDRA_DEFEATED:String =	 	"hydra_defeated";
		
		public const HADES_OFFERING:String = 		"hades_offering";
		public const POSEIDON_OFFERING:String = 	"poseidon_offering";
		
		public const LOAD_RIVER_STYX:String =		"load_river_styx";
		public const SIMON_START:String = 			"simon_start";
		
		public const SPHINX_WAKE_SOUND:String = 	"sphinx_wake_sound";
		
		public const PLAY_MUSIC:String =			"play_music";
		public const HERC_BREAK_LOCK:String = 		"herc_break_lock";
		public const UNLOCK_MOTION:String = 		"unlock_motion";
		public const LOCK_MOTION:String = 			"lock_motion";
		
		public const USE_MIRROR:String =			"use_mirror";
		public const TELEPORT:String = 				"teleport";
		public const TELEPORT_HERC:String =			"teleport_herc";
		public const TELEPORT_FINISHED:String = 	"teleport_finished";
		
		public const BUY_BAG_OF_WIND:String = 		"buy_bag_of_wind";
		public const USE_BAG_OF_WIND:String = 		"use_bag_of_wind";
		
		public const NOT_APHRODITE:String =			"not_aphrodite";
		public const NOT_POSEIDON:String = 			"not_poseidon";
		public const NOT_HADES:String = 			"not_hades";
		public const NOT_ZEUS:String =				"not_zeus";
		
		// items
		public const APHRODITE_MIRROR:String = 		"aphroditeMirror";
		public const BAG_OF_WIND:String =			"bagOfWind";
		public const CERBERUS_WHISKER:String =		"cerberusWhisker";
		public const GIANT_PEARL:String = 			"giantPearl";
		public const GOLDEN_APPLE:String = 			"goldenApple";
		public const HADES_CROWN:String = 			"hadesCrown";
		public const HYDRA_SCALE:String = 			"hydraScale";
		public const MEDAL_MYTHOLOGY:String = 		"medalMythology";
		public const MINOTAUR_RING:String =			"minotaurRing";
		public const PIPE_TUNE:String =				"pipeTune";
		public const POMEGRANATES:String = 			"pomegranates";
		public const POSEIDON_TRIDENT:String = 		"poseidonTrident";
		public const REED_PIPE:String = 			"reedPipe";
		public const SILVER_DRACHMA:String = 		"silverDrachma";
		public const SPHINX_FLOWER:String = 		"sphinxFlower";
		public const STARFISH:String =	 			"starfish";
		public const ZEUS_SCROLL:String =	 		"zeusScroll";
	}
}