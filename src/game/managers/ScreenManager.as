package game.managers
{
	import com.poptropica.AppConfig;
	
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.media.StageVideoAvailability;
	import flash.system.Capabilities;
	
	import engine.Manager;
	import engine.managers.GroupManager;
	
	import game.data.PlatformType;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.ScreenEffects;

	public class ScreenManager extends Manager
	{
		public function ScreenManager(stage:Stage)
		{
			_stage = stage;
			PerformanceUtils.stage = _stage;
			
			// NOTE :: This was previously in AdManager, shoudl be here in stead, though maybe not in the consttructor. -bard
			stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoAvail);
			stage.addEventListener(Event.RESIZE, updateSize);
		}
		
		/**
		 * Could use more info on StageVideoAvailability.
		 * @param e
		 */
		private function onStageVideoAvail(e:StageVideoAvailabilityEvent):void
		{
			trace("ScreenManager: stageVideoAvailable is: " + e.availability);
			_stageVideoAvailable = (e.availability == StageVideoAvailability.AVAILABLE);
		}
		/**
		 * Resize viewport
		 * @param e
		 */
		private function updateSize(e:Event):void
		{
			setSize();
		}
		public function setSize():void
		{
			if (true)
			{
				var newwidth:Number = 960;
				var newheight:Number = 640;
				var deviceWidth:Number = Math.max(newwidth, newheight);
				var deviceHeight:Number = Math.min(newwidth, newheight);
				var gameSize:Rectangle = new Rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT);
				var deviceSize:Rectangle = new Rectangle(0, 0, deviceWidth, deviceHeight);
				var appScale:Number = (deviceSize.width / gameSize.width);
				shellApi.viewportWidth = newwidth;
				shellApi.viewportHeight = newheight;
				//appScale = 1;
				trace("ScreenManager :: appScale = " + appScale);
				trace("ScreenManager :: gamesize width = " + gameSize.width + " gamesize height = " + gameSize.height);

				_container.scaleX = appScale //- .02;
				_container.scaleY = appScale //- .07;
				shellApi.viewportScale = appScale;
				
				
			}
		}
		public function setSizeTwo():void
		{
		
				var newwidth:Number = 700; 
				var newheight:Number = 400; 
				var deviceWidth:Number = Math.max(newwidth, newheight);
				var deviceHeight:Number = Math.min(newwidth, newheight);
				var gameSize:Rectangle = new Rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT);
				var deviceSize:Rectangle = new Rectangle(0, 0, deviceWidth, deviceHeight);
				var appScale:Number = deviceSize.width / gameSize.width;
				shellApi.viewportWidth = gameSize.width;
				shellApi.viewportHeight = gameSize.height;
				//_appScale = appScale;
				_container.scaleX = _container.scaleY = appScale;
				shellApi.viewportScale = appScale;
				
		}
		override protected function construct():void
		{
			super.construct();
			
			this.setupScreen();
		}
		
		/**
		 * Scale the screen container to fit the width/height of the device. 
		 */
		private function setupScreen():void
		{
			_container = new Sprite();
			_container.name = 'shellContainer';
			stage.addChild(_container);
			
			var serverString:String = unescape(Capabilities.serverString);
			//trace(serverString);
			var reportedDpi:Number = Number(serverString.split("&DP=", 2)[1]);
			var dpi:Number = Capabilities.screenDPI;
			var dpWide:Number = _stage.fullScreenWidth * 160 / dpi;
			var inchesWide:Number = _stage.fullScreenWidth / dpi;
			var landscape:Boolean = _stage.fullScreenWidth > _stage.fullScreenHeight;

			_stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage.align = StageAlign.TOP_LEFT;
			
			var gameWidth:Number;
			var gameHeight:Number;
			var deviceWidth:Number;
			var deviceHeight:Number;
			
			var visibleArea:Rectangle = PlatformUtils.isMobileOS?Screen.mainScreen.visibleBounds:new Rectangle(0,0,stage.fullScreenWidth, stage.fullScreenHeight);
			
			if(landscape)
			{
				gameWidth = GAME_WIDTH;
				gameHeight = GAME_HEIGHT;
				deviceWidth = Math.max(visibleArea.width, visibleArea.height);
				deviceHeight = Math.min(visibleArea.width, visibleArea.height);
			}
			else
			{
				// for portrait orientation we flip the width and height of the game dimensions.
				gameWidth = GAME_HEIGHT;
				gameHeight = GAME_WIDTH;
				deviceWidth = Math.min(visibleArea.width, visibleArea.height);
				deviceHeight = Math.max(visibleArea.width, visibleArea.height);
			}
			//round up odd numbers
			deviceHeight += deviceHeight%2;
			deviceWidth += deviceWidth%2;
			
			deviceHeight = 640;
			deviceWidth = 960;
			
			var gameSize:Rectangle = new Rectangle(0, 0, gameWidth, gameHeight);
			var deviceSize:Rectangle = new Rectangle(0, 0, deviceWidth, deviceHeight);
			var appScale:Number = 1;
			var appSize:Rectangle = gameSize.clone();
			var appOffsetX:Number = 0;
			var appOffsetY:Number = 0;
			
			// if device is wider than game aspect ratio, height determines scale. No change for desktop systems
			if(false )
			{
				if ((deviceSize.width/deviceSize.height) > (gameSize.width/gameSize.height)) 
				{
					appScale = deviceSize.height / gameSize.height;
					appSize.width = deviceSize.width / appScale;
					appOffsetX = Math.round((appSize.width - gameSize.width) / 2);
				} 
					// if device is taller than game aspect ratio, width determines scale
				else 
				{
					appScale = deviceSize.width / gameSize.width;
					appSize.height = deviceSize.height / appScale;
					appOffsetY = Math.round((appSize.height - gameSize.height) / 2);
				}
			}
			
			if(!AppConfig.mobile)
			{
				AppConfig.platformType = PlatformType.DESKTOP;
			}
			else if(inchesWide > 4)
			{
				AppConfig.platformType = PlatformType.TABLET;
			}
			else
			{
				AppConfig.platformType = PlatformType.MOBILE;
			}
			
			// make the viewport larger by the difference
			shellApi.viewportWidth = gameSize.width + appOffsetX * 2;
			shellApi.viewportHeight = gameSize.height + appOffsetY * 2;
			
			// store the offset for ui positioning
			shellApi.viewportDeltaX = appOffsetX * 2;
			shellApi.viewportDeltaY = appOffsetY * 2;
			shellApi.viewportScale = appScale;
			
			_deviceSize = deviceSize;
			
			_container.scaleX = _container.scaleY = appScale;
			
			createContainers(_container);
		}
		
		/**
		 * Resize the viewport.  GroupManager passes this along to all groups.
		 */
		public function resize(viewportWidth:Number, viewportHeight:Number) : void
		{
			GroupManager(this.shellApi.getManager(GroupManager)).resize(viewportWidth, viewportHeight);
			_backgroundContainer.width = viewportWidth;
			_backgroundContainer.height = viewportHeight;
		}
		
		private function createContainers(baseContainer:Sprite):void
		{
			var screenEffects:ScreenEffects = new ScreenEffects();
			_backgroundContainer = screenEffects.createBox(shellApi.viewportWidth, shellApi.viewportHeight);
			_backgroundContainer.name = 'backgroundContainer';
			baseContainer.addChild(_backgroundContainer);
			
			_sceneContainer = new Sprite();
			_sceneContainer.name = 'sceneContainer';
			baseContainer.addChild(_sceneContainer);
			_sceneContainer.mouseEnabled = false;
			
			_overlayContainer = new Sprite();
			_overlayContainer.name = 'overlayContainer';
			baseContainer.addChild(_overlayContainer);
			
			_devToolsContainer = new Sprite();
			_devToolsContainer.name = 'devToolsContainer';
			baseContainer.addChild(_devToolsContainer);
		}
		
		public function get stage():Stage { return this._stage; }
		public function get container():Sprite { return(_container); }
		public function get backgroundContainer():Sprite { return(_backgroundContainer); }
		public function get sceneContainer():Sprite { return(_sceneContainer); }
		public function get overlayContainer():Sprite { return(_overlayContainer); }
		public function get devToolsContainer():Sprite { return(_devToolsContainer); }
		public function get stageVideoAvailable():Boolean { return(_stageVideoAvailable); }
		public function get appScale():Number { return(_appScale); }
		public function get deviceSize():Rectangle { return(_deviceSize); }
		
		private var _stage:Stage;
		private var _container:Sprite;
		private var _backgroundContainer:Sprite;
		private var _sceneContainer:Sprite;
		private var _overlayContainer:Sprite;
		private var _devToolsContainer:Sprite;
		private var _stageVideoAvailable:Boolean;
		private var _appScale:Number = 1;
		private var _deviceSize:Rectangle;
		
		public static const GAME_WIDTH:Number = 960;
		public static const GAME_HEIGHT:Number = 640;
	}
}