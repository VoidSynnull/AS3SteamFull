package com.poptropica.shells.browser.steps
{
	import com.poptropica.shells.shared.steps.SetupCampaigns;
	
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerBrowser;
	import game.managers.interfaces.IAdManager;
	
	public class BrowserStepSetupCampaigns extends SetupCampaigns
	{
		public function BrowserStepSetupCampaigns()
		{
			super();
			stepDescription = "Setting up ad campaigns";
		}
		
		/**
		 * Create ad manager for browser
		 * @return AdManagerBrowser
		 */
		override protected function createAdManager():AdManager
		{
			return shellApi.addManager(new AdManagerBrowser(), IAdManager) as AdManagerBrowser;
		}	
	}
}