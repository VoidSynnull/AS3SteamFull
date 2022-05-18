package game.scene.template.ui
{
	import engine.util.Command;
	
	import game.components.ui.CardItem;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ui.card.CardAction;
	import game.data.ui.card.CardItemData;
	import game.managers.ItemManager;
	import game.managers.ads.AdManager;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.ui.CardGroup;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.utils.AdUtils;
	
	/**
	 * Poptropcia specific group to handle creation of cards, which are their own groups
	 * CardGroup must be a child of a DisplayGroup. 
	 * @author umckiba
	 */
	public class CardGroupPop extends CardGroup
	{
		/**
		 * Callback for card xml loaded.  
		 * @param cardXml
		 * @param cardItem
		 * @param isPreloadDisplay
		 * @param handler
		 */
		override public function onCardDataXmlLoaded( cardXml:XML, cardItem:CardItem, loadDisplay:Boolean, handler:Function = null):void
		{
			try
			{
				if ( cardXml != null )
				{
					if( cardItem.cardData == null )
					{
						cardItem.cardData = new CardItemData(null, super.shellApi);
					}
					cardItem.cardData.parse( cardXml );
					
					if ( DataUtils.validString(cardItem.cardData.campaignId) )	// if campaign card or store card with campaign assigned, apply campaign data to card
					{
						// trigger callback when donei
						AdManager(super.shellApi.adManager).cardApplyCampaign( cardItem.cardData, Command.create(super.onCardDataLoaded, cardItem, loadDisplay, handler) );
						// card impression only if dsplayed
						if (loadDisplay)
						{
							AdManager(super.shellApi.adManager).track(cardItem.cardData.campaignId, AdTrackingConstants.TRACKING_CARD_IMPRESSION, cardItem.cardData.name);
						}
					}
					else
					{
						super.onCardDataLoaded( cardItem, loadDisplay, handler);
					}
				}
				else
				{
					var message:String = ("CardGroup :: Card XML not found.");
					throw new Error( message ); 
				}
			}
			catch ( e:Error )
			{
				trace( "Error :: CardGroup : " + e );
				if( handler != null )
				{
					handler( cardItem, null );
				}
				//handle whatever needs handling
			}
		}

		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// BUTTON ACTIONS ////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Handles actions associated with card buttons.
		 */
		override protected function handleAction( cardItem:CardItem, cardAction:CardAction ):void
		{
			super.handleAction(cardItem, cardAction);
			
			switch(cardAction.type)
			{
				// AD SPECIFIC
				case cardAction.GO_TO_URL:
				{
					AdManager.visitSponsorSite(super.shellApi, cardItem.cardData.campaignId, triggerSponsorSite, cardItem, cardAction);
					break;
				}
			}
		}
		
		private function triggerSponsorSite(cardItem:CardItem, cardAction:CardAction):void
		{
			// track card item (action is NOT attached to button anymore)
			// don't want tracking to trigger when confirmation popup appears
			track( cardItem, cardAction);
			
			var clickURL:String = AdvertisingConstants.CAMPAIGN_FILE;
			// check if http is passed, then use that
			if ((cardAction.params.byId("urlId") != null) && (cardAction.params.byId("urlId").substr(0,4) == "http"))
			{
				clickURL = cardAction.params.byId("urlId")
			}
			
			// pass through adManager in case a popurl is used
			AdUtils.openSponsorURL(super.shellApi, clickURL, cardItem.cardData.campaignId, "Card", cardItem.cardData.name);
			_blockParentClose = true;		// TEMP :: Until I fix Tweening for groups
		}
		
		override protected function track( cardItem:CardItem, cardAction:CardAction, event:String = null ):void
		{
			var eventType:String = cardAction.params.byId( CardGroup.EVENT_TYPE );
			if (event != null) { eventType = event; }
			var choice:String = DataUtils.useString( cardAction.params.byId( CardGroup.EVENT_CHOICE ), "" );
			var subchoice:String = DataUtils.useString( cardAction.params.byId( CardGroup.EVENT_SUBCHOICE ), "" );
			
			// if campaign card, then route through ad manager
			if(( cardItem.cardData.campaignId ) && (cardItem.cardData.type == "custom"))
			{
				// if radio button has value, then set subchoice to that value (no longer passed)
				//if( (cardItem.currentRadioBtnValue != null) && (eventType != "gotoUrl") && (eventType != null) )
				//	subchoice = cardItem.currentRadioBtnValue;
				
				// track via ad manager
				super.shellApi.adManager.track(cardItem.cardData.campaignId, eventType, "Card", subchoice);
			}
			else
			{
				// for member gift cards
				if (cardItem.cardData.campaignId == "MemberGift")
				{
					super.shellApi.track( "Clicked", subchoice, "", "MemberGift");
				}
				else
				{
					trace("CardGroup :: track : event: " + eventType + ", choice: " + choice+ ", subchoice: " + subchoice);
					super.shellApi.track( eventType, choice, subchoice );
				}
			}
		}
	}
}

