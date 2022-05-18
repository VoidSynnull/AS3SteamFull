package game.scenes.hub.bundleShop
{
	import com.greensock.easing.Back;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.ui.Button;
	import game.components.ui.CardItem;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.GridSlot;
	import game.components.ui.Ratio;
	import game.components.ui.ScrollBox;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.GridScrollableCreator;
	import game.data.bundles.BundleData;
	import game.data.display.BitmapWrapper;
	import game.data.dlc.DLCContentData;
	import game.data.ui.TransitionData;
	import game.data.ui.card.CardSet;
	import game.managers.BundleManager;
	import game.scene.template.ContentRetrievalGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.scenes.hub.bundleShop.components.Bundle;
	import game.systems.ui.ScrollBoxSystem;
	import game.ui.card.CardView;
	import game.ui.popup.Popup;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	public class BundleShowcase extends Popup
	{
		public function BundleShowcase(container:DisplayObjectContainer=null, content:MovieClip = null)
		{
			super(container);
			super.screen = content;
			super.id = GROUP_ID;
			
			onBundlePurchased = new Signal(BundleData);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.config( null, null, false, false, true, false );

			if( super.screen == null )
			{
				super.screenAsset = "bundle_showcase.swf";
				super.groupPrefix = "scenes/hub/bundleShop/";	// TODO : if we're to use this universally this will need to be placed elsewhere.
				super.init(container); // creates a new groupContainer, and adds it to container
				super.load();
			}
			else
			{
				super.init(container); // creates a new groupContainer, and adds it to container
				this.loaded();
			}
		}
		
		public override function destroy():void 
		{
			// NOTE :: this step is important, need to remove references BundleManager may keep to assets
			if( _bundleManager )
			{
				_bundleManager.clearBundleData();
				_bundleManager = null;
			}
			
			if (_loadingCardWrapper) {
				_loadingCardWrapper.destroy();
			}

			if (_loadingWheelWrapper) {
				_loadingWheelWrapper.destroy();
			}
			
			if( _darkenSignal )
			{
				_darkenSignal.removeAll();
				_darkenSignal = null;
			}

			super.destroy();
		}
		
		override public function loaded():void
		{
			super.preparePopup();
			
			// config transition, now know dimensions of screen
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = 0.5;
			super.transitionIn.startPos = new Point( 0, -DisplayObject(super.screen).height);
			super.transitionIn.endPos = new Point(0, 0);
			super.transitionIn.ease = Back.easeOut;

			DisplayObjectContainer(super.groupContainer).mouseEnabled = false;
			
			// TODO :: scale to fit screen dimensions, then bitmap
			// TODO :: once scale appropriately, need to reposition to center of scene
			var clip:MovieClip = this.screen["bundle_panel"];
			//var scalePercent:Number = super.shellApi.viewportWidth/clip.width;
			//var scalePercent:Number = 1 - (super.shellApi.camera.scale - 1); 
			//clip.scaleX = scalePercent;
			super.createBitmap( clip, super.shellApi.camera.scale );
			
			clip = this.screen["buy_panel"];
			super.convertContainer( clip, super.shellApi.camera.scale );

			// load active Bundle data
			// NOTE :: bundle Manager will likely be setup prior to opening BundleShop
			// TODO :: Need to handle error/fail scenarios when loading/decompressing zips. - bard
			if( _bundleManager == null )	
			{ 
				_bundleManager = super.shellApi.getManager(BundleManager) as BundleManager; 
			}
			
			if( PlatformUtils.isMobileOS )
			{
				_bundleManager.clearBundleData();	// NOTE :: Here as a precaution, should get cleared out in destroy method
				_bundleManager.setup( this.setup, true, true ) ;
			}
			else
			{
				// FOR DEBUG :: Create BundleManager if not already present (in cases where shell step that creates BundleManager was not included)
				// allow for bundles to be viewed on non-mobile versions, useful for testing
				if( !_bundleManager )
				{
					// add Bundles manager
					_bundleManager = new BundleManager();
					this.shellApi.addManager( _bundleManager );
				}
				// loads bundle data, skips content load, loads bundle card data
				_bundleManager.clearBundleData();	// NOTE :: Here as a precaution, should get cleared out in destroy method
				_bundleManager.setup( Command.create( _bundleManager.loadActiveBundleDatas, this.setup) );
			}
			
			// create group to manage content retrieval
			_contentRetrievalGroup = new ContentRetrievalGroup();
			_contentRetrievalGroup.setupGroup( this.parent, true, Scene(this.parent).overlayContainer );
		}
		
		private function setup():void
		{
			this._cardGroup = CardGroupPop(this.getGroupById("cardGroup"));
			if(!this._cardGroup)
			{
				this._cardGroup = this.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroupPop;
			}
			
			_gridCreator = new GridScrollableCreator();
			
			this.setupBuyButton();
			this.setupBundles();
			
			var clip:MovieClip = super.screen["bundleFrame_ref"];
			var bundleFrameRect:Rectangle = clip.getBounds(clip.parent);
			bundleFrameRect.x = bundleFrameRect.y = 0;
			clip.parent.removeChild(clip);
			
			var bundleGrid:Entity = _gridCreator.create( bundleFrameRect.clone(), BUNDLE_BOUNDS, 1, 0, this, BUNDLE_GUTTER, false, null, BUNDLE_GUTTER, "bundle_grid");
			var bundleGridControl:GridControlScrollable = bundleGrid.get( GridControlScrollable );
			var ratio:Ratio = bundleGrid.get(Ratio);
			
			bundleGridControl.createSlots( _bundleManager.totalActiveBundles, 0, 1);
			var bundleContainer:MovieClip = super.screen["bundleContainer"];
			bundleContainer.mouseChildren = bundleContainer.mouseEnabled = true;
			
			var box:ScrollBox = new ScrollBox(bundleContainer, bundleFrameRect.clone(), 100, SCROLL_RATE, false, 50);
			bundleGrid.add(box);
			
			//var interactions:Array = [InteractionCreator.CLICK];
			var i:int;
			var maxBundles:int = Math.min( _bundleManager.totalActiveBundles, MAX_BUNDLEVIEWS);
			for (i = 0; i < MAX_BUNDLEVIEWS; i++)
			{	
				var bundleEntity:Entity = EntityUtils.createMovingEntity( this, null, bundleContainer );
				bundleEntity.add( new Bundle() );
				//InteractionCreator.addToEntity( bundleEntity, interactions ); 
				_gridCreator.addSlotEntity( bundleGrid, bundleEntity, BUNDLE_BOUNDS, onBundleActivated, onBundleDeactivated );
				bundleEntity.add( new Id(String("bundle_" + i)) );
				bundleEntity.sleeping = true;
				
				//bundleEntity.add( new Sleep( true, true ) );
			}
			
			// keep reference to textfields
			this._bundleName 			= TextUtils.refreshText(super.screen["bundleName"]);
			this._bundleName.autoSize 	= TextFieldAutoSize.CENTER;
			this._bundleStatus 			= TextUtils.refreshText(super.screen["bundleStatus"]);
			this._bundleStatus.autoSize = TextFieldAutoSize.CENTER;
			
			// create Cards
			var cardContainer:MovieClip = super.screen["cardContainer"];
			cardContainer.mouseChildren = cardContainer.mouseEnabled = true;
			
			clip = super.screen["cardFrame_ref"];
			var cardFrameRect:Rectangle = clip.getBounds(clip.parent);
			cardContainer.x = clip.x;
			cardContainer.y = clip.y;
			cardFrameRect.x = cardFrameRect.y = 0;
			clip.parent.removeChild( clip );

			// want dimension of card slot in a single row layout, want to fit at least 3 cards on screen at once 
			_cardGrid = _gridCreator.create( cardFrameRect, CardGroup.CARD_BOUNDS, MIN_CARDS_VISIBLE, 1, this, CARD_GUTTER, true, onCardGridShift, CARD_GUTTER, "card_grid");
			_cardGridControl = _cardGrid.get( GridControlScrollable );
			_cardRatio = _cardGrid.get( Ratio );
			//_cardScale = _cardGridControl.slotRect.width/CardGroup.CARD_BOUNDS.width;
			_cardScale = CARD_DISPLAY_SCALE;
			
			// add ScrollBox to gridEntity
			_cardGrid.add(new ScrollBox( cardContainer, _cardGridControl.frameRect, 100, 50, true) );
			var interactions:Array = [InteractionCreator.CLICK];
			for (i = 0; i < MAX_CARDVIEWS; i++) 
			{	
				var cardView:CardView = _cardGroup.createCardView( this );	// create CardView (inherets from UIView)
				var cardEntity:Entity = cardView.createCardEntity( null, cardContainer );	// create card Entity within CardView
				// add additional components necessary for inventory
				InteractionCreator.addToEntity( cardEntity, interactions ); 
				_gridCreator.addSlotEntity( _cardGrid, cardEntity, CardGroup.CARD_BOUNDS, onCardActivated, onCardDeactivated );
				cardEntity.add( new OwningGroup( cardView ) );
				cardEntity.add( new Id(String("bundle_card_" + i)) );
			}
			
			this.addSystem(new ScrollBoxSystem());

			shellApi.loadFiles( [ shellApi.assetPrefix + LOADING_CARD_PATH, shellApi.assetPrefix + LOADING_WHEEL_PATH], onCardDefaultsLoaded );	// load the 'loading card" asset
		}	
		
		/**
		 * Determines what cards should be included with bundle, can vary based on gender of user.
		 * Updates BundleData's CardSet
		 */
		private function setupBundles():void
		{
			// create the final card set for all active bundles based on gender
			var gender:String = this.shellApi.profileManager.active.gender;
			if( !DataUtils.validString(gender) )
			{
				gender = SkinUtils.getLookAspect( shellApi.player, SkinUtils.GENDER).value
			}
			
			// determine what cards should be included with bundle, this can vary based on gender of user
			var cardSet:CardSet;
			var bundleData:BundleData;
			var i:int;
			var j:int;
			var k:int;
			for (i = 0; i < _bundleManager.bundleDatas.length; i++) 
			{
				bundleData = _bundleManager.bundleDatas[i];		
				if( bundleData.cardSetActive == null )	
				{ 
					bundleData.cardSetActive = new CardSet( "active" ); 
				}
				
				for (j = 0; j < bundleData.cardSets.length; j++) 
				{
					cardSet = bundleData.cardSets[j];
					if( cardSet.id == "shared" || cardSet.id == gender )
					{
						for (k = 0; k < cardSet.cardIds.length; k++) 
						{
							bundleData.cardSetActive.add( cardSet.cardIds[k] ); 
						}
					}
				}
			}
		}
		
		private function setupBuyButton():void
		{
			var clip:MovieClip = super.screen["buy_panel"];
			_buyPanelInX = clip.x;
			_buyPanelOutX = clip.x + clip.width;
			_buyPanel = EntityUtils.createMovingEntity( this, clip );
			_buyPanel.add( new Tween() );
			_buyPanelHidden = false;
			
			// buy button has different states depending on bundle ( Buy, Get, Owned )
			clip = clip["buy_btn"];
			//super.convertContainer( clip );	// Bitmapping becomes tricky with mutliple states
			this._buyButton = ButtonCreator.createButtonEntity(clip, this, this.getBundle);
			
			// start panel off screen
			( _buyPanel.get(Spatial) as Spatial ).x = _buyPanelOutX;
			_buyPanelHidden = true;
		}
		
		private function onCardDefaultsLoaded():void
		{			
			// store references to loading assets
			var loadWheel:MovieClip = shellApi.getFile( shellApi.assetPrefix + LOADING_WHEEL_PATH ) as MovieClip;
			_loadingWheelWrapper = DisplayUtils.convertToBitmapSprite( loadWheel, loadWheel.getBounds(loadWheel), _cardScale, false );
			var loadingCard:MovieClip = shellApi.getFile( shellApi.assetPrefix + LOADING_CARD_PATH ) as MovieClip;
			_loadingCardWrapper = DisplayUtils.convertToBitmapSprite( loadingCard, CardGroup.CARD_BOUNDS, _cardScale );
			
			// create darken effect
			_darkenEffect = new ScreenEffects( Scene(this.parent).overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight, .5, 0);//, new Point(-shellApi.viewportWidth/2,-shellApi.viewportHeight/2) );
			//_darkenEffect = new ScreenEffects( this.groupContainer, shellApi.viewportWidth, shellApi.viewportHeight, .5, 0);//, new Point(-shellApi.viewportWidth/2,-shellApi.viewportHeight/2) );
			_darkenEffect.hide();
			
			// create CardView, use to display the 'selected' cards
			_selectionCardView = _cardGroup.createCardView( this );
			var cardEntity:Entity = _selectionCardView.createCardEntity( null, Scene(this.parent).overlayContainer );
			//var cardEntity:Entity = _selectionCardView.createCardEntity( null, super.groupContainer );
			_selectionCardView.cardEntity.add( new Tween() );
			
			// display initial bundle
			changeBundle(  _bundleManager.bundleDatas[0] );
			
			super.open();
			super.groupReady();
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// BUNDLES /////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Attmept the retrieval/purchase of the currently selected bundled 
		 * @param entity - Buy button Entity, not necessary for method
		 */
		private function getBundle(entity:Entity = null):void
		{
			if(activeBundle && !_activeBundleLocked)
			{
				// check to see if bundle has already been retrieved
				if( checkPurchased( activeBundle.id ) || activeBundle.free)
				{
					if( checkOwned( activeBundle.id ) )
					{
						return;	// player already has bundle, do nothing
					}
				}
				
				// trigger purchase process
				if( AppConfig.iapOn && shellApi.dlcManager != null )
				{
					var dlcData:DLCContentData = shellApi.dlcManager.getDLCContentData(activeBundle.id);
					if( dlcData )
					{
						unlockActiveBundle(false);	// lock active bundle until transaction is complete
						_contentRetrievalGroup.processComplete.addOnce(retrievalResponse);
						_contentRetrievalGroup.purchaseContent(activeBundle.id, this.CONTENT_TYPE, false );
					}
					else
					{
						trace( this," : WARNING :: getBundle :: content could not be found for: " + activeBundle.id );
					}
					//This "return" was removed so debug builds could still call getBundleCards() with debug on without a successful store purchase.
					//return;
				}
				
				// FOR TESTING :: allow for cards to be retrieved outside of DLC process
				if( AppConfig.debug )
				{
					if(!AppConfig.production)
					{
						getBundleCards();
					}
				}
			}
		}
		
		private function retrievalResponse( success:Boolean = false, content:String = "" ):void
		{
			if( success )
			{
				getBundleCards();
			}
			else
			{
				unlockActiveBundle(true);
			}
		}
		
		private function getBundleCards():void
		{
			// close popup
			if( _contentRetrievalGroup ) { _contentRetrievalGroup.closePopup(); }
			
			// make sure ItemGroup is available
			var itemGroup:ItemGroup = super.parent.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( itemGroup == null )
			{
				itemGroup = new ItemGroup();
				itemGroup.setupScene( Scene(super.parent) );
			}
			
			// show/give cards
			var cardShown:Boolean = false;
			if( activeBundle.cards.length > 0  )
			{
				var index:int = activeBundle.cards.length - 1;
				var cardItem:CardItem;
				for(index; index >= 0; --index)
				{
					cardItem = activeBundle.cards[index];
					if( super.shellApi.getItem( cardItem.itemIdNoPrefix, CardGroup.STORE ) )
					{
						cardShown = true;
						if( index > 0 )
						{
							itemGroup.showItem( cardItem.itemId, CardGroup.STORE);
						}
						else
						{
							// on last card shown we want to add a handler
							itemGroup.showItem( cardItem.itemId, CardGroup.STORE, unlockActiveBundle );
						}
					}
				}
			}
			else
			{
				trace( this," :: Error : getBundleCards : bundle should always have list of cards, activebundle did not: " + activeBundle.id );
			}
			
			// cards were already in inventory, no need to shown them again so unlock bundles
			// otherwise Bundles will unlock when cards finish displaying
			if( !cardShown )
			{
				// TODO :: May want to update bundle status to let user know items are already in inventiry? - bard
				unlockActiveBundle();
			}
			
			//Add the current BundleData to the active ProfileData's Array of BundleData.
			setOwned( activeBundle );
			this.shellApi.saveGame();
			
			// update textual status of bundle
			this.setBundleStatus();
			onBundlePurchased.dispatch( activeBundle );
		}
		
		private function unlockActiveBundle( unlock:Boolean = true ):void
		{
			_activeBundleLocked = !unlock;
		}
		
		/**
		 * Change the active bundle
		 * @param bundleData
		 */
		private function changeBundle( bundleData:BundleData ):void 
		{
			if( _activeBundleLocked )
			{
				// can't change bundle until it is unlocked
				return; 
			}
			else if( activeBundle == null )
			{
				// if no bundle has been set yet (bundle showcase is first opening)
				activeBundle = bundleData;
			}
			else if ( activeBundle.id == bundleData.id)
			{
				// is current card set is already being displayed ignore request
				trace("BundleStore :: changeBundle : Won't redisplay the same bundle set");
				return;
			}
			else										// different bundle has been selected, save current setting before setting assigning new page
			{
				activeBundle = bundleData;
			}

			// update text display with bundle info
			this._bundleName.text 	= activeBundle.title;
			
			this.setBundleStatus();
			
			// prepare cards for display, if no cards are present displays message
			prepareCardSet();
			
			// determine slot dimensions, create new slots
			var slotRect:Rectangle = GeomUtils.getLayoutCellRect( _cardGridControl.frameRect, CardGroup.CARD_BOUNDS, MIN_CARDS_VISIBLE, 1, CARD_GUTTER );	// determine dimension of Tableau slot
			_cardGridControl.createSlots( activeBundle.numCards(), 1, 0, slotRect );	// create new slots	for grid (not the same as the cards)							
			
			// apply saved grid position
			_cardRatio.decimal = 0;
			//_percent.percent = activePage.savedGridPercent
			
			// allow card grid to be unlocked if applicable
			lockCardSlide( !_cardGridControl.canScroll );
		}
		
		private function setBuyBundleButton( state:String = "", disable:Boolean = false ):void
		{
			if( state != "" )
			{
				var clip:MovieClip = MovieClip(EntityUtils.getDisplayObject(_buyButton)["button"]);
				if( state == BUTTON_BUY )
				{
					DisplayObject(clip[BUTTON_BUY]).visible = true;
					DisplayObject(clip[BUTTON_RETRIEVE]).visible = false;
				}
				else if ( state == BUTTON_RETRIEVE )
				{
					DisplayObject(clip[BUTTON_BUY]).visible = false;
					DisplayObject(clip[BUTTON_RETRIEVE]).visible = true;
				}
			}

			if( disable )
			{
				if( !_buyPanelHidden )
				{
					TweenUtils.entityTo( _buyPanel, Spatial, .5, { x:_buyPanelOutX, ease:Back.easeIn });
					(_buyButton.get(Button) as Button).isDisabled = true;
					_buyPanelHidden = true;
				}
			}
			else
			{
				if( _buyPanelHidden )
				{
					TweenUtils.entityTo( _buyPanel, Spatial, .5, { x:_buyPanelInX, ease:Back.easeOut });
					(_buyButton.get(Button) as Button).isDisabled = false;
					_buyPanelHidden = false;
				}
			}
		}
		
		/**
		 * Update the buy button and bundle text based on active bundle's state.
		 */
		private function setBundleStatus():void
		{		
			if( checkPurchased(activeBundle.id) )
			{
				if( checkOwned(activeBundle.id) )
				{
					this._bundleStatus.text = "Purchased & Available in Inventory!";
					setBuyBundleButton( "", true );
				}
				else
				{
					this._bundleStatus.text = "Purchased! Click below to add to Inventory.";
					setBuyBundleButton( BUTTON_RETRIEVE );
				}
			}
			else
			{
				this._bundleStatus.text = ( activeBundle.free ) ? "FREE" : "Buy Now";
				if(checkOwned(activeBundle.id))// making it so that free items that have been purchased do not have a buy button
					setBuyBundleButton( "", true );
				else
					setBuyBundleButton( BUTTON_BUY );
			}
		}
		
		/**
		 * Determines if the bundle has been purchsed on an app-wide level.
		 * @param bundleId
		 * @return 
		 */
		private function checkPurchased( bundleId:String ):Boolean
		{
			// check dlc for purchased status
			if( shellApi.dlcManager )
			{
				var dlcContent:DLCContentData = shellApi.dlcManager.getDLCContentData( activeBundle.id );
				if( dlcContent != null )
				{
					return dlcContent.purchased;
				}
			}
			else
			{
				// USED FOR TESTING :: Should really only refer to DLCContentData to determine purchased
				var ownedBundleIds:Array = this.shellApi.profileManager.active.bundlesOwned;
				for(var index:int = ownedBundleIds.length - 1; index > -1; --index)
				{
					if( String(ownedBundleIds[index]) == activeBundle.id)
					{
						return true;
					}
				}
			}
			return false;
		}
		
		/**
		 * Determines if the bundle is 'posessed' by the currently active user.
		 * This does not refer to DLCManager, but only the list of ownedBundles by active profile. 
		 * @param bundleId
		 * @return 
		 */
		private function checkOwned( bundleId:String ):Boolean
		{
			var ownedBundleIds:Array = this.shellApi.profileManager.active.bundlesOwned;
			for(var index:int = ownedBundleIds.length - 1; index > -1; --index)
			{
				if( String(ownedBundleIds[index]) == bundleId )
				{
					return true;
				}
			}
			return false;
		}
		
		private function setOwned( bundleData:BundleData ):void
		{			
			// Add to bundle id to profile specific list of owned bundles
			if( this.shellApi.profileManager.active.bundlesOwned.indexOf( bundleData.id ) == -1 )
			{
				this.shellApi.profileManager.active.bundlesOwned.push( bundleData.id );
			}
		}
		
		private function onBundleDeactivated(bundleEntity:Entity):void 
		{
			//Sleep(bundleEntity.get(Sleep)).sleeping = true;
			bundleEntity.sleeping = true;
			EntityUtils.visible(bundleEntity, false);
		}
		
		private function onBundleActivated(bundleEntity:Entity):void 
		{
			EntityUtils.visible(bundleEntity, true);
			bundleEntity.sleeping = false;
			
			// assign data
			var slot:GridSlot = bundleEntity.get(GridSlot);
			if(slot.index < _bundleManager.totalActiveBundles)
			{
				trace("Slot :", slot.index, "/", _bundleManager.totalActiveBundles);
				
				var bundleData:BundleData = _bundleManager.bundleDatas[slot.index];
				Bundle(bundleEntity.get(Bundle)).bundleData = bundleData;
				
				trace("BundleData :: ID =", bundleData.id, ", Clip =", bundleData.clip, ", Loading =", bundleData.isLoading);
				
				// assign display
				if( bundleData.clip == null )		
				{
					if( !bundleData.isLoading )
					{
						EntityUtils.visible(bundleEntity, false);
						_bundleManager.loadBundleAssets( bundleEntity, bundleData, Command.create(this.onBundleAssetsLoaded, bundleEntity, bundleData) );
					}
				}
				else
				{
					showBundleIcon( bundleEntity, bundleData );
				}
			}
		}
		
		private function onBundleAssetsLoaded( bundleEntity:Entity, bundleData:BundleData ):void
		{
			// TODO :: convert to bitmap timeline, add button
			EntityUtils.visible(bundleEntity, true);
			bundleData.isLoading = false;
			var display:Display = bundleEntity.get(Display);
			display.refresh( bundleData.clip, display.container );
			
			ButtonCreator.assignButtonEntity( bundleEntity, bundleData.clip, this, bundleClicked, null, null, null, false );	// Bitmapping causes headaches, maybe leave as vector for now. -bard
			
			if( bundleData == activeBundle )
			{
				_activeBundleEntity = bundleEntity;
				Button(_activeBundleEntity.get(Button)).isSelected = true;
			}

			GridControlScrollable(super.getEntityById("bundle_grid").get(GridControlScrollable)).refreshPositions = true;
		}
		
		private function showBundleIcon( bundleEntity:Entity, bundleData:BundleData):void
		{
			// refresh Button state
			(bundleEntity.get(Button) as Button).isSelected = ( bundleData == activeBundle );
			
			// replace DisplayObject
			EntityUtils.replaceDisplayObject( bundleEntity, bundleData.clip );
			
			//ButtonCreator.assignButtonEntity( bundleEntity, bundleData.clip, this, bundleClicked, null, null, null, false, true );	// Bitmapping causes headaches, maybe leave as vector for now. -bard

			enableBundleInteraction( bundleEntity );
		}
		
		private function enableBundleInteraction( bundleEntity:Entity ):void 
		{
			var interaction:Interaction = bundleEntity.get(Interaction);
			interaction.click.add( bundleClicked );
		}
		
		private function bundleClicked( bundleEntity:Entity ):void 
		{
			if( !_activeBundleLocked )
			{
				Button(_activeBundleEntity.get(Button)).isSelected = false;
				Button(bundleEntity.get(Button)).isSelected = true;
				
				_activeBundleEntity = bundleEntity;
				
				// TODO :: position to center of slider. - Bard
				changeBundle( Bundle(bundleEntity.get(Bundle)).bundleData );
			}
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// SCROLL //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		private function lockCardSlide( lock:Boolean = true ):void 
		{
			// set disabled
			_cardGridControl.lock = lock;
			//Draggable(_slider.get(Draggable)).disable = lock;
			ScrollBox(_cardGrid.get(ScrollBox)).disable = lock;
			
			// determine slider & scroll visibility
			var disabled:Boolean = !_cardGridControl.canScroll;
			//MovieClip(super.screen.content.border_R).visible = MovieClip(super.screen.content.border_L).visible = !disabled;
			//MovieClip(super.screen.content.sliderContainer).visible = !disabled;
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// CARDS /////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Grid has shifted, update current card entities based on visibility determined by tableau.
		 */
		private function onCardGridShift():void 
		{
			if( super.isReady )
			{
				closeSelectionCard();	// close display card (closes if open)
			}
		}
		
		/**
		 * Add CardItem components to CardSet. 
		 */
		private function prepareCardSet():void 
		{
			if(this.activeBundle.cards == null)	
			{
				this.activeBundle.cards = new Vector.<CardItem>();
				
				var cardItem:CardItem;
				var idPrefix:String;
				var listIndex:int = 0;
				
				var j:int;
				for (j = 0; j < this.activeBundle.cardSetActive.cardIds.length; j++) 
				{
					cardItem = new CardItem();
					cardItem.disableButtons = true;
					cardItem.itemIdNoPrefix = this.activeBundle.cardSetActive.cardIds[j];
					cardItem.itemId = ItemGroup.ITEM_PREFIX + cardItem.itemIdNoPrefix;
					cardItem.listIndex = listIndex++;
					cardItem.pathPrefix = "items/" + CardGroup.STORE + "/" + cardItem.itemId;
					this.activeBundle.cards.push( cardItem );
				}
			}
		}
		
		private function onCardDeactivated(cardEntity:Entity):void 
		{
			(cardEntity.group as CardView).deactivate();
		}
		
		private function onCardActivated(cardEntity:Entity):void 
		{
			var cardView:CardView = cardEntity.group as CardView
			var cardItem:CardItem = this.activeBundle.cards[GridSlot(cardEntity.get(GridSlot)).index];
			
			cardView.activate();				// activate CardView, unpauses 
			cardView.addCardItem( cardItem );	// replace/add cardItem from card set to CardView
			
			// if cardItem hasn't loaded yet, start load
			if( !cardItem.displayLoaded )		
			{
				if( !cardItem.isLoading )
				{
					//cardView.showLoading( _loadingCardWrapper );
					_cardGroup.loadCardItem( cardItem, true, Command.create( cardItemLoaded, cardView) );	// loads card xml and assets
					// TODO :: Need to handle a failed load, should display an Under Construction card instead.
				}
			}
			else
			{
				cardItemLoaded( cardItem, cardView );
			}
		}
		
		private function cardItemLoaded(cardItem:CardItem, cardView:CardView):void 
		{
			if( cardItem != null && cardView != null )
			{
				if(cardItem.cardData)
				{
					if(cardView.cardEntity.get(CardItem) == cardItem)
					{
						cardView.loadCardContent( null, _loadingWheelWrapper);
						if( !cardItem.bitmapWrapper ) 
						{ 
							cardView.bitmapCardBack(CardGroup.CARD_BOUNDS, _cardScale);
						}
						cardView.displayCardItem();
						cardView.hide( false );
						enableCardInteraction( cardView );
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
		
		private function enableCardInteraction( cardView:CardView ):void 
		{
			var interaction:Interaction = cardView.cardEntity.get(Interaction);
			interaction.click.add( Command.create( cardClicked, cardView) );
		}
		
		private function cardClicked( cardEntity:Entity, cardView:CardView ):void 
		{
			//check if card has finished loading
			if( CardItem(cardEntity.get(CardItem)).displayLoaded )
			{
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
				var hiddenSpatial:Spatial = _hiddenCardView.cardEntity.get(Spatial);	
				var point:Point = DisplayUtils.localToLocal( _hiddenCardView.container, super.groupContainer);
				spatial.x = point.x;
				spatial.y = point.y;
				spatial.scaleX = hiddenSpatial.scaleX;
				spatial.scaleY = hiddenSpatial.scaleY;
				
				
				// transfer selected card's display to _selectionCardView
				_selectionCardView.transferDisplay( _hiddenCardView );
				Display(_selectionCardView.cardEntity.get(Display)).visible = true;
				Display(_hiddenCardView.cardEntity.get(Display)).visible = false;
				
				this._buyButton.remove(ToolTipActive);
				
				// tween display card to center
				// scale card back first & bitmap. reshrink and apply tween
				var tweenDuration:Number = .3;
				selectionCardEntity.get(Tween).to(spatial, tweenDuration, {scaleX:CARD_DISPLAY_SCALE, scaleY:CARD_DISPLAY_SCALE, x:shellApi.viewportWidth/2, y:shellApi.viewportHeight/2, ease:Back.easeOut, onComplete:onSelectionOpened});
				
				lockCardSlide( true );
			}
		}
		
		private function onSelectionOpened():void 
		{
			lockCardSlide( !_cardGridControl.canScroll );		
		}
		
		private function onDarkenClicked( e:Event ):void 
		{
			closeSelectionCard();
		}
		
		private function closeSelectionCard():void 
		{
			this._buyButton.add(new ToolTipActive());
			
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
				_hiddenCardView = null;
			}
		}
		
		public static const GROUP_ID:String = "bundleStoreGroup";
		
		public const CARD_GUTTER:Number 		= 10;
		public const BUNDLE_GUTTER:Number 		= 5;
		public const MIN_CARDS_VISIBLE:uint 	= 4;
		public const CARD_DISPLAY_SCALE:Number 	= 1;
		public const MAX_CARDVIEWS:int 			= 6;
		public const MAX_BUNDLEVIEWS:int 		= 6;
		public const BUNDLE_BOUNDS:Rectangle = new Rectangle( -60, -40, 120, 80 );
		
		private const SCROLL_RATE:int = 10;
		private const LOADING_CARD_PATH:String = "items/ui/background_loading.swf";
		private const LOADING_WHEEL_PATH:String = "ui/general/load_wheel.swf";
		
		private const BUTTON_BUY:String = "buy";
		private const BUTTON_RETRIEVE:String = "retrieve";
		
		public var onBundlePurchased:Signal;
		
		private var _activeBundleLocked:Boolean = false;
		private var _activeBundle:BundleData;
		public function set activeBundle( bundleData:BundleData):void 
		{
			if( !_activeBundleLocked ) { _activeBundle = bundleData; }
		}
		public function get activeBundle():BundleData	{ return _activeBundle; }

		
		private const CONTENT_TYPE:String = "Bundle";
		
		private var _activeBundleEntity:Entity;
		
		private var _bundleName:TextField;
		private var _bundleStatus:TextField;
	
		private var _cardGrid:Entity;
		private var _cardGridControl:GridControlScrollable;
		private var _loadingCardWrapper:BitmapWrapper;
		private var _loadingWheelWrapper:BitmapWrapper;
		private var _selectionCardView:CardView;			// entity used for when a card is selected, scales up and into center of screen
		private var _cardScale:Number;
		private var _cardRatio:Ratio;
		private var _hiddenCardView:CardView;
		private var _darkenEffect:ScreenEffects;
		private var _darkenSignal:NativeSignal;
		private var _buttonCreator:ButtonCreator;
		
		private var _buyPanel:Entity;
		private var _buyPanelHidden:Boolean;
		private var _buyPanelInX:int;
		private var _buyPanelOutX:int;
		private var _buyButton:Entity;
		
		private var _cardGroup:CardGroupPop;
		private var _gridCreator:GridScrollableCreator;
		private var _view:CardView;
		private var _bundleManager:BundleManager;
		private var _contentRetrievalGroup:ContentRetrievalGroup;
		
		
		private var allBundlesPurchased:Boolean = false;
		private var _bundlesTotal:int = 0;
	}
}
