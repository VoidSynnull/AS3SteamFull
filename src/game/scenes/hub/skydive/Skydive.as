package game.scenes.hub.skydive
{
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.SFSUser;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.entities.variables.UserVariable;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Timer;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.input.Input;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.character.CharacterData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.managers.SmartFoxManager;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.SFSceneGroup;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.DisplayPositionUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Skydive extends GameScene
	{
		private var smartFoxGroup:SmartFoxGroup;
		private var gameOver:Boolean = false;
		private var clickedPlayAgain:Boolean = false;
		private var otherPlayerLeft:Boolean = false;
		private var otherPlayAgain:Boolean = false;
		private var countdownV:Number;
		
		private var gameID:String = "Skydive";
		
		public function Skydive()
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
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();

			smartFoxGroup = new SmartFoxGroup();
			smartFoxGroup.setupGroup(this);
			smartFoxGroup.extensionResponse.add(onExtensionResponse);
			smartFoxGroup.roomJoined.add(onRoomJoin);
			smartFoxGroup.userEntered.add(onUserEnter);
			smartFoxGroup.userExitted.add(onUserExit);
			smartFoxGroup.startGame.add(handleStartGame);
			smartFoxGroup.connectionLost.addOnce(onDisconnect);
			
			// idle my connection so i don't get timed out
			//shellApi.smartFoxManager.idleMe();
			
			// listen for admin messages
			shellApi.smartFoxManager.adminMessage.add(onAdminMessage);
			
			super.addSystem(new SkydiveSystem());
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.hitContainer);
			
			setupInput();
			
			setupCountdown();
			
			_parachuteContainer = new Sprite();
			super.hitContainer.addChild(_parachuteContainer);
			
			startGame();
		}
		
		private function connect():void
		{
			smartFoxGroup.gameConnect("play" + gameID);
		}
		
		private function handleStartGame(event:SFSEvent):void
		{
			clickedPlayAgain = false;
			otherPlayerLeft = false;
			otherPlayAgain = false;
			
			_totalPlayersInQueue = 0;
						
			if(_waitingDisplay)
			{
				super.overlayContainer.removeChild(_waitingDisplay);
				_waitingDisplay = null;
			}
			
			shellApi.track(SmartFoxManager.TRACK_SFS_GAME_PLAY, gameID, null, "Starcade");
			
			_gameStarted = true;
			
			// delay the start of the countdown by a second
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, showCountdown));
		}

		public function onExtensionResponse(evt:SFSEvent):void
		{
			var params:ISFSObject = evt.params.params;
			var cmd:String = evt.params.cmd;
			
			switch(cmd)
			{
				case "changePlayerState":
					var newState:String = params.getUtfString("newState");
					var playerId:int = params.getInt("playerId");
					var entity:Entity = super.getEntityById(playerId.toString());
					if (entity == null)
						return;
					var playerState:PlayerState = entity.get(PlayerState);
					
					// block player's state changes (if _setLocalPlayerStateInstantly)
					if(playerState.state != newState && playerId != _playerId)
					{
						// if deployed chute, locally activate float (like the player)
						if(newState == PlayerState.DEPLOY_CHUTE)
						{
							SceneUtil.addTimedEvent(this, new TimedEvent(CHUTE_DEPLOY_WAIT, 1, Command.create(chuteOpened, playerId)));
						}
						
						playerState.state = newState;

						// check for player win or lose.
						checkForRoundResult(playerId, newState);
						
						if(newState == PlayerState.START)
						{							
							_totalPlayersInQueue++;
							
							if(_totalPlayersInQueue >= MIN_PLAYERS)
							{
								startGame();
							}
						}
						else if (newState == PlayerState.PLAY_AGAIN_CLICKED)
						{
							otherPlayAgain = true;
							// if both have clicked then restart game
							if (clickedPlayAgain)
							{
								restartGame();
							}
						}
					}
					break;
				
				case "countdownSet":
					finishCountdown();
					break;
				
				case "gameEnded":
					if(!_roundComplete && _gameStarted)
					{
						_roundComplete = true;
						_playerLeftTimer = SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(showResultPopup, "playerLeft")));
					}
					break;
			}
		}

		private function checkForRoundResult(playerId:int, newState:String):void
		{
			if (newState == PlayerState.PLAY_AGAIN_CLICKED)
				return;
			
			if(newState == PlayerState.WIN || newState == PlayerState.LOSE)
			{
				_playersFinished++;
			}
			
			if(newState == PlayerState.WIN)
			{
				if(playerId == _playerId)
				{
					updateRoundResult(PlayerState.WIN);
				}
				else
				{
					updateRoundResult(PlayerState.LOSE);
				}
			}
			else if(newState == PlayerState.LOSE)
			{
				if(playerId == _playerId)
				{
					updateRoundResult(PlayerState.LOSE);
				}
			}
				
			if(_roundResult != null && !_roundComplete && _playersFinished >= MIN_PLAYERS)
			{
				_roundComplete = true;
				_resultTimer = SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(showResultPopup, _roundResult)));
			}
		}
		
		private function updateRoundResult(result:String):void
		{
			if(_roundResult == null)
			{
				_roundResult = result;
			}
		}
		
		protected function onRoomJoin(users:Array):void
		{
			var localUser:User = smartFoxGroup.smartFox.mySelf;
			
			_playerId = localUser.id;
			
			for each(var user:SFSUser in users)
			{
				if(super.getEntityById(user.playerId) == null)
				{
					var userVar:UserVariable = user.getVariable(SFSceneGroup.USER_CHAR_LOOK)
					
					if(userVar != null)
					{
						var look:String = userVar.getStringValue();
						playerJoined(user.id, look);
					}
				}
			}
		}
		
		protected function onUserEnter(user:SFSUser):void
		{
			if(super.getEntityById(user.playerId) == null)
			{
				var userVar:UserVariable = user.getVariable(SFSceneGroup.USER_CHAR_LOOK)
				
				if(userVar != null)
				{
					var look:String = userVar.getStringValue();
					playerJoined(user.id, look);
				}
			}
		}
		
		protected function onUserExit(user:SFSUser):void
		{
			// if not me
			if (!user.isItMe)
			{
				otherPlayerLeft = true;
			}
				
			var entity:Entity = super.getEntityById(user.id);
			if(entity != null)
			{
				super.removeEntity(entity);
			}
			if (!gameOver)
			{
				checkForRoundResult(user.id, PlayerState.LOSE);
			}
			// if game is over and clicked play again then restart game immediately
			else if (clickedPlayAgain)
			{
				restartGame();
			}
		}
		
		private function showResultPopup(result:String):void
		{
			if(super.getGroupById("resultPopup") == null)
			{
				gameOver = true;
				
				var resultText:String = "You Lose!";
				
				if(result == PlayerState.WIN)
				{
					resultText = "You Win!";
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "crowd_cheer_01.mp3");
				}
				else if(result == "playerLeft")
				{
					resultText = "Player Left!";
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "crowd_disgusted_oh_01.mp3");
				} else {
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "crowd_disgusted_oh_01.mp3");
				}
				
				var popup:Result = super.addChildGroup(new Result(resultText, super.overlayContainer)) as Result;
				popup.id = "resultPopup";
				
				// add a listener to this popup's custom signal.  This listener will get removed in the popup's 'destroy()' method.
				popup.playAgainClicked.add(onPlayAgainClicked);
				popup.doneCountdown.add(backToChooser);
			}
		}
		
		private function playerJoined(playerId:int, lookString:String):void
		{			
			var local:Boolean = (_playerId == playerId);
			var converter:LookConverter = new LookConverter();
			var look:LookData = converter.lookDataFromLookString(lookString);
			var x:Number = super.sceneData.startPosition.x;
			var y:Number = super.sceneData.startPosition.y;
			var charData:CharacterData = new CharacterData();
			
			x += _totalPlayersInQueue * 230;
			
			charData.id				= playerId.toString();
			charData.type			= CharacterCreator.TYPE_NPC;
			charData.variant		= CharacterCreator.VARIANT_HUMAN;
			
			charData.look 			= look;
			charData.position.x 	= x;
			charData.position.y 	= y;
			charData.direction 		= CharUtils.DIRECTION_RIGHT;
			
			if(_totalPlayersInQueue > 0)
			{
				charData.direction = CharUtils.DIRECTION_LEFT;
			}
			
			charData.event 			= GameEvent.DEFAULT;	// set the event to default
			
			var characterGroup:CharacterGroup = super.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			var entity:Entity = characterGroup.createDummyFromData(charData, super.hitContainer, this, characterLoaded);
			var motion:Motion = new Motion();
			motion.maxVelocity = new Point(0, 700);
			entity.add(motion);
			
			var playerState:PlayerState = new PlayerState();
			playerState.local = local;
			entity.add(playerState);
			
			playerState.stageChangeRequested.add(changePlayerState);
			
			var motionBounds:MotionBounds = new MotionBounds();
			entity.add(motionBounds);
			motionBounds.box = super.sceneData.bounds;			
			entity.add(new AudioRange(500));
			
			loadParachute(entity);
			
			// store entities (for trash collection)
			_playerEntities.push(entity);

			if(local)
			{
				var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
				cameraGroup.setTarget(entity.get(Spatial), true);
				
				if(_totalPlayersInQueue == 0)
				{
					_host = true;
				}
			}
			else
			{
				_opponentId = playerId;
			}
			
			_totalPlayersInQueue++;
		}
				
		private function loadParachute(parent:Entity):void
		{
			var entity:Entity = new Entity();
	
			super.addEntity(entity);
			EntityUtils.addParentChild(entity, parent);
			EntityUtils.loadAndSetToDisplay(_parachuteContainer, super.groupPrefix + "parachute.swf", entity, this, parachuteLoaded);
			EntityUtils.followTarget(entity, parent, .8);
		}
		
		private function parachuteLoaded(display:MovieClip, entity:Entity):void
		{
			Spatial(entity.get(Spatial)).scale = 1.75;
			TimelineUtils.convertClip(display.parachute, this, entity, null, false);

			var parent:Parent = entity.get(Parent);
			var parachute:Parachute = parent.parent.get(Parachute);
		
			if(parachute == null)
			{
				parachute = new Parachute(entity);
				parent.parent.add(parachute);
			}
			else
			{
				parachute.entity = entity;
			}
		}
				
		private function showCountdown():void
		{
			var countdown:Entity = super.getEntityById("countdown");
			Display(countdown.get(Display)).visible = true;
			var timeline:Timeline = countdown.get(Timeline);
			timeline.labelReached.add(countdownLabelReached);
			timeline.play();
		}
		
		private function countdownLabelReached(label:String):void
		{
			if(label == "set" && !_countdownSet)
			{
				if(shellApi.smartFoxManager.isInRoom){
					var countdown:Entity = super.getEntityById("countdown");
					var timeline:Timeline = countdown.get(Timeline);
					timeline.gotoAndStop("set");
					timeline.labelReached.removeAll();
					
					_countdownSet = true;

					smartFoxGroup.smartFox.send( new ExtensionRequest("countdownSet", null, smartFoxGroup.smartFox.lastJoinedRoom) );
				}
			}
			else if(label == "showReady")
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_05.mp3");
			}
			else if(label == "showSet")
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_05.mp3");
			}
		}
		
		private function finishCountdown():void
		{
			var countdown:Entity = super.getEntityById("countdown");
			var timeline:Timeline = countdown.get(Timeline);
			timeline.gotoAndPlay("go");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "buzzer_02.mp3");
			_readyToJump = true;
		}
		
		private function setupInput():void
		{
			var inputEntity:Entity = shellApi.inputEntity;
			var input:Input = inputEntity.get(Input) as Input;						
			
			input.inputDown.add(handleDown);
		}
		
		private function handleDown(input:Input):void 
		{
			if(_gameStarted)
			{
				var entity:Entity = super.getEntityById(_playerId);
				var playerState:PlayerState = entity.get(PlayerState);
				var currentState:String = playerState.state;
				var newState:String = currentState;
				
				if(!_readyToJump)
				{
					// do nothing (no false starts triggered anymore)
				}
				else
				{
					switch(currentState)
					{
						case PlayerState.START :
							newState = PlayerState.FALL;
							break;
						
						case PlayerState.FALL :
							// change it right away to see a visual difference
							if(playerState.state == PlayerState.FALL)
							{
								newState = PlayerState.DEPLOY_CHUTE;
								SceneUtil.addTimedEvent(this, new TimedEvent(CHUTE_DEPLOY_WAIT, 1, Command.create(chuteOpened, _playerId)));
							}
							break;
					}
				}
				
				if(newState != currentState)
				{
					changePlayerState(newState);
				}
			}
		}
				
		private function chuteOpened($playerID:int):void
		{
			var entity:Entity = super.getEntityById($playerID);
			if(entity){
				var playerState:PlayerState = entity.get(PlayerState);
				var currentState:String = playerState.state;
				
				if(currentState == PlayerState.DEPLOY_CHUTE)
				{
					changePlayerState(PlayerState.FLOAT, $playerID);
				}
			}
		}
		
		private function switchCamera(opponent:Boolean = true):void
		{
			var id:int = _playerId;
			
			if(opponent)
			{
				id = _opponentId;
			}
			
			var entity:Entity = super.getEntityById(id);
			
			if(entity)
			{
				var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
				cameraGroup.setTarget(entity.get(Spatial), true);
			}
			
		}
		
		private function changePlayerState(newState:String, id:Number = NaN):void
		{
			if(isNaN(id))
			{
				id = _playerId;
			}
			
			var clientState:Boolean = false;
			var entity:Entity = super.getEntityById(id);
			var playerState:PlayerState = entity.get(PlayerState);
			
			if((_setLocalPlayerStateInstantly && id == _playerId) || _clientStates.indexOf(newState) > -1)
			{
				if(playerState.state != newState && newState != PlayerState.START)
				{
					playerState.state = newState;
					checkForRoundResult(id, newState);
				}
			}
			// do not send these state changes
			if(playerState.state != PlayerState.LAND && playerState.state != PlayerState.CRASH && playerState.state != PlayerState.FLOAT)
			{
				if(shellApi.smartFoxManager.isInRoom)
				{
					var sfso:SFSObject = new SFSObject();
					sfso.putInt("playerId", id);
					sfso.putUtfString("newState", newState);
					smartFoxGroup.smartFox.send( new ExtensionRequest("changePlayerState", sfso, smartFoxGroup.smartFox.lastJoinedRoom) );
				}
			}
		}

		private function setupCountdown():void
		{
			var clip:MovieClip = super.hitContainer["countdown"];
			var countdown:Entity = TimelineUtils.convertClip(clip, this, null, null, false);
			
			countdown.add(new Id("countdown"));
			countdown.add(new Display(clip));
			countdown.add(new Spatial(clip.x, clip.y));
			countdown.get(Display).visible = false;
			countdownV = clip.y;
		}
		
		private function startGame():void
		{
			ButtonCreator.loadCloseButton(this, super.overlayContainer, backToChooser);
			
			super.loadFile("waiting.swf", waitingLoaded);
		}
		
		private function backToChooser(buttonEntity:Entity = null):void
		{
			// go to choose game
			shellApi.loadScene(ChooseGame);
		}
		
		private function waitingLoaded(display:MovieClip):void
		{
			if(!_gameStarted)
			{
				_waitingDisplay = super.overlayContainer.addChild(display) as MovieClip;
				DisplayPositionUtils.centerWithinDimensions(_waitingDisplay, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
				
				// join new game
				connect();
			}
		}
		
		private function characterLoaded(entity:Entity):void
		{
			Sleep(entity.get(Sleep)).sleeping = false;
			Sleep(entity.get(Sleep)).ignoreOffscreenSleep = true;
			
			CharUtils.setAnim(entity, Stand);
			
			// add standard player audio
			var audioGroup:AudioGroup = super.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			audioGroup.addAudioToEntity(entity, "player");
			
			// backup for setting spatial position.
			var spatial:Spatial = entity.get(Spatial);
			spatial.y = super.sceneData.startPosition.y;
		}
		
		private function onPlayAgainClicked(timeLeft:Number):void
		{
			if(shellApi.smartFoxManager.isInRoom)
			{
				var sfso:SFSObject = new SFSObject();
				sfso.putInt("playerId", _playerId);
				sfso.putUtfString("newState", "playAgainClicked");
				smartFoxGroup.smartFox.send( new ExtensionRequest("changePlayerState", sfso, smartFoxGroup.smartFox.lastJoinedRoom) );
			}

			gameOver = false;
			clickedPlayAgain = true;
			
			var popup:Result = super.getGroupById("resultPopup") as Result;
			popup.close();
			
			switchCamera(false);
			
			// if other player has left or clicked play again then restart game right away
			if ((otherPlayerLeft) || (otherPlayAgain))
			{
				restartGame();
			}
			// else wait for other player to click play again and end countdown
			else
			{
				// show message that waiting for other player to decide
				var countdown:Entity = super.getEntityById("countdown");
				countdown.get(Display).visible = true;
				countdown.get(Spatial).y = super.getEntityById(_playerId).get(Spatial).y - 100;
				countdown.get(Timeline).gotoAndStop("deciding");
				// set timer for restarting game
				var timedEvent:TimedEvent = new TimedEvent(timeLeft, 1, restartGame);
				SceneUtil.addTimedEvent(this, timedEvent, "restart");
			}
		}
		
		private function restartGame():void
		{
			shellApi.track(SmartFoxManager.TRACK_SFS_GAME_PLAY, gameID);
			
			// clear timer
			clearTimer()
			
			resetGame();
			
			if(_totalPlayersInQueue == 0)
			{
				super.loadFile("waiting.swf", waitingLoaded);
			}
		}
		
		private function clearTimer():void
		{
			var timer:Timer = SceneUtil.getTimer(this, "restart");
			if (timer != null)
			{
				timer.timedEvents = new Vector.<TimedEvent>();
			}
		}

		// disconnect handlers
		
		private function onDisconnect(event:SFSEvent):void
		{
			clearTimer();
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", returnToPrevious)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		private function resetPlayer(id:int):void
		{
			trace("reset player:"+id);	
			
			var entity:Entity = super.getEntityById(id);
			MotionUtils.zeroMotion(entity);
			CharUtils.setAnim(entity, Stand);
			var parachute:Parachute = entity.get(Parachute);
			
			if(parachute.entity)
			{
				super.removeEntity(parachute.entity);
			}
			
			loadParachute(entity);
			
			Spatial(entity.get(Spatial)).y = super.sceneData.startPosition.y;
		}
		
		private function resetGame():void
		{
			// removed timed events
			if(_playerLeftTimer){
				_playerLeftTimer.stop();
				_playerLeftTimer = null;
			}
			
			if(_resultTimer){
				_resultTimer.stop();
				_resultTimer = null;
			}
			
			// clear "SET" / "GO"
			var countdown:Entity = super.getEntityById("countdown");
			var timeline:Timeline = countdown.get(Timeline);
			timeline.gotoAndStop(0);
			countdown.get(Spatial).y = countdownV;
			
			// clear entities
			for each(var entity:Entity in _playerEntities)
			{
				this.removeEntity(entity);
			}
			
			// reset camera position
			var x:Number = super.sceneData.startPosition.x;
			var y:Number = super.sceneData.startPosition.y;
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			cameraGroup.setTarget(new Spatial(x,y), true);
			
			_gameStarted = false;
			_readyToJump = false;
			_countdownSet = false;
			_roundComplete = false;
			_playersFinished = 0;
			_roundResult = null;
			_totalPlayersInQueue = 0;
		}
		
		private function returnToPrevious():void
		{
			var destScene:String = shellApi.sceneManager.previousScene;
			var destSceneX:Number = shellApi.sceneManager.previousSceneX;
			var destSceneY:Number = shellApi.sceneManager.previousSceneY;
			var destSceneDirection:String = shellApi.sceneManager.previousSceneDirection;
			
			shellApi.loadScene(ClassUtils.getClassByName(destScene), destSceneX, destSceneY, destSceneDirection);
		}
				
		// scene destroy handler
		override public function destroy():void
		{
			clearTimer();
			sfsReset(); // remove references and listeners of smartFox
			super.destroy();
		}
		
		public function sfsReset():void
		{
			// end idle
			shellApi.smartFoxManager.idleMe(false);
			
			// remove admin message listener
			shellApi.smartFoxManager.adminMessage.remove(onAdminMessage);
		}
		
		protected function onAdminMessage($message:String):void{
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, $message)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		private var _playersFinished:int = 0;
		private var _playerId:int;
		private var _playerEntities:Vector.<Entity> = new Vector.<Entity>();
		private var _totalPlayersInQueue:int = 0;
		private var _host:Boolean = false;
		private var _countdownSet:Boolean = false;
		private var _gameStarted:Boolean = false;
		private var _readyToJump:Boolean = false;
		private var _roundComplete:Boolean = false;
		private var _parachuteContainer:Sprite;
		private var _waitingDisplay:MovieClip;
		private var _opponentId:int;
		private var _roundResult:String;
		private static const MIN_PLAYERS:int = 2;
		private static const CHUTE_DEPLOY_WAIT:Number = .2;
		private var _setLocalPlayerStateInstantly:Boolean = true;
		private var _clientStates:Array = [PlayerState.CRASH, PlayerState.LAND, PlayerState.WIN, PlayerState.LOSE];
		
		private var _playerLeftTimer:TimedEvent;
		private var _resultTimer:TimedEvent;
	}
}