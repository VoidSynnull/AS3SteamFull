package game.scenes.superPower
{
	import game.scenes.superPower.adGroundH4.*;
	import game.scenes.superPower.bank.*;
	import game.scenes.superPower.bathroomBoys.*;
	import game.scenes.superPower.bathroomGirls.*;
	import game.scenes.superPower.comic.*;
	import game.scenes.superPower.costume.*;
	import game.scenes.superPower.downtown.*;
	import game.scenes.superPower.junkyard.*;
	import game.scenes.superPower.mainStreet.*;
	import game.scenes.superPower.news.*;
	import game.scenes.superPower.park.*;
	import game.scenes.superPower.sewerEntrance.*;
	import game.scenes.superPower.sewerRoom.*;
	import game.scenes.superPower.skyscraper.*;
	import game.scenes.superPower.station.*;
	import game.scenes.superPower.subway.*;
	import game.data.island.IslandEvents;
	
	public class SuperPowerEvents extends IslandEvents
	{
		public function SuperPowerEvents()
		{
			super();
			super.scenes = [AdGroundH4,game.scenes.superPower.mainStreet.MainStreet,Bank,BathroomBoys,BathroomGirls,Comic,Costume,Downtown,Junkyard,News,Park,SewerEntrance,SewerRoom,Skyscraper,Station,Subway,];
		}

		// events
		public const BEAT_BOSS_:String  			= "beatBoss_";  // add number to end of string (total of 6 bosses)
		public const BEAT_EASY_BOSSES:String		= "beatEasyBosses";  // if you defeat all of the bosses you don't need powers for
		public const CAN_FLY:String					= "canFly";	// been to the phonebooth		
		
		// temporary events (not saved on server)
//		public const SHOWER_STARTED:String 		= "shower_started";
		
		// items
		public const ANTI_POWER_CUFFS:String 			= "antiPowerCuffs";
		public const HOTDOG:String 						= "hotdog";
		public const MEDALLION_SUPER:String 			= "medallionSuper";
		public const MEDALLION_SUPER_REPLAY:String 		= "medallionSuperReplay";
		public const SUPER_HERO_HANDBOOK:String			= "superHeroHandbook";
		public const SUPER_HERO_ID:String				= "superHeroID";
		public const SUPER_VILLAIN_FILES:String			= "superVillainFiles";
	}
}