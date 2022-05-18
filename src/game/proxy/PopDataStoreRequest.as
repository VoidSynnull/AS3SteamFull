package game.proxy {
import com.poptropica.AppConfig;

import flash.net.URLVariables;
import flash.utils.ByteArray;

import game.data.ads.PlayerContext;
import game.util.PlatformUtils;
import game.util.ProxyUtils;


public class PopDataStoreRequest extends DataStoreRequest {

	// data descriptors
	public static const PLAYER_CAMPAIGNS:uint			= 102;
	public static const ACTIVE_CAMPAIGNS:uint			= 103;

	public static const MEMBER_STATUS:uint				= 104;

	public static const NEW_REALM:uint					= 105;
	public static const PLAYER_REALMS:uint				= 106;
	public static const REALM_INFO:uint					= 107;
	public static const REALM_SCENE:uint				= 108;
	public static const REALM_SCENE_MAP:uint			= 109;
	public static const DELETE_REALM:uint				= 110;
	public static const REALMS_LAST_SCENE:uint			= 111;
	public static const REALM_LAST_SCENE_BY_ID:uint		= 112;
	public static const ITEM_COUNT:uint					= 113;
	public static const INCREMENT_ITEM_COUNT:uint		= 114;
	public static const REALM_ITEMS:uint				= 115;
	public static const REALM_ITEMS_BY_TYPE:uint		= 116;
	public static const USER_POPTANIUM:uint				= 117;
	public static const USER_EXPERIENCE:uint			= 118;
	public static const USER_STATS:uint					= 119;
	public static const VISIT_REALM:uint				= 120;
	public static const VISIT_REALM_SCENE:uint			= 121;
	public static const REALM_LOCATION:uint				= 122;
	public static const REALM_SHARE_STATUS:uint			= 123;
	public static const SCENE_SHARE_STATUS:uint			= 124;
	public static const REALM_APPROVAL_STATUS:uint		= 125;
	public static const SCENE_APPROVAL_STATUS:uint		= 126;
	public static const REALM_RATING:uint				= 127;
	public static const SCENE_RATING:uint				= 128;
	public static const PUBLIC_REALMS:uint				= 129;
	public static const PENDING_REALMS:uint				= 130;

	public static const AVATAR_DATA:uint				= 131;
	public static const STORE_CARDS:uint				= 132;

	public static const ISLAND_INFO:uint				= 133;
	public static const SCENE:uint						= 134;
	public static const PENDING_REALM_SCENES:uint		= 135;
	public static const WEB_CAMPAIGNS_XML:uint			= 136;
	public static const MOBILE_CAMPAIGNS_XML:uint		= 137;
	
	public static const LOGIN:uint                      = 666;
	
	public static const RANDOM_WINNER:uint				= 777;

	//// CREATOR METHODS ////

	public static function memberStatusRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = MEMBER_STATUS;
		return instance;
	}

		// ads

	public static function playerCampaignsRequest(context:PlayerContext):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PLAYER_CAMPAIGNS;
		var data:URLVariables = new URLVariables();
		data.playerContext = context;
		instance.requestData = data;
		return instance;
	}

	public static function WebCampaignsXMLRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = WEB_CAMPAIGNS_XML;
		var data:URLVariables = new URLVariables();
		// removed this and now use two php scripts
		//data.mobile = (AppConfig.mobile ? "true" : "false");
		instance.requestData = data;
		return instance;
	}
	
	public static function MobileCampaignsXMLRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = MOBILE_CAMPAIGNS_XML;
		var data:URLVariables = new URLVariables();
		// removed this and now use two php scripts
		//data.mobile = (AppConfig.mobile ? "true" : "false");
		instance.requestData = data;
		return instance;
	}
	
	public static function activeCampaignsRequest(types:Array):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = ACTIVE_CAMPAIGNS;
		var data:URLVariables = new URLVariables();
		data.types = types;
		instance.requestData = data;
		return instance;
	}

		// realms

	public static function newRealmStorageRequest(realmName:String, biomeName:String, realmSize:int, realmSeed:uint):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = NEW_REALM;
		var realmData:URLVariables = new URLVariables();
		realmData.realmName = realmName;
		realmData.biomeName = biomeName;
		realmData.realmSize = realmSize;
		realmData.realmSeed = realmSeed;
		instance.requestData = realmData;
		return instance;
	}

	public static function realmsRetrievalRequest(realmCreator:String):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PLAYER_REALMS;
		instance.requestData = new URLVariables('creator=' + realmCreator);
		return instance;
	}

	public static function realmInfoStorageRequest(realmID:int, realmName:String, biomeName:String, realmSize:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_INFO;
		var data:URLVariables = new URLVariables();
		data.realmID	= realmID;
		data.realmName	= realmName;
		data.biomeName	= biomeName;
		data.realmSize	= realmSize;
		instance.requestData = data;
		return instance;
	}

	public static function realmInfoRetrievalRequest(realmID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALM_INFO;
		instance.requestData = new URLVariables('realmID=' + realmID);
		return instance;
	}

	public static function realmSceneStorageRequest(realmID:int, sceneID:int, biomeName:String, filePath:String, thumbnailData:ByteArray, sharedStatus:int, xPos:Number=NaN, yPos:Number=NaN):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_SCENE;
		var data:URLVariables = new URLVariables();
		data.realmID		= realmID;
		data.sceneID		= sceneID;
		data.biomeName		= biomeName;
		data.filePath		= filePath;
		data.thumbnailData	= thumbnailData;
		data.sharedStatus	= sharedStatus;
		data.xPos			= xPos;
		data.yPos			= yPos;
		instance.requestData = data;
		return instance;
	}

	public static function realmSceneRetrievalRequest(realmID:int, sceneID:int, bucket:String=''):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALM_SCENE;
		instance.requestData = new URLVariables('realmID=' + realmID + '&sceneID=' + sceneID + '&bucket=' + bucket);
		if (bucket) {
			instance.requestData.bucket = bucket;
		}
		return instance;
	}

	public static function realmSceneMapRetrievalRequest(realmID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALM_SCENE_MAP;
		instance.requestData = new URLVariables('realmID=' + realmID);
		return instance;
	}

	public static function realmDeletionRequest(realmID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = DELETE_REALM;
		instance.requestData = new URLVariables('realmID=' + realmID);
		return instance;
	}

	public static function realmsLastSceneRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALMS_LAST_SCENE;
		return instance;
	}

	public static function realmsLastSceneByRealmIdRetrievalRequest(realmID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALM_LAST_SCENE_BY_ID;
		instance.requestData = new URLVariables('realmID=' + realmID);
		return instance;
	}

	public static function itemCountStorageRequest(itemID:int, itemCount:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = ITEM_COUNT;
		instance.requestData = new URLVariables('itemID=' + itemID + '&itemCount=' + itemCount);
		return instance;
	}

	public static function itemCountRetrievalRequest(itemID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = ITEM_COUNT;
		instance.requestData = new URLVariables('itemID=' + itemID);
		return instance;
	}

	public static function itemCountIncrementRequest(itemID:int, amount:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = INCREMENT_ITEM_COUNT;
		instance.requestData = new URLVariables('itemID=' + itemID + '&amount=' + amount);
		return instance;
	}

	public static function realmItemsStorageRequest(itemName:String, itemCount:int=1):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_ITEMS
		instance.requestData = new URLVariables('itemName=' + itemName + '&itemCount=' + itemCount);
		return instance;
	}

	public static function realmItemsRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALM_ITEMS;
		return instance;
	}

	public static function realmItemsByTypeRetrievalRequest(itemName:String):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = REALM_ITEMS_BY_TYPE;
		instance.requestData = new URLVariables('itemName=' + itemName);
		return instance;
	}

	public static function userPoptaniumChangeRequest(poptaniumCount:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = USER_POPTANIUM;
		instance.requestData = new URLVariables('poptaniumCount=' + poptaniumCount);
		return instance;
	}

	public static function userExperienceChangeRequest(experienceCount:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = USER_EXPERIENCE;
		instance.requestData = new URLVariables('experienceCount=' + experienceCount);
		return instance;
	}

	public static function userStatsRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = USER_STATS;
		return instance;
	}

	public static function userStatsStorageRequest(poptaniumDelta:int, experienceDelta:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = USER_STATS;
		instance.requestData = new URLVariables('poptaniumDelta=' + poptaniumDelta + '&experienceDelta=' + experienceDelta);
		return instance;
	}

	public static function visitRealmStorageRequest(realmID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = VISIT_REALM;
		instance.requestData = new URLVariables('realmID=' + realmID);
		return instance;
	}

	public static function visitRealmSceneStorageRequest(realmID:int, sceneID:int, xPos:int, yPos:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = VISIT_REALM_SCENE;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.sceneID = sceneID;
		data.xPos = xPos;
		data.yPos = yPos;
		instance.requestData = data;
		return instance;
	}

	public static function realmLocationStorageRequest(realmID:int, sceneID:int, xPos:int, yPos:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_LOCATION;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.sceneID = sceneID;
		data.xPos = xPos;
		data.yPos = yPos;
		instance.requestData = data;
		return instance;
	}

	public static function realmShareStatusStorageRequest(realmID:int, shareStatus:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_SHARE_STATUS;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.shareStatus = shareStatus;
		instance.requestData = data;
		return instance;
	}

	public static function sceneShareStatusStorageRequest(realmID:int, sceneID:int, shareStatus:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = SCENE_SHARE_STATUS;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.sceneID = sceneID;
		data.shareStatus = shareStatus;
		instance.requestData = data;
		return instance;
	}

	public static function realmApprovalStatusStorageRequest(realmID:int, approvalStatus:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_APPROVAL_STATUS;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.approvalStatus = approvalStatus;
		instance.requestData = data;
		return instance;
	}

	public static function sceneApprovalStatusStorageRequest(realmID:int, sceneID:int, approvalStatus:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = SCENE_APPROVAL_STATUS;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.sceneID = sceneID;
		data.approvalStatus = approvalStatus;
		instance.requestData = data;
		return instance;
	}

	public static function realmRatingStorageRequest(realmID:int, rating:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REALM_RATING;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.rating = rating;
		instance.requestData = data;
		return instance;
	}

	public static function sceneRatingStorageRequest(realmID:int, sceneID:int, rating:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = SCENE_RATING;
		var data:URLVariables = new URLVariables();
		data.realmID = realmID;
		data.sceneID = sceneID;
		data.rating = rating;
		instance.requestData = data;
		return instance;
	}

	public static function publicRealmsRetrievalRequest(quantity:int, offset:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PUBLIC_REALMS;
		var data:URLVariables = new URLVariables();
		data.quantity	= quantity;
		data.offset		= offset;
		instance.requestData = data;
		return instance;
	}

	public static function pendingRealmsRetrievalRequest(quantity:int, offset:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PENDING_REALMS;
		var data:URLVariables = new URLVariables();
		data.quantity	= quantity;
		data.offset		= offset;
		instance.requestData = data;
		return instance;
	}

	public static function pendingRealmScenesRetrievalRequest(realmID:int, firstSceneID:int, lastSceneID:int):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PENDING_REALM_SCENES;
		var data:URLVariables = new URLVariables();
		data.realmID		= realmID;
		data.firstSceneID	= firstSceneID;
		data.lastSceneID	= lastSceneID;
		instance.requestData = data;
		return instance;
	}
	
	// store
	
	public static function storeCardsRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = STORE_CARDS;
		return instance;
	}

	// player

	public static function avatarDataRetrievalRequest(lookupUser:String=''):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = AVATAR_DATA;
		if (lookupUser) {
			instance.requestData = new URLVariables('lookupUser=' + lookupUser);
		}
		return instance;
	}

	public static function loginRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = LOGIN;
		return instance;
	}
	
	public static function islandInfoRetrievalRequest(islands:Array, useAS2Format:Boolean=false):DataStoreRequest
	{
		var formattedIslands:Array = [];
		for (var i:int=0; i<islands.length; i++) {
			formattedIslands.push(useAS2Format ? ProxyUtils.convertIslandToAS2Format(islands[i]) : ProxyUtils.convertIslandToServerFormat(islands[i]));
		}
		// for mobile, add app version to beginning of array
		if (PlatformUtils.isMobileOS)
		{
			// get app version number (has form "0.0.0")
			var appVersion:String = AppConfig.appVersionNumber;
			trace("current app version number: " + appVersion);
			// change to form @app_version=2.32.101
			appVersion = "@app_version=" + appVersion;
			// add to beginning of array
			formattedIslands.unshift(appVersion);
		}
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = ISLAND_INFO;
		var data:URLVariables = new URLVariables();
		data.islands = formattedIslands;
		instance.requestData = data;
		return instance;
	}

	public static function lastSceneRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = SCENE;
		return instance;
	}
	
	public static function getRandomWinner(prizes:Array):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = RANDOM_WINNER;
		
		var data:URLVariables = new URLVariables();
		data.prizes = prizes;
		instance.requestData = data;
		return instance;
	}

	//// CONSTRUCTOR ////

	public function PopDataStoreRequest(type:uint=2, descriptor:uint=0, data:URLVariables=null)
	{
		super(type, descriptor, data);
	}
}

}
