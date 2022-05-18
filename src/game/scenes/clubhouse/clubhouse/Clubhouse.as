package game.scenes.clubhouse.clubhouse
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.input.Input;
	import game.components.motion.Draggable;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.PlayerLocation;
	import game.data.comm.PopResponse;
	import game.data.profile.MembershipStatus;
	import game.data.ui.ToolTipType;
	import game.managers.SceneManager;
	import game.managers.ScreenManager;
	import game.proxy.Connection;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SFSceneGroup;
	import game.scenes.hub.town.Town;
	import game.systems.motion.DraggableSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.hud.Hud;
	import game.ui.popup.DecorationMemberPopup;
	import game.ui.popup.DecorationStorePopup;
	import game.ui.saveGame.SaveGamePopup;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	// clubhouse scene for all clubhouses
	public class Clubhouse extends PlatformerGameScene
	{
		// tracking constants
		private const TRACK_CLUBHOUSE_ENTER:String 		= "ClubhouseEnter";
		private const TRACK_CLUBHOUSE_EXIT:String 		= "ClubhouseExit";
		private const TRACK_CLUBHOUSE_DISCONNECT:String = "ClubhouseDisconnect";
		private const TRACK_USE_DECORATION:String 		= "ClubhouseUseDecoration";
		private const TRACK_DELETE_DECORATION:String 	= "ClubhouseDeleteDecoration";
		public const TRACK_BUY_DECORATION:String 		= "ClubhouseBuyDecoration";
		private const TRACK_SAVE_DECORATIONS:String 	= "ClubhouseSaveDecorations";
		private const TRACK_ERROR:String 				= "ClubhouseError";
		
		// clubhouse names with corresponding scene IDs and default wallpaper
		private const CLUBHOUSE_LIST:Array = ["Clubhouse", "Castle", "Diner", "Fairytale"];
		private const CLUBHOUSE_SCENE_IDS:Array = ["2008", "2010", "2009", "2020"];
		private const CLUBHOUSE_WPAP_IDS:Array = ["8000", "8001", "8002", "8015"];
		
		// other constants
		private const NUM_ITEMS:Number = 4;						// number of items per preview group
		private const PREV_SPAN:Number = 424;					// vertical span of preview group (4 x 106)
		private const SLIDE:Number = 155;						// amount to slide ui panel to left
		private const FOLLOW_RATE:Number = 0.03;				// follow rate for camera when dragging decorations
		private const SWITCH_ROOM:String = "Switch Room";		// rollover text for room switch
		
		// hold connection should be changed to true if playing head-to-head games
		private var _holdConnection:Boolean = false;			// hold Smartfox connection
		private var _container:DisplayObjectContainer;			// scene container
		private var clubhouseName:String;						// current clubhouse name
		private var clubhouseID:String;							// current clubhouse id
		private var myClubhouse:Boolean = false;				// my clubhouse flag (as opposed to visiting friend's clubhouse)
		public var isMember:Boolean = true;					// membership status
		private var resetting:Boolean = false;					// when resetting decorations
		private var gotAllData:Boolean = false;					// when got all server data
		private var exiting:Boolean = false;					// when exiting
		
		// wallpaper
		private var wallpaper:DisplayObject;					// first wallpaper to load
		private var defaultWallpaperID:String;					// default wallpaper ID
		private var currWallpaperID:String;						// current wallpaper ID (can be overriden by server-saved value)
		private var draggingWallpaper:Boolean = false;			// when dragging wallpaper
		private var noWallpaperSaved:Boolean = false;			// when no wallpaper has beens saved to the server
		private var cameraFollow:Boolean = false;				// when camera is following while dragging decoration
		
		// ui
		private var ui:MovieClip;								// ui movie clip
		private var uiReady:int = 0;							// when scene and ui are loaded
		private var decorationPanel:Entity;						// decoration panel entity
		private var decorCollapsed:Boolean = false;				// when decoration panel is collapsed
		private var decorVisible:Boolean = false;				// when decoration panel is visible
		private var dragClip:MovieClip;							// drag art clip
		
		// buttons
		private var decorButton:Entity;
		private var storeButton:Entity;
		private var topArrow:Entity;
		private var bottomArrow:Entity;
		private var collapseButton:Entity;
		private var uncollapseButton:Entity;
		private var deleteButton:Entity;
		private var flipButton:Entity;
		private var switchButton:Entity;
		private var saveDecorButton:Entity;
		private var closeSaveDecorButton:Entity;
		private var saveStoreButton:Entity;
		private var closeSaveStoreButton:Entity;
		private var buttons:Vector.<Entity> = new Vector.<Entity>(); // all other buttons
		
		// panels
		private var currentTab:String = "";						// name of current tab category
		private var numPanels:int = 0;							// total number of panels per category
		private var numItems:int = 0;							// total number of decoration items per category
		private var panels:Vector.<Entity>;						// array of panel entities (each panel holds 4 previews)			
		private var previewButtons:Vector.<Entity>;				// array of panel preview buttons
		private var dots:Vector.<MovieClip>;					// array of dots to indicate page
		private var showFirstPanel:Boolean = true;				// showing first panel flag
		private var itemPos:int = 0;							// current item position based on scrolling
		private var isScrolling:Boolean = false;				// is scrolling flag
		
		// arrays of decorations by category type
		private var wall:Array = [];
		private var furn:Array = [];
		private var appl:Array = [];
		private var misc:Array = [];
		private var wpap:Array = [];
		private var wallStore:Array = [];
		private var furnStore:Array = [];
		private var applStore:Array = [];
		private var miscStore:Array = [];
		private var wpapStore:Array = [];
		
		// decorations
		private var counter:int = 0;							// counter when loading saved decorations
		private var decorationList:Array = [];					// list of scene decorations (not wallpapers)
		private var decorationUsage:Object = {};				// decoration usage by ID
		private var currDecoration:Entity;						// current decoration being dragged or highlighted
		private var dragging:Boolean = false;					// dragging decoration flag
		private var startingDepth:int;							// starting index when dragging decoraions
		private var edited:Boolean = false;						// when scene decorations edited
		private var depthError:Boolean = false;					// error flag when depths get messed up (don't want to save)
		
		// INITIALIZATiON =========================================================
		
		public function Clubhouse()
		{
			super();
		}
		
		// preload setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// remember container for later
			_container = container;
			
			// get name of clubhouse based on class name
			// used for default wallpaper for clubhouse scene
			clubhouseName = ClassUtils.getNameByObject(this);
			var arr:Array = clubhouseName.split("::");
			clubhouseName = arr[arr.length - 1];
			
			// get clubhouse scene ID
			var index:int = CLUBHOUSE_LIST.indexOf(clubhouseName);
			clubhouseID = CLUBHOUSE_SCENE_IDS[index];

			// set default and current wallpaper IDs (can be overriden by server-saved values)
			defaultWallpaperID = CLUBHOUSE_WPAP_IDS[index];
			currWallpaperID = defaultWallpaperID;

			// get member status
			var status:uint = shellApi.profileManager.active.memberStatus.statusCode;
			// is a member
			//if ((status == MembershipStatus.MEMBERSHIP_ACTIVE) || (status == MembershipStatus.MEMBERSHIP_EXTENDED))
			//{
				isMember = true;
			//}

			// testing
			//shellApi.sceneManager.clubhouseLogin = "testingmember";
			
			// check for login (if null or mine, then assumes my clubhouse)
			// if someone else's clubhouse, then that is set before this scene is loaded
			if ((shellApi.sceneManager.clubhouseLogin == null) || (shellApi.sceneManager.clubhouseLogin == shellApi.profileManager.active.login))
			{
				shellApi.sceneManager.clubhouseLogin = shellApi.profileManager.active.login;
				
				// set to my clubhouse
				myClubhouse = true;
				
				// load clubhouse UI (will be disabled for guests)
				shellApi.loadFile(shellApi.assetPrefix + "ui/clubhouse/ui.swf", uiLoaded);
			}
			
			trace("clubhouse login: " + shellApi.sceneManager.clubhouseLogin);
			
			var vars:URLVariables = new URLVariables();
			if (myClubhouse)
			{
				vars.login 			= shellApi.profileManager.active.login;
				vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
				vars.dbid 			= shellApi.profileManager.active.dbid;
			}
			else
			{
				vars.login 			= shellApi.profileManager.active.login;
				vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
				vars.dbid 			= shellApi.profileManager.active.dbid;
				vars.lookup_user 	= shellApi.sceneManager.clubhouseLogin;
			}
			vars.scene_id 			= clubhouseID; // clubhouse scene ID
			
			// if guest then load default wallpaper
			if (shellApi.profileManager.active.isGuest)
			{
				loadFirstWallpaper();
			}
			// if not guest then get decoration data
			else
			{
				var connection:Connection = new Connection();
				connection.connect(shellApi.siteProxy.secureHost + "/interface/Decorations/get", vars, URLRequestMethod.POST, gotClubhouseData);
			}
		}
		
		// when get clubhouse scene data
		private function gotClubhouseData(event:Event):void
		{
			trace("Clubhouse data: " + event.target.data);
			
			var wallpaperID:String;
			var wallpaperName:String;
			
			// convert to JSON
			var json:Object = JSON.parse(event.currentTarget.data);
			
			// if success
			if (json.answer == "ok")
			{
				trace("gotClubhouseData: success");
				
				// get decorations
				var decorations:Array = json.stickers;
				
				// iterate and look for wall paper and create decoration list placeholders
				for (var i:int = decorations.length - 1; i!= -1; i--)
				{
					var decoration:Object = decorations[i];
					
					// if wallpaper
					if ((decoration.x == 0) && (decoration.y == 0) && (decoration.z == -1))
					{
						wallpaperID = decoration.item_id;
						wallpaperName = decoration.item_name;
						trace("Got clubhouse wallpaper: " + wallpaperID + ": " + wallpaperName);
						// remove from array
						decorations.splice(i, 1);
					}
					// if not wallpaper, create placholder in decoration list
					else
					{
						decorationList.push(null);
					}
				}
				
				// iterate to match z depth
				for each (decoration in decorations)
				{
					var data:Object = {};
					// remove number suffix from name, if any
					var index:int = decoration.item_name.indexOf("|");
					if (index != -1)
					{
						decoration.item_name = decoration.item_name.substr(0,index);
					}
					data.item_name = decoration.item_name;
					trace("Got clubhouse decoration: " + decoration.item_name + " at depth " + decoration.z);
					data.item_id = decoration.item_id;
					data.x = Number(decoration.x);
					data.y = Number(decoration.y);
					data.z = Number(decoration.z);
					data.reflect = Number(decoration.reflect);
					decorationList[data.z] = data;
				}
			}
			else
			{
				trace("Error fetching decorations!");
				// tracking
				shellApi.track(TRACK_ERROR, "get", null, "Clubhouse");
			}
			
			// load first wallpaper before loading scene
			loadFirstWallpaper(wallpaperID, wallpaperName);
		}
		
		// load wallpapper before loading scene
		// default wallpaper name must contain clubhouse name
		// if wallpaper ID is null, then use default wallpaper
		private function loadFirstWallpaper(wallpaperID:String = null, wallpaperName:String = null):void
		{
			// load wallpapper before loading scene
			// default wallpaper name must contain clubhouse name
			// if wallpaper ID is null, then use default wallpaper
			if (wallpaperID == null)
			{
				noWallpaperSaved = true;
				wallpaperName = "wpap_" + clubhouseName.toLowerCase();
			}
				// if wallpaper ID not null, then set current wallpaper ID
			else
			{
				currWallpaperID = wallpaperID;
			}
			
			// load wallpaper jpeg
			var path:String = shellApi.assetPrefix + "clubhouse/" + wallpaperName + ".jpg";
			super.shellApi.loadFile(path, gotFirstWallpaper);
		}
		
		private function setupSteamClubhouse():void
		{
			furnStore = new Array();
			var object:Object = new Object();
			object.count = 1;
			object.item_id = "7005";
			object.item_mem_only = "0";
			object.item_name = "furn_blue_throne";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7007";
			object.item_mem_only = "0";
			object.item_name = "furn_castle_armoire";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7008";
			object.item_mem_only = "0";
			object.item_name = "furn_castle_book_shelf01";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7009";
			object.item_mem_only = "0";
			object.item_name = "furn_castle_fireplace";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7011";
			object.item_mem_only = "0";
			object.item_name = "furn_claw_machine";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7012";
			object.item_mem_only = "0";
			object.item_name = "furn_green_safe";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7013";
			object.item_mem_only = "0";
			object.item_name = "furn_hat_stand";
			object.item_price = "125";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7014";
			object.item_mem_only = "0";
			object.item_name = "furn_ice_cream_machine";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7015";
			object.item_mem_only = "0";
			object.item_name = "furn_mini_trampoline";
			object.item_price = "175";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7016";
			object.item_mem_only = "0";
			object.item_name = "furn_mirror_dresser";
			object.item_price = "0";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7017";
			object.item_mem_only = "0";
			object.item_name = "furn_red_throne";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7018";
			object.item_mem_only = "0";
			object.item_name = "furn_restaurant_booth01";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7019";
			object.item_mem_only = "0";
			object.item_name = "furn_soda_dispenser";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7021";
			object.item_mem_only = "0";
			object.item_name = "furn_wooden_chest";
			object.item_price = "150";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7073";
			object.item_mem_only = "0";
			object.item_name = "furn_bean_bag_chair_unicorn";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7074";
			object.item_mem_only = "0";
			object.item_name = "furn_throne_unicorn";
			object.item_price = "250";
			object.priority = "1";
			furnStore.push(object);
			
			applStore = new Array();
			object = new Object();
			object.count = 1;
			object.item_id = "7003";
			object.item_mem_only = "0";
			object.item_name = "appl_hanging_light";
			object.item_price = "75";
			object.priority = "1";
			applStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7004";
			object.item_mem_only = "0";
			object.item_name = "appl_metal_sconce";
			object.item_price = "75";
			object.priority = "1";
			applStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7134";
			object.item_mem_only = "0";
			object.item_name = "appl_styleradio";
			object.item_price = "75";
			object.priority = "1";
			applStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7236";
			object.item_mem_only = "0";
			object.item_name = "appl_blue_fridge";
			object.item_price = "250";
			object.priority = "1";
			applStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7233";
			object.item_mem_only = "0";
			object.item_name = "appl_tv";
			object.item_price = "250";
			object.priority = "1";
			applStore.push(object);
			miscStore = new Array()
			object = new Object();
			object.count = 1;
			object.item_id = "7023";
			object.item_mem_only = "0";
			object.item_name = "misc_basketball";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7025";
			object.item_mem_only = "0";
			object.item_name = "misc_burger";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7027";
			object.item_mem_only = "0";
			object.item_name = "misc_chocolate_shake";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7029";
			object.item_mem_only = "0";
			object.item_name = "misc_football";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7031";
			object.item_mem_only = "0";
			object.item_name = "misc_french_fries";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7033";
			object.item_mem_only = "0";
			object.item_name = "misc_hot_dog";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7034";
			object.item_mem_only = "0";
			object.item_name = "misc_ketchup";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7035";
			object.item_mem_only = "0";
			object.item_name = "misc_mustard";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7043";
			object.item_mem_only = "0";
			object.item_name = "misc_soccer_ball";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7045";
			object.item_mem_only = "0";
			object.item_name = "misc_soda_can";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7048";
			object.item_mem_only = "0";
			object.item_name = "misc_sub_sandwich";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7092";
			object.item_mem_only = "0";
			object.item_name = "misc_pet_dish";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7094";
			object.item_mem_only = "0";
			object.item_name = "misc_puppy_bone";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7096";
			object.item_mem_only = "0";
			object.item_name = "misc_dog_house";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7101";
			object.item_mem_only = "0";
			object.item_name = "misc_baseball_mitt";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7102";
			object.item_mem_only = "0";
			object.item_name = "misc_tennis_racket";
			object.item_price = "75";
			object.priority = "1";
			miscStore.push(object);
			wallStore = new Array();
			object = new Object();
			object.count = 1;
			object.item_id = "7051";
			object.item_mem_only = "0";
			object.item_name = "wall_basketball_hoop";
			object.item_price = "150";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7052";
			object.item_mem_only = "0";
			object.item_name = "wall_blue_butterfly";
			object.item_price = "75";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7054";
			object.item_mem_only = "0";
			object.item_name = "wall_colored_lights";
			object.item_price = "125";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7056";
			object.item_mem_only = "0";
			object.item_name = "wall_keepeth_out_sign";
			object.item_price = "75";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7058";
			object.item_mem_only = "0";
			object.item_name = "wall_orange_butterfly";
			object.item_price = "75";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7059";
			object.item_mem_only = "0";
			object.item_name = "wall_party_neon_sign";
			object.item_price = "200";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7060";
			object.item_mem_only = "0";
			object.item_name = "wall_pop_blimp";
			object.item_price = "0";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7061";
			object.item_mem_only = "0";
			object.item_name = "wall_red_rocket";
			object.item_price = "200";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7062";
			object.item_mem_only = "0";
			object.item_name = "wall_red_royal_drapes";
			object.item_price = "150";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7064";
			object.item_mem_only = "0";
			object.item_name = "wall_singer_poster";
			object.item_price = "75";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7065";
			object.item_mem_only = "0";
			object.item_name = "wall_stained_glass_window";
			object.item_price = "250";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7066";
			object.item_mem_only = "0";
			object.item_name = "wall_sword_shield";
			object.item_price = "150";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7068";
			object.item_mem_only = "0";
			object.item_name = "wall_unicorn_flag";
			object.item_price = "150";
			object.priority = "1";
			wallStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "7075";
			object.item_mem_only = "0";
			object.item_name = "wall_moon_decoration_unicorn";
			object.item_price = "75";
			object.priority = "1";
			wallStore.push(object);
			
			wpapStore = new Array();
			object = new Object();
			object.count = 1;
			object.item_id = "8000";
			object.item_mem_only = "0";
			object.item_name = "wpap_clubhouse";
			object.item_price = "0";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8001";
			object.item_mem_only = "0";
			object.item_name = "wpap_castle";
			object.item_price = "0";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8002";
			object.item_mem_only = "0";
			object.item_name = "wpap_diner";
			object.item_price = "0";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8003";
			object.item_mem_only = "0";
			object.item_name = "wpap_bookcase";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8004";
			object.item_mem_only = "0";
			object.item_name = "wpap_sandstone";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8005";
			object.item_mem_only = "0";
			object.item_name = "wpap_brick";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8006";
			object.item_mem_only = "0";
			object.item_name = "wpap_stone_sand";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8007";
			object.item_mem_only = "0";
			object.item_name = "wpap_striped";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8008";
			object.item_mem_only = "0";
			object.item_name = "wpap_wood_panel";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8009";
			object.item_mem_only = "0";
			object.item_name = "wpap_pink_diner";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8010";
			object.item_mem_only = "0";
			object.item_name = "wpap_unicorn";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8011";
			object.item_mem_only = "0";
			object.item_name = "wpap_fairytale_summer";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8012";
			object.item_mem_only = "0";
			object.item_name = "wpap_sunken_ship";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8013";
			object.item_mem_only = "0";
			object.item_name = "wpap_home01";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8014";
			object.item_mem_only = "0";
			object.item_name = "wpap_fairytale_spring";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			object = new Object();
			object.count = 1;
			object.item_id = "8015";
			object.item_mem_only = "0";
			object.item_name = "wpap_fairytale";
			object.item_price = "150";
			object.priority = "1";
			wpapStore.push(object);
			
			
		}
		
		// when got first wallpaper
		private function gotFirstWallpaper(clip:DisplayObject):void
		{
			wallpaper = clip;
			super.groupPrefix = "scenes/clubhouse/" + clubhouseName.toLowerCase() + "/";
			super.init(_container);
		}
		
		// all assets ready (called after wallpaper loaded)
		override public function loaded():void
		{
			// tracking
			shellApi.track(TRACK_CLUBHOUSE_ENTER, clubhouseName, null, "Clubhouse");
			
			// listen for hud closing and opening
			Hud(this.getGroupById(Hud.GROUP_ID)).openingHud.add(hudOpened);
			
			// start multiplayer
			shellApi.smartFoxManager.disconnected.addOnce(onDisconnect);
			shellApi.sceneManager.enableMultiplayer(false, true, false);

			// clear clubhouse login
			shellApi.sceneManager.clubhouseLogin = null;
			
			super.loaded();
			
			// add wallpaper to backdrop
			var backdrop:DisplayObjectContainer = DisplayObjectContainer(this._hitContainer.parent.getChildAt(0));
			if (wallpaper != null)
			{
				var image:DisplayObject = backdrop.addChild(wallpaper);
				// align to camera bounds bottom
				image.y = this.sceneData.bounds.height - image.height;
			}
			
			// load decorations
			for each (var decorationData:Object in decorationList)
			{
				trace("load decoration " + decorationData.item_name + " holder at depth " + decorationData.z);
				// create holder and add at bottommost depth
				var clip:MovieClip = new MovieClip();
				clip = MovieClip(_hitContainer.addChildAt(clip, 0));
				clip.name = "content";
				super.shellApi.loadFile(shellApi.assetPrefix + "clubhouse/" + decorationData.item_name + ".swf", Command.create(addDecoration, decorationData));
			}
			
			// if my clubhouse
			if (myClubhouse)
			{
				// create room switch button
				switchButton = ButtonCreator.createButtonEntity(_hitContainer["roomSwitch"], this, switchRoom, null, null, ToolTipType.CLICK);
				switchButton.get(ToolTip).label = SWITCH_ROOM;
				
				// setup clubhouse UI
				setupUI();
				
				// if not guest
				if (!shellApi.profileManager.active.isGuest)
				{
					// add system
					this.addSystem( new DraggableSystem() );
					
					// get bought inventory (priced)
					getInventory();
					
					// create listener for clicking in scene
					SceneUtil.getInput( this ).inputDown.add( clickBackground );
				}
				// if guest, then restore buttons and pretend we got all data
				else
				{
					gotAllData = true;
					
					// show UI buttons
					showButton(decorButton, true);
					showButton(storeButton, true);
					setupSteamClubhouse();
					sortArray(wallStore);
					sortArray(furnStore);
					sortArray(applStore);
					sortArray(miscStore);
					sortArray(wpapStore);
				}
			}
			// else hide room switch if friends are visiting
			else
			{
				_hitContainer["roomSwitch"].visible = false;
			}
		}
		
		// add saved decoration to scene
		private function addDecoration(clip:MovieClip, data:Object):void
		{
			if(clip != null) {
					
				trace("Adding decoration " + data.item_name + " at depth " + data.z);
				// add clip to container created earlier
				var holder:MovieClip = MovieClip(_hitContainer.getChildAt(data.z));
				holder.addChild(clip["content"]);
				holder.x = data.x;
				holder.y = data.y;
				
				// create entity
				var decoration:Entity = EntityUtils.createSpatialEntity(this, holder, _hitContainer);
				decoration.add(new Sleep(true));
				
				// flip if requested
				if (data.reflect == 1)
				{
					var content:DisplayObject = decoration.get(Display).displayObject.getChildAt(0);
					content.scaleX = -content.scaleX;
				}
				
				// add entity to decoration list
				data.entity = decoration;
				
				// interations and tooltip
				InteractionCreator.addToEntity(decoration, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], holder);
				
				// make draggable
				var draggable:Draggable = new Draggable();
				draggable.drag.add( decorDown );
				draggable.drop.add( Command.create(decorUp, data) );
				draggable.forward = false;
				draggable.disable = true;
				decoration.add(draggable);
	
				// disable mouse
				decoration.get(Display).displayObject.mouseEnabled = false;
			}
		}
		
		// SERVER FUNCTIONS ======================================================
		
		// get bought decorations
		private function getInventory():void
		{
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.island 		= "Clubhouse_as3";
			
			// get data
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/list_items.php", vars, URLRequestMethod.POST, gotInventory);
		}
		
		// when got bought decorations
		private function gotInventory(event:Event):void
		{
			if (exiting)
			{
				return;
			}
			trace("Clubhouse inventory data: " + event.currentTarget.data);
			var vars:URLVariables = new URLVariables(event.currentTarget.data);
			// get items_info array
			var list:Object = JSON.parse(vars.items_info);
			if (list is Array)
			{
				for each (var decoration:Object in list)
				{
					// get category
					var category:String = decoration.item_name.substr(0,4);
					var inventory:Array = this[category];
					trace("Adding bought decoration: " + decoration.item_id);
					inventory.push(decoration);
				}
			}
			getDecorations();
		}
		
		// get decorations list
		private function getDecorations():void
		{
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.scene_id 		= CLUBHOUSE_SCENE_IDS[0]; // clubhouse scene ID
			
			// get data
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Decorations/list", vars, URLRequestMethod.POST, gotCMSDecorations);
		}
		
		// when got CMS decoration data
		private function gotCMSDecorations(event:Event):void
		{
			if (exiting)
			{
				return;
			}
			trace("Clubhouse CMS data: " + event.currentTarget.data);
			// convert to JSON
			var json:Object = JSON.parse(event.currentTarget.data);
			if (json.answer == "ok")
			{
				// process clubhouse decoration items
				for each (var item:Object in json.stickers)
				{
					// get decoration prefix from item name
					var decorPrefix:String = item.item_name.substr(0, 4);
					
					// set max count (default is one)
					var count:int = 1;
					
					// get decoration name
					var name:String = item.item_name;
					
					// trim off any trailing number (number is used to set max quantity)
					var index:int = name.indexOf("|");
					if (index != -1)
					{
						count = int(name.substr(index + 1));
						// save new name
						item.item_name = name.substr(0,index);
					}
	
					// add max to item
					item.count = count;
					
					// get inventory and store arrays for prefix
					var inventory:Array = this[decorPrefix];
					var store:Array = this[decorPrefix + "Store"];
					
					// if no inventory array found, then error
					if (inventory == null)
					{
						trace("ERROR: decoration name doesn't start with allowed prefix! item: " + item.item_id + " prefix: " + decorPrefix);
					}
					// if array found and priority is non-zero
					else if (item.item_priority != "0")
					{
						// if free item, then add to inventory
						if (item.item_price == "0")
						{
							// add item if player is member or if not a members only decoration
							if ((isMember) || (item.item_mem_only == "0"))
							{
								inventory.push(item);
							}
						}
						// if has price then add to store
						else
						{
							store.push(item);
						}
					}
				}
				// sort arrays by priority
				sortArray(wall);
				sortArray(furn);
				sortArray(appl);
				sortArray(misc);
				sortArray(wpap);
				
				
				// get usage now
				getUsage();
			}
			else
			{
				trace("gotCMSDecorations Error"); 
				// tracking
				shellApi.track(TRACK_ERROR, "list", null, "Clubhouse");
			}
			setupSteamClubhouse();
			sortArray(wallStore);
			sortArray(furnStore);
			sortArray(applStore);
			sortArray(miscStore);
			sortArray(wpapStore);
		}
		
		// sort array by priority descending
		private function sortArray(array:Array):void
		{
			if (array.length != 0)
			{
				array.sortOn(["item_priority"], [Array.DESCENDING]);
			}
		}
		
		// get decorations usage
		private function getUsage():void
		{
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.island_id 		= 103;
			
			// get data
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Decorations/getUsageByIsland", vars, URLRequestMethod.POST, gotUsage);
		}
		
		// when got decoration usage
		private function gotUsage(event:Event):void
		{
			if (exiting)
			{
				return;
			}
			trace("Clubhouse usage data: " + event.currentTarget.data);
			// convert to JSON
			var json:Object = JSON.parse(event.currentTarget.data);
			if (json.answer == "ok")
			{
				// use stickers object
				decorationUsage = json.stickers;
				
				// if no wallpaper saved to server for this clubhouse, then set default wallpaper and usage
				if (noWallpaperSaved)
				{
					// check wallpaper usage
					var wallpaperCount:int = 0;
					for (var id:String in decorationUsage)
					{
						// if wallpaper (wallpapers start with 8000)
						// if all clubhouses have saved wallpaper, then count will match number of clubhouses
						if (int(id) >= 8000)
						{
							wallpaperCount++;
						}
					}
					trace("Saved wallpaper count: " + wallpaperCount);
					
					// get clubhouse index in list
					var index:int = CLUBHOUSE_LIST.indexOf(clubhouseName);
					// set usage for all wallpapers for this index on
					for (var i:int = index; i!= CLUBHOUSE_LIST.length; i++)
					{
						// set usage for this wallpaper and ones to follow
						decorationUsage[CLUBHOUSE_WPAP_IDS[i]] = 1;
					}
					saveWallpaper(index);
				}
				// we got all data now
				gotAllData = true;
				
				// show UI buttons
				showButton(decorButton, true);
				showButton(storeButton, true);
			}
			else
			{
				trace("error fetching usage");
				// tracking
				shellApi.track(TRACK_ERROR, "getUsageByIsland", null, "Clubhouse");
			}
		}
				
		// UI FUNCTIONS ================================================
		
		// when clubhouse UI loaded
		private function uiLoaded(clip:MovieClip):void
		{
			// remember clip
			ui = clip;
			// stop at first frame
			ui.ui.gotoAndStop(1);
			// setup clubhouse UI
			setupUI();
		}
		
		// setup clubhouse UI
		private function setupUI():void
		{
			// increments when UI loaded and scene loaded
			uiReady++;
			
			// if both loaded
			if (uiReady == 2)
			{
				// add ui to overlay
				ui = MovieClip(this.overlayContainer.addChild(ui));
				
				// adjust if screen is more square
				if (shellApi.camera.viewportWidth / shellApi.camera.viewportHeight < ScreenManager.GAME_WIDTH / ScreenManager.GAME_HEIGHT)
				{
					// move ui down to bottom of screen area
					ui.y = shellApi.camera.viewportHeight - ScreenManager.GAME_HEIGHT;
					// scale panel to fit height
					ui.ui.scaleX = ui.ui.scaleY = shellApi.camera.viewportHeight / ScreenManager.GAME_HEIGHT;
				}
				
				// decoration panel
				decorationPanel = EntityUtils.createSpatialEntity(this, ui.ui, ui);
				
				// edge rollover for uncollapsing panel
				ui.ui.edge.addEventListener(MouseEvent.MOUSE_OVER, overEdge);
				ui.ui.edge.visible = false;
				
				// setup drag clip (stop buttons at frame 1)
				dragClip = ui.dragHolder.drag;
				dragClip.deleteButton.gotoAndStop(1);
				dragClip.flipButton.gotoAndStop(1);
				
				// decoration button
				decorButton = ButtonCreator.createButtonEntity( ui.decorButton, this, Command.create(showDecorationPanel, true), null, null, ToolTipType.CLICK);
				// if guest, then dim
				if (shellApi.profileManager.active.isGuest)
				{
					decorButton.get(Display).alpha = 0.5;
				}
				else
				{
					showButton(decorButton, false);
				}
				
				// store button
				storeButton = ButtonCreator.createButtonEntity( ui.storeButton, this, openStore, null, null, ToolTipType.CLICK);
				// if guest, then dim
				if (shellApi.profileManager.active.isGuest)
				{
					storeButton.get(Display).alpha = 0.5;
				}
				else
				{
					showButton(storeButton, false);
				}
				
				// collapse button
				collapseButton = ButtonCreator.createButtonEntity( ui.ui.collapseButton, this, Command.create(collapsePanel, false), null, null, ToolTipType.CLICK);
				showButton(collapseButton, false);
				
				// uncollapse button
				uncollapseButton = ButtonCreator.createButtonEntity( ui.ui.uncollapseButton, this, Command.create(collapsePanel, true), null, null, ToolTipType.CLICK);
				
				// delete button
				var btn:MovieClip = MovieClip(_hitContainer.addChild(ui.deleteButton));
				btn.x = -1000;
				deleteButton = ButtonCreator.createButtonEntity( btn, this, deleteDecoration, null, null, ToolTipType.CLICK, false);
				
				// flip button
				btn = MovieClip(_hitContainer.addChild(ui.flipButton));
				btn.x = -1000;
				flipButton = ButtonCreator.createButtonEntity( btn, this, flipDecoration, null, null, ToolTipType.CLICK, false);
				
				// reset button
				if (AppConfig.debug)
				{
					//ButtonCreator.createButtonEntity( ui.resetButton, this, clearDecorations, null, null, ToolTipType.CLICK);
				}
				
				// add other buttons
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.closeButton, this, Command.create(showDecorationPanel, false), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.taButton, this, Command.create(scroll,-1), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.baButton, this, Command.create(scroll,1), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.wallButton, this, Command.create(doTab,"wall"), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.furnButton, this, Command.create(doTab,"furn"), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.applButton, this, Command.create(doTab,"appl"), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.miscButton, this, Command.create(doTab,"misc"), null, null, ToolTipType.CLICK));
				buttons.push(ButtonCreator.createButtonEntity( ui.ui.wpapButton, this, Command.create(doTab,"wpap"), null, null, ToolTipType.CLICK));
				
				// arrow buttons
				topArrow = this.getEntityById("taButton");
				bottomArrow = this.getEntityById("baButton");
				
				// save panel for decor button
				ui.savePanel.visible = false;
				saveDecorButton = ButtonCreator.createButtonEntity( ui.savePanel.saveButton, this, saveGame, null, null, ToolTipType.CLICK);
				showButton(saveDecorButton, false);
				closeSaveDecorButton = ButtonCreator.createButtonEntity( ui.savePanel.closeButton, this, Command.create(showSaveDecorPanel,false), null, null, ToolTipType.CLICK);
				showButton(closeSaveDecorButton, false);
				
				// save panel for store button
				ui.storePanel.visible = false;
				saveStoreButton = ButtonCreator.createButtonEntity( ui.storePanel.saveButton, this, saveGame, null, null, ToolTipType.CLICK);
				showButton(saveStoreButton, false);
				closeSaveStoreButton = ButtonCreator.createButtonEntity( ui.storePanel.closeButton, this, Command.create(showSaveStorePanel,false), null, null, ToolTipType.CLICK);
				showButton(closeSaveStoreButton, false);
				
				// hide decoration ui
				showDecorationPanel(null, false);
			}
		}
		
		// show/hide decoration panel
		private function showDecorationPanel(btnEntity:Entity, state:Boolean):void
		{
			// if clicking disabled button
			if ((btnEntity != null) && (btnEntity.get(Display).alpha == 0.5))
			{
				// show save panel
				showSaveDecorPanel(null, true);
			}
			else
			{
				decorVisible = state;
				
				// toggle panel
				decorationPanel.get(Display).visible = state;
				
				// toggle menu button
				var mainHud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
				mainHud.hideButton(Hud.HUD, state);
				
				// toggle chat buttons
				var group:SFSceneGroup = SFSceneGroup(this.groupManager.getGroupById("sfsSceneGroup"));
				group.suppressIconsOnInit = state;
				if (group.chat)
				{
					group.chat.showChatBtns(!state);
				}
				
				// toggle emotes
				if (group.emotes)
				{
					group.emotes.showEmotes(!state);
				}
				
				// toggle decoration and store button (hide when decoration panel is showing)
				if (gotAllData)
				{
					showButton(decorButton, !state);
					showButton(storeButton, !state);
				}
				
				// dim switch button
				switchButton.get(Display).alpha = (state) ? 0.5 : 1;
				showButtonTooltip(switchButton, !state, true, SWITCH_ROOM);
				
				// toggle door
				var doorEntity:Entity = this.getEntityById("exitClubhouse");
				showButtonTooltip(doorEntity, !state, true, "EXIT");
				
				// toggle remaining buttons
				ui.ui.visible = state;
				for each (var button:Entity in buttons)
				{
					showButton(button, state);
				}
				
				// if turning on
				if (state)
				{
					// if first time showing, then show wall decorations
					if (showFirstPanel)
					{
						showFirstPanel = false;
						doTab(null, "wall");
					}
					// if not first time, then update arrows
					else
					{
						doneScroll(false);
					}
					
					// if decoration panel collapsed, then force open immediately
					if (decorCollapsed)
					{
						decorCollapsed = false;
						decorationPanel.get(Spatial).x += SLIDE;
					}
				}
				// if turning off and not first panel
				else if (!showFirstPanel)
				{
					// hide previews
					showPanels(false);
					// follow player
					SceneUtil.setCameraTarget(this, shellApi.player);
					// remove drag art from current decoration
					clearDragArt();
					// save layout of decorations
					saveDecorations();
				}
				
				// enable/disable draggables if not first panel
				if (!showFirstPanel)
				{
					disableDraggables(!state);
				}
			}
		}
		
		// when hud closed then show buttons
		private function hudOpened(state:Boolean):void
		{
			showButton(decorButton, !state);
			showButton(storeButton, !state);
		}
		
		// click tab button
		private function doTab(btnEntity:Entity, category:String, force:Boolean = false):void
		{
			// if new tab or forcing
			if ((category != currentTab) || (force))
			{
				// remember category
				currentTab = category;
				
				// go to tab frame
				ui.ui.gotoAndStop(category);
				
				// reset item position
				itemPos = 0;
				
				// clear all (entities and dots);
				for each (var panel:Entity in panels)
				{
					this.removeEntity(panel);
				}
				for each (var button:Entity in previewButtons)
				{
					this.removeEntity(button);
				}
				for (var dot:int = ui.ui.dots.numChildren - 1; dot != -1; dot--)
				{
					ui.ui.dots.removeChildAt(dot);
				}
				panels = new Vector.<Entity>();
				previewButtons = new Vector.<Entity>();
				dots = new Vector.<MovieClip>();;
				
				// hide arrows until after panels are loaded
				topArrow.get(Display).visible = false;
				bottomArrow.get(Display).visible = false;
				
				// get array for type
				var tabItems:Array = this[category];
				
				// create copy of array (id, name, price, and count)
				var allItems:Array = [];
				for each (var item:Object in tabItems)
				{
					var newItem:Object = {};
					newItem.item_id = item.item_id;
					newItem.item_name = item.item_name;
					newItem.item_price = item.item_price;
					newItem.count = item.count;
					allItems.push(newItem);
				}
				numItems = allItems.length;
							
				// if no items then return
				if (numItems == 0)
				{
					return;
				}
				// if items
				else
				{
					// load each group of preview panels
					// calculate number of needed panels
					numPanels = Math.ceil(numItems/NUM_ITEMS);
					// starting position
					var pos:int = 0;
					
					// for each panel
					for (var i:int = 0; i!= numPanels; i++)
					{
						// get subset of array items
						var items:Array = [];
						for (var j:int = 0; j!= NUM_ITEMS; j++)
						{
							// for as many items in array
							if (allItems.length != 0)
							{
								items.push(allItems.shift());
							}
						}
						// load panel with preview items
						shellApi.loadFile(shellApi.assetPrefix + "ui/clubhouse/preview.swf", Command.create(panelLoaded, i, pos, items));
						
						// load dot if more than one panel
						if (numPanels != 1)
						{
							shellApi.loadFile(shellApi.assetPrefix + "ui/clubhouse/dot.swf", dotLoaded, i, numPanels);
						}
						// increment position
						pos += PREV_SPAN;
						
						// add dot holder
						dots.push(null);
					}
					
					// adjust arrows based on item pos
					doneScroll(false);
				}
			}
		}
		
		// BUTTON FUNCTIONS ============================================
		
		// when click on room switch
		private function switchRoom(btnEntity:Entity = null):void
		{
			// if decoration panel not visible
			if (!decorVisible)
			{
				// if member
				if (true)
				{
					exiting = true;
					// get index in list
					var index:int = CLUBHOUSE_LIST.indexOf(clubhouseName);
					index = (index + CLUBHOUSE_LIST.length + 1) % CLUBHOUSE_LIST.length;
					var room:String = CLUBHOUSE_LIST[index];
					var roomClass:Object = ClassUtils.getClassByName("game.scenes.clubhouse." + room.toLowerCase() + "." + room);
					shellApi.loadScene(roomClass);
				}
				else
				{
					var popup:DecorationMemberPopup = this.addChildGroup(new DecorationMemberPopup()) as DecorationMemberPopup;
					popup.init( shellApi.sceneManager.currentScene.overlayContainer );					
				}
			}
		}
		
		// PANELS ============================================================
		
		// when panel is loaded
		private function panelLoaded(clip:MovieClip, index:int, pos:int, items:Array):void
		{
			// add clip to previews holder and position
			clip = ui.ui.previews.addChild(clip);
			clip.y = pos;
			
			// for each preview
			for (var i:int = 0; i!= NUM_ITEMS; i++)
			{
				// if item, then load item preview
				if (i < items.length)
				{
					var item:Object = items[i];
					
					trace("load " + item.item_name);
					
					// make preview clip draggable on mousedown
					var preview:MovieClip = clip["preview" + i];
					var btnEntity:Entity = ButtonCreator.createButtonEntity( preview, this, null, null, [InteractionCreator.DOWN], ToolTipType.CLICK);
					btnEntity.get(Interaction).down.add(Command.create(clickPreview, preview, item));
					btnEntity.add(new Id(item.item_id));
					
					// add to array of preview buttons
					previewButtons.push(btnEntity);
					
					// set number (max count - usage)
					var usage:int = (decorationUsage[item.item_id] == null) ? 0 : decorationUsage[item.item_id];
					preview.num.text = String(item.count - usage);
					
					// hide coin if free
					if (item.item_price == "0")
					{
						preview.coin.visible = false;
					}
					
					// load preview with server fallback
					var path:String = shellApi.assetPrefix + "clubhouse/" + item.item_name + "_preview.png";
					super.shellApi.loadFile(path, gotPreview, preview);
				}
				// if no item then delete holder
				else
				{
					clip.removeChild(clip["preview" + i]);
				}
			}
			
			// create preview panel entity and add to panels array
			var panelEntity:Entity = EntityUtils.createSpatialEntity(this, clip);
			panelEntity.add(new Id("panel" + index));
			panels.push(panelEntity);
			
			// hide panel if not first panel
			if (pos != 0)
			{
				panelEntity.get(Spatial).x = -2000;
			}
		}
		
		// when click preview
		private function clickPreview(btnEntity:Entity, preview:MovieClip, data:Object):void
		{
			// remove drag art from any entity
			clearDragArt();
			
			// if not scrolling
			if (!isScrolling)
			{
				// get number
				var num:String = preview.num.text;
				if (num != "0")
				{
					// if wallpaper, then load into background (no dragging)
					if (currentTab == "wpap")
					{
						// do nothing if same wallpaper
						if (data.item_id != currWallpaperID)
						{
							draggingWallpaper = true;
							// decrement usage for current wallpaper
							updateUsage(currWallpaperID, -1);
							// remember new wallpaper ID
							currWallpaperID = data.item_id;
							// load wallpaper preview
							super.shellApi.loadFile(shellApi.assetPrefix + "clubhouse/" + data.item_name + "_preview.png", gotDecoration, data);
						}
						else
						{
							return;
						}
					}
					else
					{
						super.shellApi.loadFile(shellApi.assetPrefix + "clubhouse/" + data.item_name + ".swf", gotDecoration, data);
					}
					// decrement number
					preview.num.text = String(int(num) - 1);
					// increment usage
					updateUsage(data.item_id, 1);
				}
			}
		}
		
		//update inventory usage
		private function updateUsage(id:String, value:int):void
		{
			// get usage
			var usage:int = (decorationUsage[id] == null) ? 0 : decorationUsage[id];
			// update usage value
			usage += value;
			// if zero then delete
			if (usage == 0)
			{
				delete decorationUsage[id];
			}
			// if non-zero
			else
			{
				// save the value
				decorationUsage[id] = usage;
			}
			
			// if decrementing, increment number of preview
			if (value == -1)
			{
				// find preview entity
				var previewEntity:Entity = this.getEntityById(id);
				// if found
				if (previewEntity != null)
				{
					// get clip
					var clip:MovieClip = MovieClip(previewEntity.get(Display).displayObject);
					// get current number
					var currNum:int = int(clip.num.text);
					// increment
					clip.num.text = String(currNum + 1);
				}
			}
		}
		
		// LOADED FUNCTIONS ==================================================
		
		// when dot loaded
		private function dotLoaded(clip:MovieClip, pos:int, total:int):void
		{
			// dot spacing
			var spacing:int = 20;
			// add to dots holder
			clip = MovieClip(ui.ui.dots.addChild(clip));
			// position and scale
			clip.y = -((total - 1) * spacing) / 2 + pos * spacing
			clip.scaleX = clip.scaleY = 0.35;
			// set frame
			if (pos == 0)
			{
				clip.gotoAndStop(2);
			}
			else
			{
				clip.gotoAndStop(1);
			}
			// add to array
			dots[pos] = clip;
		}
		
		// when preview is loaded
		private function gotPreview(clip:Object, location:MovieClip):void
		{
			if (clip)
			{
				// add to holder
				location.holder.addChild(clip);
				// hide loading clip
				location.loading.visible = false;
			}
		}
		
		// when wallpaper loaded
		private function gotWallpaper(clip:DisplayObject, data:Object):void
		{
			edited = true;
			
			// unlock input
			SceneUtil.lockInput(this, false);
			
			// get backdrop
			var backdrop:DisplayObjectContainer = DisplayObjectContainer(this._hitContainer.parent.getChildAt(0));
			// remove previous backdrop
			if (backdrop.numChildren == 1)
			{
				backdrop.removeChild(backdrop.getChildAt(0));
			}
			
			// add clip
			var image:DisplayObject = backdrop.addChild(clip);
			// align to camera bounds bottom
			image.y = this.sceneData.bounds.height - image.height;
		}
		
		// DECORATIONS =================================================
		
		// when decoration loaded
		private function gotDecoration(downloaded:DisplayObject, data:Object):void
		{
			edited = true;
			
			// tracking
			shellApi.track(TRACK_USE_DECORATION, data.item_name, null, "Clubhouse");

			// desired depth
			startingDepth = decorationList.length;
			trace("decoration starting depth " + startingDepth);
						
			// add clip
			var holder:MovieClip = new MovieClip();
			holder.name = "content";
			var clip:MovieClip;
			// if wallpaper, then center preview 
			if (draggingWallpaper)
			{
				downloaded.x = -downloaded.width/2;
				downloaded.y = -downloaded.height/2;
				holder.addChild(downloaded);
				clip = MovieClip(_hitContainer.addChild(holder));
			}
			else
			{
				holder.addChild(downloaded["content"]);
				clip = MovieClip(_hitContainer.addChildAt(holder, startingDepth));
			}
			
			// align with cursor
			var point:Point = new Point(clip.stage.mouseX, clip.stage.mouseY);
			point = clip.globalToLocal(point);
			clip.x = point.x;
			clip.y = point.y;
			
			// create decoration entity
			currDecoration = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			currDecoration.add(new Sleep());
			
			// add to decoration list
			if (!draggingWallpaper)
			{
				var decorationData:Object = {};
				decorationData.item_name = data.item_name;
				decorationData.item_id = data.item_id;
				decorationData.x = 0;
				decorationData.y = 0;
				decorationData.z = startingDepth;
				decorationData.reflect = 0;
				decorationData.entity = currDecoration;
				decorationList.push(decorationData);
			}
			
			// interations and tooltip
			InteractionCreator.addToEntity(currDecoration, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT], clip);
			ToolTipCreator.addToEntity(currDecoration);
			
			// make draggable
			var draggable:Draggable = new Draggable();
			draggable.drag.add( decorDown );
			draggable.drop.add( Command.create(decorUp, data) );
			draggable.forward = false;
			draggable.forceOffset = true;
			draggable.offsetX = 0;
			draggable.offsetY = 0;
			draggable.onDrag();
			currDecoration.add(draggable);
			dragging = true;
			
			// collapse decoration panel
			collapsePanel(null, true);
			
			// add drag clip
			if (!draggingWallpaper)
			{
				// follow entity
				cameraFollow = true;
				SceneUtil.setCameraTarget(this, currDecoration, false, FOLLOW_RATE);
				
				clip.addChild(dragClip);
			}
		}
		
		// mouse down on decoration
		private function decorDown(decorationEntity:Entity):void
		{
			// only works in decoration mode
			if (decorVisible)
			{
				dragging = true;
				
				// slide decoration panel to left
				collapsePanel(null, true);
				
				// clear drag buttons
				resetDragButtons();
				
				// if not wallpaper
				if (!draggingWallpaper)
				{
					// remember decoration entity
					currDecoration = decorationEntity;
					
					// move to topmost layer of decorations below players and room switch
					startingDepth = decorationList.length - 1;
					trace("starting decoration depth " + startingDepth);
					var clip:MovieClip = MovieClip(decorationEntity.get(Display).displayObject);
					if (clip.parent.getChildIndex(clip) != startingDepth)
					{
						clip.parent.setChildIndex(clip, startingDepth);
					}
					
					// add drag art
					clip = MovieClip(clip.addChild(dragClip));
				}
				
				// check edges while dragging
				_hitContainer.addEventListener(MouseEvent.MOUSE_MOVE, checkEdges);
			}
		}
		
		// mouseup on decoration
		private function decorUp(decorationEntity:Entity, data:Object):void
		{
			// remove check edges while dragging
			_hitContainer.removeEventListener(MouseEvent.MOUSE_MOVE, checkEdges);

			// only works in decoration mode
			if ((decorVisible) && (currDecoration == decorationEntity))
			{
				edited = true;
				dragging = false;
				
				// if wallpaper then apply
				if (draggingWallpaper)
				{
					draggingWallpaper = false;
					// delete draggable
					this.removeEntity(currDecoration);
					// load large wallpaper
					super.shellApi.loadFile(shellApi.assetPrefix + "clubhouse/" + data.item_name + ".jpg", gotWallpaper, data);
					// wait for load
					SceneUtil.lockInput(this, true);
					// clear current
					currDecoration = null;
				}
				else
				{
					// if camera follow, then center on decoration
					if (cameraFollow)
					{
						cameraFollow = false;
						SceneUtil.setCameraTarget(this, currDecoration, true, 0);
					}
					
					// force back to starting index
					var clip:MovieClip = MovieClip(decorationEntity.get(Display).displayObject);
					_hitContainer.setChildIndex(clip, startingDepth);
					
					// update decoration data
					updateDecorationData(data.item_id);
					
					// move delete and flip buttons
					var spat:Spatial = decorationEntity.get(Spatial);
					flipButton.get(Spatial).x = spat.x;
					flipButton.get(Spatial).y = spat.y + 100;
					_hitContainer.setChildIndex(flipButton.get(Display).displayObject, _hitContainer.numChildren - 1);
					deleteButton.get(Spatial).x = spat.x;
					deleteButton.get(Spatial).y = spat.y - 100;
					_hitContainer.setChildIndex(deleteButton.get(Display).displayObject, _hitContainer.numChildren - 1);
				}
			}
		}
		
		// delete decoration
		private function deleteDecoration(decorationEntity:Entity):void
		{
			// if decoration selected
			if (currDecoration != null)
			{
				edited = true;
				var id:String;
				
				// remember entity
				var tempDecorationEntity:Entity = currDecoration;
				
				// for each decoration in scene
				for (var i:int = decorationList.length - 1; i!= -1; i--)
				{
					var data:Object = decorationList[i];
					// if match to current decoration, then delete
					if (currDecoration == data.entity)
					{
						// remember ID
						id = data.item_id;
						// remove from list
						decorationList.splice(i,1);
						// decrement usage and increment preview
						updateUsage(id, -1);
						// tracking
						shellApi.track(TRACK_DELETE_DECORATION, data.item_name, null, "Clubhouse");
						break;
					}
				}
				
				// remove drag art
				clearDragArt();
				
				// remove decoration from scene
				this.removeEntity(tempDecorationEntity);
				
				// update depths
				updateDecorationData(id);
			}
		}
		
		// flip decoration
		private function flipDecoration(decorationEntity:Entity):void
		{
			// if decoration selected
			if (currDecoration != null)
			{
				edited = true;
				
				// flip content clip
				var content:DisplayObject = currDecoration.get(Display).displayObject.getChildAt(0);
				content.scaleX = -content.scaleX;
				
				// for each decoration in scene
				for (var i:int = decorationList.length - 1; i!= -1; i--)
				{
					var data:Object = decorationList[i];
					// if match to current decoration, then flip
					if (currDecoration == data.entity)
					{
						// swap 0 with 1 or vice-versa
						data.reflect = 1 - data.reflect;
						break;
					}
				}
			}
		}
		
		// update decoration data
		private function updateDecorationData(id:String):void
		{
			// validate depths
			for (var i:int = 0; i!=_hitContainer.numChildren; i++)
			{
				if (_hitContainer.getChildAt(i).name == "content")
				{
					if (i < decorationList.length)
					{
						trace("decoration at depth " + i + " is correct");
					}
					else
					{
						trace("decoration at depth " + i + " is WRONG");
						depthError = true;
					}
				}
			}
			
			// for testing
			if (depthError)
			{
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Decoration depths are messed up!")) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(this.overlayContainer);
			}
			
			// for each decoration in scene
			for each (var decorationData:Object in decorationList)
			{
				var decorationEntity:Entity = decorationData.entity;
				var clip:MovieClip = MovieClip(decorationEntity.get(Display).displayObject);
				var depth:int = clip.parent.getChildIndex(clip);

				// if find match, then update everything
				if (id == decorationData.item_id)
				{
					var spatial:Spatial = decorationEntity.get(Spatial);
					decorationData.x = spatial.x;
					decorationData.y = spatial.y;
					decorationData.z = depth;
					trace("updating decoration " + decorationData.item_name + " with depth " + depth);
				}
				// else update depth
				else if (depth != decorationData.z)
				{
					trace("changing depth for decoration " + decorationData.item_name + " to " + depth);
					decorationData.z = depth;
				}
			}
		}
		
		// enable/disable draggable decorations
		private function disableDraggables(state:Boolean):void
		{
			// for each decoration in scene
			for each (var decoration:Object in decorationList)
			{
				var decorationEntity:Entity = decoration.entity;
				if(decorationEntity != null) {
						
					decorationEntity.get(Draggable).disable = state;
					
					// set sleep
					Sleep(decorationEntity.get(Sleep)).sleeping = state;
					
					// toggle tooltip
					if (state)
					{
						decorationEntity.get(Display).displayObject.mouseEnabled = false;
						ToolTipCreator.removeFromEntity(decorationEntity);
					}
					else
					{
						decorationEntity.get(Display).displayObject.mouseEnabled = true;
						ToolTipCreator.addToEntity(decorationEntity);
					}
				}
			}
		}
		
		// SCROLLING ==================================================

		// scroll inventory elements
		private function scroll(btnEntity:Entity, dir:int):void
		{
			// if scrolling and arrow visible
			if ((!isScrolling) && (btnEntity.get(Display).visible))
			{
				isScrolling = true;
				var time:Number = 0.4;
				
				// clear dot
				if (numPanels != 1)
				{
					dots[Math.floor(itemPos/NUM_ITEMS)].gotoAndStop(1);
				}
				
				// update item position
				itemPos += (dir * NUM_ITEMS);
				
				// scroll each panel
				for each (var panel:Entity in panels)
				{
					TweenUtils.entityTo(panel, Spatial, time, {x:0, y:panel.get(Spatial).y - dir * PREV_SPAN});
				}
				
				// set delay
				SceneUtil.delay(this, time, doneScroll);
				
				// show all tooltips
				showPanels(true);
			}
		}
		
		// done scrolling
		private function doneScroll(updateDot:Boolean = true):void
		{
			isScrolling = false;
			
			// if more than 4 items
			if (numItems > NUM_ITEMS)
			{
				// if items at top position, then hide bottom arrow, else show
				showButton(topArrow, (itemPos != 0));
				// if extra items, then hide top arrow, else show
				showButton(bottomArrow, (itemPos < numItems - NUM_ITEMS));
			}
			// if less than 4, then hide arrows
			else
			{
				showButton(topArrow, false);
				showButton(bottomArrow, false);
			}
			
			// set dot
			var page:int = Math.floor(itemPos/NUM_ITEMS);
			if ((updateDot) && (numPanels != 1))
			{
				dots[page].gotoAndStop(2);
			}
			// hide all panel except for page
			showPanels(false, page);
		}
		
		// SUPPORT FUNCTIONS =====================================================
		
		// when click on background
		private function clickBackground(input:Input):void
		{
			// if decoration mode
			if (decorVisible)
			{
				// remove drag art from entity
				clearDragArt();
				// slide in panel
				collapsePanel(null, false);
			}
		}
		
		// remove drag art from current decoration
		private function clearDragArt():void
		{
			// if current decoration
			if (currDecoration != null)
			{
				// remove art
				var clip:MovieClip = MovieClip(currDecoration.get(Display).displayObject);
				clip.removeChildAt(clip.numChildren - 1);
				// clear current
				currDecoration = null;
				// move drag buttons
				resetDragButtons();
			}
		}
		
		// reset drag buttons
		private function resetDragButtons():void
		{
			deleteButton.get(Spatial).x = -1000;
			flipButton.get(Spatial).x = -1000;
		}
		
		// show/hide panels
		private function showPanels(state:Boolean, keepPanel:int = -1):void
		{
			for (var i:int = panels.length - 1; i!=-1; i--)
			{
				var panel:Entity = this.getEntityById("panel" + i);
				if (state)
				{
					panel.get(Spatial).x = 0;
				}
				// if hiding
				else
				{
					if (i == keepPanel)
					{
						panel.get(Spatial).x = 0;
					}
					else
					{
						panel.get(Spatial).x = -2000;
					}
				}
			}
		}
		
		// show/hide button
		private function showButton(btnEntity:Entity, state:Boolean):void
		{
			// set visibility
			if(btnEntity != null) {
				btnEntity.get(Display).visible = state;
				
				// toggle tooltip
				showButtonTooltip(btnEntity, state);
			}
		
		}
		
		// set button tooltip
		private function showButtonTooltip(btnEntity:Entity, state:Boolean, isSceneButton:Boolean = false, labelText:String = null):void
		{
			// enable/disable mouse if scene button (switch or door)
			if (isSceneButton)
			{
				btnEntity.get(Display).displayObject.mouseEnabled = state;
			}
			
			// set sleep
			Sleep(btnEntity.get(Sleep)).sleeping = !state;
			
			// enable/disable tooltip
			if (state)
			{
				if (!btnEntity.has(ToolTipActive))
				{
					ToolTipCreator.addToEntity(btnEntity, ToolTipType.CLICK, labelText);
				}
			}
			else
			{
				ToolTipCreator.removeFromEntity(btnEntity);
			}
		}
		
		// COLLAPSE PANEL FUNCTIONS =============================================
		
		// when rollover over decoration panel edge
		private function overEdge(event:MouseEvent):void
		{
			// if not dragging and hidden, then open panel
			if ((decorCollapsed) && (!dragging))
			{
				collapsePanel(null, false);
			}
		}
		
		// collapse/uncollapse decoration panel
		private function collapsePanel(button:Entity, state:Boolean):void
		{
			// set time
			var time:Number = 0.3;
			// get current x pos
			var destX:Number = decorationPanel.get(Spatial).x;
			
			// if collapsing (sliding to left)
			if (state)
			{
				// only slide if not already collapsed
				if (!decorCollapsed)
				{
					decorCollapsed = true;
					destX -= SLIDE;
				}
				else
				{
					return;
				}
			}
			// if uncollapsing (sliding to right)
			else
			{
				// only slide if not already uncollapsed
				if (decorCollapsed)
				{
					// hide edge rollover
					ui.ui.edge.visible = false;
					destX += SLIDE;
				}
				else
				{
					return;
				}
			}
			
			// tween to new x destination
			TweenUtils.entityTo(decorationPanel, Spatial, time, {y:decorationPanel.get(Spatial).y, x:destX});
			
			// add delay for when tween is done
			SceneUtil.delay(this, time, Command.create(doneTween, state));
		}
		
		// when decoration panel tween is done
		private function doneTween(collapsed:Boolean):void
		{
			// if now collapsed
			if (collapsed)
			{
				decorCollapsed = true;
				// show rollover edge
				ui.ui.edge.visible = true;
				// show collapse button
				showButton(collapseButton, true);
				// hide uncollapse button
				showButton(uncollapseButton, false);
			}
			else
			{
				decorCollapsed = false;
				// hide collapse button
				showButton(collapseButton, false);
				// show uncollapse button
				showButton(uncollapseButton, true);
			}
		}
		
		// check when drag to edges of screen
		private function checkEdges(event:MouseEvent):void
		{
			// 40 pixel buffer
			var buffer:Number = 40;
			// if near edges then start scrolling scene
			if ((event.stageX < buffer) || (event.stageX > shellApi.viewportWidth - buffer) || (event.stageY < buffer) || (event.stageY > shellApi.viewportHeight - buffer))
			{
				cameraFollow = true;
				SceneUtil.setCameraTarget(this, currDecoration, false, FOLLOW_RATE);
			}
		}
		
		// SAVE GAME ===========================================================
		
		// show/hide save decor panel
		private function showSaveDecorPanel(btnEntity:Entity, state:Boolean):void
		{
			ui.savePanel.visible = state;
			showButton(saveDecorButton, state);
			showButton(closeSaveDecorButton, state);
		}
		
		// show/hide save store panel
		private function showSaveStorePanel(btnEntity:Entity, state:Boolean):void
		{
			if(ui != null) {
				ui.storePanel.visible = state;
				showButton(saveStoreButton, state);
				showButton(closeSaveStoreButton, state);
			}
			
		}
		
		// save game by registering
		private function saveGame(btnEntity:Entity):void
		{
			addChildGroup(new SaveGamePopup(shellApi.currentScene.overlayContainer)) as SaveGamePopup;
		}
		
		// when user registration succeeds
		override public function registrationSuccess():void
		{
			// hide panel
			showSaveStorePanel(null, false);
			// undim store button
			storeButton.get(Display).alpha = 1;
			decorButton.get(Display).alpha = 1;
		}
		
		// SAVE AND GET FUNCTIONS ===============================================
		
		// save default wallpaper for clubhouse
		private function saveWallpaper(index:int):void
		{
			var wallpaperID:String = CLUBHOUSE_WPAP_IDS[index];
			// create decoration array to save
			var savedDecorations:Array = [];
			// create data to save
			var savedData:Object = {};
			savedData.item_id = wallpaperID;
			savedData.x = 0;
			savedData.y = 0;
			savedData.z = -1;
			savedDecorations.push(savedData);
						
			// convert to string
			var json:String = JSON.stringify(savedDecorations);
			trace("SAVING WALLPAPER: " + json);
			
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.scene_id 		= CLUBHOUSE_SCENE_IDS[index]; // clubhouse scene ID
			vars.stickers		= json;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Decorations/save", vars, URLRequestMethod.POST, doneSaveDecorations);
		}

		// save decorations as JSON encoded array
		private function saveDecorations():void
		{
			// if no depth error and decorations have been edited
			if ((!depthError) && (edited))
			{
				// tracking
				shellApi.track(TRACK_SAVE_DECORATIONS, clubhouseName, null, "Clubhouse");

				// create decoration array to save
				var savedDecorations:Array = [];
				for each (var decorationData:Object in decorationList)
				{
					var savedData:Object = {};
					savedData.item_id = decorationData.item_id;
					savedData.x = decorationData.x;
					savedData.y = decorationData.y;
					savedData.z = decorationData.z;
					if (decorationData.reflect == 1)
					{
						savedData.reflect = 1;
					}
					if ((decorationData.scale != null) && (decorationData.scale != 1))
					{
						savedData.scale = decorationData.scale;
					}
					if ((decorationData != null) && (decorationData.rotate != 0))
					{
						savedData.rotate = decorationData.rotate;
					}
					savedDecorations.push(savedData);
				}
				
				// add wallpaper always
				savedData = {};
				savedData.item_id = currWallpaperID;
				savedData.x = 0;
				savedData.y = 0;
				savedData.z = -1;
				savedDecorations.push(savedData);
				
				// convert to string
				var json:String = JSON.stringify(savedDecorations);
				trace("SAVING: " + json);
				
				// set up url with secure host
				var vars:URLVariables = new URLVariables;
				vars.login 			= shellApi.profileManager.active.login;
				vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
				vars.dbid 			= shellApi.profileManager.active.dbid;
				vars.scene_id 		= clubhouseID; // clubhouse scene ID
				vars.stickers		= json;
				
				var connection:Connection = new Connection();
				connection.connect(shellApi.siteProxy.secureHost + "/interface/Decorations/save", vars, URLRequestMethod.POST, doneSaveDecorations);
			}
			else
			{
				if (depthError)
				{
					trace("Won't save decorations if depth error");
				}
				else
				{
					trace("Nothing to save");
				}
			}
		}
		
		// clear decorations
		private function clearDecorations(btnEntity:Entity):void
		{
			resetting = true;
			
			// convert to string
			var json:String = JSON.stringify([]);
			
			// set up url with secure host
			var vars:URLVariables = new URLVariables;
			vars.login 			= shellApi.profileManager.active.login;
			vars.pass_hash 		= shellApi.profileManager.active.pass_hash;
			vars.dbid 			= shellApi.profileManager.active.dbid;
			vars.scene_id 		= clubhouseID; // clubhouse scene ID
			vars.stickers		= json;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Decorations/save", vars, URLRequestMethod.POST, doneSaveDecorations);
		}

		// when done saving
		private function doneSaveDecorations(event:Event):void
		{
			//trace(event.currentTarget.data);
			// convert to JSON
			var json:Object = JSON.parse(event.currentTarget.data);
			if (json.answer == "ok")
			{
				trace("Save success");
				// if resetting then reloaad scene
				if (resetting)
				{
					var sceneClass:Class = ClassUtils.getClassByName("game.scenes.clubhouse." + clubhouseName.toLowerCase() + "." + clubhouseName);
					shellApi.loadScene(sceneClass);
				}
			}
			else
			{
				// tracking
				shellApi.track(TRACK_ERROR, "save", null, "Clubhouse");

				// show error dialog
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Can't save your clubhouse layout! Error message: " + json.message)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(this.overlayContainer);
			}
			resetting = false;
		}
		
		// STORE FUNCTIONS =======================================================
		
		// click store button toggle
		private function openStore(btnEntity:Entity):void
		{
			if (btnEntity.get(Display).alpha == 0.5)
			{
				// show save panel
				showSaveStorePanel(null, true);
			}
			else
			{
				// reset button to first frame (fixes lingering text rollover)
				btnEntity.get(Timeline).gotoAndStop(0);
				// load store popup
				var popup:DecorationStorePopup = this.addChildGroup(new DecorationStorePopup()) as DecorationStorePopup;
				popup.init( shellApi.sceneManager.currentScene.overlayContainer );
				popup.passArrays(this, wallStore, furnStore, applStore, miscStore, wpapStore);
			}
		}
		
		// when bought decoration
		public function boughtDecoration(data:Object):void
		{
			// first check if decoration is in inventory
			var type:String = data.item_name.substr(0,4);
			var inventory:Array = this[type];
			var found:Boolean = false;
			for each (var decoration:Object in inventory)
			{
				// if found, then increment
				if (decoration.item_id == data.item_id)
				{
					found = true;
					decoration.count++;
				}
			}
			// if not found then add
			if (!found)
			{
				data.count = 1;
				inventory.push(data);
			}
			// if current tab, then update entire tab
			var category:String = data.item_name.substr(0,4);
			if (currentTab == category)
			{
				doTab(null, category, true);
			}
		}
		
		// FRIEND AND PROFILE STUFF ===================================================
		
		static public function loadClubhouse(shellApi:ShellApi, loginName:String):void
		{
			// save login name, then load clubhouse
			SceneManager(shellApi.getManager(SceneManager)).clubhouseLogin = loginName;
			
			trace("loading clubhouse for login: " + loginName);
			
			// if friend's login, then need to fetch last clubhouse from server
			if (loginName != shellApi.profileManager.active.login)
			{
				trace("getting friend's clubhouse");
				(shellApi.siteProxy as DataStoreProxyPopBrowser).getScene(loginName, "103", Command.create(gotFriendClubhouse, shellApi));
			}
			else
			{
				// get last location for clubhouse island
				var lastLoc:* = shellApi.profileManager.active.lastScene["clubhouse"];
				
				// if we have a last location, then go there
				if(lastLoc is PlayerLocation)
				{
					var lastLocation:PlayerLocation = lastLoc;
					var sceneClass:Class = ClassUtils.getClassByName(lastLocation.scene);
					shellApi.loadScene(sceneClass, Number(lastLocation.locX), Number(lastLocation.locY), lastLocation.direction == "L" ? "left" : "right");
				}
				// if not, then load the default clubhouse
				else
				{
					sceneClass = ClassUtils.getClassByName("game.scenes.clubhouse.clubhouse.Clubhouse");
					shellApi.loadScene(sceneClass);
					//shellApi.loadFile(shellApi.dataPrefix + "scenes/clubhouse/island.xml", Command.create(clubhouseXMLLoaded, shellApi));
				}
			}
		}
	
		// when got friend clubhouse data
		static private function gotFriendClubhouse(response:PopResponse, shellApi:ShellApi):void
		{
			if(response.data != null) {
				trace("got friend's cluhbouse " + response.data.toString());
				// if no clubhouse saved for friend, then visit default clubhouse
				if (response.data.scene_name == null)
				{
					var sceneClass:Class = ClassUtils.getClassByName("game.scenes.clubhouse.clubhouse.Clubhouse");
					shellApi.loadScene(sceneClass);
				}
				else
				{
					// scene name is like Clubhouse
					var sceneName:String = response.data.scene_name;
					var classPath:String = "game.scenes.clubhouse." + sceneName.toLowerCase() + "." + sceneName;
					trace("Visiting friend clubhouse: " + classPath);
					sceneClass = ClassUtils.getClassByName(classPath);
					shellApi.loadScene(sceneClass);
				}
			}
			else {
				
				var dialogBox:ConfirmationDialogBox = shellApi.currentScene.addChildGroup(new ConfirmationDialogBox(1, "Clubhouse not found for user")) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(shellApi.currentScene.overlayContainer);
			}
			
		}

		
		// CLEANUP FUNCTIONS =====================================================
		
		override public function destroy():void
		{
			shellApi.track(TRACK_CLUBHOUSE_EXIT, clubhouseName, null, "Clubhouse");
			
			// leave room
			shellApi.smartFoxManager.leaveRoom();
			
			shellApi.smartFoxManager.disconnected.remove(onDisconnect);
			shellApi.smartFoxManager.loginError.removeAll();
			shellApi.smartFoxManager.loggedIn.removeAll();
			if(!_holdConnection)
			{
				shellApi.smartFox.disconnect();
			}
			super.destroy();
		}
		
		private function onDisconnect():void
		{
			shellApi.track(TRACK_CLUBHOUSE_DISCONNECT, clubhouseName, null, "Clubhouse");
			
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", leaveClubhouse)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		private function leaveClubhouse():void
		{
			shellApi.loadScene(Town, 2900, 883);
		}
		
		public function disconnect():void
		{
			shellApi.smartFoxManager.disconnect();
		}
	}
}