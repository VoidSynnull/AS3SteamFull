package game.proxy {
	import com.novafusion.net.amfphp.AmfphpGateway;
	import com.novafusion.net.amfphp.Call;
	import com.novafusion.net.amfphp.CallEvent;
	import com.poptropica.AppConfig;
	
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	
	import game.data.TrackingEvents;
	import game.data.ads.PlayerContext;
	import game.data.comm.BrainTrackingData;
	import game.data.comm.PopResponse;
	import game.managers.GatewayManager;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;

/**
 * PopGateway implements Poptropica-specific methods
 * and provides a high-level interface to the
 * AmfphpGateway of amfphp-toolbox.
 * @author Rich Martin
 * 
 */
public class PopGateway {

	
	public static const FETCH_COMMAND:String				= 'fetch';
	public static const SAVE_COMMAND:String					= 'save';
	
	public static const OPEN_SERVICE_NAME:String			= 'OpenService';
	public static const GET_CAMPAIGNS_COMMAND:String		= 'getCampaigns';
	public static const GET_ACTIVE_CAMPAIGNS_COMMAND:String	= 'getActiveCampaigns';
	public static const GET_WEB_CAMPAIGNS_XML:String		= 'getWebCampaignsHaveXML';
	public static const GET_MOBILE_CAMPAIGNS_XML:String		= 'getMobileCampaignsHaveXML';
	public static const GET_WEB_PREFIX_COMMAND:String		= 'getWebPrefix';
	public static const STATUS_COMMAND:String				= 'status';
	public static const GET_FEATURE_STATUS_COMMAND:String	= 'getFeatureStatus';
	
	public static const PLAYER_SERVICE_NAME:String			= 'PlayerService';
	public static const GET_PLAYER_FIELDS:String			= 'getPlayerFields';
	public static const SET_PLAYER_FIELDS:String			= 'setPlayerFields';
	public static const GET_ISLAND_INFO:String				= 'getIslandInfo';
	public static const GET_LAST_SCENES:String				= 'getLastScenes';
	public static const LOG_SCENE_VISIT:String				= 'logSceneVisit';
	public static const ADD_ITEM_TO_INVENTORY:String		= 'addItemToInventory';
	public static const REMOVE_ITEM_FROM_INVENTORY:String	= 'removeItemFromInventory';
	public static const COMPLETE_EVENT:String				= 'completeEvent';
	public static const COMPLETED_ISLANDS:String			= 'completedIslands';
	public static const DELETE_EVENTS:String				= 'deleteEvents';
	public static const RESET_ISLAND:String					= 'resetIsland';
	public static const STARTED_ISLANDS:String				= 'startedIslands';

	public static const CREATE_REALM:String					= 'createRealm';
	public static const GET_REALMS:String					= 'getRealms';
	public static const GET_REALM:String					= 'getRealm';
	public static const GET_REALM_SCENE:String				= 'getRealmScene';
	public static const GET_REALM_SCENE_MAP:String			= 'getRealmSceneMap';
	public static const SAVE_REALM:String					= 'saveRealm';
	public static const SAVE_REALM_SCENE:String				= 'saveRealmScene';
	public static const DELETE_REALM:String					= 'deleteRealm';
	public static const GET_REALMS_LAST_SCENE:String		= 'getRealmsLastScene';
	public static const GET_REALM_LAST_SCENE_BY_REALM_ID:String	= 'getRealmLastSceneByRealmId';
	public static const GET_ITEM_COUNT:String				= 'getItemCount';
	public static const SAVE_ITEM_COUNT:String				= 'saveItemCount';
	public static const INCREMENT_ITEM_COUNT:String			= 'incrementItemCount';
	//public static const GET_USER_POPTANIUM:String			= 'getUserPoptanium';
	//public static const SAVE_USER_POPTANIUM:String			= 'saveUserPoptanium';
	//public static const GET_USER_EXPERIENCE:String			= 'getUserExperience';
	//public static const SAVE_USER_EXPERIENCE:String			= 'saveUserExperience';
	public static const GET_USER_LAND_ITEMS:String			= 'getUserLandItems';
	public static const GET_USER_LAND_ITEMS_BY_TYPE:String	= 'getUserLandItemsByType';
	public static const SAVE_USER_LAND_ITEM:String			= 'saveUserLandItem';
	public static const GET_USER_STATS:String			 	= 'getUserStats';
	public static const SAVE_USER_STATS:String			 	= 'saveUserStats';
	public static const VISIT_REALM:String					= 'visitRealm';
	public static const VISIT_REALM_SCENE:String			= 'visitRealmScene';
	public static const SAVE_REALM_LOCATION:String			= 'saveRealmLocation';
	public static const SET_REALM_SHARE_STATUS:String		= 'setRealmShareStatus';
	public static const SET_SCENE_SHARE_STATUS:String 		= 'setSceneShareStatus';
	public static const SET_REALM_APPROVAL_STATUS:String	= 'setRealmApprovalStatus';
	public static const SET_SCENE_APPROVAL_STATUS:String	= 'setSceneApprovalStatus';
	public static const RATE_REALM:String					= 'rateRealm';
	public static const RATE_SCENE:String					= 'rateScene';
	public static const GET_PUBLIC_REALMS:String			= 'getPublicRealms';
	public static const GET_PENDING_REALMS:String			= 'getPendingRealms';
	public static const GET_USER_INFO:String				= 'getUserInfo';
	public static const GET_PENDING_REALM_SCENES:String		= 'getPendingRealmScenes';

	private static const COMPLETED_EVENTS:String			= 'completedEvents';
	private static const GET_FIELDS:String					= 'getFields';
	private static const SET_FIELDS:String					= 'setFields';
	public static const GET_SCENE:String					= 'getScene';			// PlayerService uses this method name to get the last scene
	private static const VISITED_SCENE:String				= 'visitedScene';
	
	public static const NO_AUTH_DATA:String 				= "noAuthData";
	
	public static const BRAIN_SERVICE_NAME:String			= 'BrainService';
	public static const TRACK_COMMAND:String				= 'track';
	
	public static const GET_RANDOM_WINNER:String			= 'getRandomWinner';
	
	public static function methodRequiresCredentials(methodName:String):Boolean {
		var service:String = PopGateway.serviceForMethod(methodName);
		return PLAYER_SERVICE_NAME == service;
	}
	
	private static function serviceForMethod(methodName:String):String {
		if (0 == methodName.indexOf('track')) {
			return BRAIN_SERVICE_NAME;
		}
		var openMethods:Array = ['getCampaigns', 'getWebCampaignsHaveXML', 'getMobileCampaignsHaveXML', 'getActiveCampaigns', 'getWebPrefix', 'getServerStatus', 'getPendingRealms'];
		var isOpen:Boolean = (-1 < openMethods.indexOf(methodName));
		trace("PopGateway::serviceForMethod(): isOpen?", isOpen, "returning", (isOpen ? OPEN_SERVICE_NAME : PLAYER_SERVICE_NAME));
		return isOpen ? OPEN_SERVICE_NAME : PLAYER_SERVICE_NAME;
	}

	public var responsePending:Signal;

	private var gateway:AmfphpGateway;
	private var authorizationData:Object;
	private var gatewayManager:GatewayManager;

	public function PopGateway(manager:GatewayManager, statusHandler:Function=null) {
		gatewayManager = manager;
		gateway = new AmfphpGateway('');
		if (statusHandler) {
			gateway.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
			gateway.addEventListener(IOErrorEvent.IO_ERROR, statusHandler);
			gateway.addEventListener(SecurityErrorEvent.SECURITY_ERROR, statusHandler);
		}
		gateway.setListeners(onAMFPHPResult, onAMFPHPError);
		responsePending = new Signal(uint, PopResponse);
	}

	public function get authData():Object {	return authorizationData; }
	public function set authData(newData:Object):void {
		authorizationData = Utils.overlayObjectProperties(newData, {login:'', pass_hash:'', dbid:''});
	}

	public function set gatewayURL(newURL:String):void {
		gateway.gateway = newURL;
	}
	public function get gatewayURL():String {
		return(gateway.gateway);
	}

	public function sendCall(call:Call):Call {
		gateway.talk(call);
		return call;
	}

	//// OpenService ////
	
	public function getCampaigns(context:PlayerContext):Call {
		var payload:Array = [];
		payload['age']		= context.age;
		payload['gender']	= context.gender;
		payload['island']	= context.island;
		payload['types']	= context.types;
		payload['exclude']	= context.exclude;
		payload['platform'] = context.platform;

		trace(this,":: getCampaigns: context:", context);
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + GET_CAMPAIGNS_COMMAND, payload);
		return sendCall(call);
	}

	public function getWebCampaignsHaveXML(payload:Object):Call {
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + GET_WEB_CAMPAIGNS_XML, payload);
		return sendCall(call);
	}
	
	public function getMobileCampaignsHaveXML(payload:Object):Call {
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + GET_MOBILE_CAMPAIGNS_XML, payload);
		return sendCall(call);
	}
	
	public function getActiveCampaigns(types:Array):Call {
		var payload:Object = {};
		payload['types']	= types;
		//payload['country']	= context.country;
		
		trace(this,":: getActiveCampaigns : types:" + types);
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + GET_ACTIVE_CAMPAIGNS_COMMAND, payload);
		return sendCall(call);
	}
	
	public function getWebPrefix(alwaysShouldBeNull:Object=null):Call {
		//call(OPEN_SERVICE_NAME, GET_WEB_PREFIX_COMMAND);
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + GET_WEB_PREFIX_COMMAND);
		return sendCall(call);
	}

	/*	it's odd how this OpenService command requires credentials
		Dan Franklin explains it this way:
			Although it takes authentication credentials,
			it doesn't always use them, because it is designed
			to be able to return the logout indication
			when one or more databases are offline.
		[CHORUS]
			Fa la la la la la la la la
	*/
	public function getServerStatus(alwaysShouldBeNull:Object=null):Call {
		var authData:Object = gatewayManager.credentials;
		
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + STATUS_COMMAND);
		if (authData) {
			call.addParams(authData);
			sendCall(call);
		} else {
			call.fault = "Didn't send " + STATUS_COMMAND + ", no usable credentials found.";
		}
		return call;
	}

	public function getFeatureStatus(featureName:String):Call {
		var payload:Array = [];
		payload['feature'] = featureName;
		var call:Call = new Call(OPEN_SERVICE_NAME + '/' + GET_FEATURE_STATUS_COMMAND, payload);
		return sendCall(call);
	}

	//// PlayerService ////

	public function getLastScenes(alwaysShouldBeNull:Object=null):Call
	{
		return fetchFromPlayerService(GET_LAST_SCENES, null);
	}

	public function getPlayerFields(fieldNames:Array):Call {	// a null argument will return all fields, otherwise just the ones requested
		return fetchFromPlayerService(GET_FIELDS, fieldNames);
	}

	public function setPlayerFields(fieldData:Array):Call {		// each array item is a hash: [{<fieldName>:<fieldValue>},...]
		return saveToPlayerService(SET_FIELDS, fieldData);
	}

	public function getIslandInfo(islandAS2Names:Array):Call 
	{
		return fetchFromPlayerService(GET_ISLAND_INFO, islandAS2Names);
	}

	public function logSceneVisit(sceneData:Array):Call {
		return saveToPlayerService(VISITED_SCENE, sceneData);
	}

	public function getScene(payload:Object):Call {
		return fetchFromPlayerService(GET_SCENE, payload);
	}

	public function getUserInfo(loginData:Array):Call {
		return fetchFromPlayerService(GET_USER_INFO, loginData);
	}
	
	/**
	 *
	 * @param itemID	An int identifying the inventory item being added to the player's inventory
	 * @param authData
	 */
	public function getItem(itemID:int):Call 
	{
		return saveToPlayerService(ADD_ITEM_TO_INVENTORY, itemID);
	}
	
	public function removeItem(itemID:int):Call 
	{
		return saveToPlayerService(REMOVE_ITEM_FROM_INVENTORY, itemID);
	}
		
	/**
	 *
	 * @param islandData	An Object of the form {islandName:&lt;String&gt;, timestamp:&lt;int&gt;}, where a timestamp of zero means 'right now', otherwise use Date::time
	 * @param authData
	 */
	public function startedIslands(islandData:Object):Call {
		return saveToPlayerService(STARTED_ISLANDS, islandData);
	}

	/**
	 *
	 * @param islandData	An Object of the form {islandName:&lt;String&gt;, timestamp:&lt;int&gt;}, where a timestamp of zero means 'right now', otherwise use Date::time
	 * @param authData
	 */
	public function completedIslands(islandData:Object):Call {
		return saveToPlayerService(COMPLETED_ISLANDS, islandData);
	}

	/**
	 *
	 * @param eventName	An array of strings identifying the events which have been completed
	 * @param authData
	 */
	public function completeEvent(eventNames:Array):Call 
	{
		return saveToPlayerService(COMPLETED_EVENTS, eventNames);
	}

	public function deleteEvent(eventNames:Array):Call 
	{
		return saveToPlayerService(DELETE_EVENTS, eventNames);
	}
	
	public function resetIsland(island:String):Call 
	{
		return saveToPlayerService(RESET_ISLAND, island);
	}

	public function createRealm(realmData:Object):Call
	{
		return saveToPlayerService(CREATE_REALM, realmData);
	}

	public function getRealms(creatorData:Object):Call
	{
		return fetchFromPlayerService(GET_REALMS, creatorData);
	}

	public function getRealm(realmData:Object):Call
	{
		return fetchFromPlayerService(GET_REALM, realmData);
	}

	public function getRealmScene(sceneData:Object):Call
	{
		return fetchFromPlayerService(GET_REALM_SCENE, sceneData);
	}

	public function getRealmSceneMap(sceneData:Object):Call
	{
		return fetchFromPlayerService(GET_REALM_SCENE_MAP, sceneData);
	}

	public function saveRealm(realmData:Object):Call
	{
		return saveToPlayerService(SAVE_REALM, realmData);
	}

	public function saveRealmScene(sceneData:Object):Call
	{
		return saveToPlayerService(SAVE_REALM_SCENE, sceneData);
	}

	public function deleteRealm(realmData:Object):Call
	{
		return saveToPlayerService(DELETE_REALM, realmData);
	}

	public function getRealmsLastScene(alwaysShouldBeNull:Object=null):Call
	{
		return fetchFromPlayerService(GET_REALMS_LAST_SCENE, null);
	}

	public function getRealmLastSceneByRealmId(realmData:Object):Call
	{
		return fetchFromPlayerService(GET_REALM_LAST_SCENE_BY_REALM_ID, realmData);
	}

	public function getItemCount(itemData:Object):Call
	{
		return fetchFromPlayerService(GET_ITEM_COUNT, itemData);
	}

	public function saveItemCount(countData:Object):Call
	{
		return saveToPlayerService(SAVE_ITEM_COUNT, countData);
	}

	public function incrementItemCount(incrementData:Object):Call
	{
		return saveToPlayerService(INCREMENT_ITEM_COUNT, incrementData);
	}

	public function getUserLandItems(alwaysShouldBeNull:Object=null):Call
	{
		return fetchFromPlayerService(GET_USER_LAND_ITEMS, null);
	}

	public function getUserLandItemsByType(itemData:Object):Call
	{
		return fetchFromPlayerService(GET_USER_LAND_ITEMS_BY_TYPE, itemData);
	}

	public function saveUserLandItem(itemData:Object):Call
	{
		return saveToPlayerService(SAVE_USER_LAND_ITEM, itemData);
	}

	public function getUserStats(alwaysShouldBeNull:Object=null):Call
	{
		return fetchFromPlayerService(GET_USER_STATS, null);
	}

	public function saveUserStats(statsDeltas:Object):Call
	{
		return saveToPlayerService(SAVE_USER_STATS, statsDeltas);
	}

	public function visitRealm(realmData:Object):Call
	{
		return saveToPlayerService(VISIT_REALM, realmData);
	}

	public function visitRealmScene(realmData:Object):Call
	{
		return saveToPlayerService(VISIT_REALM_SCENE, realmData);
	}

	public function saveRealmLocation(realmData:Object):Call
	{
		return saveToPlayerService(SAVE_REALM_LOCATION, realmData);
	}

	public function setRealmShareStatus(statusData:Object):Call
	{
		return saveToPlayerService(SET_REALM_SHARE_STATUS, statusData);
	}

	public function setSceneShareStatus(statusData:Object):Call
	{
		return saveToPlayerService(SET_SCENE_SHARE_STATUS, statusData);
	}

	public function setRealmApprovalStatus(approvalData:Object):Call
	{
		return saveToPlayerService(SET_REALM_APPROVAL_STATUS, approvalData);
	}

	public function setSceneApprovalStatus(approvalData:Object):Call
	{
		return saveToPlayerService(SET_SCENE_APPROVAL_STATUS, approvalData);
	}

	public function rateRealm(ratingData:Object):Call
	{
		return saveToPlayerService(RATE_REALM, ratingData);
	}

	public function rateScene(ratingData:Object):Call
	{
		return saveToPlayerService(RATE_SCENE, ratingData);
	}

	public function getPublicRealms(data:Object):Call
	{
		return fetchFromPlayerService(GET_PUBLIC_REALMS, data);
	}

	public function getPendingRealms(data:Object):Call
	{
		return fetchFromPlayerService(GET_PENDING_REALMS, data);
	}

	public function getPendingRealmScenes(data:Array):Call
	{
		return fetchFromPlayerService(GET_PENDING_REALM_SCENES, data);
	}
	
	public function getRandomWinner(data:Array):Call
	{
		return fetchFromPlayerService(GET_RANDOM_WINNER, data);
	}
	//// BrainService ////

	// TODO: the following three methods will have to mine some data from active profile (or from caller as an arg)
	//  'grade' => (age minus 5), 'gender' => 1, 'platform' => 1, 'login' => 1, 'country' => 1, 'lang' => 1, 'member' => 1
	public function trackSceneLoaded(sceneName:String):Call {
		var btd:BrainTrackingData = BrainTrackingData.instanceFromInitializer({event:TrackingEvents.SCENE_LOADED, choice:sceneName});
		return trackBrainEvent(btd);
	}
	
	public function trackEventCompleted(eventID:String):Call {
		var btd:BrainTrackingData = BrainTrackingData.instanceFromInitializer({eventName:TrackingEvents.COMPLETE_EVENT, choice:eventID});
		return trackBrainEvent(btd);
	}
	
	public function trackItemAdded(itemID:String):Call {
		var btd:BrainTrackingData = BrainTrackingData.instanceFromInitializer({eventName:TrackingEvents.GOT_ITEM, choice:itemID});
		return trackBrainEvent(btd);
	}
	
	public function trackBrainEvent(payload:BrainTrackingData):Call {
		//call(BRAIN_SERVICE_NAME, TRACK_COMMAND, payload);
		var call:Call = new Call(BRAIN_SERVICE_NAME + '/' + TRACK_COMMAND, payload);
		gateway.talk(call);
		return call;
	}

	//// Grunts ////

	public function authDataIsUsable(auth:Object):Boolean {
		//trace("is usable?", DataUtils.toJSONString(auth));
		if (! auth) {
			return false;
		}
		if (!('login' in auth)) {
			return false;
		}
		if (!auth.login) {
			return false;
		}
		if (!('pass_hash' in auth)) {
			return false;
		}
		if (!auth.pass_hash) {
			return false;
		}
		if (!('dbid' in auth)) {
			return false;
		}
		if (!auth.dbid) {
			return false;
		}
		return true;
	}
	
	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function fetchFromPlayerService(fetchMethod:String, payload:Object):Call {
		return callPlayerService(FETCH_COMMAND, fetchMethod, payload);
	}

	private function saveToPlayerService(saveMethod:String, payload:Object):Call {
		return callPlayerService(SAVE_COMMAND, saveMethod, payload);
	}

	private function callPlayerService(commandName:String, methodName:String, payload:Object):Call {
		var authData:Object = gatewayManager.credentials;

		var call:Call = new Call(PLAYER_SERVICE_NAME + '/' + commandName, methodName);
		if (authData) {
			call.addParams(authData, payload);
			sendCall(call);
		} else {
			call.addParams(payload);
			call.fault = "Didn't send to '" + PLAYER_SERVICE_NAME + '/' + commandName + '/' + methodName + "', no usable credentials found.";
		}
		return call;
	}

	private function onAMFPHPResult(e:CallEvent):void {
		var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_SUCCESS);
		if (e.result) {
			response.updateFromObject(e.result);
		} else {	// there was no result, which is unexpected
			response.status = GatewayConstants.AMFPHP_PROBLEM;
			response.error = 'Unexpected null AMFPHP result';
		}

		responsePending.dispatch(e.callId, response);
	}
	
	private function onAMFPHPError(e:CallEvent):void {
		var response:PopResponse = new PopResponse(GatewayConstants.AMFPHP_PROBLEM);
		if (e.fault) {
			//trace("PopGateway::onAMFPHPError() gets a fault:", DataUtils.toJSONString(e.fault));
			var errMsg:String = 'Unknown AMFPHP error';
			if (e.fault.description) {
				errMsg = e.fault.description;
			} else if (e.fault.faultString) {
				errMsg = e.fault.faultString;
			} else if (e.fault.faultDetail) {
				errMsg = e.fault.faultDetail;
			}
			response.error = errMsg;
		} else {
			response.error = "It's a strange thing: this error event has no fault property";
		}

		responsePending.dispatch(e.callId, response);		
	}

/*	private function assertAuthData(auth:Object):Object {
		if (!authDataIsUsable(auth)) {
			
			if (authDataIsUsable(authData)) {
				auth = authData;
			} else {
				return null;
			}
		}
		return auth;
	}*/

}

}
