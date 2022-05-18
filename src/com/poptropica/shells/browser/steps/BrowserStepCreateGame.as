package com.poptropica.shells.browser.steps
{
	import com.poptropica.shells.shared.steps.CreateGamePop;
	
	import game.managers.PhotoManager;
	import game.managers.browser.IslandManagerBrowser;
	import game.managers.interfaces.IIslandManager;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.DoorGroupPop;
	import game.ui.hud.HudPopBrowser;
	import game.util.ProxyUtils;

	public class BrowserStepCreateGame extends CreateGamePop
	{
		// create game classes for scenes
		public function BrowserStepCreateGame()
		{
			super();
			stepDescription = "Creating game systems";
		}
		
		override protected function build():void
		{
			// Checks browser URL for parameter 'overrideScene' which allows the start up scene to be overridden with given scene
			trace("loader parameters for shell: " + shell.params);
			if(shell.params)
			{
				if (shell.params.hasOwnProperty("overrideScene"))
				{
					shellApi.sceneManager.gameData.overrideScene = unescape(shell.params.overrideScene);
					trace("overrideScene: " + shellApi.sceneManager.gameData.overrideScene);
				}
			}
			//shellApi.sceneManager.gameData.overrideScene = "game.scenes.mocktropica.megaFightingBots.MegaFightingBots";

			// add managers specific to Browser
			var islandManager:IslandManagerBrowser = this.shellApi.addManager(new IslandManagerBrowser(), IIslandManager) as IslandManagerBrowser;
			islandManager.gameData = shellApi.sceneManager.gameData;
			islandManager.hudGroupClass = HudPopBrowser;
			islandManager.doorGroupClass = DoorGroupPop;
			
			shellApi.addManager(new PhotoManager());	// QUESTION :: photos only available in browser?
			
			this.shellApi.photoManager.restore(this.shellApi.profileManager.active.photos);
			shellApi.profileManager.updateCredits();	// Update the user's credits field

			// set ShellApi to check on server connection on interval
			(shellApi.siteProxy as DataStoreProxyPopBrowser).setupLogoutTimeout();
			
			// add standard game managers that are shared across platforms IF we don't override them here.
			super.addManagers();
			super.createDevTools();
			
			built();
		}
	}
}
