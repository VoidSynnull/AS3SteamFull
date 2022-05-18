package com.poptropica.shells.browser.steps
{
	import com.poptropica.shellSteps.shared.GetFirstScene;
	
	import game.data.PlayerLocation;
	import game.data.comm.PopResponse;
	import game.data.game.GameData;
	import game.managers.ProfileManager;
	import game.managers.SceneManager;
	import game.managers.ads.AdManagerBrowser;
	import game.proxy.DataStoreRequest;
	import game.proxy.PopDataStoreRequest;
	import game.proxy.browser.AdProxyUtils;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;

	/**
	 * Determines what Scene game should open to first.
	 */
	public class BrowserStepGetFirstScene extends GetFirstScene
	{
		protected var initializingLogin:Boolean = false;
		
		public function BrowserStepGetFirstScene(initializingLogin:Boolean)
		{
			super();
			this.initializingLogin = initializingLogin;
			stepDescription = "Initializing first scene";
		}
		
		override protected function build():void
		{
			var profileManager:ProfileManager = shellApi.getManager(ProfileManager) as ProfileManager;
			var sceneManager:SceneManager = shellApi.getManager(SceneManager) as SceneManager;
			var gameData:GameData = sceneManager.gameData;
			var readyToAdvance:Boolean = true;
			
			// overrideScene used for testing or 'standalone' builds that should automatically launch a minigame.
			if (gameData.overrideScene) 
			{
				trace("Shell :: BrowserStepGetFirstScene : gamedata overrides scene", profileManager.active.scene, 'with', sceneManager.gameData.overrideScene);
				profileManager.active.scene = gameData.overrideScene;
				profileManager.save();
			}
			else if( PlatformUtils.inBrowser )	// request last scene data from server
			{
				var siteProxy:DataStoreProxyPopBrowser = shellApi.siteProxy as DataStoreProxyPopBrowser;

				// profileManager.active.scene is first set in ProfileManager restore()
				// if after login then force fetching from server
				// don't do this if player is guest
				if ( ((initializingLogin) || (profileManager.active.scene == null)) && (!profileManager.active.isGuest)) 
				{
					trace("Shell :: BrowserStepGetFirstScene : requesting last scene data from server, waiting on response.");
					var req:DataStoreRequest = PopDataStoreRequest.lastSceneRetrievalRequest();
					req.requestTimeoutMillis = 1000;
					(shellApi.siteProxy as DataStoreProxyPopBrowser).getScene(null, null, onLastAS3Scene);
					readyToAdvance = false;					// need to wait for server response before proceeding
				} 
				else
				{
					// if active scene reverted to default save change to profile
					if( !super.checkActiveSceneValid() )
					{
						// if not valid then assumes login
						clearCampaignData();
						profileManager.save();
					}
				}
			}
			else
			{
				// if active scene reverted to default save change to profile
				if( !super.checkActiveSceneValid() )
				{
					// if not valid then assumes login
					clearCampaignData();
					profileManager.save();
				}
			}
	
			if (readyToAdvance) 
			{
				getCampaignsFromLSO();
				built();
			}
		}
		
		private function clearCampaignData():void
		{
			if (!initializingLogin)
			{
				trace("BrowserShell :: BrowserStepGetFirstScene :: clean out campaign data if calling default scene.");
				AdProxyUtils.cleanOutCampaignData();
			}
		}
		
		private function getCampaignsFromLSO():void
		{
			if (!initializingLogin)
			{
				// this should follow any cleanup of campaign data
				trace("BrowserShell :: BrowserStepGetFirstScene :: get campaigns from LSO.");
				// get any campaigns from LSO if not desktop
				if (PlatformUtils.inBrowser)
				{
					AdManagerBrowser(shellApi.adManager).getCampaignsFromLSO();
				}
			}
		}
		
		/**
		 * Handler called after requesting last scene data from server, if found data is applied to ProfileManager.
		 * If response fails, defaults are used.
		 * @param result - PopResponse from server, if success contains data for settings panel
		 * 
		 * Example server response:
		 * {status:7, error:'', data:{"x":"1516","y":"475","scene_id":"854","status":7,"direction":"R","error":null,"island_name":"Carrot_as3","scene_name":"diner"}}
		 */
		private function onLastAS3Scene(result:PopResponse):void
		{
			/*
			Assert.assert(result.succeeded, "Scene lookup failed.");
			Assert.assert(result.data != null, "Result is null.");
			Assert.assert(!DataUtils.isNull(result.data.scene_name), "Scene name is null.");
			Assert.assert(!DataUtils.isNull(result.data.island_name), "Island name is null.");
			*/
			
			if (result.succeeded && result.data != null && !DataUtils.isNull(result.data.scene_name) && !DataUtils.isNull(result.data.island_name)) 
			{
				trace("Shell :: BrowserStepGetFirstScene : last scene data from server successfully received.");
				var profileManager:ProfileManager = shellApi.profileManager;
				
				// convert island name into AS3 format
				var islandName:String = result.data.island_name;
				// if AS2 scene
				if (islandName.indexOf("_as3") == -1)
				{
					islandName = ProxyUtils.AS3IslandNameFromAS2IslandName(islandName);
					//profileManager.active.previousIsland = ['pop://gameplay', islandName, result.data.scene_name, result.data.x, result.data.y].join('/');
				}
				else
				{
					islandName = ProxyUtils.convertIslandFromServerFormat(islandName);
					//profileManager.active.previousIsland = islandName;
				}
				profileManager.active.scene = ProxyUtils.getSceneClassName(result.data.scene_name, islandName);
				profileManager.active.lastX = result.data.x;
				profileManager.active.lastY = result.data.y;
				profileManager.active.lastDirection = result.data.direction == 'L' ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
				// save previous island to profile
				profileManager.active.previousIsland = islandName;
				if ( !super.checkActiveSceneValid() )
				{
					// if not valid then assumes login
					clearCampaignData();
				}
				profileManager.save();
			}
			else
			{
				if ( !super.checkActiveSceneValid() )
				{
					// if not valid then assumes login
					clearCampaignData();
				}
				trace(" ERROR :: Shell :: BrowserStepGetFirstScene : failed to receive valid last scene data from server.");
			}
			
			getCampaignsFromLSO();
			built();
		}
	}
}