package game.scenes.spy
{
	import game.scenes.spy.adGroundH5.AdGroundH5;
	import game.scenes.spy.attic.Attic;
	import game.scenes.spy.bistro.Bistro;
	import game.scenes.spy.control.Control;
	import game.scenes.spy.controlInterior.ControlInterior;
	import game.scenes.spy.docks.Docks;
	import game.scenes.spy.docksInterior.DocksInterior;
	import game.scenes.spy.greenhouse.Greenhouse;
	import game.scenes.spy.hairClub.HairClub;
	import game.scenes.spy.headquarters.Headquarters;
	import game.scenes.spy.mainStreet.MainStreet;
	import game.scenes.spy.mansion.Mansion;
	import game.scenes.spy.satellite.Satellite;
	import game.scenes.spy.spyTowers1.SpyTowers1;
	import game.scenes.spy.spyTowers2.SpyTowers2;
	import game.scenes.spy.spyglass.Spyglass;
	import game.data.island.IslandEvents;
	
	public class SpyEvents extends IslandEvents
	{
		public function SpyEvents()
		{
			super();
			super.scenes = [AdGroundH5, Attic, Bistro, Control, ControlInterior, Docks, DocksInterior, Greenhouse, HairClub, Headquarters, MainStreet, Mansion, Satellite, Spyglass, SpyTowers1, SpyTowers2];
		}
	}
}