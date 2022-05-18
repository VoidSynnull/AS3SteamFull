package game.managers.islandSetupCommands.browser
{
	import flash.utils.getQualifiedClassName;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.ads.AdvertisingConstants;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.data.profile.ProfileData;
	import game.managers.ProfileManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.util.ArrayUtils;
	import game.util.ProxyUtils;
	
	/**
	 * GetIslandDataFromServer - BROWSER SPECIFIC
	 * 
	 * Pulls the completed events and items from the server for a new island.  
	 * If events or items exist for the equivalent island in as2, reset them.  
	 */
	
	public class GetIslandDataFromServer extends CommandStep
	{
		public function GetIslandDataFromServer(profileData:ProfileData, island:String, shellApi:ShellApi, newIsland:Boolean)
		{
			super();
			
			_profileData = profileData;
			_island = island;
			_shellApi = shellApi;
			_newIsland = newIsland;
		}
		
		override public function execute():void
		{
			// if entering a new island and user is not guest, then retrieve data from server
			// RLH: skip if island is Custom
			if( (_newIsland) && (null != _profileData.login) && (!_profileData.isGuest) && (_island != AdvertisingConstants.AD_ISLAND) )
			{
				// If there is a login name and not a guest...
				// first we must reset any as2 events for a converted island if they exist.  Next we restore as3 events for an island.
				checkForAS2IslandDataFromServer();
			}
			else
			{
				super.complete();
			}
		}
		
		/**
		 * Check server to see if player have data from the AS2 version of the current island 
		 */
		private function checkForAS2IslandDataFromServer():void
		{
			// request possible data from AS2 version of island
			// TODO :: Shouldn't we know which islands even applies?  Might be able to skip this step entirely. - bard
			var req:DataStoreRequest = PopDataStoreRequest.islandInfoRetrievalRequest([_island], true);
			req.requestTimeoutMillis = 1000;
			(_shellApi.siteProxy as IDataStore2).call(req, resetAS2IslandData);
		}
		
		/**
		 * Callback from server query regarding player having data from the AS2 version of the current island
		 * @param result
		 */
		private function resetAS2IslandData(result:PopResponse):void
		{
			if (result.succeeded) {
				ArrayUtils.traceObject(result.data, "GetIslandDataFromServer :: AS2 Island Info : ");
			
				// see if data was available from AS2 island
				if (result.data != null && result.data.hasOwnProperty('events') != null) 
				{
					var as2Island:String = ProxyUtils.convertIslandToAS2Format(_island);
					if (result.data.events.hasOwnProperty(as2Island)) 
					{
						// only reset if the as2 equivalent of an island has saved data.
						if(result.data.events[as2Island])
						{
							trace( this,":: resetAS2IslandData :: events for AS2 island found.");
							_shellApi.resetIsland(_island, restoreIslandDataFromServer, DataStoreProxyPopBrowser.RESET_AS2_ISLAND );
							return;
						}
					}
				}
				trace( this,":: resetAS2IslandData :: NO events for AS2 island found.");
			} else {	// PopResponse was not successful
				trace("GetIslandDataFromServer::resetAS2IslandData() NO REPLY was received after one second", result);
			}

			restoreIslandDataFromServer();
		}
		
		private function restoreIslandDataFromServer(...args):void
		{
			trace( this,":: restoreIslandDataFromServer.");
			var req:DataStoreRequest = PopDataStoreRequest.islandInfoRetrievalRequest([_island]);
			req.requestTimeoutMillis = 1000;
			//_shellApi.siteProxy.retrieve(PopDataStoreRequest.islandInfoRetrievalRequest([_island]), saveIslandDataFromServer);
			(_shellApi.siteProxy as IDataStore2).call(req, saveIslandDataFromServer);
		}
		
		private function saveIslandDataFromServer(result:PopResponse):void 
		{
			var currentIslandInventory:Array = new Array();
			var currentIslandEvents:Array = new Array();
			var profileManager:ProfileManager = _shellApi.profileManager;
			
			if (result.succeeded)
			{
				var islandServerFormat:String = ProxyUtils.convertIslandToServerFormat(_island);
				var event:String;
				
				// looks like we are getting fields back as well? If so we should update userfields at this point - bard˙
				ArrayUtils.traceObject(result.data, "GetIslandDataFromServer :: AS3 Island Info : ");
				
				if (result.data) 
				{
					if (result.data.hasOwnProperty('error'))
					{
						if (result.error) 
						{
							trace("GetIslandDataFromServer :: island info error", JSON.stringify(result));
						}
					}
					
					trace("GetIslandDataFromServer :: Saving island data for " + _island);
					
					// assign island events from server to active profile
					if (result.data.hasOwnProperty('events')) 
					{
						if (result.data.events.hasOwnProperty(islandServerFormat)) 
						{
							currentIslandEvents = result.data.events[islandServerFormat];
							
							for (var n:int = 0; n < currentIslandEvents.length; n++)
							{
								event = currentIslandEvents[n];
								currentIslandEvents[n] = event.slice(String(_island + "_").length);
								
								if(currentIslandEvents[n] == "as3_started")
								{
									currentIslandEvents[n] = GameEvent.STARTED;
								}
							}
							
							trace("GetIslandDataFromServer :: Adding events for : " + _island + " : " + currentIslandEvents);
						}
						
						if(currentIslandEvents.indexOf(GameEvent.STARTED) < 0)
						{
							_shellApi.completeEvent(GameEvent.STARTED);
							_shellApi.track("IslandStarted", _island);
							_shellApi.siteProxy.store(DataStoreRequest.islandStartStorageRequest(_island));
						}
					}
					
					// assign island items from server to active profile
					if (result.data.hasOwnProperty('items')) 
					{
						if (result.data.items.hasOwnProperty(islandServerFormat)) 
						{
							if (ProxyUtils.idToItemMap[_island])
							{
								var allIslandItems:* = result.data.items[islandServerFormat];	
								var itemId:String;
								
								for (var item:* in allIslandItems)	// check each key, key should be numeric server id of item
								{
									trace("GetIslandDataFromServer :: Looking up item int : " + item);
									
									// check item id against island's item map (this maps numeric id on server to textual ids used in code)
									if(ProxyUtils.idToItemMap[_island].hasOwnProperty(item))
									{
										itemId = String(ProxyUtils.idToItemMap[_island][item]);
										currentIslandEvents.push(GameEvent.GOT_ITEM + itemId);
										
										// if item value is '1' (from server) we currently possess the item.  
										// If value is '0' we once had the item but then got rid of it somehow (returned it, lost it, etc.)
										if ( Number(allIslandItems[item]) == 1 )	
										{
											currentIslandEvents.push(GameEvent.HAS_ITEM + itemId);
											currentIslandInventory.push(itemId);
										}
									}
								}
								trace("GetIslandDataFromServer :: Adding items for : " + _island + " : " + currentIslandInventory);
							}
							else
							{
								trace("Error : GetIslandDataFromServer :: No items map found for: " + _island);
							}
						}
						else
						{
							trace("GetIslandDataFromServer :: No items for island (Server Format): " + islandServerFormat);
						}		
					}
					else
					{
						trace("GetIslandDataFromServer :: No items data");
					}
					
					// assign island photos from server to active profile
					if (result.data.hasOwnProperty('photos')) 
					{
						if (result.data.photos.hasOwnProperty(islandServerFormat)) 
						{
							var allPhotos:Array = result.data.photos[islandServerFormat];
							
							_profileData.photos[_island] = allPhotos;
							
							trace("GetIslandDataFromServer :: Added photos for : " + islandServerFormat + " : " + allPhotos);
						}
					}
					
					if (result.data.hasOwnProperty('fields')) 
					{
						try
						{
							var values:* = result.data.fields;
							//trace("GetIslandDataFromServer :: The user fields for", _island, "are...");
							for(var key:* in values)
							{
								var value:* = values[key];
								//trace("Before JSON:", key, "=", value, "->", getQualifiedClassName(value));
								value = JSON.parse(value);
								//trace("After JSON:", key, "=", value, "->", getQualifiedClassName(value));
								_profileData.setUserField(key, value, _island);
							}
						} 
						catch(error:Error) 
						{
							trace("GetIslandDataFromServer :: UserField object is invalid somehow.");
						}
						
						// TODO :: Want to applies these, but I don't know the format they come in as - bard
						trace("TESTING :: GetIslandDataFromServer :: got userfields: " + result.data.fields);
					}
				}
				else
				{
					trace("WARNING :: GetIslandDataFromServer :: results contained no data.");
				}
			} else {	// PopResponse did not succeed
				trace("GetIslandDataFromServer::saveIslandDataFromServer() NO REPLY was received after one second", result);
			}
			
			// Assigned locally created Arrays to profile
			// TODO :: probably need to do validation here. - bard
			_profileData.items[_island] = currentIslandInventory;
			_profileData.events[_island] = currentIslandEvents;
			profileManager.save();
			
			super.complete();
		}
		
		private var _profileData:ProfileData;
		private var _island:String;
		private var _shellApi:ShellApi;
		private var _newIsland:Boolean;
	}
}
