package game.proxy.browser 
{
	import com.poptropica.AppConfig;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.Dictionary;
	
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.data.CommunicationData;
	import game.data.character.LookData;
	import game.data.character.PartDefaults;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.data.profile.MembershipStatus;
	import game.data.ui.card.CardSet;
	import game.managers.GatewayManager;
	import game.managers.WallClock;
	import game.proxy.DataStoreProxyPop;
	import game.proxy.DataStoreRequest;
	import game.proxy.GatewayConstants;
	import game.proxy.PopDataStoreRequest;
	import game.proxy.PopGateway;
	import game.scene.template.SceneUIGroup;
	import game.util.Base64;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.TribeUtils;
	import game.util.Utils;
	
	/**
	 * PopSiteProxy provides Poptropica specific communication services.
	 * @author Rich Martin
	 * 
	 */	
	public class DataStoreProxyPopBrowser extends DataStoreProxyPop
	{
		// flag names for resetIsland()
		public static const RESET_AS2_ISLAND:Boolean = true;
		public static const RESET_AS3_ISLAND:Boolean = false;
		
		public static const LOOKCLOSET_META_ITEM_ID:uint	= 5020;
		private var _campaignCallback:Function;
		
		public function DataStoreProxyPopBrowser() 
		{
			super();
		}
		
		//// ACCESSORS ////
		
		private function get memberStatusURL():String	{ return commData.memberStatusURL; }
		private function get embedInfoURL():String		{ return commData.embedInfoURL; }
		private function get changeLookURL():String		{ return commData.changeLookURL; }
		private function get changePasswordURL():String	{ return commData.changePasswordURL; }
		private function get playerCreditsURL():String	{ return commData.playerCreditsURL; }
		
		//// PUBLIC METHODS ////
		
		/**
		 * Prepares the instance for active duty, configuring itself with the
		 * hosts and URLs provided by <code>commData</code>. When ready,
		 * the instance will dispatch a <code>Signal</code> via AMFPHPGateWayReady.
		 * @param commData	An XML document of type <code>communicationConfig</code>
		 */	
		override public function init( commData:CommunicationData ):void 
		{
			_gatewayManager = new GatewayManager(shellApi);
			_commConfig = commData;
			
			//shellApi.logWWW("SiteProxy init, here's the transit token");
			
			// NOTA BENE: Since ProfileManager hasn't been created this early in the Startup Sequence,
			// GatewayManager's authconfig will be empty to start with.
			// Shell must freshen the data during the GET_PROFILE section of the startup sequence
			
			// TODO: re-examine this bit of logic
			// clear the flag which gets set by the travelmap to trigger "new island" business
			
			// BROWSER SPECIFIC
			this.checkCharToken();
			
			// request secure host
			super.requestSecureHost();
		}
		
		public override function call(transactionData:DataStoreRequest, callback:Function=null):int
		{
			var waitTime:uint = transactionData.hasOwnProperty('requestTimeoutMillis') ? transactionData.requestTimeoutMillis : 0;
			var args:Object;
			
			if (DataStoreRequest.STORAGE_REQUEST_TYPE == transactionData.requestType) {
				switch (transactionData.dataDescriptor) {
					case DataStoreRequest.PLAYER_LOOK:
						savePlayerLook(transactionData.requestData.look, callback);
						return 0;
						
					case DataStoreRequest.COMPLETE_EVENT:
						return completeEvent(transactionData.requestData.events, transactionData.requestData.islandName, callback);
					case DataStoreRequest.DELETE_EVENT:
						return deleteEvent(transactionData.requestData.events, transactionData.requestData.islandName, callback);
					case DataStoreRequest.USER_FIELDS:
						return setUserField(transactionData.requestData.fieldID, transactionData.requestData.fieldValue, transactionData.requestData.islandName, callback);
					case DataStoreRequest.SCENE_VISIT:
						return storeSceneVisit(transactionData.requestData.scene, transactionData.requestData.playerX, transactionData.requestData.playerY, transactionData.requestData.playerDirection, callback);
						
					case DataStoreRequest.CLOSET_LOOK:
						saveLookToCloset(transactionData.requestData.lookData, callback);
						return 0;
					case DataStoreRequest.DELETE_CLOSET_LOOK:
						deleteLookFromCloset(transactionData.requestData.lookItemID, callback);
						return 0;
						
					case DataStoreRequest.SCENE_PHOTO:
						takePhoto(transactionData.requestData.photoID, transactionData.requestData.setID, transactionData.requestData.lookData);
						return 0;
						
					case DataStoreRequest.GAIN_ITEM:
						return getItem(transactionData.requestData.itemName, transactionData.requestData.itemType, callback); 
					case DataStoreRequest.REMOVE_ITEM:
						return removeItem(transactionData.requestData.itemName, transactionData.requestData.itemType, callback);
						
					case DataStoreRequest.ISLAND_FINISH:
						return completedIsland(transactionData.requestData.islandName, callback);
						
					case DataStoreRequest.PASSWORD_CHANGE:
						changePassword(transactionData.requestData.login, transactionData.requestData.pass_hash, transactionData.requestData.pass_hash_new, transactionData.requestData.new_password, callback);
						return 0;
						
					case DataStoreRequest.PARENTAL_EMAIL:
						if ('insertParentEmail' == transactionData.requestData.action) {
							setParentalEmail(transactionData.requestData.parent_email, callback);
							return 0;
						}
						return -1;
						
					case DataStoreRequest.HIGH_SCORE:
						saveHighScore(transactionData.requestData.game, transactionData.requestData.score, callback);
						return 0;
						
					default:
						args = extractStorageArgs(transactionData);
						if (args != -1 && !args.methodArg) {	// we don't recognize this request as either a connection or gateway method
							return super.call(transactionData, callback);
						}
						break;
				}
			} else if (DataStoreRequest.RETRIEVAL_REQUEST_TYPE == transactionData.requestType) {
				switch (transactionData.dataDescriptor) {
					case PopDataStoreRequest.MEMBER_STATUS:
						getMemberStatus(callback);
						return 0;
						
					case DataStoreRequest.PARENTAL_EMAIL:
						if ('hasParentEmail' == transactionData.requestData.action) {
							getParentalEmailStatus(callback);
							return 0;
						}
						return -1;
						
					case DataStoreRequest.PLAYER_CREDITS:
						getPlayerCredits(transactionData.requestData.limit, transactionData.requestData.offset, callback);
						return 0;
						
					case PopDataStoreRequest.STORE_CARDS:
						getStoreCards(callback);
						return 0;
						
					case PopDataStoreRequest.AVATAR_DATA:
						if (!transactionData.requestData) {
							transactionData.requestData = new URLVariables();
						}
						if (!transactionData.requestData.hasOwnProperty('lookupUser')) {
							transactionData.requestData.lookupUser = activeProfile.login;
						}
						args = extractRetrievalArgs(transactionData);
						break;
					
					case DataStoreRequest.CLOSET_LOOKS:
						getClosetLooks(transactionData.requestData.numLooks, transactionData.requestData.offset, callback);
						return 0;
						
					case DataStoreRequest.USER_FIELDS:
						if (transactionData.requestData.fieldID ) {
							return getUserField(transactionData.requestData.fieldID, transactionData.requestData.islandName, callback);
						} else if (transactionData.requestData.fieldIDs ) {
							return getUserFields(transactionData.requestData.fieldIDs, transactionData.requestData.islandName, callback);
						}
						break;
					
					default:
						args = extractRetrievalArgs(transactionData);
						if (!args.methodArg) {	// we don't recognize this request as either a connection or gateway method
							return super.call(transactionData, callback);
						}
						break;
				}
			} else {
				trace("DataStoreProxy::call() Unknown requestType", transactionData.requestType);
			}
			
			return args != -1 && args.methodArg ? sendToGatewayWithTimeout(args.methodArg, args.payloadArg, callback, waitTime) : -1;
		}
		
		protected override function extractStorageArgs(transactionData:DataStoreRequest):Object
		{
			var data:URLVariables = transactionData.requestData;
			var args:Object = {methodArg:null, payloadArg:null};
			var payload:Array = [];
			
			switch (transactionData.dataDescriptor) {
				case DataStoreRequest.USER_PREFERENCES:
					args.methodArg	= PopGateway.SET_PLAYER_FIELDS;
					payload['musicVolume']		= data.musicVolume;
					payload['effectsVolume']	= data.sfxVolume;
					payload['dialogSpeed']		= data.dialogSpeed;
					payload['qualityLevel']		= data.qualityLevel;
					//		payload['language']			= data.preferredLanguage;
					args.payloadArg	= payload;
					break;
				case DataStoreRequest.ISLAND_START:
					if (activeProfile.isGuest || isNaN(activeProfile.dbid)) 
					{
						var charLSO:SharedObject = ProxyUtils.getAS2LSO('Char');
						var island:String = transactionData.requestData.islandName;
						if (charLSO.data) {
							if (!charLSO.data.hasOwnProperty('islandTimes')) {
								charLSO.data.islandTimes = {};
							}
							if (!charLSO.data.islandTimes[island]) {
								charLSO.data.islandTimes[island] = {};
							}
							charLSO.data.islandTimes[island].start = Math.round(new Date().time / 1000);
							charLSO.flush();
						}
						return -1;
					}
					// RLH: "IslandStarted" already called for all users in SendStartedIsland.as line 40
					// this is only getting called for registered users here
					//shellApi.track("IslandStarted", shellApi.island, null, "IslandEvent");
					args.methodArg	= PopGateway.STARTED_ISLANDS;
					var payloadObj:Object = {};
					payloadObj[transactionData.requestData.islandName] = Math.round(new Date().time / 1000);
					args.payloadArg	= payloadObj;
					break;
				case DataStoreRequest.ISLAND_RESET:
					args.methodArg	= PopGateway.RESET_ISLAND;
					args.payloadArg	= data.islandName;
					break;
				
				default:
					args = super.extractStorageArgs(transactionData);
					break;
			}
			return args;
		}
		
		protected override function extractRetrievalArgs(transactionData:DataStoreRequest):Object
		{
			var data:URLVariables = transactionData.requestData;
			var args:Object = {methodArg:null, payloadArg:null};
			var payload:Array = [];
			
			switch (transactionData.dataDescriptor) {
				case DataStoreRequest.SERVER_STATUS:
					args.methodArg	= 'getServerStatus';
					break;
				case PopDataStoreRequest.ISLAND_INFO:
					args.methodArg	= PopGateway.GET_ISLAND_INFO;
					args.payloadArg	= data.islands;
					break;
				case DataStoreRequest.USER_TRIBE:
					args.methodArg	= PopGateway.GET_PLAYER_FIELDS;
					args.payloadArg	= [TribeUtils.TRIBE_FIELD];
					break;
				case DataStoreRequest.USER_PREFERENCES:
					args.methodArg	= PopGateway.GET_PLAYER_FIELDS;
					args.payloadArg	= ['musicVolume', 'effectsVolume', 'dialogSpeed', 'qualityLevel'];//, 'language'];
					break;
				
				default:
					args = super.extractRetrievalArgs(transactionData);
					break;
			}
			return args;
		}
		
		//////////////////////////////////////// PLAYER ////////////////////////////////////////
		
		// TODO: convert this to AMFPHP
		/**
		 * Determines membership status of current user.
		 * If gateway has been established requests status from server.
		 * @param callback - handler for server response, if not specified defaults to <code>onMemberStatus</code>
		 */
		public function getMemberStatus(callback:Function = null):void 
		{
			callback = Command.create( onMemberStatus, callback );
			if (gatewayManager) 
			{
				var postVars:URLVariables = new URLVariables();
				gatewayManager.makeAuthorizedConnection(secureHost + memberStatusURL, postVars, callback);
			} 
			else 
			{
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = "gateway manager is null";
				callback.apply(null, [response]);
			}
		}
		
		/**
		 * Handler for server response regarding membership status.
		 * Updates active profile with received membership status.
		 * @param response - response form Pop server, contains data regarding membership status
		 */
		public function onMemberStatus(response:PopResponse, callback:Function = null):void 
		{
			if (!response.succeeded) 
			{
				trace("SiteProxy::onMemberStatus():", response.toString());
			}
			activeProfile.memberStatus = MembershipStatus.instanceFromURLVariables(response.data as URLVariables);
			
			// save to lso
			var lso:SharedObject = ProxyUtils.as2lso;
			lso.data.mem_status = MembershipStatus.getAS2Status(activeProfile.memberStatus.statusCode);
			lso.flush();
			
			if( callback != null ) { callback(response); }
		}
		
		protected function changePassword(login:String, pass_hash:String, pass_hash_new:String, new_password:String, callback:Function=null):void
		{
			if (!callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables();
				postVars.login			= login;
				postVars.pass_hash		= pass_hash;
				postVars.pass_hash_new	= pass_hash_new;
				// for Pop 2.0 compatibility
				postVars.new_password	= new_password;
				gatewayManager.makeConnection(secureHost + changePasswordURL, postVars, callback);
			} else {
				respondWithRegrets("gateway manager is null", callback);
			}
		}
		
		protected function getParentalEmailStatus(callback:Function=null):void
		{
			if (!callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				gatewayManager.makeAuthorizedConnection(secureHost + commData.parentalEmailURL, new URLVariables('action=hasParentEmail'), callback);
			} else {
				respondWithRegrets("gateway manager is null", callback);
			}
		}
		
		protected function setParentalEmail(newEmail:String, callback:Function=null):void
		{
			if (!callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables('action=insertParentEmail');
				postVars.parent_email = newEmail;
				gatewayManager.makeAuthorizedConnection(secureHost + commData.parentalEmailURL, postVars, callback);
			} else {
				respondWithRegrets("gateway manager is null", callback);
			}
		}
		
		protected function getStoreCards(callback:Function):void
		{
			// set up url with secure host
			var request:URLRequest = new URLRequest(this.shellApi.siteProxy.secureHost + "/list_redeemable_items.php");
			var vars:URLVariables = new URLVariables;
			// need all cards so we can properly display store cards already earned
			vars.all_active = "Y";
			vars.cats = "2003|2004|2011|2012|2013|2014|2015|2016|2017|2018|2019";
			// for mobile
			if (PlatformUtils.isMobileOS)
			{
				// get app version number (has form "0.0.0")
				var appVersion:String = AppConfig.appVersionNumber;
				trace("current app version number: " + appVersion);
				vars.app_version = appVersion;
			}
			request.data = vars;
			var urlLoader:URLLoader = new URLLoader();
			
			// add listeners
			urlLoader.addEventListener(Event.COMPLETE, callback);
			
			// get data
			request.method = URLRequestMethod.POST;
			urlLoader.load(request);
		}
		
		protected function getPlayerCredits(limit:uint, offset:uint, callback:Function=null):void
		{
			if (!callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables();
				postVars.limit	= limit;
				postVars.offset	= offset;
				postVars.name	= activeProfile.login;
				gatewayManager.makeAuthorizedConnection(secureHost + commData.playerCreditsURL, postVars, callback);
			} else {
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = "gateway manager is null";
				callback.apply(null, [response]);
			}
		}
		
		protected function saveHighScore(gameName:String, score:String, callback:Function=null):void
		{
			if (!callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables('game='+gameName+'&score='+score);
				gatewayManager.makeAuthorizedConnection(secureHost + commData.highScoreURL, postVars, callback);
			} else {
				respondWithRegrets("gateway manager is null", callback);
			}
		}
		
		protected function savePlayerLook(lookString:String, callback:Function=null):void
		{
			if (!callback) {
				callback = tracePopResponse;
			}
			
			// send converted look data to server
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables();
				postVars.look = lookString;
				gatewayManager.makeAuthorizedConnection(secureHost + changeLookURL, postVars, callback);
			} else {
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = "gateway manager is null";
				callback.apply(null, [response]);
			}
		}
		
		// TODO :: Save special ability function
				
		/**
		 * Default handler for <code>getEmbedInfo()</code>.
		 * It extracts the requested player data received from the webserver
		 * and copies those values into the player's active profile.
		 * 
		 * If partKeyLibrary's defined is used with look conversion.
		 * This causes incoming part ids to be checked for frame numbers.
		 * 
		 * @param response	A PopResponse containing the requested player data
		 * @see game.data.comm.PopResponse
		 * @see game.data.profile.ProfileData
		 */	
		public function onEmbedInfo(response:PopResponse):void 
		{
			var lookString:String;
			var firstName:String;
			var lastName:String;
			var summary:String = 'Error retrieving embedInfo';
			
			if (response.succeeded) 
			{
				if (response.data) 
				{
					if (response.data.error) 
					{
						summary = "Error from server: " + response.data.error;
					} 
					else 
					{
						lookString = response.data.look;
						if (response.data.hasOwnProperty('fname')) {
							firstName = response.data.fname;
						} else if (response.data.hasOwnProperty('first_name')) {
							firstName = response.data.first_name;
						}
						if (response.data.hasOwnProperty('lname')) {
							lastName = response.data.lname;
						} else if (response.data.hasOwnProperty('last_name')) {
							lastName = response.data.last_name;
						}
						
						summary = "Success retrieving embedInfo:" + response.data.toString();
					}
				}
			} 
			else 
			{
				summary += ': ' + response.error;
			}
			
			activeProfile.avatarFirstName = DataUtils.useString(firstName, activeProfile.avatarFirstName);
			activeProfile.avatarLastName  = DataUtils.useString(lastName,  activeProfile.avatarLastName);
			
			if(lookString != null)
			{
				activeProfile.look = _lookConverter.playerLookFromLookString(shellApi, lookString, null, partKeyLibrary, activeProfile);
			}
			trace(this," ::onEmbedInfo : summary: " + summary);
		}

		//////////////////////////////////////// CLOSET ////////////////////////////////////////
		
		/**
		 * Retrieves a number of lookStrings from a member's account on the server. The list of looks will be returned in reverse-chronological order.
		 * @param callback	A function which takes a <code>PopResponse</code> as its only argument. The list will be found in <code>response.data.closetLooks</code>.
		 * @param numLooks	How many looks should be returned. Defaults to the maximum number of looks, which is 30. Fewer may be returned.
		 * @param offset	An offset from the zeroth look in the list. Defaults to zero.
		 * 
		 */	
		protected function getClosetLooks(numLooks:uint, offset:uint, callback:Function=null):void
		{
			var response:PopResponse;
			//	if (activeProfile.isMember) {
			var postVars:URLVariables = new URLVariables();
			postVars.look_types_array = LOOKCLOSET_META_ITEM_ID;
			postVars.quantity = numLooks;
			postVars.offset = offset;
			
			if (gatewayManager) 
			{
				gatewayManager.makeAuthorizedConnection(secureHost + commData.getClosetLooksURL, postVars, Command.create(onClosetLooksReceived, callback));
			} 
			else
			{
				// something must have gone wrong if we had to create a response
				response = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = "gateway manager is null";			
				if (callback) 
				{
					callback(response);
				} 
				else 
				{
					tracePopResponse(response, "SiteProxy::getClosetLooks():");
				}
			}
			//	} else {	// player is either a guest or a registered non-member
			//		response = new PopResponse(GatewayConstants.AMFPHP_NOT_MEMBER);
			//		response.error = "Non-members lack closet privileges.";
			//	}
		}
		
		/**
		 * Handler for server response regarding closet looks.
		 * Default handler for <code>getClosetLooks</code>.
		 * @param response
		 * @param callback
		 */
		private function onClosetLooksReceived(response:PopResponse, callback:Function):void
		{
			trace(this," :: onClosetLooksReceived():", response.toString());
			var lookDatas:Array = [];
			if (response.succeeded) 
			{
				if (response.data) 
				{
					trace(this," :: onClosetLooksReceived() : data received");
					// the JSON should look like this: {lookItemID:[lookString,captionNum], lookItemID:[lookString,captionNum],...}
					var lookStrings:Object = JSON.parse(response.data.json);//new JsonDecoder(response.data.json, true).getValue() as Object;
					for (var itemID:String in lookStrings) 
					{
						var theData:Object = {};
						theData[itemID] = _lookConverter.lookDataFromLookString(lookStrings[itemID][0]);
						lookDatas.push(theData);
					}
					// now our closetLooks is of the form: [{lookItemID:lookData}, {lookItemID:lookData}, ...]
					response.data = new URLVariables();
					response.data.closetLooks = lookDatas;
				} 
				else 
				{
					trace(this," :: onClosetLooksReceived() : Although the request succeeded, the response contained no data. Go figure.");
				}
			}
			else 
			{
				trace(this," :: onClosetLooksReceived() : Better luck next time, that response failed");
			}
			
			if (callback) 
			{
				callback(response);
			} 
			else 
			{
				tracePopResponse(response," DataStoreProxyPopBrowser :: onClosetLooksReceived() : has no callback for");
			}
		}
		
		/**
		 * Accepts a <code>LookData</code>, converts it to a legacy lookString (format 0), and stores it in the (member) player's account. 
		 * @param lookData	The <code>LookData</code> describing the look to be saved.
		 * @param callback	A function which takes a <code>PopResponse</code> as its only argument.
		 */	
		protected function saveLookToCloset(lookData:LookData=null, callback:Function=null):void
		{
			var lookString:String = (lookData != null) ? _lookConverter.getLookStringFromLookData(lookData) : _lookConverter.assertLookString(shellApi);
			if ("" == lookString) {
				throw new Error("SiteProxy::saveLookToCloset(): Could not get player's look string");
			}
			var postVars:URLVariables = new URLVariables();
			postVars.look		= lookString;
			postVars.look_type	= LOOKCLOSET_META_ITEM_ID;
			
			// if no callback is given, assign default handler
			if( callback == null ) { callback = this.onLookSavedToCloset; }
			
			//	if (activeProfile.isMember) {
			if (gatewayManager) 
			{
				gatewayManager.makeAuthorizedConnection(secureHost + commData.saveClosetLookURL, postVars, callback);
			} 
			else
			{
				// something must have gone wrong if we had to create a response
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.data = new URLVariables('look=' + lookString);
				response.error = "gateway manager is null";
				callback(response);
			}
			//	} else {	// player is either a guest or a registered non-member
			// a la AS2 wardrobe.fla, we are supposed to offer membership here
			//		response = new PopResponse(GatewayConstants.AMFPHP_NOT_MEMBER);
			//		response.data = new URLVariables('look=' + lookString);
			//		response.error = "Non-members lack closet privileges.";
			//	}
		}
		
		private function onLookSavedToCloset( response:PopResponse ):void
		{
			trace(this," :: onLookSavedToCloset :  PopResponse:", response.data.answer, response.succeeded, response.status, response.error, response.toString());
			
			//There is no available item ID. All closet "slots" (1-30) are filled.
			if(response.status == GatewayConstants.AMFPHP_NO_AVAILABLE_ITEM)
			{
				// closet is full
			}
			else if(response.status == GatewayConstants.AMFPHP_UNVALIDATED_USER)
			{
				// guest attempted to save a look to a closet they don't have.
			}
			else if(response.status == GatewayConstants.AMFPHP_PROBLEM)
			{
				// error
			}
			else
			{
				// if success save game
				this.shellApi.saveGame();
			}
		}
		
		/**
		 * Clears one of the 30 available 'slots' in a member's closet.
		 * @param lookItemID	The item ID of the slot to clear. IDs range from 11583 to 11612
		 * @param callback		A function which takes a <code>PopResponse</code> as its only argument.
		 * 
		 */	
		protected function deleteLookFromCloset(lookItemID:String, callback:Function=null):void
		{
			var postVars:URLVariables = new URLVariables();
			postVars.look_item_id = lookItemID;
			var response:PopResponse;
			if (gatewayManager) {
				gatewayManager.makeAuthorizedConnection(secureHost + commData.deleteClosetLookURL, postVars, callback);
			} else {
				response = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.data = new URLVariables('lookItemID=' + lookItemID);
				response.error = "gateway manager is null";
			}
			
			if (response) {			// something must have gone wrong if we had to create a response
				if (callback) {
					callback(response);
				} else {
					tracePopResponse(response, "SiteProxy::deleteLookFromCloset():");
				}
			}
		}
		
		//////////////////////////////////////// PHOTOS ////////////////////////////////////////
		
		// TODO: get the ProfileManager involved, better mobile device support
		/**
		 * Stores a photo record in a registered player's account by POSTing
		 * the photo's ID and the player's current lookstring
		 * to /take_photo.php.
		 * @param photoID	The number which identifies the photo.
		 * @param setId
		 * @param lookData
		 */	
		protected function takePhoto(photoID:String, setId:String, lookData:LookData = null):void 
		{
			var response:PopResponse;
			var postVars:URLVariables = new URLVariables();
			var lookString:String
			if( lookData != null )
			{
				lookString = _lookConverter.getLookStringFromLookData(lookData);
			}
			else
			{
				lookString = _lookConverter.assertLookString(shellApi);
			}
			if ("" == lookString) {
				var pd:PartDefaults = new PartDefaults();
				lookString = _lookConverter.getLookStringFromLookData(pd.randomLookData());
			}
			
			postVars.look = lookString;
			postVars.look_item_id = photoID;
			
			if (activeProfile.isGuest)
			{	// these responses are basically lifted from AS2
				trace(this," :: takePhoto : When a guest is photographed, the photoID (" + photoID + " in this case) is appended to the photos Array in the guest's 'Char' LSO.");
				syncPhotoToAS2LSO(photoID);
				response = new PopResponse(GatewayConstants.AMFPHP_SUCCESS);
				response.data = new URLVariables('answer=ok&look_item_id=' + photoID);
				onPhotoTaken(response);
			} 
			else 
			{
				if (gatewayManager) 
				{
					gatewayManager.makeAuthorizedConnection(secureHost + commData.takePhotoURL, postVars, onPhotoTaken);
				} 
				else 
				{
					response = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
					response.data = new URLVariables('look_item_id=' + photoID);
					response.error = 'gateway manager is null';
					onPhotoTaken(response);
				}
			}
		}
		
		private function onPhotoTaken(response:PopResponse):void 
		{
			if(response.data)
			{
				if(response.data.vars)
				{
					var photoID:String = response.data.vars.look_item_id;
					if (photoID) {
						shellApi.logWWW("onPhotoTaken():", response.toString(), "for photo id", photoID);
						if (!response.error) {
							//(shellApi.sceneManager._groupManager.getGroupById('ui') as SceneUIGroup).showPhotoNotification();
						}
					}
					
					// There an inventory item named
					// "Photo Feed" whose id is always this value
					const PHOTO_FEED_ITEM_ID:uint = 12003;
					saveFeedItem(PHOTO_FEED_ITEM_ID);
				}
			}
		}
		
		private function saveFeedItem(itemID:uint, callback:Function=null):void 
		{
			var response:PopResponse;
			var postVars:URLVariables = new URLVariables();
			var lookString:String = _lookConverter.assertLookString(shellApi);
			if ("" == lookString) {
				var pd:PartDefaults = new PartDefaults();
				lookString = _lookConverter.getLookStringFromLookData(pd.randomLookData());
			}
			postVars.look = lookString;
			postVars.look_item_id = itemID;
			
			if (gatewayManager) {
				gatewayManager.makeAuthorizedConnection(secureHost + commData.saveFeedItemURL, postVars, callback);
			} else {
				response = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = 'gateway manager is null';
			}
			
			if (response) {
				if (callback) {
					callback(response);
				} else {
					tracePopResponse(response, "SiteProxy::saveLookToCloset():");
				}
			}
		}
		
		/**
		 * Queries the webserver for any unusual conditions which may require
		 * the player to quit the game.
		 * <p>For instance, if the database is going offline for maintenance,
		 * it is important to force a logout so that no game state is lost.</p>
		 * @param callback	A reference to a function to be called when the operation is complete.
		 */	
		protected function getServerStatus(callback:Function):int 
		{
			if (activeProfile.isGuest) {
				trace(this," :: getServerStatus : Won't check server status for a guest");
				return -1;
			}
			return sendToGateway('getServerStatus', null, callback);
		}
		
		protected function storeSceneVisit(scene:Scene, playerX:Number, playerY:Number, playerDirection:String, callback:Function=null):int 
		{
			var islandName:String = ProxyUtils.convertIslandToServerFormat(shellApi.island);
			var sceneName:String = ProxyUtils.convertSceneToServerFormat(scene);
			var payload:Array = [];
			payload['island']		= islandName;
			payload['scene']		= sceneName;
			payload['x']			= playerX;
			payload['y']			= playerY;
			payload['direction']	= CharUtils.DIRECTION_LEFT == playerDirection ? 'L' : 'R';
			
			shellApi.logWWW("SiteProxy :: storeSceneVisit(): sending", payload['island'], payload['scene'], payload['x'], payload['y'], payload['direction']);
			if (null == callback) {
				callback = onSceneVisitStored;
			}
			return sendToGateway('logSceneVisit', payload, callback);
		}
		
		private function onSceneVisitStored(response:PopResponse):void {
			tracePopResponse(response, "SiteProxy::onSceneVisitStored()");
		}
				
		//////////////////////////////////////// SETTINGS PANEL ////////////////////////////////////////
		
		/**
		 * Tries to obtain player's preferred values for options in the Settings Popup.
		 * @param callback	Reference to a Function which will handle the result. If null, results will simply be printed to the console.
		 * @return Boolean indicating whether player is a guest
		 */	
		// 	protected function retrieveSettingsPanelPrefs(callback:Function=null):int 
		// 	{
		// 		return getUserFieldsFromServer(['musicVolume', 'effectsVolume', 'dialogSpeed', 'qualityLevel', 'language'], callback);
		// 	}
		
		protected function storeSettingsPanelPrefs(musicVolume:Number, sfxVolume:Number, dialogSpeed:Number, qualityLevel:Number, preferredLanguage:String, callback:Function=null):int 
		{
			var fields:Array = [];
			fields["musicVolume"] 	= musicVolume;
			fields["effectsVolume"] = sfxVolume;
			fields["dialogSpeed"] 	= dialogSpeed;
			fields["qualityLevel"] 	= qualityLevel;
			fields["language"] 		= preferredLanguage;
			if (null == callback) {
				callback = onSettingsPanelStored;
			}
			return setUserFieldsOnServer(fields, callback);
		}
		
		private function onSettingsPanelStored(response:PopResponse):void {
			tracePopResponse(response, "onSettingsPanelStored():");
		}
		
		//////////////////////////////////////// USER FIELDS ////////////////////////////////////////
		
		/**
		 * Retrieve a value from user field from backend
		 * On result the field value is set locally and returned with the callback.
		 */
		protected function getUserField( fieldId:String, islandID:String = "", callback:Function = null ):int
		{
			trace( this,":: getUserField : looking for field: " + fieldId + " in island: " + islandID );
			// check server for field (if permitted)
			if( !this.activeProfile.isGuest )
			{
				trace( this,":: getUserField : checking server." );
				return sendToGateway(PopGateway.GET_PLAYER_FIELDS, [fieldId], Command.create( onUserFieldLoaded, fieldId, islandID, callback ) );
			}
			else
			{
				if( callback != null ) { callback(null); }
			}
			
			return -1;
		}
		
		protected function onUserFieldLoaded( result:PopResponse, fieldId:String, islandID:String = "", callback:Function = null ):void 
		{
			trace( this,":: onUserFieldLoaded : fieldId: " + fieldId + " in island: " + islandID + " result: " + result.toString() );
			var value:* = null;
			if ( result.succeeded ) 
			{
				if( result.data != null )
				{
					var fields:Object = result.data.fields;
					if( fields != null && fields[ fieldId ] != null ) 
					{
						// NOTE :: fieldValue comes back from server in JSON format, requires parsing
						value = JSON.parse(fields[ fieldId ] as String);	
						// WARNING :: This will not set the AS2 LSO, which I think is OK in this circumstance, should keep an eye on. - bard
						shellApi.setUserField( fieldId, value, islandID);
						trace( this,":: onUserFieldLoaded : field value found: " + value);
					}
					else
					{
						trace( this,":: onUserFieldLoaded : field " + fieldId + " not found in database." );
					}
				}
				else
				{
					trace( this,":: onUserFieldLoaded : results have no data for result: " + result.toString() );
				}
			}
			else
			{
				trace( this,":: onUserFieldLoaded : Field Load fail: " +  result.toString() );
			}
			
			if( callback != null )	{ callback( value ); }
		}
		
		/**
		 * Retrieve a values from user fields from backend
		 * On result the field values are set locally and returned with the callback with a Dictionary using field ids as key.
		 */
		protected function getUserFields( fieldIds:Array, islandID:String = "", callback:Function = null ):int
		{
			trace( this,":: getUserFields : looking for fields: " + fieldIds + " in island: " + islandID );
			if( !this.activeProfile.isGuest )
			{
				trace( this,":: getUserFields : checking server." );
				return sendToGateway(PopGateway.GET_PLAYER_FIELDS, fieldIds, Command.create( onUserFieldsLoaded, fieldIds, islandID, callback ) );
			}
			else
			{
				if( callback != null ) { callback(null); }
			}
			
			return -1;
		}
		
		protected function onUserFieldsLoaded( result:PopResponse, fieldIds:Array, islandID:String = "", callback:Function = null ):void 
		{
			trace( this,":: onUserFieldsLoaded : fieldIds: " + fieldIds + " in island: " + islandID + " result: " + result.toString() );
			var value:*;
			var fieldId:String;
			var fieldValues:Dictionary = new Dictionary();
			
			if ( result.succeeded ) 
			{
				if( result.data != null )
				{
					var fieldsObject:Object = result.data.fields;
					if( fieldsObject != null)
					{
						for (var i:int = 0; i < fieldIds.length; i++) 
						{
							fieldId = fieldIds[i];
							if( fieldsObject[ fieldId ] != null ) 
							{
								// NOTE :: fieldValue comes back from server in JSON format, requires parsing
								value = JSON.parse(fieldsObject[ fieldId ]);
								// WARNING :: This will not set the AS2 LSO, which I think is OK in this circumstance, should keep an eye on. - bard
								shellApi.setUserField( fieldId, value, islandID);
								trace( this,":: onUserFieldsLoaded : for field: " + fieldId + " value found: " + value);
							}
							else
							{
								trace( this,":: onUserFieldsLoaded : field " + fieldId + " not found in database." );
							}
						}
					}
					else
					{
						trace( this,":: onUserFieldsLoaded : results.data has no fields" );
					}
				}
				else
				{
					trace( this,":: onUserFieldsLoaded : resulst has no data for result: " + result.toString() );
				}
			}
			else
			{
				trace( this,":: onUserFieldsLoaded : Field Load fail: " +  result.toString() );
			}
			
			if( callback != null )	{ callback( fieldValues ); }
		} 
				
		/**
		 * Set user field
		 */
		protected function setUserField( fieldId:String, fieldValue:*, islandName:String, callback:Function = null ):int
		{
			// values must be wrapped in an Array for SiteProxy.setPlayerFields
			if (!activeProfile.isGuest ) 
			{
				// fields array must be an associative array of the form: [<keyString>:<valueString>,...]
				var fields:Array = [];
				fields[ fieldId ] = JSON.stringify(fieldValue);
				return setUserFieldsOnServer(fields, callback);
			}
			else
			{
				if( callback != null )	{ callback(); }
			}
			return -1;
		}
		
		/**
		 * Send userfields to server.
		 * @param fieldValues - fieldValues Array must be an associative array of the form: [<keyString>:<valueString>,...], values must be in JSON format
		 * @param callback
		 * @return 
		 */
		private function setUserFieldsOnServer(fieldValues:Array, callback:Function=null):int 
		{
			//shellApi.logWWW("AS3 stores field values");
			return sendToGateway(PopGateway.SET_PLAYER_FIELDS, fieldValues, callback);
		}
		
		//////////////////////////////////////// ISLAND SPECIFIC ////////////////////////////////////////
		
		/**
		 * Makes an AMFPHP connection to the game server and requests it to record the successful completion of an island. 
		 * @param island	A String containing the name of the island.
		 * @param callback
		 */		
		protected function completedIsland(island:String, callback:Function=null):int 
		{
			if (activeProfile.isGuest) {	// guest players have no database storage, so we stash the value in the AS2 Char LSO until they're registered
				var charLSO:SharedObject = ProxyUtils.getAS2LSO('Char');
				if (charLSO.data) {
					if (!charLSO.data.hasOwnProperty('islandTimes')) {
						charLSO.data.islandTimes = {};
					}
					if (!charLSO.data.islandTimes[island]) {
						charLSO.data.islandTimes[island] = {};
					}
					charLSO.data.islandTimes[island].end = Math.round(new Date().time / 1000);
					charLSO.flush();
				}
				return logIslandMilestone(island, PopGateway.COMPLETED_ISLANDS, callback);
			} else {
				// RLH: "IslandCompleted" is already getting called for all users in ShellApi.as line 1322
				// this is only getting called for registered users here
				//shellApi.track("IslandFinished", shellApi.island, null, "IslandEvent");
				return logIslandMilestone(island, PopGateway.COMPLETED_ISLANDS, callback);
			}
			return -1;
		}
				
		//////////////////////////////////////// EVENTS ////////////////////////////////////////
		
		/**
		 *
		 * @param events	An array of strings identifying the events which have been completed
		 * @param island
		 * @param callback	
		 */
		protected function completeEvent(events:*, island:String, callback:Function=null):int 
		{
			var allEvents:Array = new Array();
			if (typeof(events) == "string") 
			{
				allEvents.push(events);
			} 
			else if (events is Array) 	// with no args, slice() returns a shallow clone of the source array (just like concat())
			{
				allEvents = events.slice();		
			} 
			else 
			{
				throw new Error("Can't process " + events + " because it is neither String nor Array");
			}
			
			var eventsToSave:Array = extractPermanentEvents(allEvents);
			var numEventsToSave:int = eventsToSave.length;
			for (var i:int=0; i<numEventsToSave; i++) 
			{
				eventsToSave[i] = ProxyUtils.convertEventToServerFormat(eventsToSave[i], island);
			}
			if (0 < numEventsToSave) 
			{
				if (activeProfile.isGuest) 	// store completed events in as2lso for use by as2 registration popup.
				{	
					syncEventsToAS2LSO(island);
				}
				//trace("SiteProxy :: completeEvent : "+ eventsToSave, "going to gateway. isguest?", activeProfile.isGuest);
				return sendToGateway('completeEvent', eventsToSave, callback);
			}
			return -1;
		}
		
		protected function deleteEvent(events:*, island:String, callback:Function=null):int 
		{
			var allEvents:Array = new Array();
			if (typeof(events) == "string") {
				allEvents.push(events);
			} else if (events is Array) {
				allEvents = events.slice();		// with no args, slice() returns a shallow clone of the source array (just like concat())
			} else {
				throw new Error("Can't process " + events + " because it is neither String nor Array");
			}
			
			var eventsToDelete:Array = extractPermanentEvents(allEvents);
			var deleteCount:int = eventsToDelete.length;
			for (var i:int=0; i<deleteCount; i++) {
				eventsToDelete[i] = ProxyUtils.convertEventToServerFormat(eventsToDelete[i], island);
			}
			if (0 < deleteCount) {
				trace(this," :: deleteEvent : "+ eventsToDelete);
				if (activeProfile.isGuest) {	// remove deleted events in as2lso too
					syncEventsToAS2LSO(island);
				}
				return sendToGateway('deleteEvent', eventsToDelete, callback);
			}
			return -1;
		}
		
		//////////////////////////////////////// ITEMS ////////////////////////////////////////
		
		/**
		 * Add item on server 
		 * @param item
		 * @param callback
		 * @param type
		 * @return 
		 */
		protected function getItem(item:String, type:String = null, callback:Function=null):int
		{
			if(type == null) { type = shellApi.island; }
			
			// convert item to Number
			var itemFormattedForServer:Number = ProxyUtils.convertItemToServerFormat(item, type, ProxyUtils.itemToIdMap[type]);
			
			if( !isNaN(itemFormattedForServer) )
			{
				// store obtained items in as2lso for use by as2 registration popup.
				// Need to update items for previously visited AS2 islands even for registered users
				//if(this.activeProfile.isGuest )
				//{
				if( DataUtils.validString(type) ){
					syncItemsToAS2LSO(type);
				}else{
					trace( this,":: getItem : invalid item type: " + type );
				}
				//}
				shellApi.logWWW(this,":::: getting item : " + itemFormattedForServer);
				return sendToGateway('getItem', itemFormattedForServer, callback);
			}
			
			return -1;
		}
		
		protected function removeItem(item:String, type:String = null, callback:Function=null):int
		{
			if(type == null) { type = shellApi.island; }
			
			// convert item to Number
			var itemFormattedForServer:Number = ProxyUtils.convertItemToServerFormat(item, type, ProxyUtils.itemToIdMap[type]);
			
			if( !isNaN(itemFormattedForServer) )
			{
				// removed items in as2lso for use by as2 registration popup.
				// Need to update items for previously visited AS2 islands even for registered users
				//if(this.activeProfile.isGuest)
				//{
				syncItemsToAS2LSO(type);
				//}
				shellApi.logWWW("SiteProxy :: removing item : " + itemFormattedForServer);
				return sendToGateway('removeItem', itemFormattedForServer, callback);
			}
			
			return -1;
		}
		
		/**
		 * Determines removed and current item cards of a given card type and updates AS2LSO with lists of each.
		 * This is only used when player is guest.
		 * @param type - type of card set to update, can be island sets ( i.e. "carrot, "myth", "survival1"), or CardGroup.STORE and CardGroup.CUSTOM sets.
		 * 
		 */
		public function syncItemsToAS2LSO(type:String):void
		{
			var lso:SharedObject = ProxyUtils.as2lso;
			var allCurrentItems:Vector.<String> = CardSet(shellApi.itemManager.getMakeSet(type)).cardIds;
			var allEvents:Vector.<String> = shellApi.gameEventManager.getEvents(type);
			var convertedRemovedItems:Array = new Array();
			var convertedCurrentItems:Array = new Array();
			var event:String;
			var item:String;
			var index:int = 0;
			var islandAS2:String = ProxyUtils.convertIslandToAS2Format(type);	// this includes "Store" & "Custom"
			
			// REMOVED ITEMS
			// find card items that have been removed
			// iterate through all events, searching for items that have ben received, GOT_ITEM, but are no longer held, HAS_ITEM.
			// If found isolate item id within event string and convert to numeric id, add to convertedRemovedItems array
			for(index = 0; index < allEvents.length; index++)
			{
				event = allEvents[index];
				
				if(event.indexOf(GameEvent.GOT_ITEM) > -1)
				{
					item = event.slice(GameEvent.GOT_ITEM.length);
					
					if(allEvents.indexOf(GameEvent.HAS_ITEM + item) < 0)
					{
						convertedRemovedItems.push(ProxyUtils.convertItemToServerFormat(item, type, ProxyUtils.itemToIdMap[type]));
					}
				}
			}
			
			if(!lso.data.hasOwnProperty('removedItems'))
			{
				lso.data.removedItems = new Object();
			}
			lso.data.removedItems[islandAS2] = convertedRemovedItems;
			
			// CURRENT ITEMS
			// find cards itmes that are currently held
			// convert each item id within ItemManager's CardSet specified by type, add each to convertedCurrentItems array
			for(index = 0; index < allCurrentItems.length; index++)
			{
				convertedCurrentItems.push(ProxyUtils.convertItemToServerFormat(allCurrentItems[index], type, ProxyUtils.itemToIdMap[type]));
			}
			
			if(!lso.data.hasOwnProperty('inventory'))
			{
				lso.data.inventory = new Object();
			}
			
			// this include Store and Custom as islands
			lso.data.inventory[islandAS2] = convertedCurrentItems;
			
			lso.flush();
		}
		
		//// PRIVATE METHODS ////
		
		private function logIslandMilestone(island:String, methodName:String, callback:Function=null):int {
			var payload:Object = {};
			island = ProxyUtils.convertIslandToServerFormat(island);
			payload[island] = Math.round(new Date().time / 1000);
			trace("SiteProxy ::", methodName, ":", island);
			return sendToGateway(methodName, payload, callback);
		}
		
		/**
		 * Generic result handler. since result strings have so many different formats,
		 * custom handlers should process the results independently.
		 * @param event
		 */
		private function onPOSTResult(event:Event):void 
		{
			var theResult:String = (event.target as URLLoader).data;
			var resultVars:URLVariables = new URLVariables((event.target as URLLoader).data);
			//shellApi.logWWW("POST result", theResult, JSON.stringify(resultVars));
			//for (var p:String in resultVars) 
			//{
			//	shellApi.logWWW(p, '=', resultVars[p]);
			//}
			
			(event.target as URLLoader).removeEventListener(Event.COMPLETE, onPOSTResult);
			(event.target as URLLoader).removeEventListener(IOErrorEvent.IO_ERROR, onPOSTError);
		}
		
		private function onPOSTError(e:IOErrorEvent):void {
			shellApi.logWWW("POST error:", e.text);
			(e.target as URLLoader).removeEventListener(Event.COMPLETE, onPOSTResult);
			(e.target as URLLoader).removeEventListener(IOErrorEvent.IO_ERROR, onPOSTError);
		}
		
		private function encodeUserName(s:String):String {
			function generate(n:Number):String {
				var b64Alpha:Array = new Array( 'A','B','C','D','E','F','G','H', 'I','J','K','L','M','N','O','P', 'Q','R','S','T','U','V','W','X', 'Y','Z','a','b','c','d','e','f', 'g','h','i','j','k','l','m','n', 'o','p','q','r','s','t','u','v', 'w','x','y','z','0','1','2','3', '4','5','6','7','8','9' );
				var alphaLen:int = b64Alpha.length;
				var r:String = '';
				for (var i:int=0; i<n; i++) {
					r += b64Alpha[Math.floor(Math.random()*alphaLen)];
				}
				return r;
			}
			if (!s) {
				return null;
			}
			var randomness:String = generate(6);
			return Base64.encode(randomness + Base64.encode(s));
		}
		
		private function sceneIsStorable(sceneName:String):Boolean {
			var unstorableScenes:Vector.<String> = new <String>['game.scenes.mocktropica.megaFightingBots::MegaFightingBots'];
			var sceneIndex:int = unstorableScenes.indexOf(sceneName);
			trace(this," :: sceneIsStorable : the scene", sceneName, (-1 == sceneIndex) ? 'is':'is not', 'storable');
			return -1 == sceneIndex;
		}
		
		private function respondWithRegrets(regret:String, callback:Function):void
		{
			var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
			response.error = regret;
			callback(response);
		}
		
		//////////////////////////////////////// EVENTS ////////////////////////////////////////
		
		private function syncEventsToAS2LSO(island:String):void
		{
			var lso:SharedObject = ProxyUtils.as2lso;
			var allEvents:Vector.<String> = shellApi.gameEventManager.getEvents(island);
			var eventsToSave:Array = new Array();
			var islandAS2:String = ProxyUtils.convertIslandToAS2Format(island);
			
			for(var n:int = 0; n < allEvents.length; n++)
			{
				if(ProxyUtils.permanentEvents != null)
				{
					if(ProxyUtils.permanentEvents.indexOf(allEvents[n]) > -1)
					{
						eventsToSave.push(ProxyUtils.convertEventToServerFormat(allEvents[n], island));
					}
				}
				else
				{
					// if this island doesn't differentiate 'permanent' events from 'temporary' events, just log them all.
					eventsToSave.push(ProxyUtils.convertEventToServerFormat(allEvents[n], island));
				}
			}
			
			if(!lso.data.hasOwnProperty('completedEvents'))
			{
				lso.data.completedEvents = new Object();
			}
			lso.data.completedEvents[islandAS2] = eventsToSave;
			
			lso.flush();
		}
		
		private function extractPermanentEvents(events:Array, canExtractAll:Boolean=false):Array {
			var eventsToSave:Array = [];
			var listLength:int = events.length;
			for (var i:int=0; i<listLength; i++) {
				var shouldSaveEvent:Boolean = 'started' == events[i];
				if (ProxyUtils.permanentEvents) {
					if (ProxyUtils.permanentEvents.indexOf(events[i]) > -1) {
						shouldSaveEvent = true;
					}
				} else {	// island has NO permanent events listed
					if (canExtractAll) {
						shouldSaveEvent = true;
					}
				}
				if (shouldSaveEvent) {
					eventsToSave.push(events[i]);
				} else {
					trace(this," :: completeEvent " + events[i] + " is a temp event and will not be saved to the server.");
				}
			}
			return eventsToSave;
		}
		
		//////////////////////////////////////// LOGOUT TIMER ////////////////////////////////////////
		
		public function setupLogoutTimeout():void
		{
			var wallClock:WallClock = new WallClock();
			wallClock.chime.add(onClockChime);
		}
		
		/**
		 * A callback for the Shell's wallclock, which chimes every ten minutes.
		 * 
		 */		
		private function onClockChime():void 
		{
			shellApi.logWWW("ten minutes has elapsed, let's check the server status, shall we?");
			//onServerStatus(new PopResponse(7, new URLVariables('answer=logout&message=hit+the+deck+incoming')));
			getServerStatus(onServerStatus);
		}
		
		private function onServerStatus(response:PopResponse):void 
		{
			trace("server status:", response.toString());
			if (response.data) 
			{
				if (response.data.answer) 
				{
					trace("server status is", response.data.answer);
					if ('ok' != response.data.answer) 
					{
						var message:String = DataUtils.useString(response.data.message, 'Please logout now');
						var sceneGroup:SceneUIGroup = (shellApi.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup);
						sceneGroup.showMessage( message, this.navigateToPopHome );
					}
				}
			}
		}
		
		/**
		 * Simply reloads /index.php. No POST vars, no nothing. Just a swift kick.
		 */
		public function navigateToPopHome():void 
		{
			navigateToURL(new URLRequest('/'), '_self');
		}
		
		// BROWSER SPECIFIC
		private function checkCharToken():void
		{
			var lso:SharedObject = getLSO('Char');
			if (lso.data) {
				lso.data.enteringNewIsland = false;
				lso.flush();
			}
		}
		
		public function getScene( user:String = null, islandID:String = null, callback:Function = null ):int
		{
			if( !this.activeProfile.isGuest )
			{
				var payload:Object = {};
				if (user != null)
				{
					payload["lookup_user"] = user;
				}
				if (islandID != null)
				{
					payload["island_id"] = islandID;
				}
				return sendToGateway(PopGateway.GET_SCENE, payload, callback );
			}
			else
			{
				if( callback != null ) { callback(null); }
			}
			
			return -1;
		}
		
		//////////////////////////////////////// PHOTOS ////////////////////////////////////////
		
		private function syncPhotoToAS2LSO(photoID:String):void {
			var lso:SharedObject = ProxyUtils.as2lso;
			var existingPhotos:Array = [];
			if (lso.data.photos) {
				existingPhotos = lso.data.photos.split(',');
			}
			// don't add the same ID twice
			if (-1 == existingPhotos.indexOf(photoID)) {
				existingPhotos.push(photoID);
				lso.data.photos = existingPhotos.join(',');
				lso.flush();
			}
		}
	}
}