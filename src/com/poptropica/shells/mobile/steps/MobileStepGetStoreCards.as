package com.poptropica.shells.mobile.steps
{
	import com.poptropica.AppConfig;
	
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.managers.ItemManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.proxy.PopDataStoreRequest;
	import game.util.PlatformUtils;
	
	/**
	 * Retrieves store card data
	 * @author rick hocker
	 */
	public class MobileStepGetStoreCards extends ShellStep
	{
		public static var failedToGetCards:Boolean = true;
		// get store cards
		public function MobileStepGetStoreCards()
		{
			super();
			stepDescription = "Getting store cards";
		}
		
		override protected function build():void
		{
			trace("player type: "+Capabilities.playerType);
			// will work in IDE
			if (/*(Capabilities.playerType == "Desktop") || */( (shellApi.networkAvailable())))
			{
				getCards(shellApi, built);
			}
			else
			{
				trace("MobileShell :: MobileStepGetStoreCards :: network NOT available, cannot retrieve store cards from server.");
				built();
			}
		}
		
		public static function getCards(shellApi:ShellApi, onComplete:Function):void
		{
			trace("MobileShell :: MobileStepGetStoreCards :: network IS available, getting store cards from server.");
			var req:DataStoreRequest = PopDataStoreRequest.storeCardsRequest();
			req.requestTimeoutMillis = 1000;
			(shellApi.siteProxy as IDataStore2).call(req, Command.create(onGotCards, shellApi, onComplete));
		}
		
		/**
		 * Handler for return from server, contains available store cards (priority != 0)
		 * @param e event
		 */
		private static function onGotCards(e:Event, shellApi:ShellApi, onComplete:Function):void 
		{
			// returned data fields: id, name, price, pri (priority), data, cpick (creator's pick), mem_only, pop (??)
			var data:String = e.currentTarget.data;
			var index:int = data.indexOf("=") + 1;
			//trace("card data: " + e.currentTarget.data);
			var cards:Object = JSON.parse(data.substr(index));
			
			// create store cards dictionary and populate
			var storeCards:Dictionary = new Dictionary();
			storeCards[ItemManager.MEMBERS_ONLY] = [];
			processCards(storeCards, cards, ItemManager.POWER);
			processCards(storeCards, cards, ItemManager.PRANK);
			processCards(storeCards, cards, ItemManager.FOLLOWER);
			processCards(storeCards, cards, ItemManager.MISC);
			processCards(storeCards, cards, ItemManager.COSTUME);
			processCards(storeCards, cards, ItemManager.PET);
			processCards(storeCards, cards, ItemManager.MEMBER_GIFT);
			processCards(storeCards, cards, ItemManager.PET_BODY);
			processCards(storeCards, cards, ItemManager.PET_HAT);
			processCards(storeCards, cards, ItemManager.PET_FACIAL);
			processCards(storeCards, cards, ItemManager.PET_EYES);
			
			// save to item manager
			shellApi.itemManager.storeItems = storeCards;
			
			failedToGetCards = false;
			onComplete();
		}
		
		private static function processCards(dict:Dictionary, cards:Object, category:String):void
		{
			var cardList:Array = cards[category];
			var storeList:Array = [];
			var idList:Array = [];
			if (cardList != null)
			{
				//trace("processing cards " + category + " " + cardList.length);
				// sort cards numerically
				cardList.sortOn(["pri","id"], Array.DESCENDING);
				// process list
				for each (var card:Object in cardList)
				{
					idList.push(card.id);
					var cardNum:int = int(card.id);
					// suppress unconverted cards
					if (ItemManager.isStoreItemConverted(cardNum))
					{
						var isMembersOnly:Boolean = (card.mem_only == "1");
						// if members only, then add to members only array
						// yes this is redundant, but we need to know for all cards, not just cards in the store
						if (isMembersOnly)
						{
							dict[ItemManager.MEMBERS_ONLY].push(card.id);
						}
						// suppress member gift cards or priority 0
						if ((category != ItemManager.MEMBER_GIFT) && (card.pri != "0"))
						{
							// create data object with id, price and members only
							var data:Object = {id:card.id, price:int(card.price), mem_only:isMembersOnly};
							// if pet, then add name also
							if (category == ItemManager.PET)
							{
								data["name"] = card.name;
							}
							
							if(!AppConfig.iapOn && isMembersOnly)
							{
								trace("excluding iap item: " + card.name);
							}
							else
							{
								storeList.push(data);
							}
						}
					}
				}
			}
			dict[category] = storeList;
			dict[category + "ID"] = idList;
		}
	}	
}

