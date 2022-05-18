package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.ui.CardItem;
	import game.data.display.BitmapWrapper;
	import game.data.ui.card.CardItemData;
	import game.scene.template.ui.CardGroup;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * UIView group that creates the card display and buttons
	 *  
	 */
	public class CardView extends Group
	{

		public function CardView()
		{
			super();
			super.id = "cardViewGroup";
			buttonPress = new Signal();	// dispatches when card button is pressed
		}

		override public function destroy():void
		{
			if( buttonPress )
			{
				buttonPress.removeAll();
				buttonPress = null;
			}
			if( _bitmapWrapper )
			{
				_bitmapWrapper.destroy();
				_bitmapWrapper = null
			}
			if( _loadingCardWrapper )	// _loadingCardWrapper's bitmap is disposed by the Inventory in which it originated
			{
				//_loadingCardWrapper.destroy();
				_loadingCardWrapper = null;
			}
			_container = null;
			_cardContent = null;
			_cardEntity = null;

			super.destroy();
		}

		/**
		 * Deactivate the CardView 
		 */
		public function deactivate():void
		{
			DisplayUtils.removeAllChildren(_cardDisplay);

			if( _cardContent )
			{
				// TODO :: Still working with refresh
				//_cardContent.pause();
				//_cardContentDisplay.visible = false;
				removeCardContent();
			}
			super.pause();
		}
		
		public function activate():void
		{
			super.unpause();
			Display(_cardEntity.get( Display )).visible = true;
			
			// still want to keep cardContent deactivated, as this gets loaded later
			if( _cardContent )
			{
				_cardContent.pause();
			}
			_cardContentDisplay.visible = false;
		}
		
		/**
		 * Create a card Entity, reference to entity is stored within this CardView.
		 * @param cardItem
		 * @return 
		 */
		public function createCardEntity( cardItem:CardItem = null, container:DisplayObjectContainer = null ):Entity
		{
			// create card layers
			_container = new Sprite();
			_cardDisplay = new Sprite();
			_cardDisplay.name = "card_display";
			_cardContentDisplay = new Sprite();
			_cardContentDisplay.name = "card_content_display";
			_container.addChild( _cardDisplay );
			_container.addChild( _cardContentDisplay );
			
			// create entity and components
			_cardEntity = new Entity();
			var display:Display = new Display( _container, container );
			display.visible = false;
			_cardEntity.add( display);
			_cardEntity.add( new Spatial );
			//_cardEntity.add( new Motion );
			if( cardItem == null )	{ cardItem = new CardItem(); }
			cardItem.buttonPress.add(onButtonPress);	// relay dispatch
			cardItem.valueUpdate.add(onValueUpdate);
			_cardEntity.add( cardItem );
			
			super.addEntity( _cardEntity );	// add entity to this group

			return _cardEntity;
		}
		
		private function onButtonPress():void
		{
			buttonPress.dispatch( this );
		}

		/**
		 * Replace this card Entity's CardItem component.
		 * Sets up CardView to listen for value changes with CardItem, 
		 * allows those value changes to be passed to possible CardContentView
		 * @param cardItem
		 */
		public function addCardItem(cardItem:CardItem):void
		{
			var currentCardItem:CardItem = _cardEntity.get( CardItem );
			if( currentCardItem )
			{
				currentCardItem.removeExternalListeners();	// cleans up signals
				_cardEntity.remove( CardItem );
			}
			_cardEntity.add( cardItem );
			cardItem.valueUpdate.add(onValueUpdate);
		}

		/**
		 * Apply CardItemData to CardView directly.
		 * CardItemData is assigned to internal card Entity.
		 * @param cardData
		 * 
		 */
		public function applyCardData(cardData:CardItemData):void
		{
			if( !_cardEntity )
			{
				this.createCardEntity();
			}
			CardItem(_cardEntity.get(CardItem)).cardData = cardData;	// TODO :: do we need to duplicate the data?
		}
		
		/**
		 * Apply CardItemData to CardView via xml.
		 * CardItemData is assigned to internal card Entity.
		 * @param xml
		 * 
		 */
		public function applyCardDataXml( xml:XML):void
		{
			if( !_cardEntity )
			{
				this.createCardEntity();
			}
			
			CardItem(_cardEntity.get(CardItem)).cardData = new CardItemData( xml, super.shellApi );
		}
		
		/**
		 * Show loading display for card.
		 * TODO :: probably want this to just use bitmap data. - Bard
		 * @param loadDisplay
		 */
		public function showLoading( loadingCard:BitmapWrapper, show:Boolean = true ):void
		{
			if( _loadingCardWrapper == null )
			{
				_loadingCardWrapper = loadingCard.duplicate();
				_container.addChild( _loadingCardWrapper.sprite );
			}
			
			_loadingCardWrapper.sprite.visible = show;
			if( show )
			{
				DisplayUtils.moveToTop( _loadingCardWrapper.sprite );
			}
		}

		/**
		 * Apply display from card Entity's CardItem to CardView's display container.
		 */
		public function displayCardItem():void
		{
			if( _loadingCardWrapper ) { _loadingCardWrapper.sprite.visible = false; }
			DisplayUtils.removeAllChildren( _cardDisplay );
			_cardDisplay.addChild( CardItem( _cardEntity.get(CardItem)).spriteHolder );	// add card display to bottom
		}
		
		/**
		 * Bitmaps the entire card. 
		 * NOTE :: There is a bug that causing the content to not be included in the bitmap, it is related to positioning, needs further investigation. - bard
		 * @param scale
		 * 
		 */
		public function bitmapCardAll( scale:Number = 1 ):void
		{
			displayCardItem();		// add CardItem display to CardView

			if( _bitmapWrapper )	{ _bitmapWrapper.destroy(); }

			var isVisible:Boolean = _container.visible;
			_container.visible = true;
			// prepare card content for bitmapping
			if( _cardContent )	{ _cardContent.bitmapSourceVisible( true ); }
			_bitmapWrapper = DisplayUtils.convertToBitmapSprite( _container, CardGroup.CARD_BOUNDS, scale );
			if( _cardContent )	{ _cardContent.bitmapSourceVisible( false ); }
			_container = _bitmapWrapper.sprite;
			_container.visible = isVisible;
			var display:Display = _cardEntity.get(Display);
			display.refresh( _container, display.container );
		}
				
		public function bitmapCardBack( bounds:Rectangle, scale:Number = NaN ):void
		{
			// convert bitmapHolder to bitmap
			var cardItem:CardItem = _cardEntity.get(CardItem);
			if( cardItem.bitmapHolder != null )	// if card back has not yet been bitmapped
			{
				if( isNaN( scale ) ) { scale = EntityUtils.getDisplayObject(_cardEntity).scaleX; }
				cardItem.bitmapWrapper = DisplayUtils.convertToBitmapSprite( cardItem.bitmapHolder, bounds, scale, true );
				cardItem.bitmapWrapper.sprite.mouseChildren = false;
				cardItem.bitmapWrapper.sprite.mouseEnabled = false;
				cardItem.bitmapHolder = null;
			}
			else
			{
				if( isNaN( scale ) ) { scale = EntityUtils.getDisplayObject(_cardEntity).scaleX; }
				cardItem.bitmapWrapper = DisplayUtils.convertToBitmapSprite( cardItem.bitmapHolder, bounds, scale, true );
				cardItem.bitmapWrapper.sprite.mouseChildren = false;
				cardItem.bitmapWrapper.sprite.mouseEnabled = false;
			}
		}
		
		public function startCardContent():void
		{
			if( _cardContent )
			{
				_cardContent.start();
			}
		}
		
		public function stopCardContent():void
		{
			if( _cardContent )
			{
				_cardContent.stop();
			}
		}
	
		/**
		 * Load CardContent
		 * @param loadHandler - Handler called when CardContent has finished loading.
		 * @param loadingWrapper - shared bitmapWrapper for the loading icon, generally passsed by Inventory.  Whoever passes it is repsonsible for disposal, the CardContentView will not dispoe of BitmapData.
		 * 
		 */
		public function loadCardContent( loadHandler:Function = null, loadingWrapper:BitmapWrapper = null ):void
		{
			if( _cardEntity )
			{
				var cardItem:CardItem = _cardEntity.get(CardItem);
				if( cardItem )
				{
					var cardData:CardItemData = cardItem.cardData;
					if( cardData )
					{	
						if( cardData.contentClass != null )
						{
							// check to see if CardContent can be refeshed, otherwise content is recreated
							if( _cardContent != null )	// if a CardContent group already exists
							{
								// TODO :: refresh for characters isn't quite working
								if( _cardContent.id == String(cardItem.cardData.contentClass) )	// if next CardContentView is same class as current
								{
									if( _cardContent.canRefresh )	// check to see if refresh is even possible
									{
										_cardContent.unpause();
										_cardContentDisplay.visible = true;
										
										// refresh content
										if( loadHandler != null ) { _cardContent.refresh( cardItem, Command.create( loadHandler, cardItem ) ); }
										else { _cardContent.refresh( cardItem ); }

										// If x or y have been specified apply, (0, 0) is center of the card
										if (cardData.contentX) { _cardContent.groupContainer.x = cardData.contentX; }
										if (cardData.contentY) { _cardContent.groupContainer.y = cardData.contentY; }
			
										return;
									}
								}
								
								// if new or non-refreshable card content, remove existing card content
								removeCardContent();
							}
						
							// create new CardContentView
							_cardContentDisplay.visible = true;
							_cardContent = super.addChildGroup( new cardItem.cardData.contentClass( _cardContentDisplay ) ) as CardContentView;
							if( loadingWrapper )	// pass loading icon if available
							{
								_cardContent.loadingWrapper = loadingWrapper.duplicate(); 
								if( PlatformUtils.isDesktop )	{ _cardContent.loadingWrapper.bitmap.smoothing = true; }
							}
							
							// If x or y have been specified use to position, (0, 0) is center of the card
							if (cardData.contentX) { _cardContent.groupContainer.x = cardData.contentX; }
							if (cardData.contentY) { _cardContent.groupContainer.y = cardData.contentY; }

							// initiate CardContentView
							if( loadHandler != null ) 
							{
								_cardContent.create( cardItem, Command.create( loadHandler, cardItem ) ); 
							}
							else
							{ 
								_cardContent.create( cardItem ); 
							}
							return;
						}
						removeCardContent();
					}
				}
			}
			// if no content to load, call loadHandler if specified
			if( loadHandler != null ) { loadHandler(cardItem); }
		}
		
		private function removeCardContent():void
		{					
			if( _cardContent )
			{
				super.removeGroup( _cardContent );
				_cardContent = null;
			}
		}
		
		/**
		 * Handler for when card Entity's CardItem component's value is changed.
		 * Passes changed value to the card content, if present.
		 * @param value
		 */
		private function onValueUpdate( value:* ):void
		{
			if( _cardEntity )
			{
				if( _cardContent )
				{
					_cardContent.update( _cardEntity.get(CardItem) );
				}
			}
		}
		
		/**
		 * Hide/unhide the card's display. 
		 * @param bool
		 */
		public function hide( bool:Boolean = true ):void
		{
			Display( _cardEntity.get(Display) ).visible = !bool;
			_container.visible = !bool;
			
			// if two children, then members only card, and hide members only bar
			var numChildren:int = this.cardDisplay.numChildren;
			if (numChildren == 2)
			{
				this.cardDisplay.removeChildAt(numChildren-1);
			}
		}
		
		/**
		 * Transfers a CardView's display.
		 * Relevant display's from provided CardView are reparented to this CardView.
		 * 
		 * @param fromCardView
		 */
		public function transferDisplay( fromCardView:CardView ):void
		{
			DisplayUtils.removeAllChildren( _container );

			// add card's vector display, turn off bitmap
			var fromCardItem:CardItem = fromCardView.cardEntity.get(CardItem);

			if( PlatformUtils.isMobileOS )	// can use vectors on mobile due to filter usage, need to keep as bitmap	
			{
				// TODO :: For mobile might want to resize bitmap, & reapply filter
			}
			else	// if in browser use vectors for smoother look
			{
				if (fromCardItem.bitmapWrapper != null)
				{
					fromCardItem.bitmapWrapper.bitmap.visible = false;
					_container.addChild( fromCardItem.bitmapWrapper.source );
				}
				//if( _cardContent )	{ _cardContent.bitmapSourceVisible( true ); }
			}
			_container.addChild( fromCardItem.spriteHolder );
			
			if( fromCardView.cardContent )
			{
				_container.addChild( fromCardView.cardContentDisplay );
			}
		}
		
		/**
		 * Refreshes display, making assets visible and reparenting appropriately.
		 * Necessary if CardView's display was transfer via transferDisplay.
		 */
		public function refreshDisplay():void
		{
			var cardItem:CardItem = _cardEntity.get(CardItem);
			DisplayUtils.removeAllChildren( _cardDisplay );
			if( cardItem.bitmapWrapper )
			{
				cardItem.bitmapWrapper.bitmap.visible = true;
			}
			_cardDisplay.addChild( cardItem.spriteHolder );

			if( _cardContent )	// TODO :: only want to do this if transferDisplay was called prior
			{
				_container.addChild( _cardContentDisplay );
			}
		}

		public var buttonPress:Signal;	// dispatches with CardEntity
		
		
		
		private var _bitmapWrapper:BitmapWrapper;
		private var _loadingCardWrapper:BitmapWrapper;
		
		private var _cardContent:CardContentView;
		public function get cardContent():CardContentView	{ return _cardContent; }
		
		private var _cardEntity:Entity;
		public function get cardEntity():Entity				{ return _cardEntity; }
		
		private var _cardDisplay:Sprite;
		/**
		 * Container holding the card assets & buttons
		 * @return 
		 */
		public function get cardDisplay():Sprite		{ return _cardDisplay; }
		
		private var _cardContentDisplay:Sprite;
		/**
		 * Container holding the card content assets (e.g. characters, multi-frame clips, etc.)
		 * @return 
		 */
		public function get cardContentDisplay():Sprite		{ return _cardContentDisplay; }
		
		private var _container:Sprite;
		/**
		 * Main container for CardView, function as a groupContainer 
		 * @return 
		 */
		public function get container():Sprite				{ return _container; }
	}
}
