package game.manifest.browser
{
	import com.poptropica.AppConfig;
	
	import game.manifest.DynamicallyLoadedClassManifest;
	import game.scenes.americanGirl.AmericanGirlEvents;
	import game.scenes.arab1.Arab1Events;
	import game.scenes.arab2.Arab2Events;
	import game.scenes.arab3.Arab3Events;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.cavern2.Cavern2Events;
	import game.scenes.con1.Con1Events;
	import game.scenes.con2.Con2Events;
	import game.scenes.con3.Con3Events;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.examples.ExamplesEvents;
	import game.scenes.ftue.FtueEvents;
	import game.scenes.gameJam.GameJamEvents;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.scenes.ghd.GhdEvents;
	import game.scenes.lands.LandsEvents;
	import game.scenes.lego.LegoEvents;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.myth.MythEvents;
	import game.scenes.photoBoothIsland.PhotoBoothIslandEvents;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.scenes.prison.PrisonEvents;
	import game.scenes.reality2.Reality2Events;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.start.StartEvents;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival5.Survival5Events;
	import game.scenes.testIsland.TestIslandEvents;
	import game.scenes.time.TimeEvents;
	import game.scenes.timmy.TimmyEvents;
	import game.scenes.viking.VikingEvents;
	import game.scenes.virusHunter.VirusHunterEvents;
	
	public class ClassManifestBrowser extends DynamicallyLoadedClassManifest
	{
		override protected function initEvents():Array
		{
			var events:Array = super.init();
			events.concat([
				AmericanGirlEvents,
				Arab1Events, 
				Arab2Events,
				Arab3Events,
				CarnivalEvents, 
				CarrotEvents,
				Cavern2Events,
				Con1Events, 
				Con2Events,
				Con3Events,
				DeepDive1Events, 
				DeepDive2Events, 
				DeepDive3Events,
				FtueEvents,
				GalacticHotDogEvents,
				GhdEvents,
				GameJamEvents,
				LandsEvents,
				LegoEvents,
				MocktropicaEvents, 
				MythEvents, 
				PoptropolisEvents,
				PrisonEvents,
				Reality2Events,
				ShrinkEvents,
				StartEvents,
				Survival1Events, 
				Survival2Events, 
				Survival3Events, 
				Survival4Events, 
				Survival5Events,
				TimeEvents, 
				VikingEvents,
				VirusHunterEvents, 
				TimmyEvents,
				PhotoBoothIslandEvents]);
			
			if( AppConfig.debug )
			{
				events.concat([ExamplesEvents, TestIslandEvents])
			}
			
			return(events);
		}
	}
}