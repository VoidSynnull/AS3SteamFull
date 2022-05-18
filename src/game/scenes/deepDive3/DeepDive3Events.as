package game.scenes.deepDive3
{
	import game.data.island.IslandEvents;
	import game.scenes.deepDive3.adMixed1.AdMixed1;
	import game.scenes.deepDive3.adMixed2.AdMixed2;
	import game.scenes.deepDive3.adStreet3.AdStreet3;
	import game.scenes.deepDive3.cargoBay.CargoBay;
	import game.scenes.deepDive3.cockpit.Cockpit;
	import game.scenes.deepDive3.outro.Outro;
	import game.scenes.deepDive3.laboratory.Laboratory;
	import game.scenes.deepDive3.livingQuarters.LivingQuarters;
	import game.scenes.deepDive3.mainDeck.MainDeck;
	import game.scenes.deepDive3.moduleGroupTest.ModuleGroupTest;
	import game.scenes.deepDive3.sceneObjectTest.SceneObjectTest;
	import game.scenes.deepDive3.shared.popups.IntroPopup;
	import game.scenes.deepDive3.ship.Ship;
	import game.scenes.deepDive3.ship.VictoryPopup;
	
	public class DeepDive3Events extends IslandEvents
	{
		// permanent events
		public const LAB_CREATURE_REVEALED:String 	= "lab_creature_revealed";
		public const LAB_CREATURES:String 			= "lab_creatures";
		public const ENTERED_CARGO_BAY:String 		= "entered_cargo_bay";		//entered cargo bay scene and saw door close
		public const HEARD_ALIEN_IN_CB:String 		= "heard_alien_in_cb";		//heard the alien communication in cargo bay
		public const SPOKE_WITH_AI:String 			= "spoke_with_ai";			//spoke with ai in cockpit, told to exit ship
		public const SPOKE_WITH_CAM:String 			= "spoke_with_cam";			//spoke with Cam on ship
		public const FINAL_CUTSCENE:String			= "final_cutscene";			// played final cutscene
		// power stages
		public const STAGE_1_ACTIVE:String 			= "stage_1_active";
		public const STAGE_2_ACTIVE:String 			= "stage_2_active";
		public const STAGE_3_ACTIVE:String 			= "stage_3_active";
		public const COCKPIT_UNLOCKED:String 		= "cockpit_unlocked";
		
		// group events
		
		
		// items
		public const ATLANTIS_CAPTAIN:String		= "atlantis_captain";
		public const MEDAL_DEEPDIVE3:String 		= "medal_atlantis3";
		
		public function DeepDive3Events()
		{
			super();
			super.scenes = [SceneObjectTest, ModuleGroupTest, LivingQuarters, Laboratory, CargoBay, Cockpit, MainDeck, AdMixed1, AdMixed2, AdStreet3, Ship, Outro];
			super.popups = [IntroPopup, VictoryPopup];
			var overlays:Array = [];
			
			this.island = "deepDive3";
			this.nextEpisodeEvents;
			this.accessible = true;
			this.earlyAccess = false;
		}
	}
}