package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.data.ads.AdTrackingConstants;
	import game.managers.ads.AdManager;
	import game.scenes.custom.puzzleSystems.MazeSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;

	public class MazeGame extends AdGamePopup
	{
		private var playing:Boolean = true;		// game playing flag
		private var xmlPath:String; 			// path to maze xml
		private var mazeSystem:MazeSystem;		// reference to maze system
		private var maze:MovieClip;				// reference to maze clip
		private var powerDowns:Array = [];		// array of powerdown locations
		private var powerUps:Array = [];		// array of powerup locations
		private var winX:Number = 0;			// win x point
		private var winY:Number = 0;			// win y point
		
		// these are accessed by MazeSystem
		public var walking:Boolean = false;		// player is walking flag
		public var player:MovieClip;			// reference to player clip
		public var meter:MovieClip;				// reference to meter clip
		public var meterLength:Number;			// length of meter
		public var state:String;				// game state for win, punctures, and powerUps
		public var flashingText:MovieClip;		// flash text when losing power
		public var loseHealthClip:MovieClip;	// dialog clip to show when losing health
		public var restoreHealthClip:MovieClip;	// dialog clip to show when restoring health
		
		// params from xml file
		public var _mazeType:String; 			// type of maze hexagon or square
		public var _timeout:Number = 40; 		// timeout in seconds
		public var _distance:Number = 100; 		// distance to check if wall
		public var _walkTime:Number = 1; 		// time to walk to next cell
		public var _maxLossFrames:Number = 1;	// maximum number of loss frame for player animations
		public var _alarmSound:String;			// alarm sound to play
		public var _returnPosX:Number = 0;		// return position for player in scene
		public var _returnPosY:Number = 0;		// return position for player in scene

		/**
		 * Init popup 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set tracking to empty so that it will be game ID only
			_popupType = "";
			// set gametype to Game for popup game
			_gameType= "Game";
			super.init(container);
		}
		
		/**
		 * initiate asset load of scene specific assets
		 */
		override public function load():void
		{
			// get path to swf and xml
			_swfPath = _questName + _swfName;
			xmlPath = _swfPath.replace(".swf", ".xml");
			super.loadFile(xmlPath, loadedXML);
		}
		
		/**
		 * When xml loaded, now load swf
		 */
		private function loadedXML(gameXML:XML):void
		{
			// parse xml
			parseXML(gameXML);
			super.loadFile(_swfPath, loadedSwf);
			
			// convert seconds to milliseconds
			_timeout = _timeout * 1000;
			_walkTime = _walkTime * 1000;
		}
				
		/**
		 * When swf loaded
		 */
		private function loadedSwf(clip:MovieClip):void
		{
			// save clip to screen
			super.screen = clip;
			
			// setup meter
			meter = clip.meter;
			meter.gotoAndStop(1);
			meterLength = meter.width;
			
			// get player
			player = clip.player;
			player.gotoAndStop(1);
			
			// setup maze
			maze = clip.maze;
			maze.mouseEnabled = false;
			
			// convert background to bitmap
			// background clip "back" needs to be aligned to 0,0 (center of clip)
			var backSprite:Sprite = BitmapUtils.createBitmapSprite(clip.back, 1, null, true, 0);
			var backClip:MovieClip = new MovieClip();
			backClip.addChild(backSprite);
			clip.addChildAt(backClip, 0);
			
			// remove vector background
			clip.removeChild(clip.back);
			
			// setup background to make it clickable and force click cursor
			setupButton( backClip, swallowClicks, false);
			backClip.addEventListener("click", clickMaze);
			
			// get end target
			winX = clip.end.x;
			winY = clip.end.y;
			clip.removeChild(clip.end);
			
			// get powerdown targets
			for (var i:int = 1; i!= 10; i++)
			{
				var powerdown:MovieClip = clip["powerdown" + i];
				if (powerdown != null)
				{
					powerDowns.push(new Point(powerdown.x, powerdown.y));
					clip.removeChild(powerdown);
				}
				else break;
			}
			
			// get powerup targets
			for (i = 1; i!= 10; i++)
			{
				var powerup:MovieClip = clip["powerup" + i];
				if (powerup != null)
				{
					powerUps.push(new Point(powerup.x, powerup.y));
					clip.removeChild(powerup);
				}
				else break;
			}
			
			// disables glows
			for (i = 1; i!= 10; i++)
			{
				var glow:MovieClip = clip["glow" + i];
				if (glow != null)
				{
					glow.mouseEnabled = false;
					glow.mouseChildren = false;
				}
				else break;
			}
			
			// get flashing text if any
			if (clip["flashing"] != null)
			{
				flashingText = clip["flashing"];
				flashingText.visible = false;
			}
			
			// get dialog clips
			if (clip["loseHealth"] != null)
			{
				loseHealthClip = clip["loseHealth"];
			}
			if (clip["restoreHealth"] != null)
			{
				restoreHealthClip = clip["restoreHealth"];
			}

			super.loaded();
		}
		
		/**
		 * Setup specific popup features 
		 */
		override protected function setupPopup():void
		{
			// move avatar in scene
			if (_returnPosX != 0)
			{
				super.shellApi.player.get(Spatial).x = _returnPosX;
				super.shellApi.player.get(Spatial).y = _returnPosY;
			}
			
			// init maze system
			mazeSystem = MazeSystem(this.addSystem( new MazeSystem(this), SystemPriorities.update ));
		}
		
		/**
		 * When click on maze 
		 */
		private function clickMaze(e:MouseEvent):void
		{
			// if playing and not walking
			if ((playing) && (!walking))
			{
				// get angle to point in local coords
				var angle:Number = -Math.atan2(e.localY - player.y, e.localX - player.x);
				if (angle < 0)
					angle += (Math.PI * 2);
				
				// force to nearest angle
				var slice:Number;
				if (_mazeType == "hexagon")
				{
					slice = Math.PI/3;
					angle = Math.round(angle/slice + 0.5) * slice - slice/2;
				}
				
				// get distance to next grid along angle
				var distX:Number = _distance * Math.cos(angle);
				var distY:Number = -_distance * Math.sin(angle);
				
				// get point on wall projected along angle (half distance)
				var point:Point = new Point(player.x + distX/2, player.y + distY/2);
				point = maze.localToGlobal(point);
				
				// if not hit wall
				if (!maze.hitTestPoint(point.x, point.y, true))
				{
					// rotate player
					player.rotation = -angle * 180 / Math.PI;
					
					// walk down path to destination
					player.startX = player.x;
					player.startY = player.y;
					player.distX = distX;
					player.distY = distY;
					player.destX = player.x + distX;
					player.destY = player.y + distY;
					mazeSystem.startWalk();
					
					// check if win when done walking
					if (checkProximity(player, winX, winY))
					{
						state = "win";
					}
					// check powerDowns
					for each (var testPoint:Point in powerDowns)
					{
						if (checkProximity(player, testPoint.x, testPoint.y))
						{
							state = "powerdown";
							break;
						}
					}
					// check powerUps
					for each (testPoint in powerUps)
					{
						if (checkProximity(player, testPoint.x, testPoint.y))
						{
							state = "powerup";
							break;
						}
					}
				}
			}
		}
		
		/**
		 * Test proximity to target 
		 */
		private function checkProximity(player, testX, testY):Boolean
		{
			return ((Math.abs(player.destX - testX) < _distance/2) && (Math.abs(player.destY - testY) < _distance/2));
		}
		
		/**
		 * swallow mouse clicks on background
		 */
		private function swallowClicks(entity:Entity):void
		{
		}

		// END FUNCTIONS //////////////////////////////////////////////////////////////////
		
		/**
		 * End game 
		 */
		public function endGame(win:Boolean = false):void
		{
			playing = false;
			
			// cleanup maze system
			mazeSystem.endGame();
			
			// remove maze system
			this.removeSystem(mazeSystem);

			// determine win or lose popup
			var popupClass:Class;
			if (win)
				popupClass = AdWinGamePopup;
			else
				popupClass = AdLoseGamePopup;
			
			// load popup
			var popup:Popup = super.shellApi.sceneManager.currentScene.addChildGroup(new popupClass()) as Popup;
			popup.campaignData = super.campaignData;
			popup.init( super.shellApi.sceneManager.currentScene.overlayContainer );
		}
		
		/**
		 * Close popup
		 * @param button
		 */
		override protected function closePopup(button:Entity):void
		{
			AdManager(super.shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLOSE_GAME_POPUP, _trackingChoice);
			endGame();
		}
	}
}