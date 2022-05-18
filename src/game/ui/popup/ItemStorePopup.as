package game.ui.popup
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.ui.CardItem;
	import game.components.ui.Cursor;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.ScrollBox;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.GridScrollableCreator;
	import game.data.PlayerLocation;
	import game.data.display.BitmapWrapper;
	import game.data.profile.ProfileData;
	import game.data.ui.ToolTipType;
	import game.data.ui.card.CardItemData;
	import game.data.ui.card.CardSet;
	import game.managers.ItemManager;
	import game.managers.LanguageManager;
	import game.managers.SceneManager;
	import game.proxy.Connection;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ui.CardGroup;
	import game.scenes.hub.town.Town;
	import game.ui.card.CardView;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.hud.Hud;
	import game.ui.hud.HudPopBrowser;
	import game.ui.inventory.InventoryPage;
	import game.ui.saveGame.SaveGamePopup;
	import game.util.BitmapUtils;
	import game.util.ClassUtils;
	import game.util.DisplayUtils;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	
	public class ItemStorePopup extends Popup
	{
		// tracking constants
		private const TRACK_STORE_ENTER:String 			= "StoreEnter";
		private const TRACK_STORE_EXIT:String 			= "StoreExit";
		private const TRACK_STORE_DISCONNECT:String 	= "StoreDisconnect";
		public  const TRACK_BUY_ITEM:String 			= "StoreBuyItem";
		private const TRACK_ERROR:String 				= "StoreError";
		private const TRACK_ITEM_CLICKED:String   		= "ItemClicked"
		private const TRACK_TAB_CHANGED:String     		= "TabChanged"
		private const TRACK_MEMBERSHIP_CLICKED:String   = "MembershipClicked";
		
		private const ITEM_COSTUME:String        	    = "Costumes";
		private const ITEM_POWER:String             	= "Power";
		private const ITEM_PRANK:String             	= "Prank";
		private const ITEM_FOLLOWER:String          	= "Follower";
		private const ITEM_MISC:String              	= "Misc";
		
		private const PET_ITEM_HAT:String         		= "Hat";
		private const PET_ITEM_FACIAL:String        	= "Facial";
		private const PET_ITEM_BODY:String          	= "Body";
		private const PET_ITEM_EYES:String       		= "Eyes";
		
		// other constants
		private const NUM_CARDS:int					= 4;			// number of cards to show at one time
		private const CARD_SCALE:Number				= 1;			// card scale
		private const LAYOUT_GUTTER:Number			= 10;			// space between cards
		private const NUM_DOTS:Number               = 13;			// number of dots to load, limits card #. 13 = 52 cards per tab
		
		private var _scene:PlatformerGameScene;						// reference to current scene
		private var _interactive:MovieClip;							// reference to interactive layer
		private var _screen:MovieClip;								// reference to popup clip
		private var _isPetStore:Boolean = false;					// flag for pet store
		private var _storeTracking:String = "Store";
		
		private var _cardGroup:CardGroup;							// reference to card group
		private var _itemHolder:Sprite;								// sprite that holds the card displays
		private var _itemHolders:Array = new Array();				// holder for 4 cards
		private var _gridControl:GridControlScrollable;				// scrollable grid control
		private var _loadingCardWrapper:BitmapWrapper;				// wrapper for loading card
		private var _loadingWheelWrapper:BitmapWrapper;				// wrapper for loading wheel
		private var _visibleCards:Vector.<CardView> = new Vector.<CardView>();
		
		private var _inventoryPages:Vector.<InventoryPage>;			// list of inventory pages
		private var _activePage:InventoryPage;						// current active inventory page
		private var _currentTab:String;								// current tab
		private var _currentCategory:String;								// current tab
		private var _numberOfPages:int;								// number of pages
		
		private var currCredits:Number = 0;							// current user credits
		private var _clickedCardIndex:Number = 0;					// current clicked card index (used when buying)
		private var _currCardIndex:Number = 0;						// current page index
		private var _currPageIndex:Number = 0;
		
		private var _membersOnlyGraphic:MovieClip;					// members only graphic
		private var _membershipPopup:MovieClip;						// popup to buy membership
		private var _buyPopup:MovieClip;							// buy card popup
		private var dots:Vector.<MovieClip>;						// array of dots to indicate page
		private var _dotsLoaded:Number = 0;							//dot loaded counter
		private var _darkenCard:Sprite;                             //darken card on btn clicks
		
		private var SteamCostumes:Array = new Array();
		private var SteamFollowers:Array = new Array();
		private var SteamMisc:Array = new Array();
		private var SteamPowers:Array = new Array();
		private var SteamPranks:Array = new Array();
		private var _storeArray:Array;

		public function get activePage():InventoryPage	{ return _activePage; } 
		public function set activePage( inventoryPage:InventoryPage ):void 
		{
			_activePage = inventoryPage;
		}
		
		public function ItemStorePopup(scene:PlatformerGameScene, isPetStore:Boolean, loadingWheelWrapper:BitmapWrapper, loadingCardWrapper:BitmapWrapper, container:DisplayObjectContainer=null)
		{
			super(container);
			_scene = scene;
			_isPetStore = isPetStore;
			_loadingWheelWrapper = loadingWheelWrapper;
			_loadingCardWrapper = loadingCardWrapper;
		}
		private function SetSteamStoreItems():void 
		{
			var itemObj:Object = new Object();
			itemObj.id = "3008";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3010";
			itemObj.mem_only = false;
			itemObj.price = 150;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3063";
			itemObj.mem_only = false;
			itemObj.price = 150;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3083";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3099";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3105";
			itemObj.mem_only = false;
			itemObj.price = 300;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3304";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3636";
			itemObj.mem_only = false;
			itemObj.price = 300;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3647";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3694";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3700";
			itemObj.mem_only = false;
			itemObj.price = 75;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3705";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3706";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3707";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3710";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3739";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3740";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3741";
			itemObj.mem_only = false;
			itemObj.price = 150;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3746";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3747";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3753";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3754";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamCostumes.push(itemObj);
			itemObj = new Object();
			
			itemObj.id = "3263";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamFollowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3359";
			itemObj.mem_only = false;
			itemObj.price = 300;
			SteamFollowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3610";
			itemObj.mem_only = false;
			itemObj.price = 250;
			SteamFollowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3649";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamFollowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3658";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamFollowers.push(itemObj);
			
			itemObj = new Object();
			itemObj.id = "3663";
			itemObj.mem_only = false;
			itemObj.price = 50;
			SteamMisc.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3664";
			itemObj.mem_only = false;
			itemObj.price = 50;
			SteamMisc.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3713";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamMisc.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3714";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamMisc.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3715";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamMisc.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3022";
			itemObj.mem_only = false;
			itemObj.price = 375;
			SteamPowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3050";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamPowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3115";
			itemObj.mem_only = false;
			itemObj.price = 375;
			SteamPowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3128";
			itemObj.mem_only = false;
			itemObj.price = 375;
			SteamPowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3332";
			itemObj.mem_only = false;
			itemObj.price = 375;
			SteamPowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3613";
			itemObj.mem_only = false;
			itemObj.price = 300;
			SteamPowers.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3076";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamPranks.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3233";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamPranks.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3324";
			itemObj.mem_only = false;
			itemObj.price = 300;
			SteamPranks.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3467";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamPranks.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3638";
			itemObj.mem_only = false;
			itemObj.price = 350;
			SteamPranks.push(itemObj);
			itemObj = new Object();
			itemObj.id = "3639";
			itemObj.mem_only = false;
			itemObj.price = 100;
			SteamPranks.push(itemObj);
			itemObj = new Object();
			/*
			itemObj.id = "3685";
			itemObj.mem_only = false;
			itemObj.price = 200;
			SteamPranks.push(itemObj);.
				*/
		}
		public override function init(container:DisplayObjectContainer=null):void 
		{
			if(AppConfig.mobile && !shellApi.networkAvailable())
			{
				var sceneUIGroup:SceneUIGroup = _scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CONNECT_TO_INTERNET, onClose, onClose);
				return;				
			}
			
			this.groupPrefix = "ui/store/";
			if(_isPetStore)
			{
				this.screenAsset = "petStore.swf";
				_storeTracking = "PetStore";
			}
			else
			{
				this.screenAsset = "store.swf";
			}
			super.darkenAlpha = 0.6;
			super.darkenBackground = true;
			super.init(container);
			super.load();
		}
		
		public override function load():void
		{
			super.load();
			super.shellApi.loadFiles( [ super.shellApi.assetPrefix + "ui/general/load_wheel.swf", super.shellApi.assetPrefix + "items/ui/background_loading.swf"], loadedInitAssets);
		}
		
		private function loadedInitAssets():void
		{
			// store references to loading assets
			var loadWheel:MovieClip = super.shellApi.getFile( super.shellApi.assetPrefix + "ui/general/load_wheel.swf" ) as MovieClip;
			_loadingWheelWrapper = DisplayUtils.convertToBitmapSprite( loadWheel, loadWheel.getBounds(loadWheel), CARD_SCALE, false );
			var loadingCard:MovieClip = super.shellApi.getFile( super.shellApi.assetPrefix + "items/ui/background_loading.swf" ) as MovieClip;
			_loadingCardWrapper = DisplayUtils.convertToBitmapSprite( loadingCard, CardGroup.CARD_BOUNDS, CARD_SCALE );
		}
		
		public override function loaded():void
		{
			super.loaded();
			_screen = super.screen;
			//refresh membership status
			shellApi.profileManager.active.RefreshMembershipStatus(shellApi);
			shellApi.profileManager.updateCredits(UpdateCredits);
			shellApi.track(TRACK_STORE_ENTER, null, null, _storeTracking);
			_interactive = _scene.hitContainer as MovieClip;	
			_interactive.mouseEnabled = false;
			
			super.centerPopupToDevice();
			_screen.leftArrow = ButtonCreator.createButtonEntity( this.screen.leftArrow, this, Command.create(scroll, -1), null, null, ToolTipType.CLICK);
			_screen.leftArrow.get(Display).visible = false;
			_screen.rightArrow = ButtonCreator.createButtonEntity( this.screen.rightArrow, this, Command.create(scroll, 1), null, null, ToolTipType.CLICK);
			
			SetSteamStoreItems();
			
			var interactions:Array = [ InteractionCreator.CLICK ];
			if(_isPetStore)
			{
				_currentTab = ItemManager.PET_HAT;
				_screen.headClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "HEAD"));
				_screen.faceClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "FACE"));
				_screen.bodyClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "BODY"));
				_screen.eyesClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "EYES"));
				_screen.headClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.faceClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.bodyClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.eyesClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				
				_screen.headTab.gotoAndStop(2);
				_screen.faceTab.gotoAndStop(0);
				_screen.bodyTab.gotoAndStop(0);
				_screen.eyesTab.gotoAndStop(0);
				
				_screen.headClick = ButtonCreator.createButtonEntity( this.screen.headClick, this, Command.create(ClickedTab, PET_ITEM_HAT), null, interactions, ToolTipType.CLICK);
				_screen.faceClick = ButtonCreator.createButtonEntity( this.screen.faceClick, this, Command.create(ClickedTab, PET_ITEM_FACIAL), null, interactions, ToolTipType.CLICK);
				_screen.bodyClick = ButtonCreator.createButtonEntity( this.screen.bodyClick, this, Command.create(ClickedTab, PET_ITEM_BODY), null, interactions, ToolTipType.CLICK);
				_screen.eyesClick = ButtonCreator.createButtonEntity( this.screen.eyesClick, this, Command.create(ClickedTab, PET_ITEM_EYES), null, interactions, ToolTipType.CLICK);
				
			}
			else
			{
				_currentTab = ItemManager.COSTUME;
				
				_screen.powerClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "POWERS"));
				_screen.prankClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "PRANKS"));
				_screen.followerClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "FOLLOWERS"));
				_screen.costumeClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "COSTUMES"));
				_screen.miscClick.addEventListener(MouseEvent.MOUSE_OVER,Command.create(RolloverTab, "MISCELLANEOUS"));
				_screen.powerClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.prankClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.followerClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.costumeClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				_screen.miscClick.addEventListener(MouseEvent.MOUSE_OUT,Command.create(RolloverTab, ""));
				
				_screen.followerTab.gotoAndStop(0);
				_screen.misceTab.gotoAndStop(0);
				_screen.pranksTab.gotoAndStop(0);
				_screen.costumeTab.gotoAndStop(2);
				_screen.powerTab.gotoAndStop(0);
				
				_screen.powerClick = ButtonCreator.createButtonEntity( this.screen.powerClick, this, Command.create(ClickedTab, ITEM_POWER), null, interactions, ToolTipType.CLICK);
				_screen.prankClick = ButtonCreator.createButtonEntity( this.screen.prankClick, this, Command.create(ClickedTab, ITEM_PRANK), null, interactions, ToolTipType.CLICK);
				_screen.followerClick = ButtonCreator.createButtonEntity( this.screen.followerClick, this, Command.create(ClickedTab, ITEM_FOLLOWER), null, interactions, ToolTipType.CLICK);
				_screen.costumeClick = ButtonCreator.createButtonEntity( this.screen.costumeClick, this, Command.create(ClickedTab, ITEM_COSTUME), null, interactions, ToolTipType.CLICK);
				_screen.miscClick = ButtonCreator.createButtonEntity( this.screen.miscClick, this, Command.create(ClickedTab, ITEM_MISC), null, interactions, ToolTipType.CLICK);
			}
			
			_screen.closeBtn = ButtonCreator.createButtonEntity(this.screen.closeBtn, this, onClose, null, null, null, true, true );
			_screen.buyBtn1 = ButtonCreator.createButtonEntity( this.screen.buyBtn1, this, Command.create(ClickedBuy, 1), null, null, ToolTipType.CLICK);
			_screen.buyBtn2 = ButtonCreator.createButtonEntity( this.screen.buyBtn2, this, Command.create(ClickedBuy, 2), null, null, ToolTipType.CLICK);
			_screen.buyBtn3 = ButtonCreator.createButtonEntity( this.screen.buyBtn3, this, Command.create(ClickedBuy, 3), null, null, ToolTipType.CLICK);
			_screen.buyBtn4 = ButtonCreator.createButtonEntity( this.screen.buyBtn4, this, Command.create(ClickedBuy, 4), null, null, ToolTipType.CLICK);
			
			_membersOnlyGraphic = this.screen.membersOnlyCard;
			_buyPopup = this.screen.buyNowPopup;
			_buyPopup.no = ButtonCreator.createButtonEntity( _buyPopup.no, this, Command.create(ClickedBuyCancel), null, null, ToolTipType.CLICK);
			_buyPopup.yes = ButtonCreator.createButtonEntity( _buyPopup.yes, this, Command.create(ClickedBuyConfirm), null, null, ToolTipType.CLICK);
			
			_membershipPopup = this.screen.membershipPopup;
			_membershipPopup.no = ButtonCreator.createButtonEntity( _membershipPopup.no, this, Command.create(ClickedBuyMembershipCancel), null, null, ToolTipType.CLICK);
			_membershipPopup.yes = ButtonCreator.createButtonEntity( _membershipPopup.yes, this, Command.create(ClickedBuyMembershipConfirm), null, null, ToolTipType.CLICK);
			
			_screen.darkenCard.visible = false;
			
			// load dot
			dots = new Vector.<MovieClip>();
			for (var j:Number=0;j<NUM_DOTS;j++)
			{	
				shellApi.loadFile(super.shellApi.assetPrefix + "ui/store/dot.swf", Command.create(dotLoaded, j, NUM_DOTS));
			}
			
			//change cursor type
			if( PlatformUtils.isDesktop ) 
			{
				Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
			}
			
			//hide hud
			var mainHud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
			mainHud.hideButton(Hud.HUD, true);
			
			// add CardGroup
			_cardGroup = super.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroup;
			
			//get user credits
			currCredits = super.shellApi.profileManager.active.credits;
			_screen.credits.text = String(currCredits);
			trace("ItemStorePopup :: loaded - Current credits: " + super.shellApi.profileManager.active.credits);
			
			// creates a clip that will contain cards displays
			_itemHolder = new Sprite();
			_itemHolder.name = "cards_container";
			_screen.addChild(_itemHolder);
			_itemHolder.x = super.shellApi.viewportWidth * (-.5);
			_itemHolder.y = super.shellApi.viewportHeight * (-.22);
			
			
			//make sure price and darken ui appear over card
			_screen.swapChildren(_itemHolder,_screen.pricebg1);
			_screen.swapChildren(_screen.pricebg1,_screen.item1Price);
			_screen.swapChildren(_itemHolder,_screen.darkenCard);
			
			//setup card space
			var portHoleBuffer:int = 2;
			var viewScale:Number = super.shellApi.viewportWidth/super.shellApi.viewportHeight;
			var portHole:Rectangle;
			//if(viewScale >.68)
			portHole = new Rectangle( 0, 0, super.shellApi.viewportWidth, _screen.cs.height);
			//else
			//portHole = new Rectangle( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight-360);
			
			// create scrollable grid for cards
			var gridCreator:GridScrollableCreator = new GridScrollableCreator();
			// want dimension of card slot in a single row layout, want to fit at least 3 cards on screen at once 
			var grid:Entity = gridCreator.create( portHole.clone(), CardGroup.CARD_BOUNDS, 1, 1, this, 8, true, null, portHoleBuffer, "StoreCardTable");
			_gridControl = grid.get( GridControlScrollable );
			
			// add ScrollBox to gridEntity
			var scrollBox:ScrollBox = new ScrollBox(_screen, portHole, 10, 50) ;
			scrollBox.disable = true;
			grid.add(scrollBox);
			
			// create pages for store
			createPages();
			
			// setup card placeholders
			for (var i:int = 0; i < NUM_CARDS; i++) 
			{	
				var cardView:CardView = _cardGroup.createCardView( this );	// create CardView (inherets from UIView)
				var cardEnt:Entity = cardView.createCardEntity( null, _itemHolder );	// create card Entity within CardView
				_itemHolders.push(cardEnt);
				_screen.darkenCard.scaleX = cardEnt.get(Spatial).scaleX;
				_screen.darkenCard.scaleY = cardEnt.get(Spatial).scaleY;
				
				var bounds:Rectangle = new Rectangle(CardGroup.CARD_BOUNDS.x,CardGroup.CARD_BOUNDS.y,CardGroup.CARD_BOUNDS.width*1.05,CardGroup.CARD_BOUNDS.height*1.05);
				//LOADS CARDS
				// reverse order
				var order:int = NUM_CARDS - i - 1;
				gridCreator.addSlotEntity( grid, cardEnt, bounds, Command.create(onCardActivated, order , order), null );
				cardEnt.add( new OwningGroup( cardView ) );
			}
			
			
		}
		
		private function UpdateCredits():void
		{
			trace("ItemStorePopup :: UpdateCredits");
			currCredits = super.shellApi.profileManager.active.credits;
			_screen.credits.text = String(currCredits);
		}
		
		private function RolloverTab(e:Event,label:String):void{
			_screen.labelText.text = label;
			if(label == "PRANKS" || label == "POWERS")
				_screen.labelText.x = (e.target.x - (_screen.labelText.width/1.8));
			else if(label == "FOLLOWERS")
				_screen.labelText.x = (e.target.x - (_screen.labelText.width/2.2));
			else if(label == "EYES")
				_screen.labelText.x = (e.target.x - (_screen.labelText.width/2.2));
			else if(label == "MISCELLANEOUS")
				_screen.labelText.x = (e.target.x - (_screen.labelText.width/3));
			else
				_screen.labelText.x = (e.target.x - (_screen.labelText.width/2.5));
		}
		private function createPages():void
		{
			var languageManager:LanguageManager = LanguageManager(shellApi.getManager(LanguageManager));
			if(_isPetStore)
			{
				createInventoryPage( "Hat", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Hat" );
				createInventoryPage( "Facial", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Facial" );
				createInventoryPage( "Body", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Body" );
				createInventoryPage( "Eyes", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Eyes" );
				
				ChangePage(PET_ITEM_HAT);
			}
			else
			{
				createInventoryPage( "Costumes", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Costumes" );
				createInventoryPage( "Prank", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Prank" );
				createInventoryPage( "Follower", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Follower" );
				createInventoryPage( "Power", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Power" );
				createInventoryPage( "Misc", 1, languageManager.get("shared.inventory.noStoreCards", "No Items"), "Misc" );
				
				ChangePage(ITEM_COSTUME);
			}
		}
		
		private function ClickedBuyCancel(button:Entity):void
		{
			_buyPopup.x = -1200;
			_buyPopup.y = - 1200;
			RemoveDarken();
		}
		private function MoveMembershipPopup(x:Number, y:Number):void
		{
			_membershipPopup.x = x;
			_membershipPopup.y = y;
		}
		private function ClickedBuyMembershipCancel(button:Entity):void
		{
			MoveMembershipPopup(super.shellApi.viewportWidth + (_membershipPopup.width * 2),
				super.shellApi.viewportHeight + (_membershipPopup.height * 2));
			RemoveDarken();
			shellApi.track(TRACK_MEMBERSHIP_CLICKED + " Cancel", null, null, _storeTracking);
			
		}
		private function GetSteamItemObjById(id:String):Object{
			switch(_currentCategory)
			{
				case ITEM_COSTUME:
					for(var i:Number = 0; i < SteamCostumes.length; i++)
					{
						if(SteamCostumes[i].id == id) {
							return SteamCostumes[i];
						}
					}
					
					break
				case ITEM_FOLLOWER:
					for(var i:Number = 0; i < SteamFollowers.length; i++)
					{
						if(SteamFollowers[i].id == id) {
							return SteamFollowers[i];
						}
					}
					break;
				case ITEM_MISC:
					for(var i:Number = 0; i < SteamMisc.length; i++)
					{
						if(SteamMisc[i].id == id) {
							return SteamMisc[i];
						}
					}
					break;
				case ITEM_POWER:
					for(var i:Number = 0; i < SteamPowers.length; i++)
					{
						if(SteamPowers[i].id == id) {
							return SteamPowers[i];
						}
					}
					break;
				case ITEM_PRANK:
					for(var i:Number = 0; i < SteamPranks.length; i++)
					{
						if(SteamPranks[i].id == id) {
							return SteamPranks[i];
						}
					}
					break;
				
			}
			return null;
		}
		private function ClickedBuyConfirm(button:Entity):void
		{			
			_buyPopup.x = -1200;
			_buyPopup.y = -1200;
			buyItem(GetItemBySlot(_clickedCardIndex).id, GetSteamItemObjById(GetItemBySlot(_clickedCardIndex).id).price);
			RemoveDarken();
		}
		private function ClickedBuyMembershipConfirm(button:Entity):void
		{			
			MoveMembershipPopup(super.shellApi.viewportWidth + (_membershipPopup.width * 2),
				super.shellApi.viewportHeight + (_membershipPopup.height * 2));
			
			if (!shellApi.networkAvailable())
			{
				var sceneUIGroup:SceneUIGroup = _scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CONNECT_TO_INTERNET, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				return;
			}
			
			HudPopBrowser.buyMembership(shellApi);
			
			shellApi.track(TRACK_MEMBERSHIP_CLICKED + " Confirm", null, null, _storeTracking);
			RemoveDarken();
		}
		
		private function onClose(button:Entity=null):void
		{
			shellApi.track(TRACK_STORE_EXIT, null, null, _storeTracking);
			
			if(_isPetStore)
			{
				// show hud again
				var mainHud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
				mainHud.hideButton(Hud.HUD, false);
				// close popup
				close();
			}
			else
			{
				var profile:ProfileData = shellApi.profileManager.active;
				var destination:String = profile.previousIsland;
				
				var as2:Boolean = destination.indexOf('pop://') == 0;
				if(!as2)
				{
					var playerLocation:PlayerLocation = profile.lastScene[destination];
					if(playerLocation.type == PlayerLocation.AS2_TYPE)
					{
						destination = playerLocation.popURL;
						as2 = true;
					}
				}
				if (as2)
				{
					// go to home island
					shellApi.loadScene(Town);
				}
				else
				{
					var sceneManager:SceneManager = shellApi.sceneManager;
					var destScene:String = sceneManager.previousScene;
					var destX:Number = sceneManager.previousSceneX;
					var destY:Number = sceneManager.previousSceneY;
					shellApi.loadScene(ClassUtils.getClassByName(destScene), destX, destY, sceneManager.previousSceneDirection);
				}
			}
		}
		
		private function ClickedTab(btn:Entity,tab:String):void
		{
			_currCardIndex = 0;
			_screen.leftArrow.get(Display).visible = false;
			_screen.leftArrow.remove(ToolTipActive);
			RemoveDarken();
			_buyPopup.x = -1200;
			_buyPopup.y = -1200;
			MoveMembershipPopup(super.shellApi.viewportWidth + (_membershipPopup.width * 2),
				super.shellApi.viewportHeight + (_membershipPopup.height * 2));
			_currentCategory = tab;
			ResetTabs();
			ChangePage(tab);
		}
		
		private function ClickedBuy(btn:Entity, slot:Number):void
		{
			
			var storeObj:Object = GetSteamItemObjById(GetItemBySlot(slot).id);
			var localPoint:Point = DisplayUtils.localToLocal(_itemHolders[NUM_CARDS-slot].get(Display).displayObject,_screen);
			if(storeObj.mem_only && !shellApi.profileManager.active.isMember)
			{ 
				_membershipPopup.x = localPoint.x - (_membershipPopup.width/2);
				_membershipPopup.y = btn.get(Spatial).y - (_membershipPopup.height * 1.5);
				_buyPopup.x = -1200;
				_buyPopup.y = -1200;
			}
			else
			{
				_buyPopup.x = localPoint.x - (_buyPopup.width/2);;
				_buyPopup.y = btn.get(Spatial).y - (_buyPopup.height * 1.5);
				MoveMembershipPopup(super.shellApi.viewportWidth + (_membershipPopup.width * 2),
					super.shellApi.viewportHeight + (_membershipPopup.height * 2));
			}
			RemoveDarken();
			var cardView:CardView = _itemHolders[NUM_CARDS - slot].group as CardView;
			
			_darkenCard = BitmapUtils.createBitmapSprite(_screen.darkenCard);
			_darkenCard.name = "darkenCard";
			_darkenCard.scaleX = _itemHolders[0].get(Spatial).scaleX * 2.1;
			_darkenCard.scaleY = _itemHolders[0].get(Spatial).scaleY * 2;
			_darkenCard.x = cardView.cardContentDisplay.x - (_darkenCard.width/2.1);
			_darkenCard.y = cardView.cardContentDisplay.y - (_darkenCard.height/2);
			//cardView.cardContentDisplay.addChildAt(_darkenCard,cardView.cardContentDisplay.numChildren);
			cardView.container.addChildAt(_darkenCard,cardView.container.numChildren);
			
			_clickedCardIndex = slot;
			shellApi.track(TRACK_ITEM_CLICKED, GetItemBySlot(_clickedCardIndex).id, null, _storeTracking);
		}
		
		private function GetItemBySlot(slot:Number):CardItemData
		{
			return CardItem(_itemHolders[NUM_CARDS - slot].get(CardItem)).cardData;
		}
		private function RemoveDarken():void
		{
			if(_darkenCard != null)
			{
				for(var i:Number=0;i<NUM_CARDS;i++)
				{
					var cardView:CardView = _itemHolders[i].group as CardView;
					if(_darkenCard.parent == cardView.container)
						cardView.container.removeChild(_darkenCard);
				}
			}
		}
		private function scroll(btn:Entity,dir:Number):void
		{
			RemoveDarken();
			_buyPopup.x = -1200;
			_buyPopup.y = -1200;
			
			//reset card price/buy btn if hidden
			ResetCardViews();
			
			// hide visible cards
			for each (var cardView:CardView in _visibleCards)
			{
				cardView.hide(true);
			}
			// reset array
			_visibleCards = new Vector.<CardView>();
			
			// increment/decrement page index by number of cards
			_currCardIndex += (NUM_CARDS*dir);
			
			if((_currPageIndex + dir) == 0)
				_currCardIndex = 0;
			if ((_currPageIndex + dir) > _numberOfPages-1)
			{
				_currCardIndex = activePage.cards.length - 3;
			}
			if(_currCardIndex < 0)
				_currCardIndex = 0;
			
			// for each card display
			for(var i:Number=0;i<NUM_CARDS;i++)
			{
				//if next item is out of range of the card set, stop
				if( (_currCardIndex + i >= activePage.cards.length) || (_currCardIndex + i < 0))
				{
					trace("ItemStorePopup : Index out of range. currentIndex: " + _currCardIndex + " numCards: " + activePage.cards.length );
					var numCardsToHide:Number = i;
					for(var j:Number = NUM_CARDS; j>numCardsToHide; j--)
					{
						_screen["item" + j + "Price"].visible = false;
						_screen["buyBtn" + j].get(Display).visible = false;
						_screen["pricebg" + j].visible = false;
					}
					
					break;
				}
				// reverse ordering
				var order:int = NUM_CARDS - i - 1;
				onCardActivated(_itemHolders[order], _currCardIndex + i, i);
			}
			
			// increment page index
			_currPageIndex += dir;
			if(_currPageIndex < 0)
			{
				_currPageIndex = 0;
			}
			else if (_currPageIndex > _numberOfPages-1)
			{
				_currPageIndex = _numberOfPages-1;
			}
			
			// if first page then no left arrow
			if(_currPageIndex == 0)
			{
				_screen.leftArrow.get(Display).visible = false;
				_screen.leftArrow.remove(ToolTipActive);
				_currCardIndex = 0;
			}
			else
			{
				_screen.leftArrow.get(Display).visible = true;
				_screen.leftArrow.add(new ToolTipActive);
			}
			
			// if last page then no right arrow
			if(_currPageIndex == _numberOfPages - 1)
			{
				_screen.rightArrow.get(Display).visible = false;
				_screen.rightArrow.remove(ToolTipActive);
			}
			else
			{
				_screen.rightArrow.get(Display).visible = true;
				_screen.rightArrow.add(new ToolTipActive);
			}
			
			
			ChangeDotPos();
		}
		private function ResetTabs():void
		{
			if(_isPetStore)
			{
				_screen.headTab.gotoAndStop(0);
				_screen.faceTab.gotoAndStop(0);
				_screen.bodyTab.gotoAndStop(0);
				_screen.eyesTab.gotoAndStop(0);
			}
			else
			{
				_screen.followerTab.gotoAndStop(0);
				_screen.misceTab.gotoAndStop(0);
				_screen.pranksTab.gotoAndStop(0);
				_screen.costumeTab.gotoAndStop(0);
				_screen.powerTab.gotoAndStop(0);
				
			}
			ResetCardViews();
		}
		private function ResetCardViews():void
		{
			_screen.item1Price.visible = true;
			_screen.buyBtn1.get(Display).visible = true;
			_screen.pricebg1.visible = true;
			
			_screen.item2Price.visible = true;
			_screen.buyBtn2.get(Display).visible = true;
			_screen.pricebg2.visible = true;
			
			_screen.item3Price.visible = true;
			_screen.buyBtn3.get(Display).visible = true;
			_screen.pricebg3.visible = true;
			
			_screen.item4Price.visible = true;
			_screen.buyBtn4.get(Display).visible = true;
			_screen.pricebg4.visible = true;
		}
		private function GetCurrentTab():Entity
		{
			var tab:Entity;
			
			switch(_currentCategory)
			{
				case ITEM_COSTUME:
					tab =_screen.costumeTab;
					break
				case ITEM_FOLLOWER:
					tab = _screen.followerTab;
					break;
				case ITEM_MISC:
					tab = _screen.misceTab;
					break;
				case ITEM_POWER:
					tab = _screen.powerTab;
					break;
				case ITEM_PRANK:
					tab = _screen.pranksTab;
					break;
				case PET_ITEM_HAT:
					tab = _screen.headTab;
					break;
				case PET_ITEM_FACIAL:
					tab = _screen.faceTab;
					break;
				case PET_ITEM_BODY:
					tab = _screen.bodyTab;
					break;
				case PET_ITEM_EYES:
					tab = _screen.eyesTab;
					break;
			}
			return tab;
		}
		/**
		 * Change the inventory page, options include island, store, or custom. 
		 * @param pageId
		 * 
		 */
		public function ChangePage(category:String):void 
		{
			_currPageIndex = 0;
			
			if( !activePage)// if no page has been set yet (inventory is first opening)
			{
				if(_isPetStore)
					activePage = getPageById(PET_ITEM_HAT);
				else
					activePage = getPageById(ITEM_COSTUME);
			}
			else
			{
				activePage = getPageById(category);
			}
			
			// hide visible cards
			for each (var cardView:CardView in _visibleCards)
			{
				cardView.hide(true);
			}
			// reset array
			_visibleCards = new Vector.<CardView>();
			_currentCategory = category;
			//set all tabs to index frame
			//ResetTabs();
			
			switch(category)
			{
				case ITEM_COSTUME:
					_currentTab = ItemManager.COSTUME;
					_screen.costumeTab.gotoAndStop(2);
					break
				case ITEM_FOLLOWER:
					_currentTab = ItemManager.FOLLOWER;
					_screen.followerTab.gotoAndStop(2);
					break;
				case ITEM_MISC:
					_currentTab = ItemManager.MISC;
					_screen.misceTab.gotoAndStop(2);
					break;
				case ITEM_POWER:
					_currentTab = ItemManager.POWER;
					_screen.powerTab.gotoAndStop(2);
					break;
				case ITEM_PRANK:
					_currentTab = ItemManager.PRANK;
					_screen.pranksTab.gotoAndStop(2);
					break;
				case PET_ITEM_HAT:
					_currentTab = ItemManager.PET_HAT;
					_screen.headTab.gotoAndStop(2);
					break;
				case PET_ITEM_FACIAL:
					_currentTab = ItemManager.PET_FACIAL;
					_screen.faceTab.gotoAndStop(2);
					break;
				case PET_ITEM_BODY:
					_currentTab = ItemManager.PET_BODY;
					_screen.bodyTab.gotoAndStop(2);
					break;
				case PET_ITEM_EYES:
					_currentTab = ItemManager.PET_EYES;
					_screen.eyesTab.gotoAndStop(2);
					break;
			}
			
			shellApi.track(TRACK_TAB_CHANGED, _currentTab, null, _storeTracking);
			
			//load cardSets if not yet loaded
			if( true )
			{
				loadCardSet(activePage.id)
			}
			
			// prepare cards for display, if no cards are present displays message
			prepareCardSet();
			
			// determine slot dimensions, create new slots
			var slotRect:Rectangle = GeomUtils.getLayoutCellRect( _gridControl.frameRect, CardGroup.CARD_BOUNDS, 1, 1, LAYOUT_GUTTER );	// determine dimension of Tableau slot
			_gridControl.createSlots( NUM_CARDS, 1, 0, slotRect );	// create new slots	for grid (not the same as the cards)							
			
			trace("Number of cards on active page: " + activePage.numCards());
			_numberOfPages = Math.ceil(activePage.numCards()/NUM_CARDS);
			if(_numberOfPages > NUM_DOTS)
			{
				//cards shouldn't exceed 50
			}
			else
			{
				RepositionDots(_numberOfPages);
			}
			
		}
		
		private function ChangeDotPos():void
		{
			for(var i:Number=0;i<NUM_DOTS;i++)
			{
				dots[i].gotoAndStop(1);
			}
			if (_currPageIndex < dots.length)
			{
				dots[_currPageIndex].gotoAndStop(2);
			}
		}
		
		private function RepositionDots(numberOfDots:Number):void
		{
			if(numberOfDots > NUM_DOTS)
				trace("ItemStorePopup :: More than 52 cards active in this tab");
			else
			{
				// RLH: sometimes the dots aren't loaded yet, when this is called
				if (dots.length != 0)
				{
					var spacing:int = 40;
					//first reset all dots
					for(var i:Number=0;i<NUM_DOTS;i++)
					{
						dots[i].visible = false;
						dots[i].gotoAndStop(1);
						
					}
					//now repostion
					for(var j:Number=0;j<numberOfDots;j++)
					{
						dots[j].x = -((numberOfDots - 1) * spacing) / 2 + j * spacing;
						if(j == 0)
							dots[j].gotoAndStop(2);
						dots[j].visible = true;
					}
				}
				
				//ResetTabs();
				
			}
		}
		
		// when dot loaded
		private function dotLoaded(clip:MovieClip, pos:int, total:int):void
		{
			// dot spacing
			var spacing:int = 40;
			// add to dots holder
			clip = MovieClip(_screen.dots.addChild(clip));
			// position and scale
			clip.x = -((total - 1) * spacing) / 2 + pos * spacing;
			clip.scaleX = clip.scaleY = 0.45;
			clip.y = 200;
			// set frame
			if (pos == 0)
			{
				clip.gotoAndStop(2);
			}
			else
			{
				clip.gotoAndStop(1);
			}
			dots.push(clip);
			_dotsLoaded++;
			if(_dotsLoaded == NUM_DOTS)
				RepositionDots(Math.ceil(activePage.numCards()/NUM_CARDS));
		}
		
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
			
			if( !_inventoryPages )
			{
				_inventoryPages = new Vector.<InventoryPage>();
			}
			_inventoryPages.push(inventoryPage);
			
			return inventoryPage;	
		}
		
		/**
		 *  Retrieve the list of cards for type, options include island, store, or custom.
		 *  Card sets are retrieved from the ItemManager.
		 * @param type
		 */
		private function loadCardSet(category:String):void 
		{
			trace( "Inventory :: loadCardSet " );
			var cardSet:CardSet;
			var storeIDs:Vector.<String> = new Vector.<String>();
			var storeArray:Array = [];
			switch(category)
			{
				case ITEM_COSTUME:
					storeArray = SteamCostumes;
					break
				case ITEM_FOLLOWER:
					storeArray = SteamFollowers;
					break;
				case ITEM_MISC:
					storeArray = SteamMisc;
					break;
				case ITEM_POWER:
					storeArray = SteamPowers;
					break;
				case ITEM_PRANK:
					storeArray = SteamPranks;
					break;
				case PET_ITEM_FACIAL:
					storeArray = super.shellApi.itemManager.storeItems[ItemManager.PET_FACIAL];
					break;
				case PET_ITEM_HAT:
					storeArray = super.shellApi.itemManager.storeItems[ItemManager.PET_HAT];
					break;
				case PET_ITEM_BODY:
					storeArray = super.shellApi.itemManager.storeItems[ItemManager.PET_BODY];
					break;
				case PET_ITEM_EYES:
					storeArray = super.shellApi.itemManager.storeItems[ItemManager.PET_EYES];
					break;
			}
			var dict:Dictionary = super.shellApi.itemManager.storeItems;
			for ( var key:Object in storeArray )
			{
				var item:Object = storeArray[key];
				storeIDs.push( item.id );
			}
			for(var i:Number=0;i<storeIDs.length;i++)
			{
				if(super.shellApi.checkHasItem(storeIDs[i]))
					storeIDs.removeAt(i);	
			}
			_storeArray = storeArray; 
			
			if (_isPetStore)
			{
				cardSet = super.shellApi.getCardSet( CardGroup.PETS, true ).duplicate();
			}
			else
			{
				cardSet = super.shellApi.getCardSet( CardGroup.STORE, true ).duplicate();
			}
			cardSet.cardIds = storeIDs;			
			
			_activePage.cardSets[0] = cardSet ;
		}
		
		/**
		 * Reposition and apply CardItem's display to card Entity.  
		 * index - index in the card set
		 * slot number - slot that is displayed (1-4)
		 */
		private function onCardActivated( cardEntity:Entity, index:Number, slotNumber:Number):void 
		{
			//index - where to start loading from
			if((index > -1) && (index < activePage.cards.length))
			{
				if(activePage.numCards() <= 4)
				{
					_screen.rightArrow.get(Display).visible = false;
					_screen.rightArrow.remove(ToolTipActive);
				}
				else
				{
					_screen.rightArrow.get(Display).visible = true;
					_screen.rightArrow.add(new ToolTipActive);
				}
				
				var cardView:CardView = cardEntity.group as CardView;
				var cardItem:CardItem = activePage.cards[index];
				
				//trace("card activated: " + index + " slot:" + slotNumber + " item" + cardItem.itemId);
				
				cardView.activate();				// activate CardView, unpauses 
				cardView.addCardItem( cardItem );	// replace/add cardItem from card set to CardView
				// add to list of visible cards
				_visibleCards.push(cardView);
				
				// if cardItem hasn't loaded yet, start load
				if( !cardItem.displayLoaded )		
				{
					if( !cardItem.isLoading )
					{
						cardView.showLoading( _loadingCardWrapper );
						_cardGroup.loadCardItem( cardItem, true, Command.create( cardItemLoaded, cardView, slotNumber));	// loads card xml and assets
						// TODO :: Need to handle a failed load, should display an Under Construction card instead.
					}
				}
				else
				{
					cardItemLoaded( cardItem, cardView, slotNumber );
				}
			}
			else
			{
				var numCardsToHide:Number = NUM_CARDS - activePage.numCards();
				for(var j:Number = 0; j<numCardsToHide; j++)
				{
					_screen["item" + (4-j) + "Price"].visible = false;
					_screen["buyBtn" + (4-j)].get(Display).visible = false;
					_screen["pricebg" + (4-j)].visible = false;
				}
				_screen.rightArrow.get(Display).visible = false;
				_screen.rightArrow.remove(ToolTipActive);
			}
		}
		
		/**
		 * Replace card Entity's display.
		 * @param cardEntity
		 * @param cardItem
		 */
		private function cardItemLoaded( cardItem:CardItem, cardView:CardView, slotNumber:Number ):void 
		{
			// check to make sure cardItem is on active page
			if (activePage.cards.indexOf(cardItem) != -1)
			{
				if( cardItem.cardData != null )
				{
					if( cardView.cardEntity.get(CardItem) == cardItem )
					{
						if(cardItem.cardData.buttonData[0] != null)
							cardItem.cardData.buttonData[0].entity.remove(ToolTipActive);
						if(cardItem.cardData.buttonData.length > 1)
							cardItem.cardData.buttonData[1].entity.remove(ToolTipActive);
						
						cardView.loadCardContent( null, _loadingWheelWrapper);
						cardView.displayCardItem();	// adds card Entity's CardItem display to CardView
						cardView.hide( false );		// makes CardView visible
						
						var dict:Dictionary = shellApi.itemManager.storeItems;
						
						var storeObj:Object;
						for ( var key:Object in _storeArray )
						{
							var item:Object = _storeArray[key];
							if(cardItem.itemId.substr(4) == item.id) {
								storeObj = item;
							}
						}
						if(storeObj != null) 
						{
							if(storeObj.mem_only)
							{
								var membersOnly:Sprite = BitmapUtils.createBitmapSprite(_membersOnlyGraphic);
								membersOnly.x = cardView.cardDisplay.x - (cardView.cardDisplay.width/2);
								membersOnly.y = cardView.cardDisplay.y;
								cardView.cardDisplay.addChild(membersOnly);
							}
							
							
							var price:String = storeObj.price;
							//price = cardItem.cardData.id;
							switch(slotNumber)
							{
								case 0:
									_screen.item1Price.text = price;
									break;
								case 1:
									_screen.item2Price.text = price;
									break;
								case 2:
									_screen.item3Price.text = price;
									break;
								case 3:
									_screen.item4Price.text = price;
									break;
							}
							cardItem.cardReady.dispatch();
						}
						
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
		
		/**
		 * Prepare cards for the active inventory page
		 */
		private function prepareCardSet():void 
		{
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
					idPrefix = "item";
					for (j = 0; j < cardSet.cardIds.length; j++) 
					{
						cardItem = new CardItem();
						cardItem.itemId = idPrefix + cardSet.cardIds[j];
						cardItem.listIndex = listIndex++;
						cardItem.pathPrefix = "items/" + cardSet.id + "/" + cardItem.itemId;
						activePage.cards.push( cardItem );
					}
				}
			}
		}
		
		// buy item
		private function buyItem(item:String, price:String):void
		{
			//trace("buy " + currentItem.item_id);
			
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.password_hash 	= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.item_id 		= item;
			vars.hard_price     = price;
			
			// get data
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/redeem_credits_priced.php", vars, URLRequestMethod.POST, Command.create(donePurchase, item));
		}
		
		// when done purchasing
		private function donePurchase(event:Event, item_name:String):void
		{
			var dialogBox:ConfirmationDialogBox;
			var vars:URLVariables = new URLVariables(event.currentTarget.data);
			if (vars.status == "true")
			{
				trace("purchase success: " + vars.credits);
				
				// tracking
				shellApi.track(TRACK_BUY_ITEM, item_name, null, _storeTracking);
				
				
				var newCredits:Number = Number(vars.credits)
				currCredits = newCredits;
				// update credits in profile (don't need to save because it's done on backend at purchase time)
				shellApi.profileManager.active.credits = newCredits;
				// update display
				_screen.credits.text = String(newCredits);
				// add to clubhouse inventory (if already in inventory, then increment max)
				super.shellApi.getItem(item_name);
				
				// success dialog
				dialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Purchase successful")) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(_scene.overlayContainer);
			}
			else
			{
				trace("Purchase error: " + vars.error);
				var message:String = "Error with purchase!";
				var save:Boolean = false;
				// show message
				switch(vars.error)
				{
					case "insufficient-credit":
						message = "You don't have enough credits to buy this.";
						break;
					case "item-already-there":
						message = "You already have this item.";
						break;
					case "no-such-user":
						message = "You must save your game first!";
						save = true;
						break;
				}
				
				shellApi.track(TRACK_ERROR, vars.error, null, _storeTracking);
				
				// insufficient-credit
				dialogBox = this.addChildGroup(new ConfirmationDialogBox(1, message)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(_scene.overlayContainer);
				if(save)
					dialogBox.removed.addOnce(saveGame);
			}
		}
		
		private function saveGame(...args):void
		{
			// TODO Auto Generated method stub
			addChildGroup(new SaveGamePopup(shellApi.currentScene.overlayContainer));
		}
	}
}