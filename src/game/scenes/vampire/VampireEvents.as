package game.scenes.vampire
{
	import game.scenes.vampire.adGroundH20.AdGroundH20;
	import game.scenes.vampire.armory.Armory;
	import game.scenes.vampire.attic.Attic;
	import game.scenes.vampire.castle.Castle;
	import game.scenes.vampire.castleGrounds.CastleGrounds;
	import game.scenes.vampire.castleTowers.CastleTowers;
	import game.scenes.vampire.cave.Cave;
	import game.scenes.vampire.cliff.Cliff;
	import game.scenes.vampire.common.Common;
	import game.scenes.vampire.countsChamber.CountsChamber;
	import game.scenes.vampire.greatHall.GreatHall;
	import game.scenes.vampire.laboratory.Laboratory;
	import game.scenes.vampire.mainStreet.MainStreet;
	import game.scenes.vampire.mausoleum.Mausoleum;
	import game.scenes.vampire.secondMausoleum.SecondMausoleum;
	import game.data.island.IslandEvents;

	public class VampireEvents extends IslandEvents
	{
		public function VampireEvents()
		{
			super();
			super.scenes = [AdGroundH20, Armory, Attic, Castle, CastleGrounds, CastleTowers, Common, Cliff, Cave, CountsChamber, GreatHall, Laboratory, Mausoleum, MainStreet, SecondMausoleum];
		}
		
		// events
		public const BOARDS_OPENED:String			= "boards_open";
		
		// temporary events
		public const BOARDS_OPENING:String 	= "boards_openning";
		public const BOARDS_ATTEMPT_OPEN:String 	= "boards_attempt_open";
		
		// items
		public const CROWBAR:String = "crowbar";
		public const BUCKET:String = "bucket";
		public const FILLED_BUCKET:String = "filled_bucket";
		public const CROSSBOW:String = "crossbow";
		public const VAMPIRE_NOVEL:String = "vampire_novel";
		public const ARMORY_KEY:String = "armory_key";
		public const CAGE_KEY:String = "cage_key";
		public const BRAMS_NOTEBOOK:String = "brams_notebook";
		public const GARLIC:String = "garlic";
		public const MANDRAKE:String = "mandrake";
		public const WOLFSBANE:String = "wolfsbane";
		public const ROOT_CAUSE:String = "root_cause";
		public const ANTI_VAMPIRE_SERUM:String = "anti_vampire_serum";
		public const GLASS_EYE:String = "glass_eye";
	}
}