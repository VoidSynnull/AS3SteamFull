package game.scenes.arab3
{
	import game.data.island.IslandEvents;
	import game.scenes.arab3.adMixed1.AdMixed1;
	import game.scenes.arab3.adMixed2.AdMixed2;
	import game.scenes.arab3.adStreet3.AdStreet3;
	import game.scenes.arab3.atrium.Atrium;
	import game.scenes.arab3.atriumGame.AtriumGame;
	import game.scenes.arab3.bazaar.Bazaar;
	import game.scenes.arab3.common.Common;
	import game.scenes.arab3.desert.Desert;
	import game.scenes.arab3.lampRoom.LampRoom;
	import game.scenes.arab3.palaceExterior.PalaceExterior;
	import game.scenes.arab3.palaceInterior.PalaceInterior;
	import game.scenes.arab3.princessRoom.DiaryPopup;
	import game.scenes.arab3.princessRoom.PrincessRoom;
	import game.scenes.arab3.shared.CrystalContentView;
	import game.scenes.arab3.shared.InstructionsPopup;
	import game.scenes.arab3.skyChase.SkyChase;
	import game.scenes.arab3.treasureKeep.TreasureKeep;
	import game.scenes.arab3.vizierRoom.VizierRoom;
	import game.scenes.arab3.vizierRoom.popups.BookshelfPopup;
	import game.scenes.arab3.vizierRoom.popups.MagicBookPopup;
	import game.util.CharUtils;
	
	public class Arab3Events extends IslandEvents
	{
		public function Arab3Events()
		{
			super();
			super.scenes = [ AdMixed1, AdMixed2, AdStreet3, Atrium, AtriumGame, Bazaar, Common, Desert, LampRoom, PalaceExterior, PalaceInterior, PrincessRoom, SkyChase, TreasureKeep, VizierRoom ];
			super.popups = [ BookshelfPopup, DiaryPopup, InstructionsPopup, MagicBookPopup ];
			var specials:Array = [CrystalContentView];
			this.island = "arab3";
			
			removeIslandParts.push(
				new<String>[CharUtils.ITEM, "an_divination_sand"],
				new<String>[CharUtils.ITEM, "an3_lamp1"],
				new<String>[CharUtils.ITEM, "an_drawing"],
				new<String>[CharUtils.ABILITY, MAGIC_CARPET]);
			
			this.accessible = true;
			this.earlyAccess = false;
		}
		//events
		public const SPOT_THE_DIFFERENCE_COMPLETE:String 	= "spot_the_difference_complete";
		public const LEARNED_JINNS_NAME:String 				= "learned_jinns_name";
		public const JINN_BOUND:String  					= "jinn_bound";
		public const THIEF_TRANSFORMED:String 				= "thief_transformed";
		public const INTRO_COMPLETE:String  				= "intro_complete";
		
		public const GENIE_IN_DESERT:String					= "genie_in_desert"; // genie forced out of palace entrance goes here
		public const GENIE_IN_DESERT_SKY:String				= "genie_in_desert_sky"; // genie in sky before atrium minigame happens
		public const GENIE_IN_ATRIUM:String					= "genie_in_atrium"; // genie ready for atrium minigame
		public const GENIE_IN_BAZAAR:String					= "genie_in_bazaar"; // genie hides here after player finds drawing
		public const GENIE_IN_PALACE:String					= "genie_in_palace"; // genie forced out of bazaar goes here
		public const GENIE_IN_LAMP_ROOM:String				= "genie_in_lamp_room"; // genie forced out of atrium goes here
		
		public const JAILER_LEFT:String						= "jailer_left";
		
		public const SKY_CHASE_COMPLETE:String				= "sky_chase_complete";
		public const SULTAN_MADE_WISH:String				= "sultan_made_wish";
		public const USED_SPYGLASS:String					= "used_spyglass";
		public const CAMEL_CHASE_STARTED:String				= "camel_chase_started";	
		
		public const CHEST_OPENED:String					= "chest_opened"; //sultan left in palace interior
		public const SULTAN_LEFT:String						= "sultan_left"; //sultan left in palace interior
		public const HIDDEN_DOOR_OPENED:String				= "hidden_door_opened";	//door open in palace interior
		
		public const LAMP_ROOM_UNLOCKED:String				= "lamp_room_unlocked";
			
		//temp events
		public const USE_SKELETON_KEY:String		= 	"use_skeleton_key";
		public const CANT_USE_SKELETON_KEY:String	=	"cant_use_skeleton_key";
		public const USE_LAMP:String 				= 	"use_lamp";
		public const CANT_USE_LAMP:String 			= 	"cant_use_lamp";		
		public const USE_GEODE:String 				= 	"use_geode";
		public const CANT_USE_GEODE:String 			= 	"cant_use_geode";		
		public const USE_MOONSTONE:String 			= 	"use_moonstone";
		public const CANT_USE_MOONSTONE:String 		= 	"cant_use_moonstone";		
		public const USE_WISHBONE:String 			= 	"use_wishbone";
		public const CANT_USE_WISHBONE:String 		= 	"cant_use_wishbone";
		public const USE_DRAWING:String				= 	"use_drawing";
		public const CANT_USE_DRAWING:String		= 	"cant_use_drawing";
		public const USE_COMPASS:String 			= 	"use_compass";
		public const CANT_USE_COMPASS:String 		= 	"cant_use_compass";
		//event groups
		
		//items
		public const BONE_MEAL:String			=	"bone_meal";
		public const BURLAP_SACK:String			=	"burlap_sack";
		public const COMPASS:String 			=	"compass";
		public const CRYSTALS:String 			= 	"crystals";
		public const DIVINATION_DUST:String 	=	"divination_dust";
		public const DRAWING:String				=	"drawing";
		public const GEODE:String  				= 	"geode";
		public const GOLDEN_LAMP:String			=	"golden_lamp";
		public const INSTRUCTIONS:String 		=	"instructions";
		public const MAGIC_BOOK:String 			=	"magic_book";
		public const MAGIC_CARPET:String 		=	"magic_carpet";
		public const MOON_DUST:String 			= 	"moon_dust";
		public const MOONSTONE:String 			=	"moonstone";
		public const ROC_FEATHER:String 		=	"roc_feather"
		public const SESAME_OIL:String 			=	"sesame_oil";
		public const SKELETON_KEY:String 		=	"skeleton_key";
		public const WISHBONE:String 			=	"wishbone";	
		public const MEDAL:String 				=	"medal_arabian3";	
	}
}