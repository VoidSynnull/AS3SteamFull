package game.scenes.hub.chooseGame
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.SFSRoom;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMovement;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.managers.ScreenManager;
	import game.managers.SmartFoxManager;
	import game.scene.template.GameScene;
	import game.scenes.hub.balloons.Balloons;
	import game.scenes.hub.skydive.Skydive;
	import game.scenes.hub.starLink.StarLink;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class ChooseGame extends GameScene
	{
		public static const TRACK_CHOOSEGAME_ENTER:String 		= "ChooseSFSGameEnter";
		public static const TRACK_CHOOSEGAME_EXIT:String 		= "ChooseSFSGameExit";
		public static const TRACK_CHOOSEGAME_DISCONNECT:String 	= "ChooseSFSGameDisconnected";

		// this list of game groups needs to be made public and default in zone configurator on Smartfox server
		private var gameIDs:Array = ["starLink", "balloons", "skydive"];
		private var gameScenes:Array = [StarLink, Balloons, Skydive];
		private var numGames:int = gameIDs.length;
		private var readyGames:Array = [];
		private var gamePos:int = 0;
		private var instructionsClip:MovieClip;
		private var _overlayContainer:Sprite;
		
		private var _upArrow:Entity;
		private var _downArrow:Entity;
		private var _playButton:Entity;
		private var _playGameButton:Entity;
		private var _opponent:Entity;
		private var _instructions:Entity;
		private var _instructionsButton:Entity;
		private var _closeInstructionsButton:Entity;
		private var _gameSelect:Entity;
		private var _opponentTimeline:Timeline;
		private var _message:String = "";
		
		public function ChooseGame()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/chooseGame/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			shellApi.track(TRACK_CHOOSEGAME_ENTER, null, null, "Starcade");
						
			// idle my connection so I don't get timed out
			//shellApi.smartFoxManager.idleMe();
			
			// center camera
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2 , shellApi.camera.viewportHeight / 2, true);

			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = super.getEntityById("interactive").get(Display).displayObject;
			var gameContent:MovieClip = _hitContainer["content"];
			
			// offset to center
			var offset:Number = (shellApi.camera.viewportWidth - ScreenManager.GAME_WIDTH) / 2;
			
			// move game contents to hit container with shifting
			for (var i:int = gameContent.numChildren - 1; i!= -1; i--)
			{
				var clip:MovieClip = MovieClip(gameContent.getChildAt(i));
				clip.x += offset;
				clip = MovieClip(_hitContainer.addChildAt(clip, 1));
				_hitContainer[clip.name] = clip;
			}

			// change depths
			instructionsClip = _hitContainer["instructions"];
			_hitContainer.addChildAt(_hitContainer["instructions"], _hitContainer.numChildren-1)
			_hitContainer.addChildAt(_hitContainer["closeInstructions"], _hitContainer.numChildren-1)
			_hitContainer.addChildAt(_hitContainer["playGameButton"], _hitContainer.numChildren-1)
			
			// setup close buttons
			var exitButton:MovieClip = _hitContainer["exitButton"];
			var width:Number = shellApi.camera.viewportWidth;
			// if device screen has narrower aspect ratio than default, then need to reposition close button
			if (shellApi.camera.viewportHeight > ScreenManager.GAME_HEIGHT)
			{
				width = ScreenManager.GAME_HEIGHT / shellApi.camera.viewportHeight * ScreenManager.GAME_WIDTH;
				width += (ScreenManager.GAME_WIDTH - width) / 2;
			}
			exitButton.x = width - (exitButton.width * 0.8);
			exitButton.y = (exitButton.height * 0.8);
			ButtonCreator.createButtonEntity(exitButton, this, doExit);
			_closeInstructionsButton = ButtonCreator.createButtonEntity(_hitContainer["closeInstructions"], this, hideInstructions);
			
			// setup buttons
			_upArrow = ButtonCreator.createButtonEntity(_hitContainer["upArrow"], this, scrollUp);
			_downArrow = ButtonCreator.createButtonEntity(_hitContainer["downArrow"], this, scrollDown);
			_playButton = ButtonCreator.createButtonEntity(_hitContainer["playButton"], this, launchGame);
			_playGameButton = ButtonCreator.createButtonEntity(_hitContainer["playGameButton"], this, launchGame);
			_opponent = ButtonCreator.createButtonEntity(_hitContainer["opponent"], this, launchGame);
			_instructionsButton = ButtonCreator.createButtonEntity(_hitContainer["instructionsButton"], this, showInstructions);
			_gameSelect = ButtonCreator.createButtonEntity(_hitContainer["gameSelect"], this, launchGame);
			
			// opponent animation
			var entity:Entity = TimelineUtils.convertClip( _hitContainer["opponent"]["char"], this );
			_opponentTimeline = entity.get(Timeline);
			_opponentTimeline.gotoAndStop(0);
			_opponentTimeline.labelReached.add(onLabelReached);
			
			// create instructions entity
			_instructions = EntityUtils.createSpatialEntity(this, instructionsClip, _hitContainer);
			instructionsClip.addEventListener(MouseEvent.CLICK, swallowClicks);
						
			// hide elements
			instructionsClip.gotoAndStop(1);
			_gameSelect.get(Display).visible = false;
			_instructions.get(Display).visible = false;
			_playButton.get(Display).visible = false;
			_playGameButton.get(Display).visible = false;
			_opponent.get(Display).visible = false;
			_instructionsButton.get(Display).visible = false;
			_closeInstructionsButton.get(Display).visible = false;

			// setup smartFox
			shellApi.smartFoxManager.loginError.add(onLoginError);
			shellApi.smartFox.addEventListener(SFSEvent.CONNECTION_LOST, onSFSDisconnect);
			
			// login
			if(!shellApi.smartFox.isConnected)
			{
				shellApi.smartFoxManager.connect(true);
				shellApi.smartFoxManager.loggedIn.addOnce(loggedIn);
			} 
			else if (shellApi.smartFox.currentZone != AppConfig.multiplayerZone)
			{
				// middle of connecting - wait for login
				shellApi.smartFoxManager.loggedIn.addOnce(loggedIn);
			} 
			else if (AppConfig.multiplayerZone)
			{
				// already connected to the poptropica zone
				loggedIn();
			}

			// player setup
			shellApi.player.get(Spatial).x += offset;
			CharUtils.setAnim(shellApi.player, Stand);
			CharUtils.setScale(shellApi.player, 1.1);
			
			// freeze character movement
			shellApi.player.remove(CharacterMovement);
			
			// remove special abilities
			this.removeSystemByClass(SpecialAbilityControlSystem);
			
			// save overlay container
			_overlayContainer = Sprite(this.overlayContainer);
		}
		
		// for looping opponent animation
		private function onLabelReached( label:String ):void
		{
			if (label == "ending")
				_opponentTimeline.gotoAndPlay("loop");
		}

		// when logged in
		private function loggedIn():void
		{
			for each (var gameID:String in gameIDs)
			{
				if (checkIfGameHasOneUser(gameID))
				{
					readyGames.push(gameID);
				}
			}
			var rand:int;
			// if no games ready, then get random of all games
			if (readyGames.length == 0)
			{
				rand = Math.floor(Math.random() * numGames);
				gameID = gameIDs[rand];
			}
			// if some games ready, then get random of ready games
			else
			{
				var count:int = readyGames.length;
				rand = Math.floor(Math.random() * count);
				gameID = readyGames[rand];
			}
			
			_instructionsButton.get(Display).visible = true;
			
			// get position in game list and show selected game
			gamePos = gameIDs.indexOf(gameID);
			showGame();
			
			// show game on timer every third second
			var timedEvent:TimedEvent = new TimedEvent( 0.33, 0, showGame );
			SceneUtil.addTimedEvent(this, timedEvent);
		}

		private function onLoginError(event:SFSEvent):void
		{
			shellApi.log("SFS LOGIN ERROR: "+event.params.popupMsg);
			// show message
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, event.params.popupMsg)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(_overlayContainer);
				
			if (shellApi.smartFox.isConnected)
			{
				shellApi.smartFoxManager.disconnect();
			}
		}
		
		// check if game group has one user waiting
		private function checkIfGameHasOneUser(groupID:String):Boolean
		{
			//trace("==========checking group " + groupID);
			var roomList:Array = shellApi.smartFox.getRoomListFromGroup(groupID);
			var count:int = roomList.length;
			var numZeros:int = 0;
			var numOnes:int = 0;
			for each (var room:SFSRoom in roomList)
			{
				if (room.userCount == 0)
				{
					numZeros++;
				}
				else if (room.userCount == 1)
				{
					numOnes++
				}
			}
			// get number of open rooms
			var totalOpenRooms:int = numZeros + numOnes;
			var message:String;
			// if no open rooms
			if (totalOpenRooms == 0)
			{
				message = "=============" + groupID + " has " + count + " rooms: none open";
			}
			// if any open rooms
			else
			{
				message = "=============" + groupID + " has " + count + " rooms: zeros: " + numZeros + ", ones: " + numOnes;
			}
			if (message != _message)
			{
				_message = message;
				trace(message);
				if (ExternalInterface.available)
					ExternalInterface.call("dbug", message);
				
			}
			return (totalOpenRooms != 0)
		}
		
		private function scrollUp(buttonEntity:Entity):void
		{
			gamePos = (gamePos + 1) % numGames;
			showGame();
		}
		
		private function scrollDown(buttonEntity:Entity):void
		{
			gamePos = (gamePos + numGames - 1) % numGames;
			showGame();
		}
		
		// show game based on game selection
		private function showGame():void
		{
			_gameSelect.get(Display).visible = true;
			_gameSelect.get(Timeline).gotoAndStop(gamePos);
			if (checkIfGameHasOneUser(gameIDs[gamePos]))
			{
				// if not already visible
				if (!_opponent.get(Display).visible)
				{
					_opponent.get(Display).visible = true;
					_opponentTimeline.gotoAndPlay(0);
				}
				_playButton.get(Display).visible = false;
			}
			else
			{
				_opponent.get(Display).visible = false;
				_playButton.get(Display).visible = true;
			}
		}
		
		// show instructions
		private function showInstructions(buttonEntity:Entity):void
		{
			_instructions.get(Display).visible = true;
			_closeInstructionsButton.get(Display).visible = true;
			_playGameButton.get(Display).visible = true;
			instructionsClip.gotoAndStop(1 + gamePos);
		}
		
		// hide instructions
		private function hideInstructions(buttonEntity:Entity):void
		{
			_instructions.get(Display).visible = false;
			_closeInstructionsButton.get(Display).visible = false;
			_playGameButton.get(Display).visible = false;
		}
		
		// launch desired game
		private function launchGame(buttonEntity:Entity = null):void
		{
			SceneUtil.lockInput(this, true);
			if(shellApi.smartFox.isConnected && shellApi.smartFox.currentZone == AppConfig.multiplayerZone)
			{
				shellApi.track(SmartFoxManager.TRACK_SFS_GAME_SELECT, gameIDs[gamePos], null, "Starcade");
				shellApi.loadScene(gameScenes[gamePos]);
			}
			// if not logged in, then attempt login and launch game
			else
			{
				shellApi.smartFoxManager.loggedIn.addOnce(launchGame);
				shellApi.smartFoxManager.loginError.addOnce(cancelGame);
				shellApi.smartFoxManager.connect();
			}
		}
		
		private function cancelGame($SFSEvent:SFSEvent = null):void
		{
			shellApi.track(SmartFoxManager.TRACK_SFS_GAME_FAIL, gameIDs[gamePos], null, "Starcade");
			
			SceneUtil.lockInput(this, false);
			
			// cancel game
			shellApi.smartFoxManager.loggedIn.remove(launchGame);
			shellApi.smartFoxManager.loginError.remove(cancelGame);
			
			// display dialog popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Failed to launch game!", returnPreviousScene)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(_overlayContainer);
		}
		
		// clicking the exit button
		private function doExit(buttonEntity:Entity):void
		{
			shellApi.track(TRACK_CHOOSEGAME_EXIT, null, null, "Starcade");
			// go to previous scene
			returnPreviousScene();
		}
		
		// to prevent click-throughs
		private function swallowClicks(event:MouseEvent):void
		{
		}
		
		// when disconnected from server
		protected function onSFSDisconnect(event:SFSEvent):void
		{
			shellApi.track(TRACK_CHOOSEGAME_DISCONNECT, null, null, "Starcade");
			
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", returnPreviousScene)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(_overlayContainer);
			shellApi.smartFoxManager.disconnected.remove(onSFSDisconnect);
		}
		
		// return to previous scene (usually main street) if disconnected or fail to load game
		// the common room is never saved
		private function returnPreviousScene():void
		{
			var destScene:String = shellApi.sceneManager.previousScene;
			if (destScene == null)
			{
				shellApi.loadScene(ClassUtils.getClassByName("game.scenes.hub.home.Home"));
			}
			else
			{
				var destSceneX:Number = shellApi.sceneManager.previousSceneX;
				var destSceneY:Number = shellApi.sceneManager.previousSceneY;
				var destSceneDirection:String = shellApi.sceneManager.previousSceneDirection;
				shellApi.loadScene(ClassUtils.getClassByName(destScene), destSceneX, destSceneY, destSceneDirection);
			}
		}

		override public function destroy():void
		{
			shellApi.smartFoxManager.disconnected.remove(onSFSDisconnect);
			shellApi.smartFoxManager.loginError.removeAll();
			shellApi.smartFoxManager.loggedIn.removeAll();
			super.destroy();
		}
	}
}