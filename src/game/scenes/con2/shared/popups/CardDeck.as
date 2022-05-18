package game.scenes.con2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.ui.CardItem;
	import game.creators.ui.ToolTipCreator;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.scenes.con2.shared.CCGCardManager;
	import game.ui.card.CardView;
	import game.ui.popup.Popup;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class CardDeck extends Popup
	{
		public function CardDeck(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent = true;
			this.darkenBackground = true;
			this.autoOpen = true;
			this.groupPrefix = "scenes/con2/shared/popups/";
			this.screenAsset = "cardDeck.swf";
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.preparePopup();
			
			this.loadCloseButton( "", 35, 35);
			
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640), true);
			
			//screen.bg.height = shellApi.viewportHeight;
			//screen.bg.width = shellApi.viewportWidth;
			//screen.titles.x *= shellApi.viewportWidth/960;
			//screen.titles.y *= shellApi.viewportHeight/640;
			
			_cardManager = shellApi.getManager(CCGCardManager) as CCGCardManager;
			retrievedCards();
		}
		
		private function retrievedCards():void
		{
			var cardString:String = _cardManager.getDeck(shellApi.island);
			SceneUtil.lockInput(this, true);
			var cards:Array = DataUtils.getArray(cardString);
			_numCards = cards.length;
			_cardList = new Array(_numCards);
			
			var cardGroup:CardGroupPop = getGroupById(CardGroup.GROUP_ID) as CardGroupPop;
			var cardWidth:Number = CardGroup.CARD_BOUNDS.width * CARD_SCALE;
			var startX:Number = cardWidth*.5;
			var deckOffsetX:Number = (screen.content.deck.width - cardWidth) / 9;
			var benchOffsetX:Number = _numCards > 11 ? (screen.content.bench.width - cardWidth)/(_numCards - 11) : 0;
			var offsetY:Number = (CardGroup.CARD_BOUNDS.height * CARD_SCALE) *.5;
			var cardView:CardView;
			
			var i:int = _numCards < 9 ? _numCards - 1 : 9;
			
			// Current cards
			for(i; i >= 0; i--)
			{
				cardView = cardGroup.createCardView(this);				
				cardGroup.createCardViewByItem(this, screen.content, cards[i], shellApi.island, cardView, Command.create(cardCreated, cardView, cardClicked));
				var deckSpatial:Spatial = cardView.cardEntity.get(Spatial);			
				
				deckSpatial.x = screen.content.deck.x + startX + (deckOffsetX * i);	
				deckSpatial.y = screen.content.deck.y - screen.content.deck.height*.5 + offsetY;
				deckSpatial.scale = CARD_SCALE;
				
				cardView.cardEntity.add(new CardOrganizer(cards[i], screen.content.numChildren-1, new Point(deckSpatial.x, deckSpatial.y), true));
				_cardList[i] = cardView.cardEntity;
			}
			
			var fraction:int = _numCards - 9;
			
			for(i = _numCards - 1; i > 9; i--)
			{
				cardView = cardGroup.createCardView(this);
				cardGroup.createCardViewByItem(this, screen.content, cards[i], shellApi.island, cardView, Command.create(cardCreated, cardView, cardClicked));
				var benchSpatial:Spatial = cardView.cardEntity.get(Spatial);
				benchSpatial.x = screen.content.bench.x + (screen.content.bench.width * (i - 9) / fraction);
				benchSpatial.y = screen.content.bench.y + offsetY;
				benchSpatial.scale = CARD_SCALE;
				cardView.cardEntity.add(new CardOrganizer(cards[i], screen.content.numChildren-1, new Point(benchSpatial.x, benchSpatial.y), false));
				_cardList[i] = cardView.cardEntity;
			}
		}
		
		private function cardCreated(cardItem:CardItem, cardView:CardView, handler:Function):void
		{
			if( !cardItem.bitmapWrapper ) 
			{ 
				cardView.bitmapCardAll(CARD_SCALE);
			}
			
			cardView.displayCardItem();
			cardView.hide(false);
			
			var interaction:Interaction = InteractionCreator.addToEntity(cardView.cardEntity, [InteractionCreator.CLICK]);
			interaction.click.add(handler);
			ToolTipCreator.addToEntity(cardView.cardEntity);
			
			_cardsLoaded++;
			// unlock input once done loading
			if(_numCards == _cardsLoaded)
			{
				SceneUtil.lockInput(this, false, false);
				super.groupReady();
			}
		}
		
		private function cardClicked(card:Entity):void
		{			
			var cardDisplay:Display = card.get(Display);
			var cardSpatial:Spatial = card.get(Spatial);
			var cardOrganizer:CardOrganizer = card.get(CardOrganizer);			
			
			// if another card is already clicked, check if swap or in same so switch or put away
			if(_currentCard)
			{
				var currentOrgainzer:CardOrganizer = _currentCard.get(CardOrganizer);
				var currentDisplay:Display = _currentCard.get(Display);
				var currentSpatial:Spatial = _currentCard.get(Spatial);
				
				// swap bench and deck position
				if(currentOrgainzer.deckCard != cardOrganizer.deckCard)
				{					
					currentOrgainzer.deckCard = !currentOrgainzer.deckCard;
					cardOrganizer.deckCard = !cardOrganizer.deckCard;
					
					cardDisplay.container.addChildAt(currentDisplay.displayObject, cardOrganizer.index);
					currentDisplay.container.addChildAt(cardDisplay.displayObject, currentOrgainzer.index);
					
					TweenUtils.globalTo(this, currentSpatial, TWEEN_TIME, {x:cardOrganizer.pos.x, y:cardOrganizer.pos.y, scale:CARD_SCALE});
					TweenUtils.globalTo(this, cardSpatial, TWEEN_TIME, {x:currentOrgainzer.pos.x, y:currentOrgainzer.pos.y, scale:CARD_SCALE});
					
					var tempPoint:Point = cardOrganizer.pos;
					cardOrganizer.pos = currentOrgainzer.pos;
					currentOrgainzer.pos = tempPoint;
					
					var tempIndex:Number = cardOrganizer.index;
					cardOrganizer.index = currentOrgainzer.index;
					currentOrgainzer.index = tempIndex;	
					
					swapCardSpots(card, _currentCard);										
					_currentCard = null;
					return;
				}
				else
				{
					// Not a swap just bring new card out and old one in if not the same
					currentDisplay.container.setChildIndex(currentDisplay.displayObject, currentOrgainzer.index);
					TweenUtils.globalTo(this, currentSpatial, TWEEN_TIME, {x:currentOrgainzer.pos.x, y:currentOrgainzer.pos.y, scale:CARD_SCALE});
				}
			}			
			
			if(_currentCard != card)
			{
				var glow:uint = cardOrganizer.deckCard ? 0xFF0000 : 0x00FF00;
				var ySpot:Number = cardOrganizer.deckCard ? screen.content.deck.y : (shellApi.viewportHeight - 10 - (CardGroup.CARD_BOUNDS.height * CARD_UP_SCALE *.5));
				var xSpot:Number = cardSpatial.x;
				
				if(xSpot - (CardGroup.CARD_BOUNDS.width * CARD_UP_SCALE * .5) < 0)
					xSpot = CardGroup.CARD_BOUNDS.width * CARD_UP_SCALE * .5 + 10;
				else if(xSpot + (CardGroup.CARD_BOUNDS.width * CARD_UP_SCALE * .5) > shellApi.viewportWidth)
					xSpot = shellApi.viewportWidth - (CardGroup.CARD_BOUNDS.width * CARD_UP_SCALE * .5) - 10
					
				DisplayUtils.moveToTop(cardDisplay.displayObject);
				TweenUtils.globalTo(this, cardSpatial, TWEEN_TIME, {y:ySpot, x:xSpot, scale:CARD_UP_SCALE});
				_currentCard = card;
			}
			else 
				_currentCard = null;
		}
		
		private function swapCardSpots(card1:Entity, card2:Entity):void
		{
			var tempIndex:Number = _cardList.indexOf(card2);
			_cardList[_cardList.indexOf(card1)] = card2;
			_cardList[tempIndex] = card1;
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			// Set user field
			if(_cardList != null)
			{
				var cardString:String = "";
				for(var i:int = 0; i < _cardList.length; i++)
				{
					if(i != 0) cardString += ",";
					cardString += _cardList[i].get(CardOrganizer).id;
				}
				
				_cardManager.updateDeck( cardString, shellApi.island);
			}
			
			super.close(removeOnClose, onClosedHandler);
		}
		
		private const CARD_SCALE:Number = .67;
		private const CARD_UP_SCALE:Number = .85;
		private const TWEEN_TIME:Number = .5;
		
		private var _currentCard:Entity;
		private var _cardList:Array;
		private var _numCards:Number = 0;
		private var _cardsLoaded:Number = 0;
		private var _cardManager:CCGCardManager;
	}
}