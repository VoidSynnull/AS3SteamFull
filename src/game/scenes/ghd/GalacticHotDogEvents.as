package game.scenes.ghd
{
	import game.data.island.IslandEvents;
	import game.data.specialAbility.islands.ghd.GelatinSaladBounce;
	import game.data.specialAbility.islands.ghd.RubGuano;
	import game.scenes.ghd.adMixed1.AdMixed1;
	import game.scenes.ghd.adMixed2.AdMixed2;
	import game.scenes.ghd.adStreet1.AdStreet1;
	import game.scenes.ghd.adStreet2.AdStreet2;
	import game.scenes.ghd.arena.Arena;
	import game.scenes.ghd.barren1.Barren1;
	import game.scenes.ghd.barren2.Barren2;
	import game.scenes.ghd.common.Common;
	import game.scenes.ghd.escape.Escape;
	import game.scenes.ghd.ghostShip.GhostShip;
	import game.scenes.ghd.lostTriangle.LostTriangle;
	import game.scenes.ghd.mushroom1.Mushroom1;
	import game.scenes.ghd.mushroom2.Mushroom2;
	import game.scenes.ghd.neonWiener.Comics;
	import game.scenes.ghd.neonWiener.Comics2;
	import game.scenes.ghd.neonWiener.NeonWiener;
	import game.scenes.ghd.neonWiener.RedButton;
	import game.scenes.ghd.outerSpace.OuterSpace;
	import game.scenes.ghd.prehistoric1.Prehistoric1;
	import game.scenes.ghd.prehistoric2.Prehistoric2;
	import game.scenes.ghd.shared.popups.galaxyMap.GalaxyMap;
	import game.scenes.ghd.spacePort.SpacePort;
	import game.scenes.ghd.store.Store;
	import game.util.CharUtils;
	
	
	public class GalacticHotDogEvents extends IslandEvents
	{
		public function GalacticHotDogEvents()
		{
			super();
			scenes = [ AdMixed1, AdMixed2, AdStreet1, AdStreet2, Arena, Barren1, Barren2, Common, Escape, OuterSpace, GhostShip, LostTriangle, Mushroom1, Mushroom2, NeonWiener, Prehistoric1, Prehistoric2, SpacePort, Store];
			popups = [ Comics, Comics2, RedButton, GalaxyMap ]; 
			
			removeIslandParts.push(new<String>[CharUtils.ITEM, "ghd_guano"],
				new<String>[CharUtils.ITEM, "ghd_gelatin"],
				new<String>[CharUtils.OVERSHIRT_PART, "medal_ghd"]);
			
			var specials:Array = [ RubGuano, GelatinSaladBounce ];
			
			this.island = "ghd";
			//this.nextEpisodeEvents = Survival2Events;
			this.accessible = true;
			this.earlyAccess = false;
			
		}
		// PERM EVENTS
		public const STARTED:String							= "started";
		public const READY_FOR_CONTEST:String				= "ready_for_contest";
		public const COOKED_DOG:String						= "cooked_dog";
		public const GOT_NUCLEAR_PELLET:String				= "got_nuclear_pellet";
		public const GIVE_FUEL_CELL:String					= "give_fuel_cell";
		public const WORM_HOLE_APPEARED:String				= "worm_hole_appeared";
		public const GOT_MAP_1:String						= "got_map_1";
		public const GOT_MAP_2:String						= "got_map_2";
		public const GOT_MAP_3:String						= "got_map_3";
		
		public const ASK_FRED:String						= "ask_fred";
		public const HAVE_SEEN_MOTHRA:String				= "used_guano";
		public const ENGINES_ON:String						= "engines_on";
		
		public const RECOVERED_COSMOE:String				= "recovered_cosmoe";
		public const RECOVERED_DAGGER:String				= "recovered_dagger";
		public const RECOVERED_HUMPHREE:String				= "recovered_humphree";
		
		public const BROKE_NUKE_CART:String					= "broke_nuke_cart";
		public const TALKED_TO_ARENA_GUARDS:String			= "talked_to_arena_guards";	
		public const SAW_QUEEN:String						= "saw_queen";
		
		public const FOUND_PLANET_PREHISTORIC:String 		= "found_planet_prehistoric";
		public const FOUND_PLANET_MUSHROOM:String 			= "found_planet_mushroom";
		public const FOUND_PLANET_BARREN:String 			= "found_planet_barren";
		public const FOUND_LOST_TRIANGLE:String				= "found_lost_triangle";
		
		public const FOUND_TRANSMISSION_COSMOE:String 		= "found_transmission_cosmoe";
		public const FOUND_TRANSMISSION_DAGGER:String 		= "found_transmission_dagger";
		public const FOUND_TRANSMISSION_HUMPHREE:String 	= "found_transmission_humphree";
		
		// EVENT GROUPS
		public const RECOVERED_CREW:String					= "recovered_crew";
		public const PRE_CONTEST:String						= "pre_contest";
		public const PRE_WORM_HOLE:String					= "pre_worm_hole";
		public const COSMOE_LOST:String						= "cosmoe_lost";
		public const DAGGER_LOST:String						= "dagger_lost";
		public const HUMPHREE_LOST:String					= "humphree_lost";
		public const UNFINISHED_CREW:String					= "unfinished_crew";
		public const GOT_ALL_MAP_PIECES:String				= "got_all_map_pieces";
		public const LOOKING_FOR_LOST_TRIANGLE:String		= "looking_for_lost_triangle";
		public const KNOW_HOW_TO_FLIP_MUSHROOMS:String		= "know_how_to_flip_mushrooms";
		
		public const RECOVERED_:String						= "recovered_";
		public const FOUND_TRANSMISSION_:String				= "found_transmission_";
		public const FOUND_PLANET_:String					= "found_planet_";
		
		// TEMP EVENTS		
		public const USE_EGG:String							= "use_egg";
		public const USE_FRUIT:String						= "use_fruit";
		public const USE_FUEL_CELL:String					= "use_fuel_cell";
		public const USE_GELATIN_SALAD:String				= "use_gelatin_salad";
		public const USE_GIANT_SPATULA:String				= "use_giant_spatula";
		public const USE_GUANO:String						= "use_guano";
		public const USE_SEED_POD:String					= "use_seed_pod";
		
		public const NO_USE_EGG:String						= "no_use_egg";
		public const NO_USE_FRUIT:String					= "no_use_fruit";
		public const NO_USE_FUEL_CELL:String				= "no_use_fuel_cell";  // card event that triggers one of the next two dialog events
		public const NO_USE_FULL_FUEL_CELL:String			= "no_use_full_fuel_cell";
		public const NO_USE_EMPTY_FUEL_CELL:String			= "no_use_empty_fuel_cell";
		
		public const NO_USE_GELATIN_SALAD:String			= "no_use_gelatin_salad";
		public const NO_USE_GIANT_SPATULA:String			= "no_use_giant_spatula";
		public const NO_USE_GUANO:String					= "no_use_guano";
		public const NO_USE_SEED_POD:String					= "no_use_seed_pod";
		
		public const TURN_TO_COSMOE:String					= "turn_to_cosmoe";
		public const TURN_TO_PRINCESS:String				= "turn_to_princess";
		public const SAY_COORDINATES:String					= "say_coordinates";
		public const STROKE_OF_LUCK:String					= "stroke_of_luck";
		public const COSMOE_AT_HELM:String					= "cosmoe_at_helm";
		
		// USERFIELDS 
		public const ROCKS1_FIELD:String 					= "barren1Rocks";
		public const ROCKS2_FIELD:String 					= "barren2Rocks";
		public const PLANET_FIELD:String 					= "current_planet";
		public const SECTORS_FIELD:String 					= "scanned_sectors";
		// possible values
		public const LOST_TRIANGLE:String					= "LostTriangle";
		public const BARREN:String							= "Barren1";
		public const PREHISTORIC:String						= "Prehistoric1";
		public const SPACE_PORT:String			 			= "SpacePort";
		public const MUSHROOM:String						= "Mushroom1";
		public const OUTER_SPACE:String						= "OuterSpace";
		
		
		
		// ITEMS
		public const EGG:String								= "egg";
		public const FRUIT:String							= "fruit";
		public const FUEL_CELL:String						= "fuel_cell";
		public const GELATIN_SALAD:String					= "gelatin_salad";
		public const GIANT_SPATULA:String					= "giant_spatula";
		public const GUANO:String							= "guano";
		public const MAP_O_SPHERE:String					= "map_o_sphere";
		public const MEDAL_GHD:String						= "medal_ghd";
		public const SEED_POD:String						= "seed_pod";
	}
}