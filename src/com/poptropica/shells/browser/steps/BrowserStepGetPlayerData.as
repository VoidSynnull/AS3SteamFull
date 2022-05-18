package com.poptropica.shells.browser.steps
{
	import com.poptropica.AppConfig;
	
	import flash.external.ExternalInterface;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	
	import engine.managers.FileManager;
	
	import game.data.PlayerLocation;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.managers.ItemManager;
	import game.managers.ProfileManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;

	/**
	 * Retrieves looks string & character name from server and applies to profileManager.
	 * @author umckiba
	 * 
	 */
	public class BrowserStepGetPlayerData extends ShellStep
	{
		private var islandsVisited:Array = [];
		private var numFilesCached:uint = 0;

		// get info embedded into the url vars with players look and name.
		public function BrowserStepGetPlayerData()
		{
			super();
			stepDescription = "Gathering remote profile data";
		}
		
		override protected function build():void
		{
			if (shellApi.profileManager.active.isGuest)
			{
				trace("Drew - Testing to try to reduce load times.");
				built();
			}
			if( shellApi.networkAvailable() && AppConfig.retrieveFromExternal )
			{
				trace("BrowserShell :: BrowserStepGetPlayerData :: network IS available, retrieve player look and name from server.");

				// make call to server for player look string and name
				// on result that data is applied to the active profile
				var req:DataStoreRequest = PopDataStoreRequest.avatarDataRetrievalRequest();
				req.requestTimeoutMillis = 1000;
				(shellApi.siteProxy as IDataStore2).call(req, onEmbedInfo);

				req = DataStoreRequest.islandCompletionsRetrievalRequest();
				(shellApi.siteProxy as IDataStore2).call(req, onIslandCompletions);
//trace("\nBEFORE WE GET started, let's have a look at your profile, eh?");
//trace(shellApi.profileManager.active);
			}
			else
			{
				trace("BrowserShell :: BrowserStepGetPlayerData :: network NOT available, cannot retrieve player look and name from server.");
				//Drew - Testing to try to reduce load times.
				built();
			}
		}
		
		/**
		 * Handler for PopResponse return from server, contain player look string an dname data.  
		 * @param response
		 */
		private function onEmbedInfo(response:PopResponse):void 
		{
			(shellApi.siteProxy as DataStoreProxyPopBrowser).onEmbedInfo(response);
		}

		private function onIslandCompletions(response:PopResponse):void
		{
			if (!response.succeeded) {
				trace("BrowserStepGetPlayerData::onIslandCompletions()", response.error);
			}
			var req:DataStoreRequest = DataStoreRequest.lastScenesRetrievalRequest();
			(shellApi.siteProxy as IDataStore2).call(req, onLastScenes);
		}

		private function onLastScenes(response:PopResponse):void
		{
			trace("BrowserStepGetPlayerData::onLastScenes()", response);
			if (response.succeeded) {
				var scenes:Array = response.data.scenes;
				trace(JSON.stringify(scenes));
//trace("\nwe got", scenes.length, "scenes for ya");
				var profileManager:ProfileManager = shellApi.profileManager;
				var profile:ProfileData = profileManager.active;
				var islandName:String;
				var initializer:Object;

				var lso:SharedObject = SharedObject.getLocal("char","/");
				lso.objectEncoding = ObjectEncoding.AMF0;
				if (lso.data.islandsVisited == null)
					lso.data.islandsVisited = [];

				for (var i:int=0; i<scenes.length; i++) {
//trace("When we get", scenes[i].island, "we really want", translateIslandName(scenes[i].island));
					var islandIsAS3:Boolean = ('_as3' == (scenes[i].island as String).slice(-4));
					islandName = translateIslandName(scenes[i].island);
					islandName = islandName.substr(0, 1).toLowerCase() + islandName.substr(1);
					
					//If the island we find isn't a valid game island (Haunted, LegendarySwords, whatever else), then don't try to do anything with it.
					var isInvalid:Boolean = shellApi.sceneManager.gameData.islands.indexOf(islandName) == -1;
					if (isInvalid || ('hub' == islandName && PlatformUtils.inBrowser))
					{
						continue;
					}
					
					initializer = {
						type:		PlayerLocation.AS3_TYPE,
						island:		islandName,
						scene:		ProxyUtils.getSceneClassName(scenes[i].scene, islandName),
						locX:		scenes[i].x,
						locY:		scenes[i].y,
						direction:	scenes[i].direction
					};
					if (!islandIsAS3) {
						//initializer.island	= scenes[i].island;
						initializer.type	= PlayerLocation.AS2_TYPE;
						initializer.scene	= scenes[i].scene;
					}
					profile.lastScene[islandName] = PlayerLocation.instanceFromInitializer(initializer);
					islandsVisited.push(scenes[i].island);

					// RLH: add visited islands to player LSO
					if (lso.data.islandsVisited.indexOf(islandName) == -1)
					{
						lso.data.islandsVisited.push(islandName);
					}

					shellApi.fileManager.cacheFile(shellApi.dataPrefix + 'scenes/' + islandName + '/island.xml', onCacheReady);
				}
				profileManager.save();
				lso.flush();
				if (0 == islandsVisited.length) {
					built();
				}
			} else {
				trace(response.error);
			}
		}

		private function onCacheReady(...args):void
		{
			//trace("\nyour xml is all cached", args, "!");
			if (++numFilesCached == islandsVisited.length) {
				shellApi.siteProxy.call(PopDataStoreRequest.islandInfoRetrievalRequest(islandsVisited, true), onIslandInfo);
			}
		}

		private function onIslandInfo(response:PopResponse):void
		{
trace("BrowserStepGetPlayerData::onIslandInfo()", response);
trace(JSON.stringify(response.data));
			if (response.succeeded)
			{
				if (response.data)
				{
					var fileManager:FileManager = shellApi.fileManager;
					var profileManager:ProfileManager = shellApi.profileManager;
					profileManager.buildingProfile = true;
					var profile:ProfileData = profileManager.active;
					var i:int;
					var islandNameServer:String;
					var islandIsAS2:Boolean;
					var AS3IslandName:String;
					var prefixLength:int;

					if (response.data.hasOwnProperty('events'))
					{
						for (islandNameServer in response.data.events)
						{
							islandIsAS2 = islandNameServer.substr(-4) != '_as3';
							
							AS3IslandName = translateIslandName(islandNameServer);
							prefixLength = islandIsAS2 ? islandNameServer.length + 1 : AS3IslandName.length + 1;
							trace("Events received for", AS3IslandName, "which was", islandNameServer);
							var serverEventList:Array = response.data.events[islandNameServer];
							var eventList:Array = [];
							for(i = 0; i < serverEventList.length; i++)
							{
								var eventServer:String = (serverEventList[i] as String);
								if (eventServer.substr(0,prefixLength) == AS3IslandName.toLowerCase() + '_') {
									eventServer = eventServer.substr(prefixLength);	// chop off the prefix <islandName>_
								}
								if ('as3_' == eventServer.substr(0,4)) {	// island started events will have an 'as3_' prefix which we don't want
									eventServer = eventServer.substr(4);
								}
								eventList.push(eventServer);
							}
//							trace("\t" + eventList);
//							trace("we should be merging this eventList with the existing events (if any) in ProfileData", profile.events, profile.events[AS3IslandName]);
							AS3IslandName = AS3IslandName.substr(0, 1).toLowerCase() + AS3IslandName.substr(1);
							profile.events[AS3IslandName] = mergeArrays(profile.events[AS3IslandName], eventList);
						}
						this.shellApi.gameEventManager.restore(profile.events);
					}

					var itemManager:ItemManager = shellApi.itemManager as ItemManager;

					if (response.data.hasOwnProperty('items')) {
						for (islandNameServer in response.data.items) {
							trace(islandNameServer);
							islandIsAS2 = islandNameServer.substr(-4) != '_as3';
							AS3IslandName = translateIslandName(islandNameServer);
							AS3IslandName = AS3IslandName.substr(0, 1).toLowerCase() + AS3IslandName.substr(1);
							var islandXML:XML = fileManager.getFile(fileManager.dataPrefix + 'scenes/' + AS3IslandName + '/island.xml', true);
							if (null == islandXML) {
								trace("No XML found for island", islandNameServer);
								continue;
							}
//trace(AS3IslandName, "island XML", islandXML);
							var itemMap:XMLList = islandXML.itemIdMap;
							prefixLength = islandIsAS2 ? islandNameServer.length + 1 : AS3IslandName.length + 1;
//trace("Items received for", AS3IslandName, "which was", p, "with map", itemMap.children().length());
							var itemList:Array = [];
							var itemCodes:Array = [];
							if (0 < itemMap.children().length()) {
								var itemData:Object = response.data.items[islandNameServer];
								for (var itemCode:String in itemData) {
									var itemName:String = itemNameFromID(itemCode, itemMap.children());
									if (itemName) {
										trace("player has: " + itemCode + " : " + itemName);
										itemList.push(itemName);
										itemCodes.push(itemData[itemCode]);
									} else {
										trace("BrowserStepGetPlayerData::onIslandInfo() WARNING: could not look up name of item with ID", itemCode);
									}
								}
							}
							var filteredItems:Array = generateEventsForItems(AS3IslandName, itemList, itemCodes);
//							trace("\t" + itemList);
//							trace("we should be merging this itemList with the existing items (if any) in ProfileData", profile.items, profile.items[AS3IslandName]);
							profile.items[AS3IslandName] = mergeArrays(profile.items[AS3IslandName], filteredItems);
						}
						this.shellApi.itemManager.restoreSets(profile.items);
					}
					
					profileManager.buildingProfile = false;
					shellApi.saveGame();					
				} 
				else 
				{
					trace("BrowserStepGetPlayerData::onIslandInfo() WARNING: bulk island info contained no data");
				}
			} 
			else 
			{
				trace("BrowserStepGetPlayerData::onIslandInfo() WARNING: couldn't retrieve bulk island info.", response.error);
			}
//trace("\nNOW THAT WE'RE done, your profile looks like this");
//trace(profile);
			built();
		}

		private function generateEventsForItems(islandName:String, items:Array, codes:Array):Array
		{
//			var itemManager:IItemManager = shellApi.itemManager;
//			var eventManager:GameEventManager = shellApi.gameEventManager;
			var theItems:Array = [];

			if (items.length != codes.length) {
				trace("ERROR: we have", items.length, "items and", codes.length, "codes. And that just ain't right.");
				return theItems;
			}

			for (var i:int=0; i<items.length; i++) {
				var theItem:String = items[i];
				if (!isNaN(parseInt(theItem))) {	// remove numeric item names
					continue;
				}
				var theCode:String = codes[i];

//				trace("code is", theCode + ',', "event is gotItem_" + theItem);
				shellApi.getItem(theItem, islandName);
				if (theCode == '0') {
//					trace("event loses hasItem_" + theItem);
					shellApi.removeItem(theItem, islandName);
				} else theItems.push(theItem);
			}
			return theItems;
		}

		private function itemNameFromID(ID:String, mapItems:XMLList):String
		{
			var numericID:Number = DataUtils.getNumber(ID);
			if (!isNaN(numericID)) {
				// if the ID is 2000–2999, this is a 'limited' card whose XML data file is named numerically
				if ((1999 < numericID) && (3000 > numericID)) {
					return ID;
				}
				//how bout store cards? in the 3000s
			}
			for each (var mapItem:XML in mapItems) {
				if (mapItem.text() == ID) {
					return mapItem.attribute('id');
				}
			}
			return null;
		}

		private function translateIslandName(serverName:String):String
		{
			var s:String = serverName.toLowerCase();
			if ('_as3' == serverName.substr(-4)) {
				s = s.slice(0, -4);
			}
			return ProxyUtils.AS3IslandNameFromAS2IslandName(s);
		}

		private function mergeArrays(a1:Array, a2:Array):Array {
			if (null == a1) {
				return a2 ? a2 : [];
			}
			if (null == a2) {
				return a1;
			}
			var merged:Array = a1.concat(a2);	// this concatenation may have dupes (we hate dupes)

			var valueSet:Object = {};			// converting the array items to object properties will filter the dupes
			var numValues:int = merged.length;
			for (var i:int=0; i<numValues; i++) {
				valueSet[merged[i]] = 1;	// we don't care about the one value at all
			}

			var result:Array = [];			// convert the object back into an array, we don't need any sorting
			for (var p:String in valueSet) {
				result.push(p);
			}
			return result;
		}

	}
}
