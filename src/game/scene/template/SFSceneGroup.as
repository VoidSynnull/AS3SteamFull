package game.scene.template
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.entities.variables.UserVariable;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMovement;
	import game.components.scene.SceneInteraction;
	import game.components.smartFox.SFScenePlayer;
	import game.components.smartFox.SFSceneState;
	import game.components.timeline.Timeline;
	import game.creators.scene.SFSceneEntityCreator;
	import game.data.TimedEvent;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.managers.SmartFoxManager;
	import game.systems.SystemPriorities;
	import game.systems.smartFox.SFSceneObjectSystem;
	import game.systems.smartFox.SFScenePlayerSystem;
	import game.systems.smartFox.SFSceneStateSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.multiplayer.Emotes;
	import game.ui.multiplayer.chat.Chat;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Add to scenes to allow for multiplayer through SmartFox
	 * @author Bart Henderson
	 */
	public class SFSceneGroup extends Group
	{
		public static const GROUP_ID:String								= "sfsSceneGroup";
		public static var DEBUG:Boolean									= false;
		
		// scene types
		public static const SCENE_PUBLIC:String     					= "S_PUB"; // public scene or "Common Room" (anyone can participate)
		public static const SCENE_PRIVATE:String    					= "S_PRV"; // private scene hidden from public (others can participate by invite only)
		public static const SCENE_OBSERVED:String   					= "S_OBV"; // a dynamically created scene visible only to selected clients (useful for devs)
		
		// commands / data identifiers
		public static const CMD_JOIN_SCENE:String       				= "joinScene";
		public static const CMD_PLAYERUPDATE:String     				= "U";
		public static const CMD_PLAYERACTION:String     				= "A";
		public static const CMD_PLAYER_HSHAKE:String                    = "P_HSK";
		public static const CMD_FLASH_STATE:String         				= "F";
		public static const CMD_CHANGE_SCENE:String						= "S_CHG";
		public static const CMD_GET_CHAT:String							= "C";
		public static const CMD_GET_MESSAGES:String						= "CM";
		public static const CMD_GET_REPLIES:String						= "CR";
		public static const TIMESTAMP_SCENE_CLOCK:String       			= "T"; // server's scene clock since the start of it's creation
		public static const TIMESTAMP_PLAYERUPDATE_RECIEVED:String    	= "R"; // time at which a player update was recieved by the server per the server's scene clock
		public static const TIMESTAMP_PLAYERUPDATE_SENT:String    		= "t"; // time at which a player has sent an update per the client's scene clock
		public static const UPDATE_FREQUENCY:String						= "F"; // update frequency from a scene
		public static const PRIORITY_PACKET:String    					= "P"; // for priority packets that override any other packet in between a server send cycle
		
		// action keys and types
		public static const KEY_ACTION_TYPE:String        				= "AT";
		
		public static const TYPE_PLAYER_EMOTE:String        			= "E";
		public static const TYPE_PLAYER_CHAT:String        				= "C";
		public static const TYPE_PLAYER_ABILITY:String					= "PA";
		public static const TYPE_PLAYER_MSG_STRING:String        		= "MS";
		public static const TYPE_PLAYER_SHARED_OBJ:String				= "PSO";
		public static const TYPE_PLAYER_STATEMENT:String    			= "S";
		public static const TYPE_PLAYER_THINK:String    				= "T";
		public static const TYPE_PLAYER_CANCEL:String    				= "CA";
		public static const TYPE_PLAYER_GAME_ADV:String     			= "GA";
		public static const TYPE_PLAYER_GAME_INV:String     			= "GI";
		
		public static const KEY_USER_ID:String                       	= "U_ID";
		public static const KEY_TARGET_USER_ID:String    				= "TU_ID";
		
		public static const KEY_MSG:String    							= "M";
		
		public static const KEY_SUBJECT_INDEX:String					= "CS";
		public static const KEY_OPTION_INDEX:String						= "CI";
		public static const KEY_OPTION_TYPE:String						= "CT";
		
		public static const KEY_SCENE_CLASS:String						= "S_CLS";
		
		public static const KEY_CMD_MSG:String							= "C_MSG";
		public static const KEY_GEN_OBJECT:String						= "G_Obj";
		public static const KEY_CHAT_CATEGORY_ID:String        		    = "CC_ID";
		public static const KEY_CHAT_MESSAGE_ID:String        		    = "CM_ID";
		
		// prefixes
		public static const PREFIX_USER:String							= "U_";
		
		// user data identifiers
		public static const USER_CHAR_NAME:String 						= "char_name"; // character's name
		public static const USER_CHAR_LOOK:String 						= "char_look"; // character's look string
		
		public var suppressIconsOnInit:Boolean							= false; // for suppressing icons in clubhouse
		
		public function SFSceneGroup(debug:Boolean = false, alertUser:Boolean = true, softCapped = false, clubhouseLogin:String = null, startTime:Number = 0, joinTime:Number = 0, updateFrequency:int = 0)
		{
			super();
			
			this.id = GROUP_ID;
			
			DEBUG = debug;
			_startTime = startTime;
			_joinTime = joinTime;
			_alertUser = alertUser;
			_softCapped = softCapped;
			_clubhouseLogin = clubhouseLogin;
			_sfsSceneEntityCreator = new SFSceneEntityCreator();
			updateFrequency = updateFrequency;
		}
		
		override public function added():void
		{
			// register a reference of the current scene
			_scene = this.parent as GameScene;
			
			// setup creators, managers and systems
			addSystem(new SFSceneStateSystem(this), SystemPriorities.update);		// maintains updates in multiplayer scene
			addSystem(new SFSceneObjectSystem(), SystemPriorities.postUpdate);		// NOT YET IN USE
			addSystem(new SFScenePlayerSystem(this), SystemPriorities.postUpdate);	// maintains updates to character state for multiplayer
			
			// create entity to be updated by SFSceneStateSystem
			_sfStateManager = new Entity();
			_sfSceneState = new SFSceneState();
			_sfStateManager.add(_sfSceneState);
			this.addEntity(_sfStateManager);
			
			// setup smartFox
			shellApi.smartFoxManager.loginError.add(onLoginError);
			
			// once connected to SmartFox verify char
			if(!shellApi.smartFox.isConnected){
				//trace(" SFSceneGroup: Not Connected ");
				shellApi.smartFoxManager.connect(_softCapped);
				shellApi.smartFoxManager.loggedIn.addOnce(verifyCharData);
			} 
			else if(shellApi.smartFox.currentZone != AppConfig.multiplayerZone)
			{
				//trace(" SFSceneGroup: Connected - Waiting for Login ");
				// middle of connecting - wait for login
				shellApi.smartFoxManager.loggedIn.addOnce(verifyCharData);
			} 
			else if(AppConfig.multiplayerZone)
			{
				// already connected to the poptropica zone -- send scene extension request
				verifyCharData();
			}
			
			// load asset and start setup for wifi HUD element
			shellApi.loadFile(shellApi.assetPrefix + "scenes/hub/starcade/signal/signal.swf", setupSignalHUD);
		}
		
		
		/////////////////////////////////// WI-FI HUD /////////////////////////////////// 
		
		/**
		 * Create UI to display connection strength to player 
		 * @param clip - asset used for UI display
		 */
		private function setupSignalHUD(clip:MovieClip):void{
			_scene.overlayContainer.addChild(clip);
			_signalHUD = EntityUtils.createSpatialEntity(this, clip["signalStrength"], _scene.overlayContainer);
			TimelineUtils.convertClip(clip["signalStrength"], this, _signalHUD, null, false);
			
			var signalSpatial:Spatial = _signalHUD.get(Spatial);
			signalSpatial.y = shellApi.camera.viewportHeight - (signalSpatial.height*0.35);
			
			Display(_signalHUD.get(Display)).visible = false;
		}
		
		public function updateSignalHUD($percentage:Number):void{
			if(_signalHUD){
				var level:int = Math.ceil($percentage * 5);
				Timeline(_signalHUD.get(Timeline)).gotoAndStop(level-1);
				if(level <= 3){
					if(_alertUser){
						Display(_signalHUD.get(Display)).visible = true;
					}
				} else if(level >= 4 && Display(_signalHUD.get(Display)).visible){
					SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, hideSignalHud));
				}
			}
		}
		
		private function hideSignalHud(...p):void{
			Display(_signalHUD.get(Display)).visible = false;
		}
		
		/////////////////////////////////////////////////////////////////////////////////// 
		
		private function onLoginError(event:SFSEvent):void{
			shellApi.log("SFS LOGIN ERROR: "+event.params.popupMsg);
			if(_alertUser){
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, event.params.popupMsg)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(_scene.overlayContainer);
			}
			if(shellApi.smartFox.isConnected){
				shellApi.smartFoxManager.disconnect();
			}
		}
		
		/**
		 * Make sure current player has registered their character data (look & name) with SFS
		 * Once character has been 'registered' with SFS can join scene 
		 */
		protected function verifyCharData():void{
			// check if user character data has been submitted - 
			var myUser:User = shellApi.smartFox.mySelf;
			if(myUser.getVariable(SmartFoxManager.USER_CHAR_LOOK) == null){
				// if not, send it and wait for a response
				// TODO :: would it be safer to send a handler instead of listening for a signal? - bard
				shellApi.smartFoxManager.charUpdated.addOnce(joinSFScene);
				shellApi.smartFoxManager.updateCharData();
				if(AppConfig.debug){
					trace("   ---------------------------------");
					trace("   updating character info ...");
					trace("   ---------------------------------");
				}
				
			} else {
				// if so, join the scene
				joinSFScene();
			}
		}
		
		/**
		 * Called after successfully connecting to a server-based scene on smartfox.
		 */
		protected function setupSFScene($otherPlayers:ISFSObject = null):void{
			
			
			_emotesGroup = this.addChildGroup(new Emotes(this)) as Emotes;
			_chatGroup = this.addChildGroup(new Chat(this)) as Chat;
			//_carrotsGroup = this.addChildGroup(new PlayerCarrots()) as PlayerCarrots;
			
			// create my player
			createPlayer(shellApi.smartFox.mySelf);
		}
		
		public function createPlayer($user:User, $sfPlayerState:ISFSObject = null):Entity{
			// create sfPlayer entity and add it to the _sfPlayers dictionary
			if($user){
				if($user.isItMe){
					// assign the entity to _mySFPlayer if it's me
					$user.properties.login = shellApi.profileManager.active.login;
					_sfPlayerLogins[$user] = shellApi.profileManager.active.login;
					_mySFPlayer = _sfPlayers[$user.name] = _sfsSceneEntityCreator.createSFPlayerEntity(_scene, $user, null, $sfPlayerState, setupPlayer);
					
				}else{
					_sfPlayers[$user.name] = _sfsSceneEntityCreator.createSFPlayerEntity(_scene, $user, null, $sfPlayerState, setupCharacter);
					
				}
				return _sfPlayers[$user.name];
			} else {
				return null;
			}
		}
		
		/**
		 * Applies additional functionality required for multiplayer characters once they have finished loading.
		 * @param $charEntity
		 */
		public function setupCharacter($charEntity:Entity):void
		{
			
			// all characters require state driven movement
			var charGroup:CharacterGroup = this.parent.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			charGroup.addFSM($charEntity);
			
			
			// chat with player on clicking another avatar
			var sceneInt:SceneInteraction = $charEntity.get(SceneInteraction);
			sceneInt.reached.add(chatPlayer);
			
			// make the approach to the NPC more omni directional
			sceneInt.minTargetDelta = new Point(200,200);
			sceneInt.offsetX = 0;
			sceneInt.offsetY = 0;
			
			// check distance and override if necessary (so chatting characters don't keep "nudging" together
			sceneInt.triggered.add(checkApproach);
			
			// disable sleep
			Sleep($charEntity.get(Sleep)).sleeping = false;
			Sleep($charEntity.get(Sleep)).ignoreOffscreenSleep = true;
		}

		private function checkApproach($entity1:Entity, $entity2:Entity):void{
			var sceneInt:SceneInteraction = $entity2.get(SceneInteraction);
			if(EntityUtils.distanceBetween($entity1, $entity2) <= 200){
				sceneInt.approach = false;
				sceneInt.reached.dispatch($entity1, $entity2);
			} else {
				sceneInt.approach = true;
			}
		}
		
		/**
		 * Applies player specific functionality for multiplayer character once it have finished loading.
		 * @param $charEntity
		 */
		public function setupPlayer($charEntity:Entity):void
		{
			setupCharacter( $charEntity );
			
			if(!SFSceneGroup.DEBUG)
			{ 
				Sleep($charEntity.get(Sleep)).sleeping = true;
				
				CharacterMovement($charEntity.get(CharacterMovement)).active = false;
				CharUtils.freeze($charEntity);
				Spatial($charEntity.get(Spatial)).x = -300; // force off screen
			}
			else
			{
				EntityUtils.visible( $charEntity, true );
			}
		}
		
		private function chatPlayer($entity:Entity, $entity2:Entity):void{
			if(!SFScenePlayer($entity2.get(SFScenePlayer)).do_not_disturb){
				_chatGroup.OpenFriendChat($entity2);
			} else {
				Dialog($entity2.get(Dialog)).allowOverwrite = true;
				Dialog($entity2.get(Dialog)).say("I'm busy right now.");
			}
		}
		
		private function greetPlayer($entity:Entity, $entity2:Entity):void{
			var user:User = SFScenePlayer($entity2.get(SFScenePlayer)).user;
			var msg:String;
			
			if(user.getVariable(USER_CHAR_NAME) != null){
				msg = "Hello there, "+user.getVariable(USER_CHAR_NAME).getStringValue()+"!";
			} else {
				msg = "Hello there!";
			}
			
			//Dialog($entity.get(Dialog)).say(msg);
			
			var obj:ISFSObject = new SFSObject();
			obj.putInt(KEY_TARGET_USER_ID, user.id);
			obj.putUtfString(KEY_ACTION_TYPE, TYPE_PLAYER_MSG_STRING);
			obj.putUtfString(KEY_MSG, msg);
			
			if(inSFScene)
				shellApi.smartFox.send(new ExtensionRequest(CMD_PLAYERACTION, stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		private function changeScene($sfsObject:ISFSObject):void{
			// load scene class - instructed by the server and confirmed by user
			var sceneClass:Class = ClassUtils.getClassByName($sfsObject.getUtfString(KEY_SCENE_CLASS));
			shellApi.loadScene(sceneClass);
		}
		
		/**
		 * Shares an object with all connected player clients or one specific player's client
		 * @param obj - Object to be shared
		 * @param shareWith - Who to share it with. Setting this to null shares the object with everyone in the room.
		 */
		public function shareObject(obj:Object, shareWith:Entity = null):void{

			// create player action SFS object - to be queued and treated like a player action
			var isfso:ISFSObject = new SFSObject();
			isfso.putUtfString(KEY_ACTION_TYPE, TYPE_PLAYER_SHARED_OBJ);
			
			// load serialized object into playerAction SFS object
			isfso.putSFSObject(KEY_GEN_OBJECT, SFSObject.newFromObject(obj));
			
			// include target player's user id if applicable
			if(shareWith){
				var userId:int = SFScenePlayer(shareWith.get(SFScenePlayer)).user.id;
				isfso.putInt(KEY_TARGET_USER_ID, userId);
			}
			
			// stamp object and send it off!
			if(inSFScene)
				shellApi.smartFox.send(new ExtensionRequest(CMD_PLAYERACTION, stampObj(isfso), shellApi.smartFox.lastJoinedRoom));
		}
		
		private function receiveObject(isfso:ISFSObject):void{
			
		}
		
		public function handshakePlayer($entity:Entity):void{
			// temporarily "buddies" up with referenced player
			var obj:ISFSObject = new SFSObject();
			obj.putInt(KEY_TARGET_USER_ID, SFScenePlayer($entity.get(SFScenePlayer)).user.id);
			
			if(inSFScene){
				shellApi.smartFox.send(new ExtensionRequest(CMD_PLAYER_HSHAKE, obj, shellApi.smartFox.lastJoinedRoom));
			}
		}
		
		public function inviteToGame($sfsObject:ISFSObject):void{
			if(inSFScene){
				shellApi.smartFox.send(new ExtensionRequest(CMD_PLAYERACTION, stampObj($sfsObject), shellApi.smartFox.lastJoinedRoom));
			}
		}
		
		public function removePlayer($user:User):void{
			// remove entity from scene and it's reference in the _sfPlayers dictionary
			var entity:Entity = _sfPlayers[$user.name];
			if(entity){
				var sfScenePlayer:SFScenePlayer = entity.get(SFScenePlayer);

				if(sfScenePlayer.spatial_debug){
					this.removeEntity(sfScenePlayer.spatial_debug);
				}
			}
			
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   [ ... SFSceneEntity Removed ... ]");
				trace("   ---------------------------------");
			}
			
			// prune any orphaned player states in queue (so that the client doesn't recreate the entity)
			for each(var state:ISFSObject in _sfSceneState.state_queue){
				state.removeElement(String(PREFIX_USER+$user.name));
			}
			
			this.removeEntity(entity);
			
			//_sfPlayers[$user.name] = null;
			delete _sfPlayers[$user.name];	// NOTE :: use delete to make sure Dictionary entry is cleaned
		}
		
		/**********************************************
		 * Join/Create a Smartfox Scene
		 */
		
		protected function joinSFScene():void
		{
			
			// check if user character data has been submitted
			var myUser:User = shellApi.smartFox.mySelf;
			if(myUser.getVariable(SmartFoxManager.USER_CHAR_LOOK) == null){
				shellApi.smartFoxManager.updateCharData();
			}
			
			// setup room/extension listeners
			shellApi.smartFox.addEventListener(SFSEvent.ROOM_JOIN, onSFSRoomJoin);
			shellApi.smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onSFSExtension);
			shellApi.smartFox.addEventListener(SFSEvent.USER_VARIABLES_UPDATE, onUserVarUpdate);
			
			// listen for a disconnect
			shellApi.smartFoxManager.disconnected.addOnce(onDisconnect);
			
			// connect to a public scene
			var params:ISFSObject = new SFSObject();
			params.putUtfString("type",SCENE_PUBLIC);
			// if clubhouse, then we use the user login for island and scene
			if (_scene.shellApi.sceneName == "Clubhouse")
			{
				if (_clubhouseLogin == null)
				{
					trace("Error: login needed for clubhouse!");
					return;
				}
				else
				{
					params.putUtfString("island", _clubhouseLogin);
					params.putUtfString("scene", _clubhouseLogin);
				}
			}
			else
			{
				params.putUtfString("island", _scene.shellApi.island);
				params.putUtfString("scene", _scene.shellApi.sceneName);
			}
			
			shellApi.smartFox.send(new ExtensionRequest(CMD_JOIN_SCENE, params));
			
			if(false){
				trace("   ---------------------------");
				trace("   joining SFScene ... " + _scene.shellApi.sceneName);
				trace("   ---------------------------");
			}
		}
		
		
		/**
		 * Handler for SFSEvent.ROOM_JOIN, possible response of CMD_JOIN_SCENE ExtensionRequest
		 * @param event
		 */
		protected function onSFSRoomJoin(event:SFSEvent):void
		{
			// trash join room listener
			shellApi.smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onSFSRoomJoin);

			setupSFScene(); // temporary
			
			// get flash state from server room
			shellApi.smartFox.send(new ExtensionRequest(CMD_FLASH_STATE, null, shellApi.smartFox.lastJoinedRoom));
			
			// setup other user join/exit listeners
			shellApi.smartFox.addEventListener(SFSEvent.USER_ENTER_ROOM, onSFSUserEnter);
			shellApi.smartFox.addEventListener(SFSEvent.USER_EXIT_ROOM, onSFSUserExit);
			
			// listen for admin messages
			shellApi.smartFoxManager.adminMessage.add(onAdminMessage);
			
			if(AppConfig.debug){
				trace("   --------------------------");
				trace("   [ ... Joined "+shellApi.smartFox.lastJoinedRoom.name+" ... ]");
				trace("   --------------------------");
			}
		}
		
		/**
		 * Handler for SFSEvent.USER_ENTER_ROOM, create a player defined by event data
		 * @param event
		 */
		protected function onSFSUserEnter(event:SFSEvent):void
		{
			// create player
			createPlayer(event.params.user);
		}
		
		/**
		 * Handler for SFSEvent.USER_EXIT_ROOM, remove a player defined by event data
		 * @param event
		 */
		protected function onSFSUserExit(event:SFSEvent):void
		{
			// remove player
			removePlayer(event.params.user);
		}
		
		private function onDisconnect():void
		{
			// clean scene of sf players
			for(var key:String in _sfPlayers){
				var entity:Entity = _sfPlayers[key];
				
				if( entity )
				{
					var sfScenePlayer:SFScenePlayer = entity.get(SFScenePlayer);
					
					if(sfScenePlayer.spatial_debug){
						this.removeEntity(sfScenePlayer.spatial_debug);
					}
					
					this.removeEntity(entity);
					//_sfPlayers[key] = null;
					delete _sfPlayers[key];		// NOTE :: use delete to make sure Dictionary entry is cleaned
				}
				else
				{
					trace(this," :: Error :: onDisconnect : entity was ot found for key: " + key );
				}
			}
			
			// remove emotes
			if(_emotesGroup)
				this.removeGroup(_emotesGroup);
			
			// attempt reconnection ?
			
		}
		
		/**********************************************
		 * Main Smartfox Extension Handler
		 */
		
		protected function onSFSExtension($event:SFSEvent):void
		{
			switch($event.params.cmd){
				case CMD_PLAYERUPDATE: // recieved player updates from smartFox scene

					// add packet to queue
					_sfSceneState.state_queue.push($event.params.params);
					// calculate latency on receipt
					var sfSceneState:ISFSObject = $event.params.params;
					var myState:ISFSObject =  sfSceneState.getSFSObject(SFSceneGroup.PREFIX_USER+shellApi.smartFox.mySelf.name);
					
					if(myState){
						if(myState.size() > 0){
							var t:int = myState.getLong(SFSceneGroup.TIMESTAMP_PLAYERUPDATE_SENT);
							var R:int = myState.getLong(SFSceneGroup.TIMESTAMP_PLAYERUPDATE_RECIEVED);
							var T:int = sfSceneState.getLong(SFSceneGroup.TIMESTAMP_SCENE_CLOCK);
							
							_lag = ((getTimer() - startTime + joinTime) - t - ( T - R ));
						}
					}
					
					break;
				case CMD_PLAYERACTION: // recieved player action from user in smartFox scene
					_sfSceneState.action_queue.push($event.params.params);
					break;
				case CMD_CHANGE_SCENE: // move player to another scene
					changeScene($event.params.params);
					break;
				case TIMESTAMP_SCENE_CLOCK: // recieved time stamp from join event
					_startTime = getTimer();
					_joinTime = ISFSObject($event.params.params).getLong(TIMESTAMP_SCENE_CLOCK);
					updateFrequency = ISFSObject($event.params.params).getInt(UPDATE_FREQUENCY);
					break;
			}
		}
		
		
		protected function onUserVarUpdate(event:SFSEvent):void
		{
			var entity:Entity = getSFPlayerByUsername(event.params.user.name);
			// update SFSceneEntity's look
			if(entity){
				var user_look_var:UserVariable = event.params.user.getVariable(USER_CHAR_LOOK);
				var lookData:LookData = new LookConverter().lookDataFromLookString(user_look_var.getStringValue());
				SkinUtils.applyLook(entity, lookData);
			}
		}
		
		protected function onAdminMessage($message:String):void{
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, $message)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(_scene.overlayContainer);
		}
		
		/*********************************************
		 * Utility Methods
		 */
		
		/**
		 * stamps the SFSObject with a time stampe in accordance to the server's clock
		 */
		public function stampObj(sfsObject:ISFSObject):ISFSObject{
			// attaches a timestamp per the client clock
			sfsObject.putLong(SFSceneGroup.TIMESTAMP_PLAYERUPDATE_SENT, getTimer() - this.startTime + this.joinTime);
			return sfsObject;
		}
		
		/**
		 * returns all SFPlayer entities in the scene.
		 */
		public function allSFPlayers():Vector.<Entity>{
			var entities:Vector.<Entity> = new Vector.<Entity>();
			for(var k:Object in _sfPlayers){
				entities.push(_sfPlayers[k]);
			}
			return entities;
		}
		
		/**
		 * returns the SFPlayer entity by it's smartfox user.name
		 * @param $userName - the smartfox user.name
		 */
		public function getSFPlayerByUsername($userName:String):Entity{
			return _sfPlayers[$userName];
		}
		
		public function get mySFPlayer():Entity{
			return _mySFPlayer;
		}
		
		public function get inSFScene():Boolean{
			// only SFScenes have this lastJoinedRoom variable as of 0211
			if(shellApi.smartFox.currentZone == AppConfig.multiplayerZone 
				&& shellApi.smartFox.isConnected 
				&& !shellApi.smartFox.isJoining 
				&& shellApi.smartFox.lastJoinedRoom.containsVariable("type")
				&& !_leaving){
				return true;
			} else {
				
				if(AppConfig.debug){
					trace("shellApi.smartFox.currentZone: "+shellApi.smartFox.currentZone);
					trace("shellApi.smartFox.isConnected: "+shellApi.smartFox.isConnected);
					trace("shellApi.smartFox.isJoining: "+shellApi.smartFox.isJoining);
					trace("shellApi.smartFox.lastJoinedRoom.containsVariable(type): "+shellApi.smartFox.lastJoinedRoom.containsVariable("type"));
					trace("_leaving: "+_leaving);
				}
				
				// signal a disconnect if the client seems to be not connected
				if(!shellApi.smartFox.isConnected || shellApi.smartFox.currentZone != AppConfig.multiplayerZone){
					shellApi.smartFoxManager.disconnected.dispatch();
				}
				return false;
			}
			
		}
		
		public function set leaving($boolean:Boolean):void{
			_leaving = $boolean;
		}
		
		public function get lag():int{
			return _lag;
		}
		
		public function get udpEnabled():Boolean{
			return _udpEnabled;
		}
		
		override public function destroy():void{
			// disconnect from smartFox
			//shellApi.smartFox.disconnect();
			
			// trash listeners
			shellApi.smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onSFSExtension);
			shellApi.smartFox.removeEventListener(SFSEvent.USER_ENTER_ROOM, onSFSUserEnter);
			shellApi.smartFox.removeEventListener(SFSEvent.USER_EXIT_ROOM, onSFSUserExit);
			shellApi.smartFox.removeEventListener(SFSEvent.USER_VARIABLES_UPDATE, onUserVarUpdate);
			shellApi.smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onSFSRoomJoin);
			
			// trash signal listeners
			shellApi.smartFoxManager.loggedIn.remove(verifyCharData);
			shellApi.smartFoxManager.loginError.remove(onLoginError);
			shellApi.smartFoxManager.charUpdated.remove(joinSFScene);
			shellApi.smartFoxManager.disconnected.remove(onDisconnect);
			shellApi.smartFoxManager.adminMessage.remove(onAdminMessage);
			
			// trash data
			_sfPlayers = null;
			_mySFPlayer = null;
			
			_scene = null;
			_sfSceneState = null;
			this.removeEntity(_sfStateManager);
			_sfStateManager = null;
			_sfObjects = null;
			
			super.destroy();
		}
		
		/*********************************************
		 * Dev Test Methods
		 */
		public function testDB():void{
			var obj:ISFSObject = new SFSObject();
			//obj.putInt(KEY_CHAT_CATEGORY_ID, 1);
			obj.putInt(KEY_CHAT_MESSAGE_ID, 34);
			
			//shellApi.smartFox.send(new ExtensionRequest(CMD_GET_CHAT, null, shellApi.smartFox.lastJoinedRoom));
			//shellApi.smartFox.send(new ExtensionRequest(CMD_GET_MESSAGES, obj, shellApi.smartFox.lastJoinedRoom));
			shellApi.smartFox.send(new ExtensionRequest(CMD_GET_REPLIES, obj, shellApi.smartFox.lastJoinedRoom));
		}
		
		public function openChat():void{
			_chatGroup.openChat(_mySFPlayer);
		}
		
		public function get startTime():Number{ return _startTime };
		public function get joinTime():Number{ return _joinTime };
		public function get scene():GameScene{ return _scene };
		public function get emotes():Emotes{ return _emotesGroup };
		public function get chat():Chat{ return _chatGroup };
		//public function get carrots():PlayerCarrots{ return _carrotsGroup };
		
		public var objectRecieved:Signal = new Signal(Object, Entity);  // object, whoFrom
		
		public var updateFrequency:int;
		
		private var _udpEnabled:Boolean;
		private var _scene:GameScene;
		protected var _mySFPlayer:Entity;
		
		private var _lag:int;
		
		protected var _sfPlayers:Dictionary = new Dictionary();
		public var _sfPlayerLogins:Dictionary = new Dictionary();
		private var _sfObjects:Vector.<Entity> = new Vector.<Entity>(); // non player smartfox managed entities
		private var _sfStateManager:Entity;
		private var _sfSceneState:SFSceneState;
		private var _sfsSceneEntityCreator:SFSceneEntityCreator
		
		private var _startTime:Number; // when we joined the scene - per client clock
		private var _joinTime:Number; // when we joined the scene - per server clock
		
		private var _emotesGroup:Emotes;
		private var _chatGroup:Chat;
		
		private var _signalHUD:Entity;
		
		private var _leaving:Boolean;
		private var _alertUser:Boolean;
		private var _softCapped:*;
		private var _clubhouseLogin:String = null;
		//private var _carrotsGroup:PlayerCarrots;
	}
}