package com.poptropica.shells.browser.steps
{
	import flash.external.ExternalInterface;
	
	import com.poptropica.shellSteps.shared.StartGame;
	
	import game.data.ads.AdvertisingConstants;
	import game.managers.ProfileManager;

	public class BrowserStepStartGame extends StartGame
	{
		public function BrowserStepStartGame()
		{
			super();
			stepDescription = "Starting game";
		}
		
		override protected function build():void
		{
			this.shell._tickProvider.start();
			
			// CMG ads
			/*
			if (shellApi.cmg_iframe)
			{
				AppConfig.adsActive = false;
			}
			*/
			
			// load playwire wrappers
			if (ExternalInterface.available){
				ExternalInterface.call("loadPWWrappers");
			}
			this.shellApi.screenManager.setSize();
			// check whether the first scene is an ad interior scene, such as coming from an AS2 ad door
			checkForAdInteriorScene();
			
			super.loadFirstScene();
			built();
		}
		
		private function checkForAdInteriorScene():void
		{
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			if (profileManager.active.scene) 
			{
				// if scene has ad delimiter, then ad interior scene
				// example: game.scenes.custom.questInterior.QuestInterior|campaignScene=GalacticHotDogsQuest_Interior&entrance=true
				// newer code only requires game.scenes.custom.questInterior.QuestInterior but must use above for legacy apps
				var dest:Array = profileManager.active.scene.split(AdvertisingConstants.CAMPAIGN_SCENE_DELIMITER);
				if (dest.length > 1)
				{
					// force scene to first array item
					profileManager.active.scene = dest[0];
				}
			}
		}
	}
}