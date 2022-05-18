package game.scenes.hub.skydive
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.Room;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	import com.smartfoxserver.v2.requests.LeaveRoomRequest;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import game.managers.SmartFoxManager;
	import game.scenes.hub.starcade.Starcade;
	
	import org.osflash.signals.Signal;
	
	public class SmartFoxGroup extends Group
	{
		public function SmartFoxGroup()
		{
			super.id = GROUP_ID;
		}
		
		override public function destroy():void
		{
			_smartFox.removeEventListener(SFSEvent.CONNECTION, onConnect);
			_smartFox.removeEventListener(SFSEvent.LOGIN, onLogin);
			_smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
			_smartFox.removeEventListener(SFSEvent.CONNECTION_LOST, onConnectionLost);
			_smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onExtension);
			_smartFox.removeEventListener(SFSEvent.ROOM_ADD, onRoomAdd);
			_smartFox.removeEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnter);
			_smartFox.removeEventListener(SFSEvent.USER_EXIT_ROOM, onUserExit);
			_smartFox.removeEventListener(SFSEvent.ROOM_VARIABLES_UPDATE, onRoomVars);
			_smartFox.removeEventListener(SFSEvent.OBJECT_MESSAGE, onMessage);
			
			connected.removeAll();
			loginError.removeAll();
			connectedHttp.removeAll();
			loggedIn.removeAll();
			roomJoined.removeAll();
			connectionLost.removeAll();
			roomVars.removeAll();
			extensionResponse.removeAll();
			roomAdded.removeAll();
			objectMessage.removeAll();

			startGame.removeAll();
			userEntered.removeAll();
			userExitted.removeAll();
			
			leaveRoom();
			
			super.destroy();
		}
		
		public function setupGroup(parent:Group):void
		{
			connected = new Signal(SFSEvent);
			loginError = new Signal(SFSEvent);
			connectedHttp = new Signal(SFSEvent);
			loggedIn = new Signal(SFSEvent);
			roomAdded = new Signal(SFSEvent);
			roomJoined = new Signal(Array);
			roomVars = new Signal(SFSEvent);
			connectionLost = new Signal(SFSEvent);
			extensionResponse = new Signal(SFSEvent);
			objectMessage = new Signal(SFSEvent);
			
			startGame = new Signal(SFSEvent);
			userEntered = new Signal(User);
			userExitted = new Signal(User);
			
			parent.addChildGroup(this);
			
			_smartFox = shellApi.smartFoxManager.smartFox;
			
			_smartFox.addEventListener(SFSEvent.CONNECTION, onConnect);
			_smartFox.addEventListener(SFSEvent.CONNECTION_LOST, onConnectionLost);
			_smartFox.addEventListener(SFSEvent.LOGIN, onLogin);
			_smartFox.addEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
			_smartFox.addEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnter);
			_smartFox.addEventListener(SFSEvent.USER_EXIT_ROOM, onUserExit);
			_smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onExtension);
			_smartFox.addEventListener(SFSEvent.ROOM_VARIABLES_UPDATE, onRoomVars);
			_smartFox.addEventListener(SFSEvent.OBJECT_MESSAGE, onMessage);
		}
		
		protected function onConnect(event:SFSEvent):void
		{
			if (event.params.success)
			{
				trace("onConnect success");
			}
			else
			{
				trace("onConnect error : " + event.params.errorMessage);
			}
			
			connected.dispatch(event);
		}

		protected function onLogin(event:SFSEvent):void
		{
			trace("onLogin");
			
			loggedIn.dispatch(event);
		}
		
		protected function onRoomAdd(event:SFSEvent):void
		{
			trace("onRoomAdded");
			
			roomAdded.dispatch(event);
		}
		
		protected function onRoomVars(event:SFSEvent):void
		{
			trace("onRoomVars : " + event.params.changedVars);
				
			roomVars.dispatch(event);
		}
		
		protected function onMessage(event:SFSEvent):void
		{
			trace("onMessage : " + event.params);
			
			objectMessage.dispatch(event);
		}
		
		protected function onRoomJoin(event:SFSEvent):void
		{
			trace("onRoomJoin");
			
			roomJoined.dispatch(event.params.room.playerList);
		}
		
		protected function onConnectionLost(event:SFSEvent):void
		{
			trace("onConnectionLost : " + event.params.reason);
			
			connectionLost.dispatch(event);
		}
		
		protected function onExtension(event:SFSEvent):void
		{
			trace("onExtension : " + event.params.cmd);
			
			extensionResponse.dispatch(event);
			
			if(event.params.cmd == START_GAME)
			{
				startGame.dispatch(event);
			}
		}
		
		public function get smartFox():SmartFox
		{
			return _smartFox;
		}
		
		protected function onUserEnter(event:SFSEvent):void
		{
			// create player
			//createPlayer(event.params.user);
			userEntered.dispatch(event.params.user);
		}
		
		protected function onUserExit(event:SFSEvent):void
		{
			// remove player
			//removePlayer(event.params.user);
			if(Room(event.params.room) == shellApi.smartFox.lastJoinedRoom){ // if only leaving the current game room (prevents listener overlap from leaving arcade room)
				userExitted.dispatch(event.params.user);
			}
		}
		
		/*****/
		// session (connect) -> user (login) -> room
		// ex : playStarLink
		public function gameConnect(game:String):void
		{
			if(!_smartFox.isConnected)
			{
				shellApi.smartFoxManager.connect();
				shellApi.smartFoxManager.loggedIn.addOnce(Command.create(addPlayerToGame, game));
				//updateStatusMessage("connecting to server");
			} 
			else 
			{
				addPlayerToGame(game);
				//updateStatusMessage("finding a game");
			}
		}
		
		public function gameLogin(game:String):void
		{
			_smartFox.send(new ExtensionRequest(game));
			//updateStatusMessage("finding a game");
		}
		
		public function disconnectGame():void
		{
			// we want to remain connected so we can reenter the arcade without pause.
			//_smartFox.disconnect(); // keep commented
			leaveRoom(); // instead - just leave the room.
		}
		
		public function exitGame():void
		{
			shellApi.loadScene(Starcade);
		}
		
		public function leaveRoom():void
		{
			if(shellApi.smartFox.lastJoinedRoom != null)
			{
				_smartFox.send(new LeaveRoomRequest(shellApi.smartFox.lastJoinedRoom)); // leave room
			}
		}
		
		protected function addPlayerToGame(game:String):void
		{
			// check if user character data has been submitted - 
			var myUser:User = super.shellApi.smartFox.mySelf;
			if(myUser.getVariable(SmartFoxManager.USER_CHAR_LOOK) == null)
			{
				// if not, send it and wait for a response
				super.shellApi.smartFoxManager.charUpdated.addOnce(Command.create(gameLogin, game));
				super.shellApi.smartFoxManager.updateCharData();
			} 
			else 
			{
				// if so, join the scene
				gameLogin(game);
			}
		}
		
		public function isConnected():Boolean
		{
			return _smartFox.isConnected;
		}
		
		/*****/
	
		public var connected:Signal;
		public var loginError:Signal;
		public var connectedHttp:Signal;
		public var loggedIn:Signal;
		public var roomAdded:Signal;
		public var roomJoined:Signal;
		public var roomVars:Signal;
		public var connectionLost:Signal;
		public var extensionResponse:Signal;
		public var startGame:Signal;
		public var userEntered:Signal;
		public var userExitted:Signal;
		public var objectMessage:Signal;
		
		public static var GROUP_ID:String = "smartFoxGroup";
		public static const START_GAME:String = "startGame";
		private var _smartFox:SmartFox;
		
		private var _gameOn:Boolean;
	}
}