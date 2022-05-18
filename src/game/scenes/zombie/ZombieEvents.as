package game.scenes.zombie
{
	import game.scenes.zombie.adGroundH27.AdGroundH27;
	import game.scenes.zombie.brownstone.Brownstone;
	import game.scenes.zombie.bunkerFPS.BunkerFPS;
	import game.scenes.zombie.carrots.Carrots;
	import game.scenes.zombie.chinatown.Chinatown;
	import game.scenes.zombie.common.Common;
	import game.scenes.zombie.financial.Financial;
	import game.scenes.zombie.fruitContainer.FruitContainer;
	import game.scenes.zombie.gamerApartment.GamerApartment;
	import game.scenes.zombie.karaokeBar.KaraokeBar;
	import game.scenes.zombie.mainStreet.MainStreet;
	import game.scenes.zombie.puddyApartment.PuddyApartment;
	import game.scenes.zombie.romeroApartment.RomeroApartment;
	import game.scenes.zombie.romerosBunker.RomerosBunker;
	import game.scenes.zombie.sewerDay2.SewerDay2;
	import game.scenes.zombie.shadySide.ShadySide;
	import game.scenes.zombie.smoothieShop.SmoothieShop;
	import game.scenes.zombie.subway.Subway;
	import game.scenes.zombie.subwayBunker.SubwayBunker;
	import game.scenes.zombie.subwayFinancial.SubwayFinancial;
	import game.scenes.zombie.subwayInterior.SubwayInterior;
	import game.scenes.zombie.subwayWharf.SubwayWharf;
	import game.scenes.zombie.survivalistsBunker.SurvivalistsBunker;
	import game.scenes.zombie.tunnel.Tunnel;
	import game.scenes.zombie.wharf.Wharf;
	import game.data.island.IslandEvents;

	public class ZombieEvents extends IslandEvents
	{
		public function ZombieEvents()
		{
			super();
			super.scenes = [AdGroundH27, BunkerFPS, Brownstone, Carrots, Chinatown, Common, Financial, FruitContainer, GamerApartment, KaraokeBar, MainStreet, PuddyApartment, RomeroApartment, RomerosBunker, SewerDay2, ShadySide, SmoothieShop, Subway, SubwayBunker, SubwayFinancial, SubwayInterior, SubwayWharf, SurvivalistsBunker, Tunnel, Wharf];
		}
		
		// events
		
		// temporary events
		
		// items
	}
}