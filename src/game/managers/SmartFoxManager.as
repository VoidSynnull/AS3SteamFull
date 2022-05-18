package game.managers
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.bitswarm.AirUDPManager;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.Room;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	import com.smartfoxserver.v2.requests.LeaveRoomRequest;
	import com.smartfoxserver.v2.requests.LoginRequest;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import engine.Manager;
	
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.systems.PerformanceMonitorSystem;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	
	import org.osflash.signals.Signal;
	
	public class SmartFoxManager extends Manager
	{
		
		public static const SFS_LOCAL_TEST:Boolean						= false;
		public static const SFS_LOCAL_ADD:String 						= "127.0.0.1"; // local machine sfs server - for local testing
		public static const SFS_DEV_ADDRESS:String						= "sfs-dev.poptropica.com";
		public static const SFS_LIVE_ADDRESS:String						= "sfs.poptropica.com";
		
		public static const SFS_PORT:int 								= 9933;
		public static const UDP_ENABLED:Boolean							= false; // override setting for udp protocol - faster but unreliable packets (works on mobile platforms only - and prevents cross-platform)
		public static const HTTP_ENABLED:Boolean						= false; // override setting for http (bluebox) protocol.
		
		// user data identifiers
		public static const USER_CHAR_NAME:String 						= "char_name"; // character's name
		public static const USER_CHAR_LOOK:String 						= "char_look"; // character's look string
		public static const USER_CHAR_ABILITIES:String					= "char_abilities"; // character's attached special abilities
		
		// ant farm
		public static var TEST_MODE_ON:Boolean							= false; // switches on if "'smartfox_test' is set to 'on' in the CMS - turns on ant farm mode
		private var overrideHost:String = "";
		
		// commands
		public static const CMD_PLAYERIDLE:String     					= "PI";
		public static const CMD_GET_ANTS:String					        = "A_GA";
		public static const CMD_CLR_ANTS:String					        = "A_CA";
		public static const CMD_VIEW_PORT:String						= "A_VP";
		public static const CMD_ANT_RESPONSE:String		                = "A_R";
		public static const CMD_UPDATE_LOC:String						= "UL";
		public static const CMD_UPDATE_CHAR:String                      = "UC";
		public static const CMD_GET_STATS:String						= "GS";
		
		// data keys
		public static const KEY_SFS_CLIENT_VERSION:String				= "V";
		public static const KEY_SOFT_CAPPED:String						= "S_CAP";
		public static const KEY_ANT_NUM:String		                    = "A_N";
		public static const KEY_ANT_TOTAL:String 	                    = "A_UT";
		public static const KEY_USER_NUM:String                    	    = "A_UN";
		public static const KEY_ANT_RESPONSE_TYPE:String	            = "A_RT";
		public static const KEY_VIEW_PORT_ON:String	            		= "A_VPO";
		public static const KEY_SCENE:String							= "L_S";
		public static const KEY_ISLAND:String							= "L_I";
		
		public static const KEY_TOTAL_PLAYERS:String 					= "T_P";
		public static const KEY_TOTAL_ROOMS:String  					= "T_R";
		public static const KEY_MIGRATIONS:String  						= "T_M";
		public static const KEY_MIGRATIONS_PER_SECOND:String  			= "MPS";
		
		// brain tracking values
		public static const TRACK_SFS_CONNECT:String					= "SFSConnect"; // track SFS login, joining rooms etc.
		public static const TRACK_SFS_ERROR:String						= "SFSError"; // track login error, time outs etc.
		public static const TRACK_SFS_GAME_PLAY:String					= "SFSGamePlay"; // track successful game starts
		public static const TRACK_SFS_GAME_SELECT:String				= "SFSGameSelect"; // track game selected
		public static const TRACK_SFS_GAME_FAIL:String					= "SFSGameLaunchFail"; // track game selected
		
		private const TIMOUT_DURATION:Number							= 6; // timeout duration in seconds
		
		
		public function SmartFoxManager()
		{
		}
		
		override protected function construct():void
		{
			super.construct();
			
			monitorNetwork();
			// check to see if AntFarm mode is enabled from the CMS
			var req:DataStoreRequest = DataStoreRequest.featureStatusRequest('smartfox_test');
			req.requestTimeoutMillis = 1000;
			//shellApi.siteProxy.retrieve(DataStoreRequest.featureStatusRequest('smartfox_test'), onTestStatus);
			(shellApi.siteProxy as IDataStore2).call(req, onTestStatus);
		}
		
		override protected function destroy():void{
			// remove listeners
			shellApi.screenManager.stage.removeEventListener(Event.DEACTIVATE, handleDeactivate);
			
			// trash connection listeners
			smartFox.removeEventListener(SFSEvent.CONNECTION, onSFSConnect);
			smartFox.removeEventListener(SFSEvent.CONNECTION_LOST, onSFSDisconnect);
			smartFox.removeEventListener(SFSEvent.CONNECTION_ATTEMPT_HTTP, onSFSConnectHTTP);
			
			// trash login listeners
			smartFox.removeEventListener(SFSEvent.LOGIN, onSFSLogin);
			smartFox.removeEventListener(SFSEvent.LOGIN_ERROR, onSFSLoginError);
			
			// trash migration listeners
			smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
			smartFox.removeEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
			smartFox.removeEventListener(SFSEvent.USER_EXIT_ROOM, onUserExitRoom);
			
			// trash data listeners
			smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
			smartFox.removeEventListener(SFSEvent.ROOM_VARIABLES_UPDATE, onRoomVars);
			smartFox.removeEventListener(SFSEvent.USER_VARIABLES_UPDATE, onUserVars);
			
			super.destroy();
		}
		
		private function monitorNetwork():void{
			_networkAvailable = shellApi.networkAvailable();
			// listen to networkMonitor
			if(shellApi.networkMonitor){
				shellApi.networkMonitor.statusUpdate.add(onNetworkStatus);
				_networkMonitored = true;
			}
			
		}
		
		private function onNetworkStatus($status:Boolean):void{
			if(AppConfig.debug){
				trace("   ------------------------------------");
				trace("   [ ... Network Status: "+$status+" ... ]");
				trace("   ------------------------------------");
				shellApi.log("Network Status: "+$status);
			}
			_networkAvailable = $status;
		}

		private function onTestStatus(response:PopResponse):void
		{
			if (response.data) {
				if (response.data.hasOwnProperty('feature_status')) {
					if(response.data.feature_status == "on"){
						// test mode is set to on, start up smartFox and turn on test mode (for ant farm)
						if(AppConfig.debug){
							trace("   ---------------------------------");
							trace("   [ ... SmartFox TEST enabled ... ]");
							trace("   ---------------------------------");
						}
						TEST_MODE_ON = true;
						connect();
					}
				}
			}
		}
		
		/**
		 * ########## Connection Methods and Handlers ########################################################################################################
		 */
		
		public function connect(softCapped:Boolean = false):void
		{
			this.softCapped = softCapped;
			
			if(!_networkMonitored){
				monitorNetwork();
			}
			
			// create failsafe timeout timer set for 10 seconds
			_timeoutTimer = new Timer(TIMOUT_DURATION * 1000, 1);
			_timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeoutConnection);
			_timeoutTimer.start();

			// first check if server is available or down for maintenence
			if(_networkAvailable){
				shellApi.siteProxy.retrieve(DataStoreRequest.featureStatusRequest('smartfox'), onLiveStatus);
			} else {
				onSFSLoginError(new SFSEvent("network", {popupMsg:"Network is not available! Please connect to the internet."}));
			}
		}
		
		private function confirmGatewayConnection():Boolean{
			// TODO: Create a check for the AMFPHPGateway -- and reconnect if necessary
			//shellApi.siteProxy.AMFPHPGateWayReady.add
			return true;
		}
		
		private function timeoutConnection($event:TimerEvent):void{
			shellApi.track(TRACK_SFS_ERROR, "login error: timed out");
			onSFSLoginError(new SFSEvent("timeout", {popupMsg:"Your connection timed out, please try again later."}));
		}
		
		private function onLiveStatus(response:PopResponse):void{
			if(AppConfig.debug)
				shellApi.log("onLiveStatus: "+response);
			if (response.data) {
				if (response.data.hasOwnProperty('feature_status')) {
					if(response.data.feature_status == "on"){
						if(AppConfig.debug){
							trace("   ---------------------------------");
							trace("   [ ... SmartFox LIVE enabled ... ]");
							trace("   ---------------------------------");
						}
						connectSmartFox();
					} else {
						// live server is set to off - thus down for maintenence
						onSFSLoginError(new SFSEvent("maint", {popupMsg:"Server is down for maintenence, please try again later."}));
					}
				}
			} else {
				if(AppConfig.debug){
					trace("   ----------------------------------");
					trace("   [ ... No feature_status Data ... ]");
					trace("   ----------------------------------");
				}
				shellApi.track(TRACK_SFS_ERROR, "feature status NA");
			}
		}
		
		private function connectSmartFox():void{
			smartFox.useBlueBox = HTTP_ENABLED;
			
			// setup connection listeners
			smartFox.addEventListener(SFSEvent.CONNECTION, onSFSConnect);
			smartFox.addEventListener(SFSEvent.CONNECTION_ATTEMPT_HTTP, onSFSConnectHTTP);
			smartFox.addEventListener(SFSEvent.CONNECTION_LOST, onSFSDisconnect);

			// make connection to smartFox
			if(!SFS_LOCAL_TEST){
				
				var hostString:String;
				if(PlatformUtils.isMobileOS)
				{
					hostString = shellApi.siteProxy.commData.sfsHost;
				}
				else
				{
					hostString = SFS_LIVE_ADDRESS;
					/*
					if(AppConfig.debug || !onLiveSite())
					{
						hostString = SFS_DEV_ADDRESS;
					}
					else
					{
						hostString = SFS_LIVE_ADDRESS;
					}
					*/
				}
				
				//Used in conjunction with the dev console (setSFSOverride/getSFSOverride)
				//to test different SmartFox servers at runtime.
				//SmartFoxManager.OverrideHost has a setter to limit it to an empty string or valid server.
				if(overrideHost.length > 0)
					hostString = overrideHost;
				
				if(AppConfig.debug){
					shellApi.log("connecting to: "+hostString+":"+SFS_PORT+" zone: "+AppConfig.multiplayerZone);
					trace("   ---------------------------------");
					trace("   connecting to: "+hostString+":"+SFS_PORT+" zone: "+AppConfig.multiplayerZone);
					trace("   ---------------------------------");
				}
				
				smartFox.connect( hostString, SFS_PORT );
			} else {
				smartFox.connect( SFS_LOCAL_ADD, SFS_PORT );
			}
		}
		
		public function get OverrideHost():String
		{
			return overrideHost;
		}
		
		public function set OverrideHost(host:String):void
		{
			if(host.substr(host.length-15,15) == ".poptropica.com")
			{
				overrideHost = host;
				if(smartFox.isConnected || smartFox.isJoining)
				{
					smartFox.disconnect();
					if(DataUtils.isValidStringOrNumber(host))
						smartFox.connect(host, SFS_PORT);
				}
			}
		}
		
		private function onLiveSite():Boolean{
			if(AppConfig.applicationUrl.indexOf("www.poptropica.com") >= 0){
				return true;
			}
			
			if(AppConfig.applicationUrl.indexOf("static.poptropica.com") >= 0){
				return true;
			}
			
			return false;
		}
		
		protected function onSFSConnect(event:SFSEvent):void
		{
			// stop and remove the timeOutTimer.
			if(_timeoutTimer){
				_timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timeoutConnection);
				_timeoutTimer.stop();
				_timeoutTimer = null;
			}
			
			if(event.params.success){
				// trash connection listeners
				smartFox.removeEventListener(SFSEvent.CONNECTION, onSFSConnect);
				smartFox.removeEventListener(SFSEvent.CONNECTION_ATTEMPT_HTTP, onSFSConnectHTTP);
				
				// setup login listeners
				smartFox.addEventListener(SFSEvent.LOGIN, onSFSLogin);
				smartFox.addEventListener(SFSEvent.LOGIN_ERROR, onSFSLoginError);
				
				// dispatch connect event
				connected.dispatch();
				
				// monitor app for deactivation
				shellApi.screenManager.stage.addEventListener(Event.DEACTIVATE, handleDeactivate);
				
				if(AppConfig.debug){
					shellApi.log("connected to "+smartFox.currentIp+":"+smartFox.currentPort);
				}
				
				// include client version
				var params:ISFSObject = new SFSObject();
				if(AppConfig.appVersionString){
					params.putUtfString(KEY_SFS_CLIENT_VERSION, AppConfig.appVersionString);
				} else {
					params.putUtfString(KEY_SFS_CLIENT_VERSION, "DEV");
				}
				
				// softcapped connection?
				params.putBool(KEY_SOFT_CAPPED, softCapped);
				
				// login to poptropica server using the profile's GUID if applicable
				var login:String = "";
				var myGUID:String = shellApi.profileManager.active.guid;
				
				if(myGUID != null){
					login = myGUID;
				}
				
				smartFox.send(new LoginRequest(login, "", AppConfig.multiplayerZone, params));
				
			} else {
				// contingent methods
				onSFSLoginError(event);
			}	
		}
		
		protected function onSFSLogin(event:SFSEvent):void
		{
			// trash login listeners
			smartFox.removeEventListener(SFSEvent.LOGIN, onSFSLogin);
			smartFox.removeEventListener(SFSEvent.LOGIN_ERROR, onSFSLoginError);
			
			// setup migration listeners
			smartFox.addEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
			smartFox.addEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
			smartFox.addEventListener(SFSEvent.USER_EXIT_ROOM, onUserExitRoom);
			
			// setup data listeners
			smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
			smartFox.addEventListener(SFSEvent.ROOM_VARIABLES_UPDATE, onRoomVars);
			smartFox.addEventListener(SFSEvent.USER_VARIABLES_UPDATE, onUserVars);
			smartFox.addEventListener(SFSEvent.ADMIN_MESSAGE, onAdminMessage);
			
			// Initialize UDP channel (for mobile only!)
			if(PlatformUtils.isMobileOS && UDP_ENABLED){
				smartFox.addEventListener(SFSEvent.UDP_INIT, onSFSUdp);
				smartFox.initUDP(new AirUDPManager(), shellApi.siteProxy.commData.sfsHost, SFS_PORT);
			}
			
			if(AppConfig.debug){
				shellApi.log("logged into: "+smartFox.currentZone);
				trace("   ---------------------------------");
				trace("   logged into: "+smartFox.currentIp+":"+smartFox.currentPort+" zone: "+smartFox.currentZone);
				trace("   ---------------------------------");
			}
			
			// if TEST_MODE_ON -- idle user on server so they do not get dropped for innactivity
			if(TEST_MODE_ON){ 
				idleMe();
			}
			
			loggedIn.dispatch();
			
			// attempt to send character data
			this.updateCharData();
			
			// listen for character look updates
			shellApi.profileManager.onLookSaved.add(this.updateCharData);
		}
		
		protected function onSFSLoginError(event:SFSEvent):void
		{
			// stop and remove the timeOutTimer
			if(_timeoutTimer){
				_timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timeoutConnection);
				_timeoutTimer.stop();
				_timeoutTimer = null;
			}
			
			if(event.params.popupMsg == null){
				
				if(event.params.errorCode != null){
					switch(event.params.errorCode){
						case 1:
							// requested zone does not exist
							event.params.popupMsg = "Could not connect to the server!";
							break;
						case 5:
							// zone is full
							event.params.popupMsg = "The server is full! Please try again later.";
							break;
						case 7:
							// server is full
							event.params.popupMsg = "The server is full! Please try again later.";
							break;
						case 8:
							// zone is currently inactive
							event.params.popupMsg = "Could not connect to the server!";
							break;
						case 10:
							// guest users not allowed in zone
							event.params.popupMsg = "Could not connect to the server!";
							break;
						default:
							event.params.popupMsg = event.params.errorMessage;
							break;
					}
					shellApi.track(TRACK_SFS_ERROR, "login error: code-"+event.params.errorCode);
					if(AppConfig.debug){
						shellApi.log("login error: code-"+event.params.errorCode);
					}
				} else {
					event.params.popupMsg = "Could not connect to the server!";
					shellApi.track(TRACK_SFS_ERROR, "login error: " + event.params.errorMessage);
				}
				
				
			}
			
			loginError.dispatch(event);
		}	
		
		public function idleMe($idle:Boolean = true):void{
			// hold connection to smartFox by sending a packet every 10 seconds
			if($idle && !_idleTimer && smartFox.isConnected){
				_idleTimer = new Timer(10000, 0); // TODO: Use something better than the Timer class - some kind of loop i can hook in to, this early in the process?
				_idleTimer.addEventListener(TimerEvent.TIMER, onIdle);
				_idleTimer.start();
				if(AppConfig.debug){
					trace("   ---------------------------------");
					trace("   [ ... SmartFox Idle enabled ... ]");
					trace("   ---------------------------------");
				}
			} else if(!$idle && _idleTimer){
				_idleTimer.stop();
				_idleTimer.removeEventListener(TimerEvent.TIMER, getStats);
				_idleTimer = null;
				if(AppConfig.debug){
					trace("   ----------------------------------");
					trace("   [ ... SmartFox Idle disabled ... ]");
					trace("   ----------------------------------");
				}
			}
		}
		
		private function onIdle($event:TimerEvent):void{
			smartFox.send(new ExtensionRequest(CMD_PLAYERIDLE));
		}
		
		/**
		 * ########## Data Methods and Handlers ########################################################################################################
		 */
		
		protected function onExtensionResponse(event:SFSEvent):void
		{
			var isfso:ISFSObject = event.params.params;
			
			switch(event.params.cmd){
				case CMD_ANT_RESPONSE:
					if(isfso.getUtfString(KEY_ANT_RESPONSE_TYPE) == "activate"){
						shellApi.log("SFSAntFarm :: "+isfso.getInt(KEY_ANT_NUM)+" ants activated out of "+isfso.getInt(KEY_USER_NUM)+" users.  Total Ants: "+isfso.getInt(KEY_ANT_TOTAL));
					} else if(isfso.getUtfString(KEY_ANT_RESPONSE_TYPE) == "deactivate"){
						shellApi.log("SFSAntFarm :: "+isfso.getInt(KEY_USER_NUM)+" ants cleared.");
					}
					break;
				case CMD_UPDATE_CHAR:
					charUpdated.dispatch();
					break;
				case CMD_GET_STATS:
					shellApi.log(isfso.getInt(KEY_TOTAL_PLAYERS)+" total players.");
					shellApi.log(isfso.getInt(KEY_TOTAL_ROOMS)+" total rooms.", null, false);
					shellApi.log(isfso.getInt(KEY_MIGRATIONS)+" total room migrations", null, false);
					shellApi.log(isfso.getInt(KEY_MIGRATIONS_PER_SECOND)+" room migrations per second.", null, false);
					break;
				default:
					extensionResponse.dispatch(event);
					break;
			}
		}
		
		/**
		 * TODO :: Supply definition
		 * @param $lookData
		 */
		public function updateCharData($lookData:LookData = null):void
		{
			try{
				//trace( this," :: updateCharData : given lookData is:" + $lookData );
				var params:ISFSObject = new SFSObject();
				var lookString:String;
				
				// attempt to get lookstring
				if( _lookConverter == null ) { _lookConverter = new LookConverter(); }
				
				if(!$lookData){
					lookString = _lookConverter.getLookStringFromLookData( _lookConverter.lookDataFromPlayerLook(shellApi.profileManager.active.look) );		
				} else {
					lookString = _lookConverter.getLookStringFromLookData($lookData);
				}
				
				
				if( DataUtils.validString(lookString) ){
					params.putUtfString(USER_CHAR_LOOK, lookString);
				} 
				
				/*else if(shellApi.player){
				lookString = new LookConverter().getLookString(shellApi.player);
				params.putUtfString(USER_CHAR_LOOK, lookString);
				}*/
				
				// attempt to get player name
				if( shellApi.profileManager.active.avatarFirstName != null && shellApi.profileManager.active.avatarLastName != null ){
					params.putUtfString(USER_CHAR_NAME, shellApi.profileManager.active.avatarFirstName+" "+shellApi.profileManager.active.avatarLastName);
				}
				
				// attempt to get special player abilities
				if( shellApi.profileManager.active.specialAbilities != null ){
					if( shellApi.profileManager.active.specialAbilities.length > 0 ){
						shellApi.logWWW("SmartFoxManager :: updateCharData - update char abilities: ");
						for(var i:Number=0;i< shellApi.profileManager.active.specialAbilities.length;i++)
							shellApi.logWWW(shellApi.profileManager.active.specialAbilities[i]);
						params.putUtfStringArray(USER_CHAR_ABILITIES, shellApi.profileManager.active.specialAbilities);
					}
				}
				
				if(smartFox.isConnected && smartFox.currentZone == AppConfig.multiplayerZone){
					smartFox.send(new ExtensionRequest(CMD_UPDATE_CHAR, params));
				}
			}
			catch(e:Error)
			{
				trace( this," :: Error :: updateCharData : error message: " + e );
			}
		}

		protected function onAdminMessage(event:SFSEvent):void{
			adminMessage.dispatch(event.params.message);
		}
		
		
		protected function onRoomVars(event:SFSEvent):void
		{
			roomVarsUpdated.dispatch(event);
		}
		
		protected function onUserVars(event:SFSEvent):void
		{
			userVarsUpdated.dispatch(event);
		}
		
		

		/**
		 * ########## Migration Methods and Handlers ########################################################################################################
		 */

		protected function onRoomJoin(event:SFSEvent):void
		{
			joinedRoom.dispatch(event);
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   <SFS> Room Joined: "+Room(event.params.room).name);
				trace("   ---------------------------------");
			}
		}
		
		protected function onUserEnterRoom(event:SFSEvent):void
		{
			userEnterRoom.dispatch(event);
		}
		
		protected function onUserExitRoom(event:SFSEvent):void
		{
			userExitRoom.dispatch(event);
		}
		
		public function leaveRoom():void{
			smartFox.send(new LeaveRoomRequest(smartFox.lastJoinedRoom));
		}
		
		/**
		 * ########## Disconnection Methods and Handlers #####################################################################################
		 */
		
		
		protected function handleDeactivate($event:Event):void
		{
			if(smartFox.isConnected && PlatformUtils.isMobileOS){
				disconnect();
			}
		}
		
		public function disconnect():void{
			smartFox.disconnect();
		}
		
		protected function onSFSDisconnect(event:SFSEvent):void
		{
			// trash connection listeners
			smartFox.removeEventListener(SFSEvent.CONNECTION, onSFSConnect);
			smartFox.removeEventListener(SFSEvent.CONNECTION_LOST, onSFSDisconnect);
			smartFox.removeEventListener(SFSEvent.CONNECTION_ATTEMPT_HTTP, onSFSConnectHTTP);
			
			// trash login listeners
			smartFox.removeEventListener(SFSEvent.LOGIN, onSFSLogin);
			smartFox.removeEventListener(SFSEvent.LOGIN_ERROR, onSFSLoginError);
			
			// trash migration listeners
			smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
			smartFox.removeEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
			smartFox.removeEventListener(SFSEvent.USER_EXIT_ROOM, onUserExitRoom);
			
			// trash data listeners
			smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
			smartFox.removeEventListener(SFSEvent.ROOM_VARIABLES_UPDATE, onRoomVars);
			smartFox.removeEventListener(SFSEvent.USER_VARIABLES_UPDATE, onUserVars);
			
			// trash idle/stats timers
			if(_statsTimer){
				_statsTimer.stop();
				_statsTimer.removeEventListener(TimerEvent.TIMER, getStats);
				_statsTimer = null;
			}
			
			if(_idleTimer){
				_idleTimer.stop();
				_idleTimer.removeEventListener(TimerEvent.TIMER, getStats);
				_idleTimer = null;
			}
			
			// trash app deactivation listener
			shellApi.screenManager.stage.removeEventListener(Event.DEACTIVATE, handleDeactivate);
			
			disconnected.dispatch();
			
			if(AppConfig.debug){
				trace("   --------------------------------");
				trace("   <SFS> Disconnected from smartfox");
				trace("   --------------------------------");
			}
		}
		
		
		
		/**
		 * ########## Developer Tools and Methods #####################################################################################
		 */
		
		public function getAnts($number:int = 1):void{
			var obj:ISFSObject = new SFSObject();
			obj.putInt(KEY_ANT_NUM, $number);
			
			smartFox.send(new ExtensionRequest(CMD_GET_ANTS, obj));
		}
		
		public function clearAnts():void{
			smartFox.send(new ExtensionRequest(CMD_CLR_ANTS));
		}
		
		public function updateLocation():void{
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(KEY_SCENE, shellApi.sceneName);
			obj.putUtfString(KEY_ISLAND, shellApi.island);
			smartFox.send(new ExtensionRequest(CMD_UPDATE_LOC, obj));
		}
		
		public function viewPort($on:Boolean = true):void{
			var obj:ISFSObject = new SFSObject();
			obj.putBool(KEY_VIEW_PORT_ON, $on);
			smartFox.send(new ExtensionRequest(CMD_VIEW_PORT, obj));
		}
		
		public function stats($loop:Boolean = false):void{
			if($loop){
				_statsTimer = new Timer(2000, 0);
				_statsTimer.addEventListener(TimerEvent.TIMER, getStats);
				_statsTimer.start();
			} else {
				if(_statsTimer){
					_statsTimer.stop();
					_statsTimer.removeEventListener(TimerEvent.TIMER, getStats);
					_statsTimer = null;
				}
				getStats();
			}
		}
		
		private function getStats(...p):void{
			smartFox.send(new ExtensionRequest(CMD_GET_STATS));
		}
		
		public function get isInRoom():Boolean{
			if(shellApi.smartFox.currentZone == AppConfig.multiplayerZone 
				&& shellApi.smartFox.isConnected 
				&& !shellApi.smartFox.isJoining){
				return true;
			} else {
				// signal a disconnect if the client seems to be not connected
				if(!shellApi.smartFox.isConnected || shellApi.smartFox.currentZone != AppConfig.multiplayerZone){
					disconnected.dispatch();
				}
				return false;
			}
		}
		
		// -------------- Properties -----------------------
		
		public var smartFox:SmartFox = new SmartFox();
		
		// smartfox connection signals
		public var connected:Signal = new Signal();
		public var loggedIn:Signal = new Signal();
		public var loginError:Signal = new Signal(SFSEvent);
		public var disconnected:Signal = new Signal();
		
		// smartfox migration signals
		public var joinedRoom:Signal = new Signal(SFSEvent);
		public var userEnterRoom:Signal = new Signal(SFSEvent);
		public var userExitRoom:Signal = new Signal(SFSEvent);
		
		// smartfox data signals
		public var extensionResponse:Signal = new Signal(SFSEvent);
		public var roomVarsUpdated:Signal = new Signal(SFSEvent);
		public var userVarsUpdated:Signal = new Signal(SFSEvent);
		public var adminMessage:Signal = new Signal(String);

		// other signals
		public var charUpdated:Signal = new Signal();  // when a player has updated user vars
		
		public function set uniqueID(value:String):void{ _uniqueID = value };
		private var _uniqueID:String;
		
		public var udpEnabled:Boolean;
		
		public var softCapped:Boolean; // cap player entrance at soft cap - by default
		
		private var _idleTimer:Timer;
		private var _statsTimer:Timer;
		private var _timeoutTimer:Timer;
		
		private var _networkAvailable:Boolean;
		private var _networkMonitored:Boolean;
		
		private var _perfMonitor:PerformanceMonitorSystem;
		
		private var _lookConverter:LookConverter;
		
		
		
		/**
		 * ########## Depreciated methods and handlers #####################################################################################
		 */

		protected function onSFSConnectHTTP(event:SFSEvent):void
		{
			if(AppConfig.debug)
				trace("<SFS> Socket connectoin failed - attempting to connect via http (bluebox).");
		}
		
		protected function onSFSUdp(event:SFSEvent):void
		{
			// trash udp listener
			smartFox.removeEventListener(SFSEvent.UDP_INIT, onSFSUdp);
			
			if (event.params.success){
				udpEnabled = true;
			}
		}
	}
}