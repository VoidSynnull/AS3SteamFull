package game.managers {
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.NetStatusEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import engine.ShellApi;
import engine.util.Command;

import game.data.comm.PopRequest;
import game.data.comm.PopResponse;
import game.data.profile.ProfileData;
import game.proxy.Connection;
import game.proxy.GatewayConstants;
import game.proxy.PopGateway;
import game.proxy.UploadPostHelper;

/**
 * GatewayManager coordinates PopRequests and PopResponses.
 * <h1>A Little Backstory</h1>
 * 
 * <p>The earliest server communications in Poptropica2 (AS3/ash framework) were little more than a stream of announcements delivered to /brain/track.php by Shell's <code>_eventTracker</code> property (a Track object), which uses a Connection object (which simply encapsulates a URLLoader). These were uncomplicated times: messaging was quite brief and wholly unidirectional (outbound).</p>
 * 
 * <p>When it came time to publish our first island conversion (24 Carrot Island) online, communications with the server became bidirectional - questions needed to be asked and answered about a player's membership status, current appearance (lookstring) and about the network locations of runtime assets. An AMFPHP (http://www.silexlabs.org/amfphp/) gateway was established as the primary mechanism for processing server queries. Even so, things remained blissfully uncomplicated. Queries were infrequent, so the stream of transactions was well-defined and orderly - queries received responses asynchronously but only one transaction was pending at any given time. It was always obvious which responses were intended for which queries.</p>
 * 
 * <p>It wasn't long before we reached the tipping point. As the sophistication of online gameplay progressed, more methods were added to the AMFPHP gateway, more queries began to fire more frequently and the delivery of responses became less orderly. It was getting difficult to associate a given response with its original query. Something had to be done quickly to protect our publishing schedule. And so the GatewayManager was born.</p>
 * 
 * <h1>GatewayManager, the early days</h1>
 * 
 * <p>In its first incarnation, GatewayManager was quite inefficient. It consumed more resources than necessary and it prevented the bundling of requests (one of the performance features of the AMFPHP gateway). But it provided a reliable pairing of queries and responses so the game could function online as well as its AS2 predecessors. During this early period, the search began for a more efficient and sophisticated solution. What was needed was a reliable dispatching system to associate responses with their originating queries. The open-source <code>'amfphp-toolbox'</code> project seemed to offer all this and more.</p>
 * 
 * <h1>amfphp-toolbox</h1>
 * 
 * <p>A developer named Michael Ebens from Queensland, Australia (http://nova-fusion.com/) created the amfphp-toolbox library in early 2011. Its GitHub project can be found at https://github.com/BlackBulletIV/amfphp-toolbox. The library was designed to address the very problems we had encountered on our busy gateway. At its heart is the <code>Call</code> class, which encapsulates an AMFPHP transaction and eliminates the confusion which results from multiple overlapping queries and responses.</p>
 * 
 * <h1>GatewayManager, now</h1>
 * 
 * <p>With the amfphp-toolbox in hand, it was time to re-write the GatewayManager. A value object called PopResponse had been created earlier to formalize the data retrieved from the AMFPHP gateway, so a <code>PopRequest</code> value object was created to equip GatewayManager with a Call-based mechanism, binding it tightly with the amfphp-toolbox. At the cost of slightly more complicated system, we finally had a scalable interface to the AMFPHP gateway with a rich feature set. Our gateway (<code>callRouter.php)</code> has not yet achieved a second growth-spurt, but when it does, we have a much more powerful tool at our disposal.</p>
 * 
 * <h1>The nitty-gritty</h1>
 * 
 * <p>Up to now, the story has been a high-level description of the evolution of our tools. Let's zoom in and have a look at the inner workings of a gateway query.</p>
 * 
 * <p>Queries, be they for AMFPHP or legacy PHP scripts, should be sent through the ShellApi's <code>siteProxy</code>. As more methods are added to the AMFPHP gateway, corresponding methods are added to SiteProxy for your programming enjoyment. Let's walk through the sequence of events involved in retrieving the accomplishments on a given island for the current player.</p>
 * 
 * <p><code>SiteProxy::getIslandInfo()</code> should be invoked with at least one argument: an array of island names you are interested in. The second argument is an optional reference to a callback function - but without a callback, the response data will simply be dumped to the tracelog. A working callback is pretty important here. A third (again, optional) argument is a Boolean indicating whether the island names in the first argument are old-style island names. SiteProxy is aware of which queries are to be forwarded to the AMFPHP gateway and which are to be forwarded to a legacy PHP script. In this case, <code>SiteProxy::sendToGateway()</code> is called to initiate the next step.</p>
 * 
 * <p><code>SiteProxy::sendToGateway()</code> requires a valid gateway method name (here, it is <code>PopGateway.GET_ISLAND_INFO</code>), an Object which is the data to be sent (here, it is your array of island names) and a reference to the callback function which will handle the response. If no gatewayManager exists, a <code>PopResponse</code> object is populated with an appropriate error and delivered to your callback function via <code>SiteProxy::onGatewayResult()</code> (which will simply trace the response if callback is null). But, under normal conditions, <code>sendToGateway()</code> will forward its arguments to <code>GatewayManager::requestService()</code>, which is where things get interesting.</p>
 * 
 * <p><code>GatewayManager::requestService()</code> will construct a <code>PopRequest</code> from its arguments (methodName, payload, callback - remember?) unless GatewayManager::status is currently OFFLINE_STATUS, in which case your callback will be invoked immediately with a <code>PopResponse</code> identifying this error. But assuming all is well, <code>requestService()</code> will invoke the PopGateway method named in its first argument (in this case, "getIslandInfo"). PopGateway will return a reference to a <code>Call</code> object associated with the request, whether or not the request was made. <code>requestService()</code> stores this reference in the <code>call</code> property of the <code>PopRequest</code>. If the request was successfully initiated, it is placed in a Dictionary of pending requests until its response is received.</p>
 * 
 * <p>The amfphp-toolbox invokes a callback in PopGateway whenever a response arrives from the AMFPHP gateway on the server. This callback assembles a <code>PopResponse</code> from the received data and dispatches a 'responsePending' Signal, which is handled by the GatewayManager. <code>GatewayManager::onGatewayResponse()</code> extracts the <code>PopRequest</code> from the pendingRequests Dictionary and delivers the <code>PopResponse</code> to the callback function stored in that <code>PopRequest</code>.</p>
 * 
 * @see http://www.silexlabs.org/amfphp/
 * @see https://github.com/BlackBulletIV/amfphp-toolbox
 * 
 * @author Rich Martin
 * 
 */
public class GatewayManager {

	
	public static const OFFLINE_STATUS:uint		= 1;	// This has apparently become obsolete? Need details from Rich. - bard
	public static const GUEST_STATUS:uint		= 2;
	public static const LOGGED_IN_STATUS:uint	= 3;
	
	public var queuedMessages:Vector.<Object> = new <Object>[];

	private var shellApi:ShellApi;
	private var gateway:PopGateway;
	private var pendingRequests:Dictionary;
	// DataStoreProxy will set this false if getSecureHost() fails
	public var connected:Boolean = true;	// optimism

	//// CONSTRUCTOR ////

	public function GatewayManager(shellApi:ShellApi, gatewayURL:String='') 
	{
		this.shellApi = shellApi;
		gateway = new PopGateway(this, onServiceStatus);
		gateway.responsePending.add(onGatewayResponse);
		this.gatewayURL = gatewayURL;
		pendingRequests = new Dictionary();
		if (shellApi.networkMonitor) {
			shellApi.networkMonitor.statusUpdate.add(onNetworkMonitorStatus);
		}
	}

	//// ACCESSORS ////
	
	public function get credentials():Object {
		var profile:ProfileData = shellApi.profileManager.active;
		return {login:profile.login, pass_hash:profile.pass_hash, dbid:profile.dbid};
	}

	public function set gatewayURL(newURL:String):void {
		gateway.gatewayURL = newURL;
	}
	
	public function get gatewayURL():String {
		return(gateway.gatewayURL);
	}

	// TODO: this needs to be updated to consider network availability on mobile devices
	public function get loginStatus():uint 
	{

		if (connected) {
			return (credentials && credentials.dbid) ? LOGGED_IN_STATUS : GUEST_STATUS;
		} else return OFFLINE_STATUS;

	}

	//// PUBLIC METHODS ////

	public function requestWithID(id:int):PopRequest
	{
		if (-1 < id) {
			return pendingRequests[String(id)];
		}
		return null;
	}

	/**
	 * Sends an AMFPHP request to a gateway service. (This used to be doRequest())
	 * @param methodName	A <code>String</code> whose value is a method name of PopGateway.
	 * @param payload	An <code>Object</code> containing parameters needed by <code>methodName</code>
	 * @param resultHandler	A reference to a function which accepts a PopResponse as its only argument.
	 * @return - id of AMFPHP call, is its position in the call array of the connection object.
	 */
	public function requestService(methodName:String, payload:Object, resultHandler:Function):int 
	{
		var requestId:int = 0;
		var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
		if (OFFLINE_STATUS == loginStatus) 
		{
			response.error = "gateway offline";
		} 
		else
		{
			// we're online // TODO :: This is inaccurate, you can get here without a connection
			var popRequest:PopRequest = new PopRequest(methodName, payload, resultHandler);
			popRequest.call = gateway[methodName](payload);
			if (popRequest.call.fault) 
			{
				response.error = popRequest.call.fault;
			} 
			else 
			{
				var requestKey:String = String(popRequest.call.callId);
				pendingRequests[requestKey] = popRequest;
				requestId = popRequest.call.callId;
			}
		}

		if (response.error) 
		{
			if (resultHandler) 
			{
				resultHandler.apply(null, [response]);
			} 
			else 
			{	// no resultHandler supplied, just trace
				trace("GatewayManager::requestService(): no resultHandler for", methodName + '. response:', response.toString());
			}
		}
		
		return(requestId);
	}

	public function cancelService(requestID:int):void
	{
trace("GatewayManager:cancelService() deletes call ID", requestID);
		delete pendingRequests[String(requestID)];
	}
	
	/**
	 * Sends POST vars to a given PHP script URL and provides the currently cached credentials as well.
	 * @param url	A <code>String</code> identifying the path to the PHP script.
	 * @param vars	A <code>URLVariables</code> containing POST vars the script will process. Values for login, pass_hash and dbid will be appended to this.
	 * @param callback	A reference to a function which accepts a PopResponse as its only argument.
	 * 
	 */	
	public function makeAuthorizedConnection(url:String, vars:URLVariables, callback:Function=null):void {
		if (LOGGED_IN_STATUS != loginStatus) {
			if (callback) {
				var errorResponse:PopResponse = new PopResponse(GatewayConstants.AMFPHP_UNVALIDATED_USER, null, "Not logged in, can't send " + (vars ? vars.toString() : '') + " to " + url);
				errorResponse.updateFromObject({vars:vars});
				callback.apply(null, [errorResponse]);
			}
		} else {
			if (0 != url.indexOf('https')) {
//				throw new Error("Won't make authorized connection using insecure protocol");
				trace("GatewayManager::makeAuthorizedConnection() ERROR! BIG ERROR!", url, "is not using a secure protocol!");
			}
			vars.login = credentials.login;
			vars.pass_hash = credentials.pass_hash;
			vars.dbid = credentials.dbid;
			makeConnection(url, vars, callback);
		}
	}

	/**
	 * Sends POST vars to a given PHP script URL, 
	 * @param url	A <code>String</code> identifying the path to the PHP script.
	 * @param vars	A <code>URLVariables</code> containing POST vars the script will process.
	 * @param callback	A reference to a function which accepts a PopResponse as its only argument.
	 * 
	 */	
	public function makeConnection(url:String, vars:URLVariables, callback:Function=null):void {
		if (OFFLINE_STATUS == loginStatus) {
			var errorResponse:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM, null, "Offline, can't send " + (vars ? vars.toString() : 'null') + " to " + url);
			if (callback) {
				callback.apply(null, [errorResponse]);
			}
		} else {

			new Connection().connect(
				url, 
				vars, 
				URLRequestMethod.POST, 
				Command.create(onConnectionData, callback), 
				Command.create(onPOSTError, callback)
			);
		}
	}

	public function sendJPG(url:String, imageData:ByteArray, metaData:Object, callback:Function=null):void {
		if (OFFLINE_STATUS == loginStatus) {
			var errorResponse:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM, null, "Offline, can't send image data to " + url);
			if (callback) {
				callback.apply(null, [errorResponse]);
			}
		} else {
			var connection:Connection = new Connection();
			var req:URLRequest = new URLRequest(url);
			req.contentType = 'multipart/form-data; boundary=' + UploadPostHelper.getBoundary();
			req.requestHeaders.push(new URLRequestHeader("Cache-Control", "no-cache"));
			req.method = URLRequestMethod.POST;
			req.data = UploadPostHelper.getPostData("landImage.jpg", imageData, metaData);
			connection.loadRequest(req, Command.create(onConnectionData, callback), Command.create(onPOSTError, callback));
		}
	}

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////
	
	private function onGatewayResponse(id:uint, response:PopResponse):void 
	{
		var clientInfo:PopRequest = pendingRequests[String(id)];
		if (clientInfo) {
			if ((clientInfo.method == "getCampaigns") && (response.data.on_main != null) && (clientInfo.payload.types != null) && (clientInfo.payload.types.indexOf("Main Street") != -1) && (clientInfo.payload.age > 5)){
				if (response.data.on_main["Main Street"] == null)
				{
					var message:String = "Missing Main Street:" + shellApi.adManager.countryCode + ": " + JSON.stringify(response.data.on_main);
					//trace("rick response: " + message);
					shellApi.errorLogger.log(message);
				}
			}
			trace("GatewayManager triggers callback for callId", id, "with response", response.toString(), "to request", clientInfo.toString());
			if (clientInfo.handler) {
				clientInfo.handler.apply(null, [response]);
			} else trace("GatewayManager [Info] - no callback found for", clientInfo.toString());
			delete pendingRequests[id];
		} else {
			trace("GatewayManager received a gateway response it wasn't expecting", id, response.toString());
		}
	}

	private function onConnectionData(e:Event, callback:Function):void 
	{
		var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_SUCCESS);
		var eventData:String = (e.target as URLLoader).data as String;
		if (eventData) {
			try {			// maybe we're getting URLencoded results
				response.data = new URLVariables(eventData);
			}
			catch(e:Error)
			{
				trace("GatewayManager :: Connection Error : "+ e);
				try {		// maybe we're getting JSON encoded results
					var obj:Object = JSON.parse(eventData);
					response.data = new URLVariables();
					response.data.info = obj;
				} catch(e) {
					trace("GatewayManager Connection Error:", e);
				}
			}
		}
		if (callback) {
			callback.apply(null, [response]);
		} else {
			trace("GatewayManager :: onConnectionData(): received", eventData);
		}
	}

	private function onPOSTError(e:IOErrorEvent, callback:Function):void {trace("GatewayManager::onPOSTError()", JSON.stringify(e));
		var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
		response.error = e.text;
		if (callback) {
			callback.apply(null, [response]);
		} else {
			trace("GatewayManager :: onPOSTError():", response.toString());
		}
	}

	private function onServiceStatus(e:Event):void 
	{
		if( e != null )
		{
			//trace("GatewayManager::onServiceStatus()", JSON.stringify(e));
			trace("GatewayManager :: onServiceStatus(): event:", e.toString() );
			if (e is NetStatusEvent) {
				trace("GatewayManager :: onServiceStatus(): received NetStatus forwarding to onServiceNetStatus()");
				onServiceNetStatus(e as NetStatusEvent);
			} else if (e is IOErrorEvent) {
				onServiceError(e as IOErrorEvent);
			} else if (e is SecurityErrorEvent) {
				onSecurityError(e as SecurityErrorEvent);
			}
		}
		else
		{
			trace("GatewayManager::onServiceStatus() : event received was null");
		}
	}

	private function onServiceNetStatus(e:NetStatusEvent):void 
	{
		if( e != null )
		{
			if ("error" == e.info.level) 
			{
				// TODO: perhaps we should set the status to OFFLINE when we get a failure? _RAM
				switch (e.info.code) {
					case 'NetGroup.Connect.Failed':
						trace("GatewayManager::onServiceNetStatus() ", e.info.group, 'failed to connect');
//						connected = false;
						break;
					case 'NetConnection.Call.Failed':
						trace("GatewayManager::onServiceNetStatus() call to:", e.info.details, "failed");
						trace("Here are the pending request IDs:");
						for (var id:String in pendingRequests) trace(id);
//						connected = false;
						break;
					default:
						trace("GatewayManager::onServiceNetStatus() received error level event:", e.info.code, e.toString());
						break;
				}
			} 
			else if ('status' == e.info.level) 
			{
				//trace("GatewayManager::onServiceNetStatus(): status", e.toString());
				switch (e.info.code) 
				{
					case 'NetConnection.Connect.Success':
						connected = true;
						break;
					case 'NetConnection.Connect.Closed':
						trace("GatewayManager::onServiceNetStatus() the AMFPHP gateway connection has closed");
//						connected = false;
						break;
					case 'NetConnection.Connect.NetworkChange':
						trace("there has been a change in the network status");
						break;
					default:
						trace("GatewayManager::onServiceNetStatus() received gateway status with info code:", e.info.code, e.toString());
						//for (var p:String in e.info) trace(p, "dats", e.info[p]);
						//trace("GatewayManager::onServiceNetStatus() received gateway status:", e.toString());
						break;
				}
			} 
			else 
			{
				trace("GatewayManager::onServiceNetStatus() received unknown event:", e.toString());
			}
		}
		else
		{
			trace("GatewayManager::onServiceNetStatus() event received was null");
		}
	}

	// TODO: getting one of these probably should close the gateway _RAM
	private function onSecurityError(e:SecurityErrorEvent):void {
		trace("GatewayManager::onSecurityError() SECURITY error:", e.text);
	}

	private function onServiceError(e:IOErrorEvent):void {
		trace("GatewayManager::onServiceError() gets", JSON.stringify(e));
	}

	private function onNetworkMonitorStatus(networkIsAvailable:Boolean):void
	{
		connected = networkIsAvailable;
	}

}

}
