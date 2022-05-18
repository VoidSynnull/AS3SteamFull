package game.proxy
{
	import com.poptropica.AppConfig;
	
	import flash.net.URLVariables;
	
	import engine.util.Command;
	
	import game.data.character.LookConverter;
	import game.data.character.part.PartKeyLibrary;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.managers.ProfileManager;
	import game.util.DataUtils;
	import game.util.ProxyUtils;

	/**
	 * Poptropica specific methods shared between Mobile and Browser versions
	 * @author umckiba
	 */
	public class DataStoreProxyPop extends DataStoreProxy
	{
		private var _partKeyLibrary:PartKeyLibrary;
		protected var _lookConverter:LookConverter;
		
		public function DataStoreProxyPop()
		{
			super();
			
			_lookConverter = new LookConverter();
		}

		public function get partKeyLibrary():PartKeyLibrary 			{ return _partKeyLibrary; }
		public function set partKeyLibrary(newKeys:PartKeyLibrary):void { _partKeyLibrary = newKeys; }
		
		public override function call(transactionData:DataStoreRequest, callback:Function=null):int
		{
			var waitTime:uint = transactionData.hasOwnProperty('requestTimeoutMillis') ? transactionData.requestTimeoutMillis : 0;
			var args:Object;
			
			if (DataStoreRequest.STORAGE_REQUEST_TYPE == transactionData.requestType) {
				switch (transactionData.dataDescriptor) {
					default:
						args = extractStorageArgs(transactionData);
						if (!args.methodArg) {	// we don't recognize this request as either a connection or gateway method
							return super.call(transactionData, callback);
						}
						break;
				}
			} else if (DataStoreRequest.RETRIEVAL_REQUEST_TYPE == transactionData.requestType) {
				switch (transactionData.dataDescriptor) {
					case PopDataStoreRequest.LOGIN:
						login(transactionData.requestData.login, transactionData.requestData.pass_hash, callback);
						return 0;
					case DataStoreRequest.INVENTORY_ITEM_INFO:
						retrieveItemInfo(transactionData.requestData.item_ids, callback);
						return 0;
					case DataStoreRequest.ISLAND_COMPLETIONS:
						retrieveIslandCompletions(callback);
						return 0;

					default:
						args = extractRetrievalArgs(transactionData);
						if (!args.methodArg) {	// we don't recognize this request as either a connection or gateway method
							return super.call(transactionData, callback);
						}
						break;
				}
			} else {
				trace("DataStoreProxyPop::call() Unknown requestType", transactionData.requestType);
			}
			
			return args && args.methodArg ? sendToGatewayWithTimeout(args.methodArg, args.payloadArg, callback, waitTime) : -1;
		}

		protected override function extractStorageArgs(transactionData:DataStoreRequest):Object
		{
			var data:URLVariables = transactionData.requestData;
			var args:Object = {methodArg:null, payloadArg:null};
			var payload:Array = [];

			switch (transactionData.dataDescriptor) {
				case PopDataStoreRequest.NEW_REALM:
					args.methodArg	= PopGateway.CREATE_REALM;
					payload['realm_name']	= data.realmName;
					payload['biome_name']	= data.biomeName;
					payload['size']			= data.realmSize;
					payload['realm_seed']	= data.realmSeed;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_INFO:
					args.methodArg	= PopGateway.SAVE_REALM;
					payload['realm_id']		= data.realmID;
					payload['realm_name']	= data.realmName;
					payload['biome_name']	= data.biomeName;
					payload['size']			= data.realmSize;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.DELETE_REALM:
					args.methodArg	= PopGateway.DELETE_REALM;
					payload['realm_id']		= data.realmID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_SCENE:
					args.methodArg	= PopGateway.SAVE_REALM_SCENE;
					payload['realm_id']			= data.realmID;
					payload['scene_id']			= data.sceneID;
					payload['biome_name']		= data.biomeName;
					payload['file_data']		= data.filePath;
					payload['thumbnail_data']	= data.thumbnailData;
					payload['scene_shared']		= data.sharedStatus;
					if (!isNaN(data.xPos)) {
						payload['x_position']	= data.xPos;
					}
					if (!isNaN(data.yPos)) {
						payload['y_position']	= data.yPos;
					}
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.ITEM_COUNT:
					args.methodArg	= PopGateway.SAVE_ITEM_COUNT;
					payload['item_id']		= data.itemID;
					payload['item_count']	= data.itemCount;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.INCREMENT_ITEM_COUNT:
					args.methodArg	= PopGateway.INCREMENT_ITEM_COUNT;
					payload['item_id']		= data.itemID;
					payload['increment_by']	= data.amount;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.USER_POPTANIUM:
					args.methodArg	= PopGateway.SAVE_USER_STATS;
					payload['poptanium']	= data.poptaniumCount;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.USER_EXPERIENCE:
					args.methodArg	= PopGateway.SAVE_USER_STATS;
					payload['experience'] = data.experienceCount;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.USER_STATS:
					args.methodArg	= PopGateway.SAVE_USER_STATS;
					payload['poptanium']	= data.poptaniumDelta;
					payload['experience']	= data.experienceDelta;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_ITEMS:
					args.methodArg	= PopGateway.SAVE_USER_LAND_ITEM;
					payload['item_name']	= data.itemName;
					payload['item_count']	= data.itemCount;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.VISIT_REALM:
					args.methodArg	= PopGateway.VISIT_REALM;
					payload['realm_id'] = data.realmID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.VISIT_REALM_SCENE:
					args.methodArg	= PopGateway.VISIT_REALM_SCENE;
					payload['realm_id']		= data.realmID;
					payload['scene_id']		= data.sceneID;
					payload['x_position']	= data.xPos;
					payload['y_position']	= data.yPos;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_LOCATION:
					args.methodArg	= PopGateway.SAVE_REALM_LOCATION;
					payload['realm_id']		= data.realmID;
					payload['scene_id']		= data.sceneID;
					payload['x_position']	= data.xPos;
					payload['y_position']	= data.yPos;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_SHARE_STATUS:
					args.methodArg	= PopGateway.SET_REALM_SHARE_STATUS;
					payload['realm_id']	= data.realmID;
					payload['status']	= data.shareStatus;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.SCENE_SHARE_STATUS:
					args.methodArg	= PopGateway.SET_SCENE_SHARE_STATUS;
					payload['realm_id']	= data.realmID;
					payload['scene_id']	= data.sceneID;
					payload['status']	= data.shareStatus;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_APPROVAL_STATUS:
					args.methodArg	= PopGateway.SET_REALM_APPROVAL_STATUS;
					payload['realm_id']	= data.realmID;
					payload['status']	= data.approvalStatus;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.SCENE_APPROVAL_STATUS:
					args.methodArg	= PopGateway.SET_SCENE_APPROVAL_STATUS;
					payload['realm_id']	= data.realmID;
					payload['scene_id']	= data.sceneID;
					payload['status']	= data.approvalStatus;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_RATING:
					args.methodArg	= PopGateway.RATE_REALM;
					payload['realm_id']	= data.realmID;
					payload['rating']	= data.rating;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.SCENE_RATING:
					args.methodArg	= PopGateway.RATE_SCENE;
					payload['realm_id']	= data.realmID;
					payload['scene_id']	= data.sceneID;
					payload['rating']	= data.rating;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.WEB_CAMPAIGNS_XML:
					args.methodArg	= PopGateway.GET_WEB_CAMPAIGNS_XML;
					//args.payloadArg	= data.mobile;
					break;
				case PopDataStoreRequest.MOBILE_CAMPAIGNS_XML:
					args.methodArg	= PopGateway.GET_MOBILE_CAMPAIGNS_XML;
					//args.payloadArg	= data.mobile;
					break;

				default:
					trace("DataStoreProxyPop::extractStorageArgs() kicking", JSON.stringify(transactionData), "to super");
					return super.extractStorageArgs(transactionData);
			}
			return args;
		}

		protected override function extractRetrievalArgs(transactionData:DataStoreRequest):Object
		{
			var data:URLVariables = transactionData.requestData;
			var args:Object = {methodArg:null, payloadArg:null};
			var payload:Array = [];

			switch (transactionData.dataDescriptor) {
				case PopDataStoreRequest.PLAYER_CAMPAIGNS:
					args.methodArg	= PopGateway.GET_CAMPAIGNS_COMMAND;
					args.payloadArg	= data.playerContext;
					break;
				case PopDataStoreRequest.WEB_CAMPAIGNS_XML:
					args.methodArg	= PopGateway.GET_WEB_CAMPAIGNS_XML;
					//payload['mobile']	= data.mobile;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.MOBILE_CAMPAIGNS_XML:
					args.methodArg	= PopGateway.GET_MOBILE_CAMPAIGNS_XML;
					//payload['mobile']	= data.mobile;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.ACTIVE_CAMPAIGNS:
					args.methodArg	= PopGateway.GET_ACTIVE_CAMPAIGNS_COMMAND;
					args.payloadArg	= data.types;
					break;
				case PopDataStoreRequest.PLAYER_REALMS:
					args.methodArg	= PopGateway.GET_REALMS;
					payload['login']	= data.creator;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_INFO:
					args.methodArg	= PopGateway.GET_REALM;
					payload['realm_id']		= data.realmID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_SCENE:
					args.methodArg	= PopGateway.GET_REALM_SCENE;
					payload['realm_id'] = data.realmID;
					payload['scene_id'] = data.sceneID;
					payload['bucket']	= data.bucket;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_SCENE_MAP:
					args.methodArg	= PopGateway.GET_REALM_SCENE_MAP;
					payload['realm_id']		= data.realmID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALMS_LAST_SCENE:
					args.methodArg	= PopGateway.GET_REALMS_LAST_SCENE;
					break;
				case PopDataStoreRequest.REALM_LAST_SCENE_BY_ID:
					args.methodArg	= PopGateway.GET_REALM_LAST_SCENE_BY_REALM_ID;
					payload['realm_id']		= data.realmID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.ITEM_COUNT:
					args.methodArg	= PopGateway.GET_ITEM_COUNT;
					payload['item_id']		= data.itemID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.REALM_ITEMS:
					args.methodArg	= PopGateway.GET_USER_LAND_ITEMS;
					break;
				case PopDataStoreRequest.REALM_ITEMS_BY_TYPE:
					args.methodArg	= PopGateway.GET_USER_LAND_ITEMS_BY_TYPE;
					payload['item_name']	= data.itemName;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.USER_STATS:
					args.methodArg	= PopGateway.GET_USER_STATS;
					break;
				case PopDataStoreRequest.PUBLIC_REALMS:
					args.methodArg	= PopGateway.GET_PUBLIC_REALMS;
					payload['quantity']		= data.quantity;
					payload['offset']		= data.offset;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.PENDING_REALMS:
					args.methodArg	= PopGateway.GET_PENDING_REALMS;
					payload['quantity']		= data.quantity;
					payload['offset']		= data.offset;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.PENDING_REALM_SCENES:
					args.methodArg	= PopGateway.GET_PENDING_REALM_SCENES;
					payload['realm_id']			= data.realmID;
					payload['first_scene_id']	= data.firstSceneID;
					payload['last_scene_id']	= data.lastSceneID;
					args.payloadArg	= payload;
					break;
				case PopDataStoreRequest.AVATAR_DATA:
					args.methodArg	= PopGateway.GET_USER_INFO;
					payload['lookup_user'] = data.lookupUser;
					args.payloadArg	= payload;
					break;

				case DataStoreRequest.LAST_SCENES:
					args.methodArg = PopGateway.GET_LAST_SCENES;
					break;
				
				case PopDataStoreRequest.RANDOM_WINNER:
					args.methodArg = PopGateway.GET_RANDOM_WINNER;
					args.payloadArg = data.prizes;
					break;

				default:
					trace("DataStoreProxyPop::extractRetrievalArgs() kicking", JSON.stringify(transactionData), "to super");
					return super.extractRetrievalArgs(transactionData);
			}
			return args;
		}

		/*********************/
		/**
		 * Temp login method
		 */
		protected function login(login:String, pass_hash:String, callback:Function=null):void 
		{
			if (null == callback) { callback = onLogin; }

			if (gatewayManager) 
			{				
				var postVars:URLVariables = new URLVariables();
				postVars.login = login;
				postVars.pass_hash = pass_hash;
				// login.php doesn't seem to work on xpop, gives dberror.
				//var path:String = /*super.secureHost*/"https://www.poptropica.com" + super.commData.loginURL;
				var path:String = shellApi.siteProxy.secureHost + super.commData.loginURL;
				gatewayManager.makeConnection(path, postVars, callback);
			} 
			else 
			{
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = 'gateway manager is null';
				callback(response);
			}
		}
		
		/**
		 * Temp handler for login response
		 */	
		public function onLogin(response:PopResponse):void 
		{
			var lookString:String;
			var firstName:String;
			var lastName:String;
			var summary:String = 'Error retrieving login';
			
			if (response.succeeded) 
			{
				if (response.data) 
				{
					if (response.data.error || !response.data.hasOwnProperty("json")) 
					{
						summary = "Error from server: " + response.data.error;
					} 
					else 
					{
						var data:Object = JSON.parse(response.data.json);
						
						lookString = data.look;
						firstName = data.firstname;
						lastName = data.lastname;
						
						activeProfile.avatarFirstName = DataUtils.useString(firstName, activeProfile.avatarFirstName);
						activeProfile.avatarLastName  = DataUtils.useString(lastName,  activeProfile.avatarLastName);
						
						if(lookString != null)
						{
							activeProfile.look = _lookConverter.playerLookFromLookString(shellApi, lookString, null, partKeyLibrary, activeProfile);
						}
						
						summary = "Success retrieving login:" + response.data.toString();
					}
				}
			} 
			else 
			{
				summary += ': ' + response.error;
			}

			trace(this," ::onLogin : summary: " + summary);
		}

		private function retrieveItemInfo(IDs:Array, callback:Function=null):void
		{
			if (null == callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables();
				postVars['item_ids[]'] = IDs;
				gatewayManager.makeConnection(secureHost + '/interface/call.php?class=PopItem&method=getInfo', postVars, callback);
			} else {
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = 'gateway manager is null';
				callback(response);
			}
		}

		private function retrieveIslandCompletions(callback:Function=null):void
		{
			if (null == callback) {
				callback = tracePopResponse;
			}
			if (gatewayManager) {
				var postVars:URLVariables = new URLVariables('sorting_type=accomplishment');
				gatewayManager.makeAuthorizedConnection(secureHost + commData.getCompletionsURL/*commData.getQuidgetsURL*/, postVars, Command.create(onIslandCompletions, callback));
			} else {
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = 'gateway manager is null';
				callback(response);
			}
		}

		private function onIslandCompletions(response:PopResponse, callback:Function):void
		{
			var completions:Object;
			if (response.succeeded) {
//				trace(response.data.islands_json);
				completions = JSON.parse(response.data.islands_json);

			}
			if (completions) {
				completions = combineCompletions(completions);
				var profileManager:ProfileManager = shellApi.profileManager;
				var profile:ProfileData = profileManager.active;
				for (var p:String in completions) {
					profile.islandCompletes[p] = completions[p];
				}
				profileManager.save();

			}
			callback(response);
		}

		private function combineCompletions(completions:Object):Object
		{
			var combined:Object = {};
			for (var p:String in completions) {
				var AS2IslandName:String = p;
				if (AS2IslandName.substr(-4) == '_as3') {
					AS2IslandName = AS2IslandName.slice(0,-4);
				}
				var AS3IslandName:String = ProxyUtils.AS3IslandNameFromAS2IslandName(AS2IslandName);

				if (combined.hasOwnProperty(AS3IslandName)) {
					combined[AS3IslandName] += completions[p];
				} else {
					combined[AS3IslandName]  = completions[p];
				}
			}
			return combined;
		}

	}
}
