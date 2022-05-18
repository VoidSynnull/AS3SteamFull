package game.scenes.cavern2
{
	import game.data.island.IslandEvents;
	import game.scenes.cavern2.palaceExterior.PalaceExterior;
	import game.scenes.cavern2.palaceInterior.PalaceInterior;
	import game.scenes.cavern2.tierTwo1.TierTwo1;
	import game.scenes.cavern2.tierTwo2.TierTwo2;
	import game.scenes.cavern2.tierTwo3.TierTwo3;

	public class Cavern2Events extends IslandEvents
	{
		public function Cavern2Events()
		{
			super();
			super.scenes = [TierTwo1, TierTwo2, TierTwo3, PalaceExterior, PalaceInterior];
			super.popups = [];
		}
		
		public const MOUTH_DROPPED:String			= "mouth_dropped";
	}
}