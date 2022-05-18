package game.managers
{
	/**
	 * A class to track items in a users inventory.  This class should not be used directly but accessed through ShellApi.
	 */
	
	import com.poptropica.AppConfig;
	
	import flash.utils.Dictionary;
	
	import game.data.TrackingEvents;
	import game.data.ads.AdvertisingConstants;
	import game.data.game.GameEvent;
	import game.data.ui.card.CardSet;
	import game.managers.ads.AdManager;
	import game.proxy.DataStoreRequest;
	import game.scene.template.ItemGroup;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	
	public class ItemManagerPop extends ItemManager
	{
		override protected function init():void
		{
			addSet( CardGroup.STORE );
			addSet( CardGroup.PETS);
			addSet( CardGroup.CUSTOM );
		}
		
		///////////////////////////////////////// SCENE METHODS  /////////////////////////////////////////
		
		/**
		 * Get an item.
		 * @param   item : The id of the item, can be an int or String.
		 * @param   [type] : The card type to add the item to.  Defaults to the current island.
		 * @param	showCard : optionally show the item's card
		 */
		override public function getItem(item:*, type:String = null, showCard:Boolean = false, showCompleteCallback:Function = null):Boolean
		{
			// if card type not specified, determine type based on item
			if ( !DataUtils.validString(type) ) { type = determineType( item ); } 

			// RLH: if custom set is missing, then add it
			if (type == CardGroup.CUSTOM)
			{
				if (getSet( CardGroup.CUSTOM ) == null)
					addSet( CardGroup.CUSTOM );
			}
			
			// strip off preceding "item" if in form "item2XXX" for custom cards
			if (String(item).substr(0,5) == "item2")
				item = String(item).substr(4);
			
			trace("ItemManagerPop: getItem: " + item);
			
			if (!checkHas(item, type)) 					// check that item is not already owned 
			{	
				if( checkValidItem( item, type ) )		// check that item is valid for specified type
				{
					trace("ItemManagerPop: getItem valid: " + item);
					
					add( String(item), type ) 			// Add item to ItemManager.
					
					if (shellApi.needToStoreOnServer())		// attempt save item to server
					{
						if (!shellApi.profileManager.buildingProfile) 
						{
							shellApi.siteProxy.store(DataStoreRequest.itemGainedStorageRequest(item, type));	// Add item to user inventory on server.  Converts to an int for island items.
						}
					}
					
					// trigger events associated with item
					shellApi.gameEventManager.trigger(GameEvent.GET_ITEM + item, type, false);
					shellApi.gameEventManager.trigger(GameEvent.GOT_ITEM + item, type, true);
					shellApi.gameEventManager.trigger(GameEvent.HAS_ITEM + item, type, true);
					
					// notify ProfileManager that a new card has been received, ignore if pet card 6000-6099
					// pet accessory card is handled normally
					var itemNum:Number = Number(item);
					if ((itemNum < 6000) || (itemNum > 6099))
					{
						shellApi.profileManager.inventoryType = type;
						shellApi.profileManager.active.newInventoryCard = true;	// NOTE :: This must be set after setting inventory type
					}
					
					if(!shellApi.profileManager.buildingProfile)
					{
						shellApi.track(TrackingEvents.GOT_ITEM, item);	// track item ( additional tracking is necessary for campaign cards, triggers in _____ 
					}
					
					// Manages showing card via ItemGroup, may want to move this out at a later date. - Bard
					if(showCard)
					{
						showItem( String(item), type, showCompleteCallback );
					}
					// AD SPECIFIC
					// if showCard is false, then card xml will not load, and campaign tracking would not get called.
					// In this case we load the card.xml to get data necessary for tracking, using CardGroup.
					// Generally this is an edge case that may only happen in rare instances. - Bard
					else if ( AppConfig.adsActive && type == CardGroup.CUSTOM )
					{
						var sceneManager:SceneManager = shellApi.getManager(SceneManager) as SceneManager;
						var cardGroup:CardGroupPop = sceneManager.currentScene.getGroupById(CardGroup.GROUP_ID) as CardGroupPop;
						if( !cardGroup )
						{
							cardGroup = sceneManager.currentScene.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroupPop;
						}
						// NOTE :: Ads require an additional tracking call once card xml has been successfully loaded.
						cardGroup.createCardItem( ItemGroup.ITEM_PREFIX + item, type, false, (shellApi.adManager as AdManager).trackCardCollected );
					}
					return true;
				}
			}
			return false;
		}	
		
		override public function showItem( itemId:String, type:String, transitionCompleteHandler:Function = null ):void
		{
			var sceneManager:SceneManager = shellApi.sceneManager;
			var itemGroup:ItemGroup = sceneManager.currentScene.getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			if( !itemGroup )
			{
				itemGroup = sceneManager.currentScene.addChildGroup( new ItemGroup() ) as ItemGroup;
			}
			
			// AD SPECIFIC
			// Campaign cards need additional tracking, which requires data within card.xml ( card name, id, & campaign, id )
			// this data is not available until card xml loads, so callback function is passed to triggers tracking on card load complete. - Bard
			if ( AppConfig.adsActive && type == CardGroup.CUSTOM )	
			{
				itemGroup.showItem( ItemGroup.ITEM_PREFIX + itemId, type, (shellApi.adManager as AdManager).trackCardCollected, transitionCompleteHandler );
			}
			else if ( type == CardGroup.STORE || type == CardGroup.PETS )	
			{
				itemGroup.showItem( ItemGroup.ITEM_PREFIX + itemId, type, null, transitionCompleteHandler );
			}
			else
			{
				itemGroup.showItem(itemId, type, null, transitionCompleteHandler );
			}
		}
		
		///////////////////////////////////////// ITEM SETUP /////////////////////////////////////////

		/**
		 * Check if item is valid for specified type.
		 */
		override public function checkValidItem(item:String, setId:String):Boolean
		{
			var itemNum:Number
			if( setId == CardGroup.STORE )
			{
				return ( checkStore( item ) );
			}
			else if ( setId == CardGroup.PETS )
			{
				return ( checkPets( item ) );
			}
			else if ( setId == CardGroup.CUSTOM )
			{
				return ( checkCustom( item ) );
			}
			else
			{
				// currently only checking validity of island items for current island
				if( shellApi.island == setId )
				{
					var numItems:int = validCurrentItems.length;
					for (var i:int = 0; i < numItems; i++) 
					{
						if( item == validCurrentItems[i] )
						{
							return true;
						}
					}
				}
				else
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Determine type based on item id.
		 */
		override public function determineType(item:String):String
		{
			if( checkStore( item ) )
			{
				return CardGroup.STORE;
			}
			else if ( checkPets( item ) )
			{
				return CardGroup.PETS;
			}
			else if ( checkCustom( item ) )
			{
				return CardGroup.CUSTOM;
			}
			else
			{
				return shellApi.island;
			}
		}
		
		/**
		 * Check if item is valid for store.
		 */
		private function checkStore(item:String):Boolean
		{
			var itemNum:Number = Number(item)
			if( itemNum is Number )
			{
				//JEK - add in 5000 range for Member only items
				if( itemNum >= 3000 && itemNum < 4000 ||
					itemNum >= 5000 && itemNum < 6000)
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Check if item is valid for pets.
		 */
		private function checkPets(item:String):Boolean
		{
			var itemNum:Number = Number(item)
			if( itemNum is Number )
			{
				if( itemNum >= 6000 && itemNum < 7000 )
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Check if item is valid for custom/campaign.
		 */
		private function checkCustom(item:String):Boolean
		{
			var itemNum:Number = Number(item)
			if( itemNum is Number )
			{
				if( itemNum >= 2000 && itemNum < 3000 )
				{
					return true;
				}
			}
			return false;
		}

		////////////////////////////////////////////////////////////
		////////////////////////// HELPERs /////////////////////////
		////////////////////////////////////////////////////////////
		
		override protected function getSet( id:String, filterExpired:Boolean = false):CardSet
		{
			var cardSet:CardSet;
			for (var i:int = 0; i < _cardSets.length; i++)
			{
				cardSet = _cardSets[i];
				if ( cardSet.id == id )
				{
					// RLH: filter out campaign cards for expired campaigns on mobile
					/*
					if ((filterExpired) && (PlatformUtils.isMobileOS) && (id == CardGroup.CUSTOM))
					{
						// make a copy of the card set, in case the campaign become active again
						// might take a while for the campaign to download or to be refreshed
						// this way, the original card set stays unaffected
						cardSet = cardSet.duplicate();
						// for each card
						for (var j:int = cardSet.cardIds.length-1; j!=-1; j--)
						{
							var url:String = "data/items/" + AdvertisingConstants.AD_PATH_KEYWORD + "/item" + cardSet.cardIds[j] + ".xml";
			
							// check if file found in local storage, only necessary for mobile devices
							if (shellApi.fileManager.verifyFileLocation(url, true) == null)
							{
								trace("ItemManagerPop :: Campaign card not found in local storage: " + url);
								cardSet.cardIds.splice(j,1);
							}
						}
					}
					*/
					return cardSet;
				}
			}
			trace("Warning :: ItemManagerPop :: getSet : no CardSet found for id: " + id);
			return null;
		}
		
	}
}
