package game.proxy
{
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.data.CommunicationData;
	import game.data.comm.PopRequest;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.managers.GatewayManager;
	import game.managers.ProfileManager;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class DataStoreProxy extends Manager implements IDataStore2
	{
	
		private var limping:Boolean;		// if ShellApi says no network is available, we invent a rotten value for _secureHost (why is this?). This execution state is known as "limping"
	
		public function DataStoreProxy()
		{
			_AMFPHPGateWayReady = new Signal();
		}
	
		//// ACCESSORS ////
	
	
		//// PUBLIC METHODS ////
	
		public function init(commData:CommunicationData):void 
		{
			_gatewayManager = new GatewayManager(shellApi);
			_commConfig = commData;
			requestSecureHost();
			if (shellApi.networkMonitor) {
				shellApi.networkMonitor.statusUpdate.add(onNetworkMonitorStatus);
			}
		}
	
		public function store(transactionData:DataStoreRequest, callback:Function=null):int
		{
			return call(transactionData, callback);
	/*		var data:URLVariables = transactionData.requestData;
	
			switch (transactionData.dataDescriptor) {
				default:
					trace("DataStoreProxy::store() Unknown dataDescriptor", transactionData.dataDescriptor);
			}
			return -1;*/
		}
	
		public function retrieve(transactionData:DataStoreRequest, callback:Function=null):int
		{
			return call(transactionData, callback);
	/*		var data:URLVariables = transactionData.requestData;
	
			switch (transactionData.dataDescriptor) {
				case DataStoreRequest.FEATURE_STATUS:
					return sendToGateway(PopGateway.GET_FEATURE_STATUS_COMMAND, data.featureName, callback);
					break;
				default:
					trace("DataStoreProxy::retrieve() Unknown dataDescriptor", transactionData.dataDescriptor);
			}
			return -1;*/
		}
	
		public function call(transactionData:DataStoreRequest, callback:Function=null):int
		{
			var waitTime:uint = transactionData.hasOwnProperty('requestTimeoutMillis') ? transactionData.requestTimeoutMillis : 0;
			var args:Object;
	
			if (DataStoreRequest.STORAGE_REQUEST_TYPE == transactionData.requestType) {
				switch (transactionData.dataDescriptor) {
					case DataStoreRequest.GAME_IMAGE:
						var xmlData:XML = transactionData.requestData.hasOwnProperty('xmlData') ? transactionData.requestData.xmlData : null;
						storeImageData(transactionData.requestData.imageData, transactionData.requestData.imageFormat, xmlData, transactionData.requestData.campaign, callback);
						return 0;
						
					default:
						args = extractStorageArgs(transactionData);
						break;
				}
			} else if (DataStoreRequest.RETRIEVAL_REQUEST_TYPE == transactionData.requestType) {
				args = extractRetrievalArgs(transactionData);
			} else {
				trace("DataStoreProxy::call() Unknown requestType", transactionData.requestType);
			}
	
			// TODO: maybe args should be a formal VO?
			return args && args.methodArg ? sendToGatewayWithTimeout(args.methodArg, args.payloadArg, callback, waitTime) : -1;
		}
	
		protected function extractStorageArgs(transactionData:DataStoreRequest):Object
		{
			var args:Object = {methodArg:null, payloadArg:null};
			
			switch (transactionData.dataDescriptor) {
				default:
					trace("DataStoreProxy::extractStorageArgs() Unknown dataDescriptor", transactionData.dataDescriptor);
					break;
			}
			
			return args;
		}
	
		protected function extractRetrievalArgs(transactionData:DataStoreRequest):Object
		{
			var args:Object = {methodArg:null, payloadArg:null};
			
			switch (transactionData.dataDescriptor) {
				case DataStoreRequest.FEATURE_STATUS:
					args.methodArg	= PopGateway.GET_FEATURE_STATUS_COMMAND;
					args.payloadArg	= transactionData.requestData.featureName;
					break;
				default:
					trace("DataStoreProxy::extractRetrievalArgs() Unknown dataDescriptor", transactionData.dataDescriptor);
					break;
			}
			
			return args;
		}
	
		private function storeImageData(data:ByteArray, fileSuffix:String="jpg", xmlData:XML=null, campaignID:String=null, callback:Function=null):void {
			var postVars:Object = {
				suffix:		fileSuffix,
				login:		activeProfile.login,
					fullName:	activeProfile.avatarName,
					age:		activeProfile.age,
					gender:		(SkinUtils.GENDER_MALE == activeProfile.gender) ? 'M' : 'F'
			};
			if (xmlData) {
				postVars.world = xmlData.toXMLString();
			}
			if (campaignID) {
				postVars.campaign = campaignID;
			}
			
			var response:PopResponse;
			if (gatewayManager) {
				gatewayManager.sendJPG(commData.saveBinaryFileURL, data, postVars);
			} else {
				response = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				response.error = "gateway manager is null";
			}
			
			if (response) {			// something must have gone wrong if we had to create a response
				if (callback) {
					callback(response);
				} else {
					tracePopResponse(response, "SiteProxy::storeJPG():");
				}
			}
		}
	
		///////////////////////////////// SECURE HOST /////////////////////////////////
		
		protected function requestSecureHost():void
		{
			var path:String = "/getPrefix.php";
			// establish secure connection to server
			var networkIsAvailable:Boolean = shellApi.networkAvailable();
			gatewayManager.connected = networkIsAvailable;
			if(networkIsAvailable)
			{
				if (!PlatformUtils.inBrowser)
				{
					path = "https://" + gameHost + path;
				}
				trace("DataStoreProxy :: requestSecureHost : gets prefix from path", path);
				gatewayManager.makeConnection(path, null, onGetSecureHost);
			}
			else
			{
				useDefaultSecureURL();					// what is the point of this?
				_AMFPHPGateWayReady.dispatch();
			}
			limping = ! networkIsAvailable;
	//trace("DataStoreProxy::requestSecureHost() just set limping to", limping);
		}
		
		protected function onGetSecureHost(response:PopResponse):void 
		{
			var failed:Boolean = false;
			
			_secureHost = '';	// bad! this is a terrible default! TODO: provide a reasonable default
			if (response) 
			{
				if (!response.succeeded) 
				{
					trace("DataStoreProxy :: onGetSecureHost : oy, failed to get a successful response.", response.error.toString());
					failed = true;
				} 
				else 
				{
					if (response.data) 
					{
						_secureHost = response.data.prefix;
						shellApi.logWWW("got prefix, secure host is", secureHost);
						gatewayManager.gatewayURL = secureHost +_commConfig.AMFPHPGatewayURL;
					} 
					else 
					{
						trace("DataStoreProxy :: onGetSecureHost : grr, failed to get prefix data, this should never happen.");
						failed = true;
					}
				}
			} 
			else 
			{
				trace("DataStoreProxy :: onGetSecureHost : response was null. never supposed to happen.");
				failed = true;
			}
			trace("DataStoreProxy :: onGetSecureHost : dispatching gateway ready");
			
			if(failed)
			{
				gatewayManager.connected = false;
				useDefaultSecureURL();
			}
			else
			{
				gatewayManager.connected = true;
				trace("DataStoreProxy :: onGetSecureHost : Using verified gatewayURL : " + _gatewayManager.gatewayURL);
			}
			
			AMFPHPGateWayReady.dispatch();
		}
		
		/**
		 * Sets secureHost to a default as a backup in case of failure.
		 * Generally this shouldn't be called if everything is working properly.
		 */
		public function useDefaultSecureURL():void
		{
			_secureHost = "https://www.poptropica.com";
			gatewayManager.gatewayURL = _secureHost + _commConfig.AMFPHPGatewayURL;
			
			trace("WARNING :: SiteProxy :: Using default gatewayURL : " + gatewayManager.gatewayURL);
		}
		
		protected function get userCredentials():Object 
		{
			return {
					login:		activeProfile.login,
					pass_hash:	activeProfile.pass_hash,
					dbid:		activeProfile.dbid
			};
		}
	
		///////////////////////////////// LSO /////////////////////////////////
		
		protected function getLSO(lsoName:String):SharedObject 
		{
			var lso:SharedObject = SharedObject.getLocal(lsoName, "/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			return lso;
		}
		
		protected function readLSO(lsoName:String):SharedObject 
		{
			var lso:SharedObject = SharedObject.getLocal(lsoName, "/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			var count:int=0;
			for (var p:String in lso.data) {
				shellApi.logWWW(p + " == " + lso.data[p]);
				count++;
			}
			shellApi.logWWW(lsoName, "contained", count, "properties");
			return lso;
		}
		
		protected function refillLSO(lso:SharedObject, newData:Object):void 
		{
			// RLH: don't delete return quest
			var returnQuest:Object = lso.data.returnQuest;
			lso.clear();
			for (var p:String in newData) {
				lso.data[p] = newData[p];
			}
			if (returnQuest)
				lso.data.returnQuest = returnQuest;
		}
		
		///////////////////////////////// GATEWAY /////////////////////////////////
	
		[Deprecated("use the timeout capabilities of call() by adding a requestTimeoutMillis to your DataStoreRequest")]
		public function cancelGatewayRequest(requestId:int):void
		{
			if (-1 < requestId) {
				gatewayManager.cancelService(requestId);
			}
		}
		
		/**
		 * 
		 * @param method
		 * @param payload
		 * @param callback
	     * @return - id of AMFPHP call, is its position in the call array of the connection object.		 * 
		 */
		protected function sendToGateway(method:String, payload:Object, callback:Function):int
		{
			//shellApi.logWWW("sendToGateway requests service", method, payload, callback);
			if (gatewayManager) 
			{
				return gatewayManager.requestService(method, payload, callback);
			} 
			else 	// no GatewayManager, gotta be a reason. Assume the reason is "mobile device offline".
			{	
				var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
				var errorMsg:String = "Could not access gateway. ";
				errorMsg += JSON.stringify(payload) + " did not get delivered to " + method;
				response.error = errorMsg;
				onGatewayResult(response, callback);
				return -1;
			}
		}
	
		protected function sendToGatewayWithTimeout(method:String, payload:Object, callback:Function, waitTime:uint):int
		{
			if (!waitTime) {
				return sendToGateway(method, payload, callback);
			}
			var t:Timer = new Timer(waitTime, 1);
			var callID:int = sendToGateway(method, payload, Command.create(handleGatewayResponse, callback, t));
			Command.callWithTimer(foregoRequest, t, gatewayManager.requestWithID(callID), callID, t);
			return callID;
		}
	
		protected function handleGatewayResponse(response:PopResponse, callback:Function, t:Timer):void
		{
			if (t) {
				if (t.running) {
					t.stop();
				}
				t = null;
			}
			callback(response);
		}
	
		protected function foregoRequest(request:PopRequest, callID:int, timer:Timer):void
		{
			if (request) {
				// send back some data about the foregone request
				var requestData:URLVariables = new URLVariables();
				requestData.method = request.method;
				requestData.payload = request.payload;
				request.handler(new PopResponse(
					GatewayConstants.AMFPHP_PROBLEM,
					requestData,
					"Request timed out after " + (timer.delay/1000).toFixed(2) + " seconds")
				);
			}
			// clean up
			timer = null;
			if (callID > GatewayConstants.INVALID_CALL_ID) {
				if (gatewayManager) {
					gatewayManager.cancelService(callID);
				}
			}
		}
		
		/**
		 * Handles the result of a call to <code>sendToGateway()</code>,
		 * populates a standard PopResponse with the received data, and
		 * provides it to the given <code>callback</code>.
		 * @param result	A response object from the AMFPHP gateway.
		 * @param callback	The <code>Function</code> which should receive the PopResponse
		 * @see game.data.comm.PopResponse
		 */	
		protected function onGatewayResult(result:Object, callback:Function=null):void 
		{
			var response:PopResponse = new PopResponse();
			if (result) 
			{
				for (var p:String in result) 
				{
					switch (p) {
						case 'status':
							if (result.status) 
							{
								response.status = result.status;
							} 
							else 
							{
								response.status = GatewayConstants.AMFPHP_PROBLEM;
							}
							break;
						case 'error':
							if (result.error) 
							{
								response.error = result.error;
							}
							break;
						default:
							if (!response.data) 
							{
								response.data = new URLVariables();
							}
							//shellApi.logWWW('copying', p, result[p], 'to response');
							response.data[p] = result[p];
							break;
					}
				}
			}
			//trace("from", JSON.stringify(result), 'created', response.toString());
			if (callback) 
			{
				callback.apply(null, [response]);
			} 
			else 
			{
				trace("onGatewayResult(): " + response.toString());
			}
		}
	
		private function onNetworkMonitorStatus(networkIsAvailable:Boolean):void
		{
			gatewayManager.connected = networkIsAvailable;
			if (networkIsAvailable) {
				if (limping) {
					trace("+=+=+=+=+= We need to re-establish our gateway URL");
					requestSecureHost();
				}
			}
		}
	
		///////////////////////////////// HELPERS /////////////////////////////////
	
		protected function tracePopResponse(response:PopResponse, prefix:String=''):void {
			trace(prefix, response.toString());
		}
		
		/**
		 * Helper function that retrieves active Profile 
		 * @return 
		 */
		protected function get activeProfile():ProfileData 
		{ 
			return (ProfileManager(shellApi.getManager(ProfileManager)).active); 
		}
	
		protected var _commConfig:CommunicationData;
		public function get commData():CommunicationData 	{ return _commConfig; }
		public function get gameHost():String				{ return _commConfig.gameHost; }
		public function get fileHost():String				{ return _commConfig.fileHost; }
		
		protected var _secureHost:String = '';
		public function get secureHost():String				{ return _secureHost; }
		
		protected var _AMFPHPGateWayReady:Signal;
		public function get AMFPHPGateWayReady():Signal { return _AMFPHPGateWayReady; }
				
		protected var _gatewayManager:GatewayManager;
		public function get gatewayManager():GatewayManager { return _gatewayManager; }
	}
}
