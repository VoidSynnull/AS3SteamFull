package com.poptropica.shells.browser.steps
{
	import com.poptropica.AppConfig;
	
	import flash.net.SharedObject;
	
	import game.data.PlayerLocation;
	import game.data.character.LookConverter;
	import game.data.character.part.PartKeyLibrary;
	import game.data.profile.ProfileData;
	import game.managers.ProfileManager;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.util.ProxyUtils;

	public class BrowserStepSyncProfileFromLSO extends ShellStep
	{
		// use data from as2 lso to populate active profile, only used in browser
		public function BrowserStepSyncProfileFromLSO()
		{
			super();
			stepDescription = "Gathering local profile data";
		}
		
		override protected function build():void
		{
			if( shellApi.networkAvailable() && AppConfig.retrieveFromExternal && !shellApi.profileManager.active.isGuest)
			{
				trace("BrowserShell :: BrowserStepSyncProfileFromLSO :: sync profile from as2LSO.");
				syncActiveProfileFromLSO(shellApi.profileManager, (shellApi.siteProxy as DataStoreProxyPopBrowser).partKeyLibrary );
				shellApi.profileManager.save();
			}
			else
			{
				trace("BrowserShell :: BrowserStepSyncProfileFromLSO :: network NOT available, skip profile sync from as2LSO.");
			}
			
			built();
		}

		/**
		 * Pulls in properties from as2 lso and transit token that are coming from the as2 site and stores them in the active profile. 
		 * Uses data from as2 lso to populate active profile.
		 * @param profileManager
		 * @param adManager
		 * @param partKeyLibrary
		 */
		private function syncActiveProfileFromLSO( profileManager:ProfileManager, partKeyLibrary:PartKeyLibrary ):void
		{
			var charLSO:SharedObject = ProxyUtils.as2lso;
			var profile:ProfileData = profileManager.active;
			
			// define player profile from lso data
			
			ProfileManager.fillOutGeneralData(profile, charLSO.data);
			
			// suppress token stuff
			//profile.pass_hash = transitTokenLSO.data.pass_hash;
			//profile.dbid = transitTokenLSO.data.dbid;
			//profile.login = transitTokenLSO.data.login;

			ProfileManager.syncScores(charLSO.data, profile);

			// suppress transit token
			/*
			analyzeOrigin(charLSO.data, transitTokenLSO.data, profile);

			if(transitTokenLSO.data.look != null)
			{
				var lookConverter:LookConverter = new LookConverter();
				// Including test look values against partKey to identify frames that need to be converted to labels
				profile.look = lookConverter.playerLookFromLookString(shellApi, transitTokenLSO.data.look, null, partKeyLibrary, profile );
				trace("AS3Embassy :: restoring player look from lso : "+ profile.look);
				// TODO :: Add special ability converter
			}
			*/
			
			// assign tribe 
			// TODO :: Would like to move tribe out of userData field and assign a specific entry, probably never going to happen - bard
			
			ProfileManager.fillOutUserData(profile, charLSO.data);

			ProfileManager.fillOutInventory(profile, charLSO.data, shellApi);
		}

		private function analyzeOrigin(char:Object, token:Object, profile:ProfileData):void
		{
			if (!(char.last_island && char.last_room)) {
				return;
			}
			var firstChar:Number = (char.last_island as String).charCodeAt(0);
			var firstLetterIsUppercase:Boolean = 64 < firstChar && firstChar < 91;
			var islandNameStyleIsAS2:Boolean = ((char.last_island as String).slice(-4) == '_as3') || firstLetterIsUppercase;

			var fromAS2:Boolean = islandNameStyleIsAS2 ? (char.last_island as String).slice(-4) != '_as3' : ProxyUtils.isAS2Island(char.last_island);
 			trace('\n><><><><><><><><><><><><><><><    CHAR');
 			trace(' last_room', char.last_room);
 			trace(' last_island', char.last_island, 'AS' + (fromAS2 ? '2' : '3'));
 			trace(' r2g', char.r2g);
 			trace('><><><><><><><><><><><><><><><    TOKEN');
 			trace(' prevSection', token.prevSection);
 			trace(' prevIsland', token.prevIsland);
 			trace(' prevScene', token.prevScene);
 			trace(' nextSection', token.nextSection);
 			trace(' nextIsland', token.nextIsland);
 			trace(' nextScene', token.nextScene);
 			trace(' punched', token.punched);
 			trace('><><><><><><><><><><><><><><><    PROFILE');
 			trace(' previousIsle', profile.previousIsland);
 			trace('><><><><><><><><><><><><><><><');

			if (fromAS2) {
				if ('Hub' != char.last_island) {
					if ('Home' != char.last_island) {
						if ('Home' != char.last_room) {
							profile.previousIsland = ['pop://gameplay', char.last_island, char.last_room, char.last_x, char.last_y].join('/');
							profile.lastScene[char.last_island] = PlayerLocation.instanceFromPopURL(profile.previousIsland);
						}
					}
				}
			} else {
				var islandName:String = islandNameStyleIsAS2 ? ProxyUtils.convertIslandFromServerFormat(char.last_island) : char.last_island;
				profile.previousIsland = islandName;
				var sceneName:String = char.last_room;
				if (sceneName.indexOf('.') == -1) {		// class names lacking dots are not fully qualified, so spell it out
					//sceneName = "game.scenes." + islandName + '.' + sceneName + '::' + StringUtil.UCFirst(sceneName);
					sceneName = ProxyUtils.getSceneClassName(sceneName, islandName);
				}
				profile.lastScene[islandName] = PlayerLocation.instanceFromInitializer(
					 {type:PlayerLocation.AS3_TYPE, island:islandName, scene:sceneName, locX:char.last_x, locY:char.last_y}
				);
			}

			trace("your previous island has been set to", profile.previousIsland);
		}
			
	}
}
