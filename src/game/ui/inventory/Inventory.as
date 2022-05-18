package game.ui.inventory 
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	import engine.util.Command;
	
	import game.components.motion.Draggable;
	import game.components.ui.CardItem;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.GridSlot;
	import game.components.ui.Ratio;
	import game.components.ui.ScrollBox;
	import game.components.ui.Slider;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.GridScrollableCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdvertisingConstants;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.data.ui.card.CardAction;
	import game.data.ui.card.CardSet;
	import game.managers.ItemManager;
	import game.managers.LanguageManager;
	import game.scene.template.ItemGroup;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.SystemPriorities;
	import game.systems.motion.DraggableSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.ui.ScrollBoxSystem;
	import game.systems.ui.SliderSystem;
	import game.ui.card.CardView;
	import game.ui.elements.BasicButton;
	import game.ui.elements.MultiStateToggleButton;
	import game.ui.elements.StandardButton;
	import game.ui.elements.TabElement;
	import game.ui.elements.TabView;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	import game.util.ScreenEffects;
	import game.util.TextUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	
	/**
	 * Inventory provides a browsing environment for Inventory Item Cards
	 * @author Bard McKinley/Rich Martin
	 */
	public class Inventory extends Popup 
	{	
		public static const GROUP_ID:String = "inventory";
		private var _membersOnlyGraphic:MovieClip;
		private var _preloadXMLTracker:Number = 0;
		
		public function Inventory(container:DisplayObjectContainer = null) 
		{
			super(container);
			
			super.id = GROUP_ID;
			itemClicked = new Signal(CardView);
		}
		
		//// PUBLIC METHODS ////
		
		public override function init(container:DisplayObjectContainer = null):void 
		{
			super.groupPrefix = "ui/inventory/";
			super.screenAsset = "inventory.swf"

			// config transition
			var transitionIn:TransitionData = new TransitionData();
			transitionIn.duration = 0.9;
			transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			transitionIn.endPos = new Point(0, 0);
			transitionIn.ease = Bounce.easeOut;
			var transitionOut:TransitionData = transitionIn.duplicateSwitch(Sine.easeIn);
			transitionOut.duration = .3;
			super.config(transitionIn, transitionOut, false, true, true, false);
			
			this.currentType = shellApi.profileManager.inventoryType;
			this.currentSubType = shellApi.profileManager.inventorySubType;
			
			super.shellApi.track( INVENTORY_OPENED, null, null, SceneUIGroup.UI_EVENT);
			
			super.init(container);
			super.shellApi.loadFile( super.shellApi.assetPrefix + "ui/store/membersOnly.swf", gotMembershipClip);
			super.load();
		}
		
		private function gotMembershipClip(clip:MovieClip):void
		{
			_membersOnlyGraphic = clip;
		}
		
		public override function destroy():void 
		{
			if(_loadingCardWrapper)
			{
				_loadingCardWrapper.destroy();
			}
			if(_loadingWheelWrapper)
			{
				_loadingWheelWrapper.destroy();
			}
			
			itemClicked.removeAll();
			itemClicked = null;
			
			if( _darkenSignal )
			{
				_darkenSignal.removeAll();
				_darkenSignal = null;
			}
			// make sure CardItem components are manually destroyed
			if( _inventoryPages && _inventoryPages.length > 0 )
			{
				var page:InventoryPage;
				for (var i:int = 0; i < _inventoryPages.length; i++) 
				{
					page = _inventoryPages[i];
					if( page.cards && page.cards.length > 0 )
					{
						for (var j:int = 0; j < page.cards.length; j++) 
						{
							page.cards[j].manualDestroy();
						}
					}
				}
			}
			
			super.destroy();
		}
		
		/**
		 * Assets loaded
		 */
		override public function loaded():void
		{
			super.autoOpen = false;
			super.preparePopup(); // handles some of the standard Popup preparation
			
			// add systems
			super.addSystem(new FollowTargetSystem());
			super.addSystem(new RenderSystem());
			super.addSystem(new MotionSystem());
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			
			// add systems for slider & scroll box
			this.addSystem(new DraggableSystem());
			this.addSystem(new SliderSystem());
			this.addSystem(new ScrollBoxSystem());
			
			var languageManager:LanguageManager = LanguageManager(shellApi.getManager(LanguageManager));
			
			// scale to fit viewport
			var clip:MovieClip = this.screen.content;
			clip.bottom_bar.width = clip.middle_canvas.width = clip.border_R.x = shellApi.viewportWidth;
			clip.top_bar.width = clip.bottom_bar.width + 2;	// NOTE :: Adding 2 because asset scaling is off, 9-slicing weirdness
			clip.top_bar.y = TAB_HEIGHT;
			clip.middle_canvas.y = clip.border_L.y = clip.border_R.y = clip.top_bar.y + clip.top_bar.height - 1; // NOTE :: Subtracting 1 because asset scaling is off, 9-slicing weirdness
			clip.bottom_bar.y = shellApi.viewportHeight - clip.bottom_bar.height;	
			clip.middle_canvas.height = clip.border_L.height = clip.border_R.height = clip.bottom_bar.y - clip.middle_canvas.y + 1; // NOTE :: Adding 1 because asset scaling is off, 9-slicing weirdness
			
			clip.layoutBtn.x = shellApi.viewportWidth - ( clip.layoutBtn.width + 16 );
			clip.tfMessage.x = (shellApi.viewportWidth - clip.tfMessage.width) * .5;
			clip.tfMessage.y = clip.middle_canvas.y + ( clip.middle_canvas.height - clip.tfMessage.height) * .5;
			
			TextUtils.refreshText(clip.removeEffectsBtn.textField).text = languageManager.get("shared.inventory.removeEffects", "Remove Effects");

			var portHoleBuffer:int = clip.border_L.width;
			_portHole = new Rectangle( 0, clip.middle_canvas.y + (LAYOUT_GUTTER * 2), shellApi.viewportWidth, clip.middle_canvas.height - LAYOUT_GUTTER * 3);

			// add CardGroup
			_cardGroup = super.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroup;
			_cardGroup.cardActivated.add( onCardAction );	// add listener for card actions
			
			createPages();
			
			// setup textfields
			var islandTitleFormat:TextFormat = new TextFormat("GhostKid AOE");
			var titleText:TextField = TextUtils.convertText( clip.islandTitle.tf, islandTitleFormat, shellApi.islandName );
			TextUtils.addShadow( titleText ); 
			_messageText = TextUtils.convertText( clip.tfMessage, new TextFormat("CreativeBlock BB", 32 )  );
			
			// setup buttons
			clip.removeEffectsBtn.stop();
			
			//Drew - Commented out costume and gold card buttons due to no functionality.
			var mstb:StandardButton = ButtonCreator.createStandardButton(clip.removeEffectsBtn, removeEffects, null, this);
			
			if( makeCloseButton )	
			{ 
				if(super.shellApi.viewportWidth > 1200 && PlatformUtils.isMobileOS)
					super.loadCloseButton( DisplayPositions.TOP_RIGHT, 50*(super.shellApi.viewportScale*3), 40); 
				else
					super.loadCloseButton( DisplayPositions.TOP_RIGHT, 50, 40); 
			}

			clip.layoutBtn.stop();
			_layoutButton = ButtonCreator.createMultiStateToggleButton(clip.layoutBtn, switchLayout, null, this);
			BasicButton.addPressAction( _layoutButton, super.playClick);
			_layoutButton.selected = true;	// update to indicate flow style
			
			// create sprite to hold card displays TODO :: Could probably just add this to the fla. - Bard
			_itemHolder = new Sprite();	// creates a clip that will contain cards displays
			_itemHolder.name = "cards_container";
			clip.addChild(_itemHolder);
			DisplayUtils.moveToTop( clip.border_L);	// move clip with side borders to top layer so it is over the newly added _itemHolder
			DisplayUtils.moveToTop( clip.border_R);
			
			// create scrollable grid for cards
			_gridCreator = new GridScrollableCreator();
			// want dimension of card slot in a single row layout, want to fit at least 3 cards on screen at once 
			_grid = _gridCreator.create( _portHole.clone(), CardGroup.CARD_BOUNDS, MIN_CARDS_VISIBLE, 1, this, LAYOUT_GUTTER, true, onGridShift, portHoleBuffer, TABLEAU_ID);
			_gridControl = _grid.get( GridControlScrollable );
			_ratio = _grid.get( Ratio );
			
			// add ScrollBox to gridEntity
			_grid.add(new ScrollBox( this.screen.content, _portHole, 100, 50) );
			
			// create CardViews, each of which contains a card Entities
			// Determine number of cards that will fit into space using layout that requires maximum number of cards
			var numCardsNeeded:uint = GeomUtils.getLayoutCapacity(_portHole, GeomUtils.getLayoutCellRect(_portHole, CardGroup.CARD_BOUNDS, 0, MAX_ROWS, LAYOUT_GUTTER), 0, MAX_ROWS, LAYOUT_GUTTER);
			numCardsNeeded += MAX_ROWS * 3;	// add extra cards as buffer
			var interactions:Array = [InteractionCreator.CLICK];
			for (var i:int = 0; i < numCardsNeeded; i++) 
			{	
				var cardView:CardView = _cardGroup.createCardView( this );	// create CardView (inherets from UIView)
				var cardEntity:Entity = cardView.createCardEntity( null, _itemHolder );	// create card Entity within CardView
				// add additional components necessary for inventory
				InteractionCreator.addToEntity( cardEntity, interactions ); 
				
				var bounds:Rectangle = CardGroup.CARD_BOUNDS.clone();
				
				_gridCreator.addSlotEntity( _grid, cardEntity, bounds, onCardActivated, onCardDeactivated );
				cardEntity.add( new OwningGroup( cardView ) );
				cardEntity.add( new Id(String("inventory_card_" + i)) );
				// add to card array
				_cardArray.push(cardView);
			}

			setupSlider();
			lockSlide( true );
			
			// create/load tabs, once loading setup is continued
			_tabView = super.addChildGroup( new TabView( super.screen.content ) ) as TabView;
			var tabs:Vector.<TabElement> = new Vector.<TabElement>();
			for (var j:int = 0; j < _inventoryPages.length; j++) 
			{
				tabs.push( (new InventoryTab( _inventoryPages[j].id, _inventoryPages[j].tabTitle )) as TabElement );
			}
			_tabView.ready.addOnce( onTabsLoaded );
			_tabView.tabSelected.add( changePage );			// dispatch returns tab id, which corresponds with page id
			_tabView.create( super.groupPrefix + "tab.swf", tabs);
		}
		
		private function removeEffects(event:MouseEvent):void
		{
			this.shellApi.specialAbilityManager.removeAllSpecialAbilities();
			handleCloseClicked();
		}
		
		protected function createPages():void
		{
			var languageManager:LanguageManager = LanguageManager(shellApi.getManager(LanguageManager));
			createInventoryPage( ISLAND, 0, languageManager.get("shared.inventory.noIslandCards", EMPTY_ISLAND_CARDS_MESSAGE), ISLAND_TAB );
			createInventoryPage( STORE, 1, languageManager.get("shared.inventory.noStoreCards", EMPTY_STORE_CARDS_MESSAGE), STORE_TAB );
			createInventoryPage( CUSTOM, 2, languageManager.get("shared.inventory.noCustomCards", EMPTY_CUSTOM_CARDS_MESSAGE), CUSTOM_TAB );
			createInventoryPage( PETS, 3, languageManager.get("shared.inventory.noPetCards", EMPTY_PETS_CARDS_MESSAGE), PETS_TAB );
		}
		
		private function onTabsLoaded( tabView:TabView ):void
		{
			_tabView.getTabById( _currentType, true );
			shellApi.loadFiles( [ shellApi.assetPrefix + LOADING_CARD_PATH, shellApi.assetPrefix + LOADING_WHEEL_PATH], openPopup );	// load the 'loading card" asset
		}
		
		/**
		 * Called once the 'loading card' * 'loading wheel' assets have completed loading.
		 *   
		 * @param displayObject
		 */
		private function openPopup():void
		{	
			// convert to loading assets to bitmaps, the bitmap data will be passed to the cards when they are created so that they share BitmapData
			
			// sets standard scale to be max scale for single row layout
			var gridSlotBounds:Rectangle = GeomUtils.getLayoutCellRect(_portHole, CardGroup.CARD_BOUNDS, MIN_CARDS_VISIBLE, 1, LAYOUT_GUTTER);
			_cardScale = gridSlotBounds.width/CardGroup.CARD_BOUNDS.width;

			// store references to loading assets
			var loadWheel:MovieClip = shellApi.getFile( shellApi.assetPrefix + LOADING_WHEEL_PATH ) as MovieClip;
			_loadingWheelWrapper = DisplayUtils.convertToBitmapSprite( loadWheel, loadWheel.getBounds(loadWheel), _cardScale, false );
			var loadingCard:MovieClip = shellApi.getFile( shellApi.assetPrefix + LOADING_CARD_PATH ) as MovieClip;
			_loadingCardWrapper = DisplayUtils.convertToBitmapSprite( loadingCard, CardGroup.CARD_BOUNDS, _cardScale );
			
			// create darken effect
			_darkenEffect = new ScreenEffects( super.groupContainer, shellApi.viewportWidth, shellApi.viewportHeight, .5 );
			_darkenEffect.hide();
			
			// create CardView, use to display the 'selected' cards
			_selectionCardView = _cardGroup.createCardView( this );
			var cardEntity:Entity = _selectionCardView.createCardEntity( null, super.groupContainer );
			//cardEntity.add( new Edge() );
			_selectionCardView.cardEntity.add( new Tween() );
			
			// open inventory popup
			this._isOpen = false;
			super.open( onInventoryOpen );
			this.groupReady();
			
			changePage( _currentType );		// display initial card set
		}
		
		private function onInventoryOpen():void
		{
			this._isOpen = true;
			lockSlide( !_gridControl.canScroll );
		}
		
		/**
		 * Handler called when a card action is triggered.  
		 * @param actions
		 * @param blockParentClose
		 */
		private function onCardAction( actions:Vector.<CardAction> = null, blockParentClose:Boolean = false ):void
		{
			// TODO :: This may allow us to delay calls until Inventory has closed. - bard
			// TODO :: May want to move blockParentClose check into Inventory rather than have it come from CardGroup. -bard
			if( blockParentClose )
			{
				closeSelectionCard();
			}
			else
			{
				handleCloseClicked();
			}
		}
		
		protected override function handleCloseClicked (...args): void 
		{
			closeSelectionCard();	//TODO :: block card click
			lockSlide( true );
			
			// store current page & subpage
			super.shellApi.profileManager.inventoryType = this.currentType;
			super.shellApi.profileManager.inventorySubType = this.currentSubType;
			
			shellApi.track(INVENTORY_CLOSED, null, null, SceneUIGroup.UI_EVENT);
			super.handleCloseClicked(args);
		}

		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// LAYOUT //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Switch to other layout.
		 * Triggered by layout button.
		 */
		private function switchLayout(e:MouseEvent = null):void 
		{
			hideSelectionCard();	// immediately hide display card
			
			shellApi.track(INVENTORY_REORGANIZED, null, null, SceneUIGroup.UI_EVENT);
			layoutStyle = ( layoutStyle == LAYOUT_FLOW_STYLE ) ? LAYOUT_GRID_STYLE : LAYOUT_FLOW_STYLE;	// switch to other layout
			
			// reset slot dimension based on grid layout ( in this case the change in number of rows ) 
			var cols:int = ( _rows == 1 ) ? MIN_CARDS_VISIBLE : 0;	// make sure that at least 3 cards fit along a single row
			var slotRect:Rectangle = GeomUtils.getLayoutCellRect(_gridControl.frameRect, CardGroup.CARD_BOUNDS, cols, _rows, LAYOUT_GUTTER);	
			_gridControl.reconfigSlots( _rows, NaN, slotRect );	// change slot given new layout			
			
			_ratio.decimal = activePage.savedGridPercent;
			lockSlide( !_gridControl.canScroll );
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// PAGES //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Get InventoryPage using its id.  
		 * @param id
		 * @return 
		 */
		private function getPageById( id:String ):InventoryPage 
		{
			if( _inventoryPages )
			{
				var inventoryPage:InventoryPage;
				for (var i:int = 0; i < _inventoryPages.length; i++) 
				{
					inventoryPage = _inventoryPages[i];
					if( inventoryPage.id == id )
					{
						return inventoryPage;
					}
				}
			}
			return null;
		}
		
		/**
		 * Create a new InventoryPage and adds it to _inventoryPages vector.
		 * Begins loading data and assets for all cards within page.
		 * 
		 * tabIndex - the index of the tab
		 * cardIds - Vector of card ids
		 */
		protected function createInventoryPage( type:String, tabIndex:uint, message:String, tabTitle:String ):InventoryPage 
		{
			var inventoryPage:InventoryPage = new InventoryPage();
			inventoryPage.id = type;
			inventoryPage.tabIndex = tabIndex;
			inventoryPage.emptyMessage = message;
			inventoryPage.tabTitle = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.inventory." + type, tabTitle);
			
			if( !_inventoryPages )	{ _inventoryPages = new Vector.<InventoryPage>(); }
			_inventoryPages.push(inventoryPage);
			
			return inventoryPage;	
		}
		
		/**
		 * Change the inventory page, options include island, store, or cutom. 
		 * @param pageId
		 * 
		 */
		public function changePage(pageId:String):void 
		{
			//set active page
			if( !activePage)							// if no page has been set yet (inventory is first opening)
			{
				activePage = getPageById(pageId);
			}
			else if ( activePage.id == pageId) 			// is current card set is already being displayed ignore request
			{
				trace("Inventory :: displayPage : Won't redisplay the same card set");
				return;
			}
			else										// different page tab has been selected, save current setting before setting assigning new page
			{
				// save current slider and offset values before moving to next page
				if (_gridControl.canScroll)
				{
					activePage.savedGridPercent = _ratio.decimal;
				}
				activePage = getPageById(pageId);
			}
			
			// turn on & off page specific UI
			screen.content.islandTitle.visible = ( pageId == ISLAND);
			
			// hide all cards
			for each (var cardView:CardView in _cardArray)
			{
				cardView.hide(true);
			}
			
			//load cardSets if not yet loaded
			if( activePage.cardSets.length == 0 )
			{
				loadCardSet( activePage.id )
				if(activePage.id == ISLAND)
				{
					preparecards();
				}
			}else
			{
				preparecards();
			}
			
			
		}
		private function preparecards():void 
		{
			// prepare cards for display, if no cards are present displays message
			prepareCardSet();
			
			// set layout based on active page's total number of cards
			layoutStyle = ( activePage.numCards() > MIN_CARDS_VISIBLE ) ? LAYOUT_GRID_STYLE : LAYOUT_FLOW_STYLE;
			
			// determine slot dimensions, create new slots
			var cols:int = ( _rows == 1 ) ? MIN_CARDS_VISIBLE : 0;					// make sure that at least 3 cards fit along a single row
			var slotRect:Rectangle = GeomUtils.getLayoutCellRect( _gridControl.frameRect, CardGroup.CARD_BOUNDS, cols, _rows, LAYOUT_GUTTER );	// determine dimension of Tableau slot
			_gridControl.createSlots( activePage.numCards(), _rows, 0, slotRect );	// create new slots	for grid (not the same as the cards)							
			
			// apply saved grid position
			_ratio.decimal = activePage.savedGridPercent
			
			// allow grid to be unlocked if Inventory has finished opening
			if( super.isOpened ) 	{ lockSlide( !_gridControl.canScroll ); }
		}
		/**
		 *  Retrieve the list of cards for type, options include island, store, or custom.
		 *  Card sets are retrieved from the ItemManager.
		 * @param type
		 * 
		 */
		private function preloadXml(cardSet:CardSet, currentCat:String):void
		{
			var type:String = currentCat;
			_preloadXMLTracker = cardSet.cardIds.length;
			if(currentCat == "custom"){currentCat = "limited";}
			if(currentCat == "store" || currentCat == "limited" || currentCat == "pets")
			{
				for each(var id:String in cardSet.cardIds)
				{
					super.shellApi.loadFile( super.shellApi.dataPrefix + "items/"+currentCat +"/item"+ id +".xml", cardXmlLoaded, cardSet, id, type );	// load card xml				
				}
			}
			
		}
		private function cardXmlLoaded(xml:XML, cardSet:CardSet, id:String, type:String):void
		{
			_preloadXMLTracker--;
			if(xml == null)
			{
				if(id != "_under_construction" || id != "_credits_card" )
				{
					cardSet.remove(id);
					trace("xml is null");
				}
				
			}
			else
			{
				trace("xml not null");
			}
			if(_preloadXMLTracker <= 0)
			{
				trace("PRELOADED XMLS!");
				_preloadXMLTracker = 0;
				getPageById( type ).cardSets.push( cardSet );
				// prepare cards for display, if no cards are present displays message
				prepareCardSet();
				
				// set layout based on active page's total number of cards
				layoutStyle = ( activePage.numCards() > MIN_CARDS_VISIBLE ) ? LAYOUT_GRID_STYLE : LAYOUT_FLOW_STYLE;
				
				// determine slot dimensions, create new slots
				var cols:int = ( _rows == 1 ) ? MIN_CARDS_VISIBLE : 0;					// make sure that at least 3 cards fit along a single row
				var slotRect:Rectangle = GeomUtils.getLayoutCellRect( _gridControl.frameRect, CardGroup.CARD_BOUNDS, cols, _rows, LAYOUT_GUTTER );	// determine dimension of Tableau slot
				_gridControl.createSlots( activePage.numCards(), _rows, 0, slotRect );	// create new slots	for grid (not the same as the cards)							
				
				// apply saved grid position
				_ratio.decimal = activePage.savedGridPercent
				
				// allow grid to be unlocked if Inventory has finished opening
				if( super.isOpened ) 	{ lockSlide( !_gridControl.canScroll ); }
			}
		}
		private function loadCardSet( type:String ):void 
		{
			trace( "Inventory :: loadCardSet :: type = " + type );
			var cardSet:CardSet
			if( type == ISLAND )	// these cards should already be loaded
			{
				//JEK 7/27/2020 readding from island tab as requested
				
				// if we have custom cards, we push custom cards to the front of the island cards (filter expired cards)
				/*
				var customCardSet:CardSet = super.shellApi.getCardSet( CUSTOM, true );
				if( customCardSet.cardIds.length > 0 )
				{
					
					cardSet = customCardSet.duplicate();
					cardSet.cardIds.reverse();
					preloadXml(cardSet.cardIds,type);
					getPageById( type ).cardSets.push( cardSet );
				}
				*/
				// RLH: don't add custom cards to island if island is custom (causes double cards since custom card set has same name as custom island)
				if (super.shellApi.island != CUSTOM)
					getPageById( type ).cardSets.push( super.shellApi.getCardSet( super.shellApi.island ).duplicate() );
			} 
			else
			{
				cardSet = super.shellApi.getCardSet( type, true ).duplicate();
				cardSet.cardIds.reverse();	// reverse order, from newest to oldest
				
				if( type == STORE)	// store cards are still incomplete on web, present Construction card until everything is avaialable
				{
					if( cardSet.cardIds.length > 0 )
					{
						if( cardSet.cardIds[0] != CONSTRUCTION_CARD )
						{
							cardSet.cardIds.unshift( CREDITS_CARD);
							
							if(!shellApi.profileManager.active.isGuest)
							{
								cardSet.cardIds.unshift( CONSTRUCTION_CARD );
							}
						}
					}
					else
					{
						cardSet.cardIds.push( CONSTRUCTION_CARD );
						
						if(!shellApi.profileManager.active.isGuest)
						{
							cardSet.cardIds.push( CREDITS_CARD );
						}
					}
				}

				preloadXml(cardSet,type);
				//test xmls here?
				
			} 
		}
		
		/**
		 * Prepare cards for the active inventory page
		 */
		private function prepareCardSet():void 
		{
			// check if text notification is necessary (in the case of no items)
			var noItemsToShow:Boolean = ( 0 == activePage.numCards() );
			_messageText.htmlText = ( noItemsToShow ) ? activePage.emptyMessage : "";
			
			_layoutButton.activated = !noItemsToShow;

			// If cardItems have not yet been created for page, create a CardItem component for each card in card set.
			// These CardItem are not as yet associated with Entities, but are stored by their corresponding Inventory Page.
			if( !activePage.cards )	
			{
				activePage.cards = new Vector.<CardItem>();
				
				var cardItem:CardItem;
				var idPrefix:String;
				var i:int;
				var j:int;
				var listIndex:int = 0;
				for (i = 0; i < activePage.cardSets.length; i++) 
				{
					var cardSet:CardSet = activePage.cardSets[i];
					idPrefix = ( cardSet.id == STORE || cardSet.id == PETS || cardSet.id == CUSTOM ) ? ItemGroup.ITEM_PREFIX : "";
					for (j = 0; j < cardSet.cardIds.length; j++) 
					{
						cardItem = new CardItem();
						cardItem.itemId = idPrefix + cardSet.cardIds[j];
						cardItem.listIndex = listIndex++;
						if (cardSet.id == CardGroup.CUSTOM)
							cardItem.pathPrefix = "items/" + AdvertisingConstants.AD_PATH_KEYWORD + "/" + cardItem.itemId;
						else
							cardItem.pathPrefix = "items/" + cardSet.id + "/" + cardItem.itemId;
						activePage.cards.push( cardItem );
					}
				}
			}
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// CARDS //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////

		private function onCardDeactivated( cardEntity:Entity):void 
		{
			(cardEntity.group as CardView).deactivate();
		}
		
		/**
		 * Reposition and apply CardItem's display to card Entity.
		 */
		private function onCardActivated( cardEntity:Entity):void 
		{
			var cardView:CardView = cardEntity.group as CardView;
			var cardItem:CardItem = activePage.cards[GridSlot(cardEntity.get(GridSlot)).index];
			
			cardView.activate();				// activate CardView, unpauses 
			cardView.addCardItem( cardItem );	// replace/add cardItem from card set to CardView
			
			// if cardItem hasn't loaded yet, start load
			if( !cardItem.displayLoaded )		
			{
				if( !cardItem.isLoading )
				{
					cardView.showLoading( _loadingCardWrapper );
					_cardGroup.loadCardItem( cardItem, true, Command.create( cardItemLoaded, cardView) );	// loads card xml and assets
					// TODO :: Need to handle a failed load, should display an Under Construction card instead.
				}
			}
			else
			{
				cardItemLoaded( cardItem, cardView );
			}
		}

		/**
		 * Replace card Entity's display.
		 * @param cardEntity
		 * @param cardItem
		 */
		private function cardItemLoaded( cardItem:CardItem, cardView:CardView, remove:Boolean = false ):void 
		{
		
			// check to make sure cardItem is on active page
			if (activePage.cards.indexOf(cardItem) != -1)
			{
				if(cardView == null)
				{
					activePage.cards.removeAt(activePage.cards.indexOf(cardItem));
					return;
				}
				if( cardItem.cardData != null )
				{
					// CardItem's base assets are available, but special card content has not yet been loaded
					// TODO :: This check handles possible loading race condition, look into further. - bard
					if( cardView.cardEntity.get(CardItem) == cardItem )
					{
						cardView.loadCardContent( null, _loadingWheelWrapper);
						// don't do for web anymore
						if (( !cardItem.bitmapWrapper ) && (PlatformUtils.isMobileOS))
						{ 
							cardView.bitmapCardBack( CardGroup.CARD_BOUNDS, _cardScale );	// adjust scale
						}
						cardView.displayCardItem();	// adds card Entity's CardItem display to CardView
						cardView.hide( false );		// makes CardView visible
						enableInteraction( cardView );
						// show members only graphic
						if (ItemManager(shellApi.itemManager).isMembersCard(cardItem.cardData.id))
						{
							//cardItem.membersOnly = BitmapUtils.createBitmapSprite(_membersOnlyGraphic);
							//addMembersOnlyGraphic(cardItem, cardView);
						}
						cardItem.cardReady.dispatch();
					}
					else
					{
						trace( "Error :: Inventory : cardItemLoaded : loading race condition." );
					}
				}
				else	// card xml failed to load
				{
					trace( "Error :: Inventory : cardItemLoaded : loading failed." );
					// TODO :: manage missing card, do we try to remove, show special card indicating circumstance?
				}
			}

		}
		
		private function enableInteraction( cardView:CardView ):void 
		{
			var interaction:Interaction = cardView.cardEntity.get(Interaction);
			interaction.click.add( Command.create( cardClicked, cardView) );
		}
		
		private function cardClicked( cardEntity:Entity, cardView:CardView ):void 
		{
			if( super.isOpened )	// don't 'open' card unless inventory has finished opening and is not in process of closing
			{
				
				//check if card has finished loading
				if( CardItem(cardEntity.get(CardItem)).displayLoaded )
				{
					//track card enlarged for ads
					if( CardItem(cardEntity.get(CardItem)).cardData.campaignId)
					{
						shellApi.adManager.track(CardItem(cardEntity.get(CardItem)).cardData.campaignId,AdvertisingConstants.TRACKING_CARD_ENLARGED,"Card", CardItem(cardEntity.get(CardItem)).cardData.name);		
					
						/*
						if(CardItem(cardEntity.get(CardItem)).cardData.campaignData != null && CardItem(cardEntity.get(CardItem)).cardData.campaignData.impressionUrls != null)
						{
							// get impressions url
							var impressions:String = CardItem(cardEntity.get(CardItem)).cardData.campaignData.impressionUrls.byIndex(0);
							// if found, then send tracking pixels
							if(impressions != null)
								shellApi.adManager.sendTrackingPixels(impressions);
						}
						*/
					}
					
					// set card that was clicked to be hidden card		
					_hiddenCardView = cardView;
					// start content (if applicable) 
					_hiddenCardView.startCardContent();
					
					// turn on darken
					_darkenEffect.fadeToBlack( .2 );	
					if( !_darkenSignal )
					{
						_darkenSignal = InteractionCreator.create( _darkenEffect.box, InteractionCreator.CLICK )
					}
					_darkenSignal.add( onDarkenClicked );
					
					// position
					var selectionCardEntity:Entity = _selectionCardView.cardEntity;
					var spatial:Spatial = selectionCardEntity.get(Spatial);
					EntityUtils.positionByEntity( selectionCardEntity, _hiddenCardView.cardEntity, true );
					spatial.x += _itemHolder.x;
					spatial.y += _itemHolder.y;
					
					// transfer selected card's display to _selectionCardView
					_selectionCardView.transferDisplay( _hiddenCardView );
					Display(_selectionCardView.cardEntity.get(Display)).visible = true;
					Display(_hiddenCardView.cardEntity.get(Display)).visible = false;
					
					// tween display card to center
					// scale card back first & bitmap. reshrink and apply tween
					var tween:Tween = selectionCardEntity.get(Tween);
					tween.to(spatial, .3, {scaleX:CARD_DISPLAY_SCALE, scaleY:CARD_DISPLAY_SCALE, x:shellApi.viewportWidth/2, y:shellApi.viewportHeight/2, ease:Back.easeOut, onComplete:onSelectionOpened});
					
					lockSlide( true );
					
					itemClicked.dispatch(_hiddenCardView);
				}
			}
		}
		
		private function onSelectionOpened():void 
		{
			lockSlide( !_gridControl.canScroll );
			
		}
		
		private function onDarkenClicked( e:Event ):void 
		{
			closeSelectionCard();
		}
		
		private function closeSelectionCard():void 
		{
			if( _selectionCardView.cardEntity )
			{
				var display:Display = _selectionCardView.cardEntity.get(Display);
				if( display.visible )
				{
					display.visible = false;
					unhideSelected();
					_darkenEffect.fadeFromBlack( .25 );
				}
			}
		}
		
		private function hideSelectionCard():void 
		{
			_selectionCardView.hide();
			_darkenEffect.hide();
			if( _darkenSignal )
			{
				_darkenSignal.removeAll();
			}
		}
		
		private function unhideSelected():void 
		{
			if( _hiddenCardView )
			{
				_hiddenCardView.refreshDisplay();
				_hiddenCardView.hide( false );
				_hiddenCardView.stopCardContent();	// stop content (if applicable)
				
				// restore members only graphic if needed
				var cardItem:CardItem = _hiddenCardView.cardEntity.get(CardItem);
				if (cardItem.membersOnly != null)
				{
					addMembersOnlyGraphic(cardItem, _hiddenCardView);
				}
				_hiddenCardView = null;
			}
		}
		
		private function addMembersOnlyGraphic(cardItem:CardItem, cardView:CardView):void
		{
			cardItem.membersOnly.x = cardView.cardDisplay.x - (cardView.cardDisplay.width/2);
			cardItem.membersOnly.y = cardView.cardDisplay.y + (cardView.cardDisplay.height/2);
			cardView.cardDisplay.addChild(cardItem.membersOnly);
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// SCROLL //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setupSlider():void
		{
			var container:MovieClip = this.screen.content.sliderContainer;
			container.x = this.shellApi.viewportWidth / 2;
			container.y = this.shellApi.viewportHeight - 18;
			
			this._slider = EntityUtils.createSpatialEntity(this, container.slider);
			InteractionCreator.addToEntity(this._slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("x");
			this._slider.add(draggable);
			this._slider.add(new Slider());
			this._slider.add(new MotionBounds(new Rectangle(-136, -5, 272, 10)));
			this._slider.add(this._ratio);
			ToolTipCreator.addToEntity(this._slider);
			draggable.drop.add( onSliderRelease );
			
			this._bar = EntityUtils.createSpatialEntity(this, container.bar);
			var interaction:Interaction = InteractionCreator.addToEntity(this._bar, [InteractionCreator.CLICK]);
			interaction.click.add(this.onBarClicked);
			ToolTipCreator.addToEntity(this._bar);
		}
		
		private function onBarClicked(entity:Entity):void
		{
			var display:DisplayObject = this._bar.get(Display).displayObject;
			var box:Rectangle = this._slider.get(MotionBounds).box;
			
			this._ratio.decimal = Utils.toDecimal(display.mouseX, box.left, box.right);
		}
		
		private function onSliderRelease( entity:Entity = null ):void 
		{
			if ( _gridControl.canScroll ) 
			{
				activePage.savedGridPercent = _ratio.decimal;
			}
		}
		
		private function lockSlide( lock:Boolean = true ):void 
		{
			// set disabled
			_gridControl.lock = lock;
			Draggable(_slider.get(Draggable)).disable = lock;
			ScrollBox(_grid.get(ScrollBox)).disable = lock;

			// determine slider & scroll visibility
			var disabled:Boolean = !_gridControl.canScroll;
			MovieClip(super.screen.content.border_R).visible = MovieClip(super.screen.content.border_L).visible = !disabled;
			MovieClip(super.screen.content.sliderContainer).visible = !disabled;
		}
		
		/**
		 * Grid has shifted, update current card entities based on visibility determined by tableau.
		 */
		private function onGridShift():void 
		{
			closeSelectionCard();	// close display card (closes if open)
		}
		
		//// ACCESSORS ////
		
		protected var _currentType:String = ISLAND;	// the tab that the inventory opens to
		public function get currentType():String { return _currentType; }
		public function set currentType( cardType:String ):void 
		{
			// check validity of tab 
			if( cardType == ISLAND || cardType == STORE || cardType == CUSTOM  || cardType == PETS )
			{
				_currentType = cardType;
			}
			else
			{
				_currentType = ISLAND;
			}
		}
		
		private var _currentSubType:String;		// the sub-tab that the inventory opens to
		public function get currentSubType():String { return _currentSubType; }
		public function set currentSubType( cardSubType:String ):void 
		{
			_currentSubType = cardSubType;
		}
		
		private var _activePage:InventoryPage;
		public function get activePage():InventoryPage	{ return _activePage; } 
		public function set activePage( inventoryPage:InventoryPage ):void 
		{
			_activePage = inventoryPage;
			_currentType = inventoryPage.id;
		}
		
		private var _layout:uint;							// dictates the layout style of Tableau
		private function get layoutStyle():uint	{ return _layout; } 
		private function set layoutStyle( layoutType:uint ):void 
		{
			_layout = layoutType;	// TODO :: check validity
			
			if( _layout == LAYOUT_FLOW_STYLE )
			{
				_rows = 1;
			}
			else if ( _layout == LAYOUT_GRID_STYLE )
			{
				_rows = 2;
			}
		}
		
		
		public static const ISLAND:String		= "island";
		public static const CUSTOM:String		= "custom";
		public static const STORE:String		= "store";
		public static const PETS:String			= "pets";
		
		public static const ISLAND_TAB:String	= "Island";
		public static const CUSTOM_TAB:String	= "Prizes";
		public static const STORE_TAB:String	= "Store";
		public static const PETS_TAB:String		= "Pets";
		
		public static const EMPTY_ISLAND_CARDS_MESSAGE:String 	= "Your inventory is empty.\nExplore the island and see what you can find!";
		public static const EMPTY_STORE_CARDS_MESSAGE:String 	= "You don't have any store items yet.\nVisit the store to get the\nlatest costumes and cool stuff.";
		public static const EMPTY_CUSTOM_CARDS_MESSAGE:String 	= "You don't have any sponsored items.\nVisit the sponsor quests to get\ncustom costumes and other prizes.";
		public static const EMPTY_PETS_CARDS_MESSAGE:String 	= "You don't have any pets yet.";
		
		public static const OPEN_SATCHEL_AUDIO:String = 'ui_open_bag.mp3';
		
		public static const THUMB_ID:String 	= 'scrollerThumb';
		public static const SLIDER_ID:String 	= 'sliderControl';
		public static const TABLEAU_ID:String 	= 'cardTableau';
		
		public static const LAYOUT_FLOW_STYLE:uint	= 0;
		public static const LAYOUT_GRID_STYLE:uint	= 1;
		
		private static const TAB_HEIGHT:Number = 73;
		public const LAYOUT_GUTTER:Number = 10;
		public const MAX_ROWS:uint = 2;
		public const MIN_CARDS_VISIBLE:uint = 3;		// minimum cards that will be visible in single row layout
		public const CARD_DISPLAY_SCALE:Number = 1.4;
		
		// brain tracking events
		public static const INVENTORY_OPENED:String			= 'InventoryOpened';
		public static const INVENTORY_CLOSED:String			= 'InventoryClosed';
		public static const INVENTORY_REORGANIZED:String	= 'InventoryReorganized';
		
		private const LOADING_CARD_PATH:String = "items/ui/background_loading.swf";
		private const LOADING_WHEEL_PATH:String = "ui/general/load_wheel.swf";
		
		// TEMP
		private const CONSTRUCTION_CARD:String = "_under_construction";
		private const CREDITS_CARD:String		= "_credits_card";
		
		/**
		 * Dispatched whenever the player clicks anywhere on an inventory item card
		 */
		public var itemClicked:Signal;	// returns the CardItem that was clicked
		public var makeCloseButton:Boolean = true;
		
		private var _cardGroup:CardGroup;
		private var _inventoryPages:Vector.<InventoryPage>;
		private var _gridCreator:GridScrollableCreator;
		
		private var _loadingCardWrapper:BitmapWrapper;
		private var _loadingWheelWrapper:BitmapWrapper;
		private var _portHole:Rectangle;
		private var _itemHolder:Sprite;						// DisplayObjectContainer which contains a set of cards
		private var _selectionCardView:CardView;			// entity used for when a card is selected, scales up and into center of screen
		private var _hiddenCardView:CardView;
		private var _darkenEffect:ScreenEffects;
		private var _darkenSignal:NativeSignal;
		
		private var _cardScale:Number;
		private var _gridControl:GridControlScrollable;
		private var _rows:uint;
		private var _layoutButton:MultiStateToggleButton;
		private var _messageText:TextField;
		
		private var _grid:Entity;
		private var _slider:Entity;
		private var _bar:Entity;
		private var _scroll:Entity;
		private var _ratio:Ratio;
		
		private var _tabView:TabView;
		private var _cardArray:Vector.<CardView> = new Vector.<CardView>();
	}
}

