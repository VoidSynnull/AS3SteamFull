package game.scenes.arab1
{
	import game.data.island.IslandEvents;
	import game.data.specialAbility.islands.arab.ThrowSmokeBomb;
	import game.scenes.arab1.adMixed1.AdMixed1;
	import game.scenes.arab1.adMixed2.AdMixed2;
	import game.scenes.arab1.adStreet3.AdStreet3;
	import game.scenes.arab1.bazaar.Bazaar;
	import game.scenes.arab1.cave.Cave;
	import game.scenes.arab1.cliff.Cliff;
	import game.scenes.arab1.common.Common;
	import game.scenes.arab1.desert.Desert;
	import game.scenes.arab1.desertScope.DesertScope;
	import game.scenes.arab1.palaceExterior.PalaceExterior;
	import game.scenes.arab1.palaceInterior.PalaceInterior;
	import game.scenes.arab2.Arab2Events;
	import game.util.CharUtils;
	
	public class Arab1Events extends IslandEvents
	{
		public function Arab1Events()
		{
			super();
			super.scenes = [AdMixed1,AdMixed2,AdStreet3, Cave,Cliff, Common, Bazaar, PalaceInterior, PalaceExterior, Desert, DesertScope];
			super.popups = [];
			var abilities:Array = [ThrowSmokeBomb];
			removeIslandParts.push(new<String>[CharUtils.ITEM, "an_bomb"]);
			
			this.island = "arab1";
			this.nextEpisodeEvents = Arab2Events;
			this.accessible = true;
			this.earlyAccess = false;
		}
		
		// permanent events
		public const QUEST_ACCEPTED:String			= "questAccepted";
		public const PLACED_TELESCOPE:String		= "placed_telescope";
		public const CAVE_ROPE_LOWERED:String		= "cave_rope_lowered";
		public const INTRO_COMPLETE:String			= "intro_complete";
		public const ENTERED_PALACE:String			= "entered_palace";
		public const GUARDS_STAND_DOWN:String		= "guards_stand_down";
		public const PLAYER_HOLDING_CAMEL:String	= "player_holding_camel";
		public const SMOKE_BOMB_LEFT:String			= "smoke_bomb_left";
		public const CLOTH_ON_DIAS:String			= "cloth_on_dias";
		public const SALT_ON_DIAS:String			= "salt_on_dias";
		public const GRAIN_ON_DIAS:String			= "grain_on_dias";
		public const CAMEL_ON_DIAS:String			= "camel_on_dias";
		public const CAMEL_TAKEN:String				= "camel_taken";
		
		// items
		public const CAMEL_HARNESS:String			= "camel_harness";
		public const CLOTH:String					= "cloth";
		public const CROWN_JEWEL:String				= "crown_jewel";
		public const GRAIN:String					= "grain";
		public const IVORY_CAMEL:String				= "ivory_camel";
		public const LAMP:String					= "lamp";
		public const PEARL:String					= "pearl";
		public const SALT:String					= "salt";
		public const SPY_GLASS:String				= "spy_glass";
		public const SMOKE_BOMB:String				= "smoke_bomb";
		public const MEDAL:String					= "medal_arabian1";
		
	}
}