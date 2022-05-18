package game.scenes.con2.shared
{
	import flash.utils.Dictionary;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.scene.template.ui.CardGroup;
	import game.util.DataUtils;
	
	// takes care of all changes to deck and only needs to get card info from server once
	// when ever the deck changes, it saves changes to server
	public class CCGCardManager extends Manager
	{
		// userfield id
		private const CARD_DATA_FIELD:String = "ccgcards";
		
		//decks can be from different islands
		private var decks:Dictionary;
		
		// constant used to initialize giving a card
		private const GET_CCG_CARD:String = "getCCGCard_";
		
		// formatting for getting a card should look like below
		
		// getCCGCard_cardId_island
		
		public function CCGCardManager()
		{
			
		}
		
		override protected function construct():void
		{
			decks = new Dictionary();
			shellApi.eventTriggered.add(onEventTriggered);//this doesnt seem to work...
		}
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event.indexOf(GET_CCG_CARD) == 0)
			{
				var params:Array = event.split("_");
				//params[0] is just the identifier so no need to keep it
				//params[1] should be the card id
				//params[2] should be the island
				var cardId:String = params[1];
				var island:String;
				if(params.length > 2)
					island = params[2];
				var givenOne:Boolean = cardId.indexOf("-") == -1;
				if(!givenOne)
				{
					while(cardId.indexOf("-") >0)
					{
						cardId = cardId.replace("-",",");
					}
				}
				addCardToDeck(cardId, island, givenOne);
			}
		}
		
		public function createDeckData(onComplete:Function = null, island:String = null):void
		{
			trace( "CCGCardManager : createDeckDatadeck : checking for field.");
			if(getDeck(island) == null)
				shellApi.getUserField(CARD_DATA_FIELD, island, Command.create(deckRetrieved, island, onComplete), true);
			else
			{
				trace( "CCGCardManager : deck already exists.");
				if(onComplete)
					onComplete();
			}
		}
		
		private function deckRetrieved( value:*, island:String, onComplete:Function = null):void
		{
			var deckString:String = value as String;
			if( !DataUtils.validString( deckString ) ){
				trace( "Error :: CCGCardManager : deck field was not found.");
			} else {
				trace( "CCGCardManager : deckRetrieved : deck field found.");
			}
			updateDeck(deckString, island);
			if(onComplete != null)	{ onComplete(); }	
		}
		
		public function addCardToDeck( cardString:String, island:String = null, show:Boolean = false):void
		{
			// cards you already have
			var deck:String = getDeck(island);
			//if first card, new card is now entirety of deck, otherwise add new card to end of deck
			deck = ( DataUtils.validString( deck ) ) ? String( deck + "," + cardString ) : cardString;
			// save new deck
			updateDeck(deck, island);
			
			if(show)
			{
				if(island == null)
					island = CardGroup.STORE;
				shellApi.showItem(cardString, island);
			}
		}
		
		public function hasCard(cardId:String, island:String = null):Boolean
		{
			var deck:String = getDeck(island);
			if( DataUtils.validString( deck )  )
			{
				if( deck.indexOf(cardId) != -1)
				{
					return true;
				}
			}
			return false;
		}
		
		public function updateDeck(cards:String, island:String = null):void
		{
			if(island == null)
			{
				decks[CARD_DATA_FIELD] = cards;
			}
			else
				decks[island] = cards;
			
			shellApi.setUserField(CARD_DATA_FIELD, cards, island, true);
		}
		
		public function getDeck(island:String = null):String
		{
			if(island == null)
				island = CARD_DATA_FIELD;
			return decks[island];
		}
	}
}