package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.components.ui.CardItem;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ads.AdTrackingConstants;
	import game.data.ui.card.CardAction;
	import game.data.ui.card.CardItemData;
	import game.managers.ads.AdManager;
	import game.ui.popup.Popup;
	import game.util.DisplayPositionUtils;
	import game.util.SceneUtil;
	
	public class LeavingPopBumper extends Popup
	{
		public function LeavingPopBumper(handler:Function, campaignName:String, cardItem:CardItem = null, cardAction:CardAction = null)
		{
			_handler = handler;
			_campaignName = campaignName;
			_cardItem = cardItem;
			_cardAction = cardAction;
			
			// if card item (this is null for posters and popups)
			if (cardItem)
				_cardData = cardItem.cardData; // need this because the card data gets removed by the time this is needed again (must be due to removing card groups)
			
			super();
			super.id = "LeavingPopBumper";
		}
		
		/**
		 * Init poupup 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/elements/";
			// set name of asset
			super.screenAsset = "dialogBox.swf";
			super.init(container);
			super.load();
		}		
		
		/**
		 * When all assets loaded 
		 */
		override public function loaded():void
		{			
			super.preparePopup();
			
			// set tf text field html text to default dialog text
			(super.screen["tf"] as TextField).htmlText = _dialogText;
			
			// center popup on screen
			DisplayPositionUtils.centerWithinScreen(super.screen, super.shellApi);
			
			// to do: build the buttons from the data
			// create text format for button
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			
			// hide ok button
			super.screen.okButton.visible = false;
			
			// create Cancel button and center
			var cancelmBtn:Entity = ButtonCreator.createButtonEntity(super.screen.cancelButton, this, this.onCancelClick );
			ButtonCreator.addLabel(super.screen.cancelButton, "Cancel", labelFormat);
			super.screen.cancelButton.x = (super.screen.width - super.screen.cancelButton.width) / 2;
			
			// setup delay
			var delay:Number = 0;
			var adManager:AdManager = super.shellApi.adManager as AdManager;
			if(adManager)
			{
				delay = adManager.bumperDelay;
				SceneUtil.addTimedEvent(this, new TimedEvent( delay, 1, onTimeout ), "leavingPop");
				// dispatch that popup is ready
				this.groupReady();
			}
			else
				close();
		}
				
		/**
		 * When click on cancel button 
		 * @param btnEntity
		 */
		private function onCancelClick( btnEntity:Entity = null ):void
		{
			// if campaign name, then trigger tracking for clicking cancel
			if (_campaignName)
				AdManager(super.shellApi.adManager).track(_campaignName, AdTrackingConstants.TRACKING_CLICK_CANCEL);
			// play cancel sound
			super.playCancel();
			// close popup
			super.close();
		}

		/**
		 * When delay times out, then perform handler function 
		 */
		private function onTimeout():void
		{
			// if handler
			if (_handler)
			{
				// if card item, then pass card data to handler
				if (_cardItem)
				{
					// restore missing card data (got deleted by the time this gets called)
					_cardItem.cardData = _cardData;
					_handler(_cardItem, _cardAction);
				}
				else
				{
					// if no card item, then just call handler without it
					_handler();
				}
			}
			// close popup
			super.close();
		}
		
		private const _dialogText:String = "You are now leaving Poptropica.";
		
		private var _handler:Function;
		private var _campaignName:String;
		private var _cardItem:CardItem;
		private var _cardAction:CardAction;
		private var _cardData:CardItemData;
	}
}
