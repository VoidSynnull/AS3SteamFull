package game.scenes.trade
{
	import game.scenes.trade.brokenBarrel.BrokenBarrel;
	import game.scenes.trade.caribbeanInterior.CaribbeanInterior;
	import game.scenes.trade.caribbeanPort.CaribbeanPort;
	import game.scenes.trade.chinaInterior.ChinaInterior;
	import game.scenes.trade.chinaPort.ChinaPort;
	import game.scenes.trade.governor.Governor;
	import game.scenes.trade.mainStreet.MainStreet;
	import game.scenes.trade.mainStreet2.MainStreet2;
	import game.scenes.trade.moroccanInterior.MoroccanInterior;
	import game.scenes.trade.moroccanPort.MoroccanPort;
	import game.scenes.trade.orleansInterior.OrleansInterior;
	import game.scenes.trade.orleansPort.OrleansPort;
	import game.scenes.trade.outpostInterior.OutpostInterior;
	import game.scenes.trade.outpostPort.OutpostPort;
	import game.scenes.trade.tradeStore.TradeStore;
	import game.scenes.trade.treasurePort.TreasurePort;
	import game.data.island.IslandEvents;
		
	public class TradeEvents extends IslandEvents
	{
		public function TradeEvents()
		{
			super();
			super.scenes = [ BrokenBarrel,CaribbeanInterior,CaribbeanPort,ChinaInterior,ChinaPort,Governor,MainStreet,MainStreet2,
				MoroccanInterior,MoroccanPort,OrleansInterior,OrleansPort,OutpostInterior,OutpostPort,TradeStore,TreasurePort];
		}
		
		public const ASK_FOR_FEED:String = "ask_for_feed";
		
		public const MEDAL_SKULLDUGGERY:String = "medalSkullduggery";	
		public const CHICKEN:String = "chicken";		
		public const FEEDBAG:String = "feedbag";
		public const DOUBLOON:String = "doubloon";
		public const MIRROR:String = "mirror";
		public const MALLET:String = "mallet";
		public const CRACKER:String = "cracker";
		public const ARCHIPELAGO_MAP:String = "archipelagoMap";
		public const TREASURE_MAP:String = "treasureMap";
		public const CANNON_STARTER_KIT:String = "cannonStarterKit";
		public const SHOVEL:String = "shovel";
		public const CANDLE:String = "candle";
		

	}
}