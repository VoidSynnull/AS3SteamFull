package game.scene.template
{
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.SFSUser;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.entities.variables.UserVariable;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	import com.smartfoxserver.v2.requests.ObjectMessageRequest;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.systems.MotionSystem;
	import engine.systems.TweenSystem;
	
	import game.components.Timer;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMovement;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.managers.ScreenManager;
	import game.managers.SmartFoxManager;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.SFSceneGroup;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.scenes.hub.skydive.SmartFoxGroup;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	// base template class for head to head games
	public class HeadToHeadGame extends GameScene
	{
		private const CMD_PLAYER_READY:String = "PR";
		private const SECONDS:int = 5; // number of seconds for countdown
		private const COUNTDOWN_TEXT:String = " seconds until game is closed";
		private const PLAY_AGAIN_MESSAGE:String = "PlayAgain";
		
		protected var gameID:String;
		protected var countdown:int = SECONDS;		// countdown timer
		protected var endDelay:int = 0;				// delay at end before end buttons appear (needed for Balloons game)
		
		protected var smartFoxGroup:SmartFoxGroup;
		protected var _opponentAvatar:Entity;
		
		protected var _status:Entity;
		protected var _playAgainButton:Entity;
		protected var _leaveGameButton:Entity;
		
		// these IDs are 1 or 2 for player positions
		protected var _myPlayerID:int;
		protected var _whoWon:int;

		protected var gameOver:Boolean = false;
		protected var clickedPlayAgain:Boolean = false;
		protected var otherPlayerLeft:Boolean = false;
		protected var otherPlayAgain:Boolean = false;
		
		// smartfox IDs (are not the same as 1 and 2 used for gameplay positions)
		protected var myID:int;
		protected var otherID:int;

		public function HeadToHeadGame()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			if(DataUtils.validString(shellApi.arcadeGame))
			{
				groupPrefix = shellApi.arcadeGame;
			}
			super.init(container);
		}
		
		// INITIALIZATION===========================================
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = super.getEntityById("interactive").get(Display).displayObject;
			
			// center camera
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2 , shellApi.camera.viewportHeight / 2, true);
			
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

			// setup smartFox
			smartFoxGroup = new SmartFoxGroup();
			smartFoxGroup.setupGroup(this);
			smartFoxGroup.extensionResponse.add(onSFSExtension);
			smartFoxGroup.roomJoined.add(onSFSRoomJoin);
			smartFoxGroup.roomVars.add(onSFSRoomVars);
			smartFoxGroup.connectionLost.addOnce(onSFSDisconnect);
			smartFoxGroup.objectMessage.add(onSFSMessage);

			// idle my connection so I don't get timed out
			//shellApi.smartFoxManager.idleMe();
			
			// remove special abilities
			this.removeSystemByClass(SpecialAbilityControlSystem);
			
			// listen for admin messages
			shellApi.smartFoxManager.adminMessage.add(onAdminMessage);
			
			// setup player--------------------------
			
			// freeze player
			shellApi.player.remove(CharacterMovement);	
			// this prevented animations from playing, so commented it out
			//shellApi.player.remove(FSMControl);
			// hide player until join room
			shellApi.player.get(Display).visible = false;
			// player stand
			CharUtils.setAnim(shellApi.player, Stand);
			
			// UI setup
			setupUI();
			
			// hide elements
			hideUI();
			
			// start game and connect
			doStart();
		}
		
		// add groups
		override protected function addGroups():void
		{
			// This group holds a reference to the parsed sound.xml data and can be used to setup an entity with its sound assets if they are defined for it in the xml.
			var audioGroup:AudioGroup = addAudio();
			
			addCamera();
			addCollisions(audioGroup);
			addCharacters();
			addCharacterDialog(this.uiLayer);
			addDoors(audioGroup);
			addItems();
			addPhotos();
			addBaseSystems();
		}
		
		// add base systems
		override protected function addBaseSystems():void
		{
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new TimelineClipSystem());
			super.addSystem(new TweenSystem());
		}
		
		// setup UI
		protected function setupUI():void
		{
			// setup exit button
			var exitButton:MovieClip = _hitContainer["exitButton"];
			var width:Number = shellApi.camera.viewportWidth;
			if (shellApi.camera.viewportHeight > ScreenManager.GAME_HEIGHT)
			{
				width = ScreenManager.GAME_HEIGHT / shellApi.camera.viewportHeight * ScreenManager.GAME_WIDTH;
				width += (ScreenManager.GAME_WIDTH - width) / 2;
			}
			exitButton.x = width - (exitButton.width * 0.8);
			exitButton.y = (exitButton.height * 0.8);
			ButtonCreator.createButtonEntity(exitButton, this, doExit);
			
			// other buttons and elements
			var playAgainButton:MovieClip = _hitContainer["playAgainButton"];
			playAgainButton.mouseChildren = false;
			_playAgainButton = ButtonCreator.createButtonEntity(playAgainButton, this, playAgain);
			_leaveGameButton = ButtonCreator.createButtonEntity(_hitContainer["leaveGameButton"], this, doExit);
			_status = EntityUtils.createSpatialEntity(this, _hitContainer["waiting"], _hitContainer);
		}
		
		// hide UI
		protected function hideUI(restartGame:Boolean = false):void
		{
			_playAgainButton.get(Display).visible = false;
			_leaveGameButton.get(Display).visible = false;
		}
		
		// BUTTON FUNCTIONS======================================
		
		// connect to game
		protected function doStart():void
		{
			// clear timer
			clearTimers();

			gameOver = false;
			clickedPlayAgain = false;
			otherPlayerLeft = false;
			otherPlayAgain = false;

			_status.get(Display).visible = true;

			if(!smartFoxGroup.isConnected)
			{
				shellApi.smartFoxManager.connect();
				shellApi.smartFoxManager.loggedIn.addOnce(onLogin);
				//updateStatusMessage("connecting to server");
			}
			else
			{
				onLogin();
			}
		}
		
		// clicking the exit button
		protected function doExit(buttonEntity:Entity = null):void
		{
			sfsReset();
			// go to choose game
			shellApi.loadScene(ChooseGame);
		}
		
		// SMARTFOX EVENT HANDLERS==============================================
		
		// when connected and logged in
		private function onLogin():void
		{
			// update char data in case its a fresh login
			shellApi.smartFoxManager.updateCharData();
			// send game play request
			smartFoxGroup.smartFox.send(new ExtensionRequest("play" + gameID));
			//updateStatusMessage("finding a game");
		}
		
		// when sending messages
		private function onAdminMessage($message:String):void
		{
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, $message)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		// when extension events trigger
		protected function onSFSExtension($event:SFSEvent):void
		{
			var params:ISFSObject = $event.params.params;
			var cmd:String = $event.params.cmd;
			switch(cmd)
			{
				case CMD_PLAYER_READY:
					smartFoxGroup.smartFox.send(new ExtensionRequest(CMD_PLAYER_READY, null, smartFoxGroup.smartFox.lastJoinedRoom));
					break;
				
				case "startGame":
					_status.get(Display).visible = false;
					shellApi.track(SmartFoxManager.TRACK_SFS_GAME_PLAY, gameID, null, "Starcade");
					var firstTurn:int = ISFSObject($event.params.params).getInt("whosTurn");
					startGame(firstTurn);
					break;
				
				case "concludeGame":
					var winnerID:int = ISFSObject(params).getInt("winnerId");
					concludeGame(winnerID);
					break;
			}
		}
		
		// when disconnected from server
		protected function onSFSDisconnect(event:SFSEvent):void
		{
			clearTimers();
			
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", returnPreviousScene)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
			shellApi.smartFoxManager.disconnected.remove(onSFSDisconnect);
		}
		
		// when joinging room
		protected function onSFSRoomJoin(users:Array):void
		{
			// get my ID
			var localUser:User = smartFoxGroup.smartFox.mySelf;
			myID = localUser.id;
			
			// activate players (Users) in room
			for each(var user:SFSUser in users)
			{
				activatePlayer(user);
				// get opponent's ID
				if (user.id != myID)
				{
					otherID = user.id;
				}
			}
			updateStatusMessage("finding player");
			
			// setup listeners
			smartFoxGroup.userEntered.add(onSFSUserEnter);
			smartFoxGroup.userExitted.add(onSFSUserExit);
		}
		
		// when user enters game
		protected function onSFSUserEnter(user:SFSUser):void
		{
			// make player appear
			activatePlayer(user);
			// hide status display
			_status.get(Display).visible = false;
		}		
		
		// when user exits game
		protected function onSFSUserExit(user:SFSUser):void
		{
			// if not me
			if (!user.isItMe)
			{
				otherPlayerLeft = true;
			}

			// remove player
			deactivatePlayer(user);
			
			// if game is not over
			if (!gameOver)
			{
				// hide UI (restart mode)
				hideUI(true);
				// show status display
				_status.get(Display).visible = true;
				// update status
				updateStatusMessage("finding another player");
			}
			// if game if over and play again clicked, then restart game immediately
			else if (clickedPlayAgain)
			{
				restartGame();
			}
		}
		
		protected function onSFSRoomVars($event:SFSEvent):void
		{
			// to be overridden by game class
		}
		
		protected function onSFSMessage($event:SFSEvent):void
		{
			var dataObj:ISFSObject = $event.params.message as SFSObject;
			var message:String = dataObj.getUtfString("message");
			switch(message)
			{
				case PLAY_AGAIN_MESSAGE:
					otherPlayAgain = true;
					// if both have clicked then restart game
					if (clickedPlayAgain)
					{
						restartGame();
					}
					break;
			}
		}
		
		// COMMON FUNCTIONS==========================================
		
		// start game in response to server
		protected function startGame(firstTurn:int):void
		{
			// to be overridden by game class
		}
		
		// restart game
		protected function restartGame():void
		{
			// hide ui
			hideUI();
			// remove opponent
			removeOpponent();
			// don't need status display
			_status.get(Display).visible = false;
			// remove listeners
			smartFoxGroup.userEntered.remove(onSFSUserEnter);
			smartFoxGroup.userExitted.remove(onSFSUserExit);
			// leave room
			smartFoxGroup.leaveRoom();
			// start new game
			doStart();
		}
		
		// activate and display player in scene
		protected function activatePlayer($user:SFSUser):void
		{
			// to be overridden by game class
		}

		// update status message
		private function updateStatusMessage($message:String):void
		{
			_status.get(Display).displayObject["message"].text = $message;
		}

		// create opponent avatar 
		protected function createOpponentAvatar($user:User, x:Number, y:Number, direction:String):Entity
		{
			var charGroup:CharacterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			var user_look_var:UserVariable = $user.getVariable(SFSceneGroup.USER_CHAR_LOOK);
			var lookData:LookData = new LookConverter().lookDataFromLookString(user_look_var.getStringValue());		
			var entity:Entity;
			
			// if first position
			if ($user.playerId == 1)
			{
				entity = charGroup.createNpc($user.name, lookData, x, y, direction, "", null, npcLoaded );
			}
			// if second position
			else 
			{
				entity = charGroup.createNpc($user.name, lookData, x, y, direction, "", null, npcLoaded );
			}
			return entity;
		}
		
		// when npc loaded
		private function npcLoaded( charEntity:Entity ):void
		{
			Sleep(charEntity.get(Sleep)).sleeping = false;
			Sleep(charEntity.get(Sleep)).ignoreOffscreenSleep = true;
			CharUtils.setAnim(charEntity, Stand);
		}
		
		// return to previous scene (common room) if disconnected or fail to load game
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
		
		// GAME END FUNCTIONS===================================
		
		// end game
		protected function concludeGame($winnerId:int):void
		{
			// player ID: either 1 or 2 (different from IDs used by Smartfox)
			_myPlayerID = smartFoxGroup.smartFox.mySelf.playerId;
			_whoWon = $winnerId;
			gameOver = true;
			
			// if you win
			if (_whoWon == _myPlayerID)
			{
				youWin();
			}
			// if draw
			else if (_whoWon == -1)
			{
				draw();
			}
			// if you lose
			else
			{
				youLose();
			}

			if (endDelay == 0)
			{
				setEndState();
			}
			else
			{
				SceneUtil.delay(this, endDelay, setEndState);
			}
		}
		
		// end state that happens after delay
		protected function setEndState():void
		{
			// show end buttons
			_playAgainButton.get(Display).visible = true;
			_leaveGameButton.get(Display).visible = true;
			
			// show status for countdown
			_status.get(Display).visible = true;
			updateStatusMessage(String(SECONDS) + COUNTDOWN_TEXT);
			var timedEvent:TimedEvent = new TimedEvent(1, SECONDS, updateCountdown);
			SceneUtil.addTimedEvent(this, timedEvent, "countdown");
		}
		
		// updating end countdown
		private function updateCountdown():void
		{
			countdown--;
			updateStatusMessage(String(countdown) + COUNTDOWN_TEXT);
			// when countdown over, then exit to chooser
			if (countdown == 0)
			{
				doExit();
			}
		}
		
		protected function youWin():void
		{
			// to be overriden
		}
		
		protected function draw():void
		{
			// to be overriden
		}
		
		protected function youLose():void
		{
			// to be overriden
		}
		
		// click play again
		protected function playAgain(buttonEntity:Entity):void
		{
			var restarting:Boolean;
			
			clickedPlayAgain = true;
			countdown = SECONDS;

			if(shellApi.smartFoxManager.isInRoom)
			{
				var sfsObject:SFSObject = new SFSObject();
				sfsObject.putUtfString("message", PLAY_AGAIN_MESSAGE);
				smartFoxGroup.smartFox.send( new ObjectMessageRequest(sfsObject, shellApi.smartFox.lastJoinedRoom));
			}

			// hide buttons
			_status.get(Display).visible = false;
			_playAgainButton.get(Display).visible = false;
			_leaveGameButton.get(Display).visible = false;
			
			// reset player
			CharUtils.setAnim(shellApi.player, Stand);
			
			// clear timer
			clearTimers();
			
			// if other player has left or clicked play again then restart game right away
			if ((otherPlayerLeft) || (otherPlayAgain))
			{
				restartGame();
			}
			// else wait for other player to click play again and end countdown
			else
			{
				// hide UI except for parts that relate to player
				hideUI(true);
				// show message that waiting for other player to decide
				_status.get(Display).visible = true;
				updateStatusMessage("Waiting for other player to decide...");
				
				// set timer for restarting game using remaining countdown time
				var timedEvent:TimedEvent = new TimedEvent(countdown, 1, restartGame);
				SceneUtil.addTimedEvent(this, timedEvent, "restart");
			}
		}
		
		// deactivate user
		protected function deactivatePlayer($user:SFSUser):void
		{
			if (($user != null) && ($user.isItMe))
			{
				// hide player
				shellApi.player.get(Display).visible = false;
			}
			else
			{
				// remove opponent
				removeOpponent();
			}
		}
		
		private function removeOpponent():void
		{
			// remove opponent
			if(_opponentAvatar)
			{
				this.removeEntity(_opponentAvatar);
				_opponentAvatar = null;
			}
		}
		
		private function clearTimers():void
		{
			var timer:Timer = SceneUtil.getTimer(this, "countdown");
			if (timer != null)
			{
				timer.timedEvents = new Vector.<TimedEvent>();
			}
			timer = SceneUtil.getTimer(this, "restart");
			if (timer != null)
			{
				timer.timedEvents = new Vector.<TimedEvent>();
			}
		}
		
		// when destroying scene
		override public function destroy():void
		{
			clearTimers();
			sfsReset(); // remove references and listeners of smartFox
			super.destroy();
		}
		
		// reset game
		public function sfsReset():void
		{
			// end idle
			shellApi.smartFoxManager.idleMe(false);
			
			// remove admin message listener
			shellApi.smartFoxManager.adminMessage.remove(onAdminMessage);
		}
	}
}