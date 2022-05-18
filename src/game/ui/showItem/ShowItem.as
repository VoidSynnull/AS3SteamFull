package game.ui.showItem
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.ui.CardItem;
	import game.scene.template.ui.CardGroup;
	import game.ui.card.CardView;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * The ShowItem UIView manages the animation which plays when a player
	 * acquires a new Inventory item. It is created by the <code>ItemGroup</code>
	 * which is present in every <code>PlatformerGameScene</code>. 
	 * @author Rich Martin/Bard McKinley
	 */	
	public class ShowItem extends DisplayGroup
	{
		private var _hud:Hud;
		private var _cardGroup:CardGroup;
		
		//// CONSTRUCTOR ////

		/**
		 * Creates a new ShowItem instance.
		 * @param container	The <code>DisplayObjectContainer</code> which will enclose this <code>UIView</code>. Typically, this will be the scene's overlay container.
		 * 
		 */		
		public function ShowItem(container:DisplayObjectContainer = null)
		{
			super(container);
			super.id = GROUP_ID;
			transitionComplete = new Signal();
		}

		//// PUBLIC METHODS ////
		
		override public function destroy():void
		{			
			transitionComplete.removeAll();
			_spatial = null;
			_cardView = null;
			_cardGroup = null;
			_hud = null;
	
			super.destroy();
		}		
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init();
			_hud = super.getGroupById(Hud.GROUP_ID) as Hud;
			_cardGroup = super.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroup;
			super.groupReady();
		}
		
		public function reset():void
		{
			if( _cardView )
			{
				super.removeGroup( _cardView );
				_cardView = null;
			}
			_spatial  = null;
		}
		
		///////////////////////////////////////////////////////////////////////////
		/////////////////////////////// DISPLAY CARD //////////////////////////////
		///////////////////////////////////////////////////////////////////////////
		
		/*
		public function displayCard( itemId:String, setId:String, group:DisplayGroup, container:DisplayObjectContainer, loadHandler:Function = null, bitmap:Boolean = false ):void
		{
			var cardView:CardView = _cardGroup.createCardView( group );
			var cardView:CardView = _cardGroup.createCardViewByItem( this, container, itemId, setId, Command.create( onCardDisplayLoaded, loadHandler, bitmap ) );
			cardView.hide(true);
			// NOTE ::setting position prior to bitmap prevents sporadic exclusion of card content when bitmapping.
			// Not sure why this is the case, will investigate. - Bard
			var spatial:Spatial = cardView.cardEntity.get(Spatial);
			spatial.x = container.x;
			spatial.y = container.y;
		}
		
		public function onCardDisplayLoaded( cardItem:CardItem = null, loadHandler:Function = null, bitmap:Boolean = false ):void
		{
			if( bitmap )
			{
				_cardView.bitmapCardAll( 1 );
			}
			_cardView.hide(false);
			// on load complete, call handler
			if( loadHandler != null )
			{
				loadHandler( _cardView );
			}
		}
		*/
		
		///////////////////////////////////////////////////////////////////////////
		//////////////////////////////// SHOW CARD ////////////////////////////////
		///////////////////////////////////////////////////////////////////////////

		/**
		 * Start show card change, uses CardGroup to create card.
		 * 
		 * @param itemId - id of card, corresponds to name of card xml file
		 * @param setId - card set ( e.g. custom, store, carrot, virusHunter ), corresponds to name of folder containing card xml file
		 * @param loadHandler - optional, handler called once card is laoded, CardItem is returned with handler call.
		 * @param cardContainer
		 * @return 
		 * 
		 */
		public function showCard( itemId:String, setId:String, loadHandler:Function = null, cardContainer:DisplayObjectContainer = null ):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'card_get.mp3', 0);
			if( cardContainer == null ) { cardContainer = super.groupContainer; }
			_cardView = _cardGroup.createCardViewByItem( this, cardContainer, itemId, setId, null, Command.create( onCardLoaded, loadHandler ) );
			_cardView.hide(true);
			// NOTE ::setting position prior to bitmap prevents sporadic exclusion of card content when bitmapping.
			// Not sure why this is the case, will investigate. - Bard
			_spatial = _cardView.cardEntity.get(Spatial);
			_spatial.x = super.shellApi.viewportWidth/2;
			_spatial.y = super.shellApi.viewportHeight/2;
		}
		
		public function onCardLoaded( cardItem:CardItem = null, loadHandler:Function = null ):void
		{
			if(cardItem.cardData.dontBitmap)
				_cardView.displayCardItem();
			else
				_cardView.bitmapCardAll();
			
			startTransitions();
			// on load complete, call handler
			if( loadHandler != null )
			{
				loadHandler( cardItem );
			}
		}
		
		public function startTransitions():void
		{
			_cardView.hide(false);
			var display:Display = _cardView.cardEntity.get(Display);
			display.displayObject.scaleX = display.displayObject.scaleY = 0;
			
			_spatial = _cardView.cardEntity.get(Spatial);
			_spatial.scaleX = _spatial.scaleY = 0;
			_spatial.rotation = -1080;

			//shellApi.soundManager.playLibrarySound('effects/card_get.mp3', shellApi.profileManager.active.effectsVolume);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'card_get.mp3');

			// start tween
			TweenUtils.entityTo( _cardView.cardEntity, Spatial, .82, {scaleX:1, scaleY:1, rotation:0, onComplete:spinOutComplete});
		}
		
		private function spinOutComplete():void
		{
			var delay:Number = SHOW_ITEM_DELAY;
			// RLH: set longer delay for all_coins in tutorial
			if (CardItem(_cardView.cardEntity.get(CardItem)).itemId == "all_coins")
			{
				delay = 2;
			}
			TweenUtils.entityTo( _cardView.cardEntity, Spatial, .25, {x:_spatial.x-2, y:_spatial.y+5, ease:Sine.easeIn, onComplete:backOffComplete}, "toInventory", delay)
		}
		
		private function backOffComplete():void 
		{
			TweenUtils.entityTo( _cardView.cardEntity, Spatial, .375, {scaleX:0, scaleY:0, x:shellApi.viewportWidth-getHudOffset(), y:40, ease:Quad.easeIn, onComplete:zoomComplete});
		}
		
		private function zoomComplete():void 
		{
			var display:Display = _cardView.cardEntity.get(Display);
			TweenUtils.entityTo( _cardView.cardEntity, Display, .33, {alpha:0, onComplete:fadeComplete, onUpdateParams:[display]});
		
			whitenHud(display.alpha);
		}

		private function fadeComplete():void
		{
			if (_cardView) 
			{
				// TODO :: should we delete cardgroup as well?
				super.removeGroup( _cardView );
				_cardView = null;
				transitionComplete.dispatch();
			}
		}
		
		///////////////////////////////////////////////////////////////////////////
		//////////////////////////////// TAKE CARD ////////////////////////////////
		///////////////////////////////////////////////////////////////////////////
		
		/**
		 * Begin process of loading in card so that it can
		 * be taken away from the user.
		 */
		public function takeItem(itemId:String, setId:String, charEntity:Entity, loadHandler:Function = null):CardView
		{
			if(charEntity != null)
			{
				_charEntity = charEntity;
			}
			
			_cardView = _cardGroup.createCardViewByItem( this, super.groupContainer, itemId, setId, null, Command.create( onTakeCardLoaded, loadHandler ) );
			_cardView.hide(true);
			return _cardView;
		}
		
		private function onTakeCardLoaded(cardItem:CardItem = null, loadHandler:Function = null ):void
		{
			_cardView.bitmapCardAll();
			_cardView.hide(false);
			var display:Display = _cardView.cardEntity.get(Display);
			display.displayObject.scaleX = display.displayObject.scaleY = 0;

			_spatial = _cardView.cardEntity.get(Spatial);
			_spatial.x = super.shellApi.viewportWidth/2;
			_spatial.y = super.shellApi.viewportHeight/2;

			// on load complete, call handler
			if( loadHandler != null )
			{
				loadHandler( cardItem );
			}

			TweenUtils.entityFrom( _cardView.cardEntity, Spatial, .8, {scaleX:0, scaleY:0, x:shellApi.viewportWidth-getHudOffset(), y:40, ease:Sine.easeOut, onComplete:bringOutComplete});
		}

		
		private function bringOutComplete():void
		{
			if(_charEntity != null)
			{
				var spatial:Spatial = _charEntity.get(Spatial);
				var point:Point = DisplayUtils.localToLocal(_charEntity.get(Display).displayObject, _cardView.cardEntity.get(Display).container);
				
				TweenUtils.entityTo( _cardView.cardEntity, Spatial, .45, {scaleX:0, scaleY:0, x:point.x, y:point.y, ease:Sine.easeIn, onComplete:intoCharComplete}, "bringOut", TAKE_ITEM_DELAY);
			}
			else
			{
				TweenUtils.entityTo( _cardView.cardEntity, Spatial, .45, {scaleX:0, scaleY:0, x:10, y:10, ease:Sine.easeIn, onComplete:intoCharComplete}, "bringOut", TAKE_ITEM_DELAY);
			}
		}
		
		private function intoCharComplete():void
		{
			if (_cardView) 
			{
				// TODO :: should we delete cardgroup as well?
				super.removeGroup( _cardView );
				_cardView = null;
				transitionComplete.dispatch();
			}
		}
		
		///////////////////////////////////////////////////////////////////////////
		//////////////////////////////// REFRESH CARD /////////////////////////////
		///////////////////////////////////////////////////////////////////////////

		/**
		 * Refesh a card item in the inventory.
		 * 
		 * @param itemId - id of card, corresponds to name of card xml file
		 * @param setId - card set ( e.g. custom, store, carrot, virusHunter ), corresponds to name of folder containing card xml file
		 * @param loadHandler - optional, handler called once card is laoded, CardItem is returned with handler call.
		 * @return 
		 * 
		 */
		public function refreshItem( itemId:String, setId:String, loadHandler:Function = null ):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'card_get.mp3', 0);
			_cardView = _cardGroup.createCardViewByItem( this, super.groupContainer, itemId, setId, null, Command.create( onRefreshCardLoaded, loadHandler ) );
			_cardView.hide(true);
			// NOTE ::setting position prior to bitmpa prevents sporadic exclusion of card content when bitmapping.
			// Not sure why this is the case, will investigate. - Bard
			_spatial = _cardView.cardEntity.get(Spatial);
			_spatial.x = super.shellApi.viewportWidth/2;
			_spatial.y = super.shellApi.viewportHeight/2;
		}
		
		public function onRefreshCardLoaded( cardItem:CardItem = null, loadHandler:Function = null ):void
		{
			_cardView.bitmapCardAll();			
			
			if( loadHandler != null )
			{
				loadHandler( cardItem );
			}
			
			var displayObject:DisplayObject = _cardView.cardEntity.get( Display ).displayObject;
			var sprite:Sprite = new Sprite();
			sprite.visible = false;
			
			sprite.x = _spatial.x;
			sprite.y = _spatial.y;
			
			var bitmapData:BitmapData = new BitmapData( displayObject.width, displayObject.height, false, 0xFFFFFF );
			var bitmap:Bitmap = new Bitmap( bitmapData );
			
			bitmap.alpha = 0;
			bitmap.x = 0 - displayObject.width * .5;
			bitmap.y = 0 - displayObject.height * .5;
			
			var display:Display = _cardView.cardEntity.get(Display);
			display.alpha = 0;
			_cardView.hide(false);
			
			_spatial.scaleX = _spatial.scaleY = 0;
			
			sprite.addChild( bitmap );
			_whiteCard = EntityUtils.createSpatialEntity( this, sprite, super.groupContainer );
			var spatial:Spatial = _whiteCard.get( Spatial );
			display = _whiteCard.get(Display);
			display.alpha = 0;
			spatial.scaleX = spatial.scaleY = 0;
			sprite.visible = true;
			bitmap.alpha = 1;
		//	bitmap.visible = true;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'card_get.mp3');
			
			TweenUtils.entityTo( _cardView.cardEntity, Display, .5, { alpha:1, onComplete:fadeInComplete}, "fadeInCard", EDIT_ITEM_DELAY );
			// _cardView.cardEntity, Spatial, .25, {x:_spatial.x-2, y:_spatial.y+5, ease:Sine.easeIn, onComplete:backOffComplete}, "fadeInCard", SHOW_ITEM_DELAY)
			TweenUtils.entityTo( _cardView.cardEntity, Spatial, .5, { scaleX:1, scaleY:1 }, "scaleCard", EDIT_ITEM_DELAY );
			TweenUtils.entityTo( _whiteCard, Spatial, .5, { scaleX:1, scaleY:1 }, "scaleWhiteCard", EDIT_ITEM_DELAY );
			TweenUtils.entityTo( _whiteCard, Display, .25, { alpha:1, onComplete:fadeWhite }, "fadeInWhiteCard", EDIT_ITEM_DELAY );
		}
		
		private function fadeWhite():void
		{
			TweenUtils.entityTo( _whiteCard, Display, .25, { alpha:0 }); 
		}
		
		private function fadeInComplete():void 
		{
			TweenUtils.entityTo( _cardView.cardEntity, Display, .5, { alpha:0, onComplete:refreshCardComplete}, "fadeOutCard", EDIT_ITEM_DELAY );
			// _cardView.cardEntity, Spatial, .25, {x:_spatial.x-2, y:_spatial.y+5, ease:Sine.easeIn, onComplete:backOffComplete}, "fadeInCard", SHOW_ITEM_DELAY)
			TweenUtils.entityTo( _cardView.cardEntity, Spatial, .5, { scaleX:0, scaleY:0 }, "scaleDownCard", EDIT_ITEM_DELAY );
			TweenUtils.entityTo( _whiteCard, Spatial, .5, { scaleX:0, scaleY:0 }, "scaleDownWhiteCard", EDIT_ITEM_DELAY );
			TweenUtils.entityTo( _whiteCard, Display, .25, {alpha:1, onComplete:fadeWhite}, "fadeOutWhiteCard", EDIT_ITEM_DELAY );
		} 
		
		private function refreshCardComplete():void
		{
			if (_cardView) 
			{
				// TODO :: should we delete cardgroup as well?
				super.removeGroup( _cardView );
				_cardView = null;
				transitionComplete.dispatch();
			}
		}
		
		//////////////////////////////// HUD METHODS /////////////////////////////
		
		private function getHudOffset():int
		{
			var xOffset:Number = 45;
			if( _hud == null )	{ _hud = super.getGroupById(Hud.GROUP_ID) as Hud; }
			if( _hud != null && _hud.isOpen)
			{
				xOffset = 125;
			}
			return xOffset;
		}
		
		private function whitenHud( alpha:Number = 1 ):void 
		{
			if( _hud == null )	{ _hud = super.getGroupById(Hud.GROUP_ID) as Hud; }
			if(_hud)
			{
				_hud.whiten( alpha );
			}	
		}
		
		/**
		 * The transitionComplete signal is dispatched when presentation of a new Inventory
		 * item is complete. That is, when it has disappeared into the HUD's chest icon
		 * (or, if the HUD is open during the animation, the HUD's satchel icon). 
		 */	
		public var transitionComplete:Signal;
		
		private const SHOW_ITEM_DELAY:Number = 1;
		private const EDIT_ITEM_DELAY:Number = .8;
		private const TAKE_ITEM_DELAY:Number = .25;
		public static const GROUP_ID:String = "showItemGroup";
		private var _cardView:CardView;
		private var _spatial:Spatial;
		private var _charEntity:Entity;
		private var _whiteCard:Entity;
		
		private const _cardDisplayPrefix:String = "items/";
	}
}