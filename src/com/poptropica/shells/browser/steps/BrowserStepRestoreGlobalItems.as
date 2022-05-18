package com.poptropica.shells.browser.steps
{
	import com.poptropica.AppConfig;
	import com.poptropica.shellSteps.shared.RestoreGlobalItems;
	
	import flash.net.SharedObject;
	import flash.net.URLVariables;
	
	import game.data.comm.PopResponse;
	import game.managers.ItemManager;
	import game.managers.ItemManagerPop;
	import game.managers.ProfileManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.GatewayConstants;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.ui.CardGroup;
	import game.util.ProxyUtils;
	
	public class BrowserStepRestoreGlobalItems extends RestoreGlobalItems
	{
		public static const ITEM_STATUS_GONE:int		= 0;
		public static const ITEM_STATUS_NORMAL:int		= 1;
		public static const ITEM_STATUS_RENTED:int		= 2;
		
		//// CONSTRUCTOR ////
		
		public function BrowserStepRestoreGlobalItems() 
		{
			super();
			stepDescription = "Restoring global items";
		}
		
		//// PROTECTED METHODS ////
		
		override protected function build():void
		{
			restoreGlobalItems(onGlobalItemsRetrieved);
		}
		
		//// PRIVATE METHODS ////
		
		private function restoreGlobalItems( callback:Function=null ):void 
		{
			// if guest, restore items from profile (profile should have already been updated from LSO)
			if (shellApi.profileManager.active.isGuest) 
			{
				super.restoreGlobalItemsFromProfile();
				if(callback) {
					callback(new PopResponse(GatewayConstants.AMFPHP_ALREADY_THERE, null, "No server data available for guest accounts. Use your existing values."));
				}
			}
			else	// if not guest, retrieve global items from server
			{
				restoreGlobalItemsFromServer(callback);
			}
		}
		
		private function restoreGlobalItemsFromServer(callback:Function=null):void
		{
			var canConnect:Boolean = shellApi.networkAvailable();
			if(canConnect)
			{
				trace("BrowserShell :: BrowserStepRestoreGlobalItems :: network IS available, retrieve global items form server.");
				var req:DataStoreRequest = PopDataStoreRequest.islandInfoRetrievalRequest(["Early", "Store", "Rental"], true);
				req.requestTimeoutMillis = 1000;
				(shellApi.siteProxy as IDataStore2).call(req, callback);
			}
			else
			{
				trace("BrowserShell :: BrowserStepRestoreGlobalItems :: network NOT available, cannot retrieve global items form server.");
				if(callback) {
					callback(new PopResponse(GatewayConstants.AMFPHP_PROBLEM, null, "Network is " + (canConnect ? '' : 'not') + " available."));
				}
			}
		}
		
		private function onGlobalItemsRetrieved(response:PopResponse):void
		{
			if (response.succeeded) {
				if (response.data) {
					updateItemManager(restoreCards(response.data));
				}
			} else {
				trace(GatewayConstants.resultNameForCode(response.status), ":", response.error);
			}
			
			built();
		}
		
		private function restoreCards(data:URLVariables):Array
		{
			function restoreConvertedCards(islandName:String, desiredStatus:int):void {
				if (data.items.hasOwnProperty(islandName))
				{
					trace("BrowserStepRestoreGlobalItems :: Island =", islandName);
					itemData = data.items[islandName];
					for (itemNumber in itemData)
					{
						trace("BrowserStepRestoreGlobalItems :: Item =", itemNumber, "Status =", itemData[itemNumber]);
						if (int(itemData[itemNumber]) == desiredStatus)
						{
							if (ItemManager.isStoreItemConverted(int(itemNumber)))
							{
								storeItems.push(itemNumber);
							}
						}
					}
				}
			}
			
			var profileManager:ProfileManager = shellApi.profileManager;
			var storeItems:Array = [];
			var campaignItems:Array = [];
			
			var itemData:Object;
			var itemNumber:String;
			
			if (data.hasOwnProperty('items')) 
			{
				trace("data properties");
				for (var itemType:String in data.items)
				{
					trace(itemType + " : " + data.items[itemType]);
				}
				
				restoreConvertedCards("Store", ITEM_STATUS_NORMAL);
				
				// NOTE :: rented items are store items acquired via membership - if membership ends, these items are lost
				if (profileManager.active.isMember) {
					restoreConvertedCards("Rental", ITEM_STATUS_RENTED);
				}
				// NOTE :: all campaign items are included with all islands, 
				// so we test an arbitrary island's items for campaign items
				trace("Admanager Ready: " + shellApi.adManager);
				
				if( shellApi.adManager != null )
				{
					if (data.items.hasOwnProperty('Early'))
					{
						trace("Early Items exist");
						itemData = data.items['Early'];
						// get current campaign cards from LSO
						var charLSO:SharedObject = ProxyUtils.as2lso;
						for (itemNumber in itemData)
						{
							trace("campaign Item: " + itemNumber);
							// if found in list of current campaign cards or if list if null (when guest)
							if ((charLSO.data.currentcampaigns == null) || (charLSO.data.currentcampaigns.indexOf(String(itemNumber)) != -1))
							{
								campaignItems.push(itemNumber);
							}
						}
					}
				}
			}
			return [storeItems, campaignItems];
		}
		
		private function updateItemManager(cardLists:Array):void
		{
			var storeItems:Array	= cardLists[0];
			var campaignItems:Array	= cardLists[1];
			// restore store items in ItemManager
			var itemManager:ItemManagerPop  = shellApi.itemManager as ItemManagerPop;
			itemManager.restoreSet( CardGroup.STORE, storeItems );
			itemManager.restoreSet( CardGroup.PETS, storeItems );
			
			// restore campaign items in ItemManager
			//AdManagerBrowser(shellApi.adManager).activeCampaignItems = campaignItems;
			trace("Campaign items: " + campaignItems);
			if (campaignItems.length != 0) 
			{
				itemManager.restoreSet( CardGroup.CUSTOM, campaignItems );
				// sync up LSO to match (fixes bug 16803 for when going to ad interior)
				(shellApi.siteProxy as DataStoreProxyPopBrowser).syncItemsToAS2LSO(CardGroup.CUSTOM);
			}
		}
	}
}
