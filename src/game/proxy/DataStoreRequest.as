package game.proxy {

import com.adobe.crypto.MD5;

import flash.net.URLVariables;
import flash.utils.ByteArray;

import ash.core.Entity;

import engine.group.Scene;

import game.data.character.LookConverter;
import game.data.character.LookData;
import game.util.ClassUtils;
import game.util.DataUtils;
import game.util.ProxyUtils;

/**
 * Value object which formalizes a request to store or retrieve
 * information to/from an IDataStore.
 * 
 * @author Rich Martin
 */
public class DataStoreRequest {

	// request types
	public static const STORAGE_REQUEST_TYPE:uint		= 1;
	public static const RETRIEVAL_REQUEST_TYPE:uint		= 2;
	public static const INTERNAL_REQUEST_TYPE:uint		= 3;
	public static const DELETION_REQUEST_TYPE:uint		= 4;

	// data descriptors
	public static const SERVER_STATUS:uint				= 1;
	public static const PLAYER_LOOK:uint				= 2;

	public static const CLOSET_LOOKS:uint				= 3;
	public static const CLOSET_LOOK:uint				= 4;
	public static const DELETE_CLOSET_LOOK:uint			= 5;

	public static const SCENE_PHOTO:uint				= 6;		// Friends Photo Album
	public static const SCENE_VISIT:uint				= 7;
	public static const USER_FIELDS:uint				= 8;
	public static const USER_TRIBE:uint					= 9;

	public static const ISLAND_START:uint				= 10;
	public static const ISLAND_FINISH:uint				= 11;
	public static const ISLAND_RESET:uint				= 12;

	public static const GAIN_ITEM:uint					= 13;
	public static const REMOVE_ITEM:uint				= 14;

	public static const COMPLETE_EVENT:uint				= 15;
	public static const DELETE_EVENT:uint				= 16;

	public static const FEATURE_STATUS:uint				= 17;
	public static const USER_PREFERENCES:uint			= 18;

	public static const CREDENTIALS:uint				= 19;
	public static const USER_INFO:uint					= 20;
	public static const AVATAR_DATA:uint				= 21;
	public static const PLAYER_INFO:uint				= 22;
	public static const LOGOUT:uint						= 23;
	public static const ACTIVITY_STATE:uint				= 24;
	public static const XAPI_STATEMENT:uint				= 25;
	public static const ME_DATA:uint					= 26;

	public static const GAME_IMAGE:uint					= 27;		// Realms and photobooth

	public static const MAX_CLOSET_LOOKS:uint			= 30;

	public static const PASSWORD_CHANGE:uint			= 31;
	public static const PARENTAL_EMAIL:uint				= 32;
	public static const PLAYER_CREDITS:uint				= 33;
	public static const HIGH_SCORE:uint					= 34;
	public static const INVENTORY_ITEM_INFO:uint		= 35;

	public static const LAST_SCENES:uint				= 36;
	public static const ISLAND_COMPLETIONS:uint			= 37;
	public static const LAST_SCENE:uint					= 38;

	public static const DEFAULT_TIMEOUT:uint			= 1000;		// one second

	//// CREATOR METHODS ////

		// player

	public static function playerLookStorageRequest(char:Entity, lookData:LookData):DataStoreRequest
	{
		var look:String = new LookConverter().getLookStringFromLookData(lookData, char);
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = PLAYER_LOOK;
		instance.requestData = new URLVariables();
		instance.requestData.look = look;
		return instance;
	}

	public static function passwordChangeStorageRequest(loginName:String, oldPassword:String, newPassword:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = PASSWORD_CHANGE;
		var data:URLVariables = new URLVariables();
		data.login			= loginName;
		data.pass_hash		= MD5.hash(oldPassword.toLowerCase());
		data.pass_hash_new	= MD5.hash(newPassword.toLowerCase());
		instance.requestData = data;
		return instance;
	}

	public static function parentalEmailStatusRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PARENTAL_EMAIL;
		instance.requestData = new URLVariables('action=hasParentEmail');
		return instance;
	}

	public static function parentalEmailUpdateRequest(newEmail:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = PARENTAL_EMAIL;
		var data:URLVariables = new URLVariables('action=insertParentEmail');
		data.parent_email = newEmail;
		instance.requestData = data;
		return instance;
	}

	/**
	 * Creates a DataStoreRequest tailored to retrieve a player's current credits and paged credit history
	 * @param limit		How many items of credit history
	 * @param offset	The page offset into the credit history
	 * @return 			The DataStoreRequest to send
	 * 
	 */	
	public static function playerCreditsRetrievalRequest(limit:uint=5, offset:uint=0):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = PLAYER_CREDITS;
		instance.requestData = new URLVariables('limit='+limit + '&offset='+offset);
		return instance;
	}

	public static function highScoreStorageRequest(gameName:String, score:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = HIGH_SCORE;
		var data:URLVariables = new URLVariables();
		data.game	= gameName;
		data.score	= score;
		instance.requestData = data;
		return instance;
	}

	public static function lastScenesRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = LAST_SCENES;
		return instance;
	}

	public static function lastSceneRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = LAST_SCENE;
		return instance;
	}
	
	public static function islandCompletionsRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = ISLAND_COMPLETIONS;
		return instance;
	}

		// user preferences

	public static function settingsRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = USER_PREFERENCES;
		return instance;
	}

	public static function settingsStorageRequest(musicVolume:Number, sfxVolume:Number, dialogSpeed:Number, qualityLevel:Number, preferredLanguage:int):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = USER_PREFERENCES;
		var data:URLVariables = new URLVariables();
		data.musicVolume = musicVolume;
		data.sfxVolume = sfxVolume;
		data.dialogSpeed = dialogSpeed;
		data.qualityLevel = qualityLevel;
		data.preferredLanguage = preferredLanguage;
		instance.requestData = data;
		return instance;
	}

		// closet

	public static function closetLooksRetrievalRequest(numLooks:uint=MAX_CLOSET_LOOKS, offset:uint=0):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = CLOSET_LOOKS;
		//instance.requestData = new URLVariables('numLooks='+numLooks+'&offset='+offset);
		var data:URLVariables = new URLVariables();
		data.numLooks = numLooks;
		data.offset = offset;
		instance.requestData = data;
		return instance;
	}

	public static function closetLookStorageRequest(lookData:LookData):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = CLOSET_LOOK;
		//instance.requestData = new URLVariables('lookData=' + lookData);
		var data:URLVariables = new URLVariables();
		data.lookData = lookData;
		instance.requestData = data;
		return instance;
	}

	public static function closetLookDeletionRequest(lookItemID:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = DELETE_CLOSET_LOOK
		//instance.requestData = new URLVariables('lookItemtID=' + lookItemID);
		var data:URLVariables = new URLVariables();
		data.lookItemID = lookItemID;
		instance.requestData = data;
		return instance;
	}

		// photos

	public static function scenePhotoStorageRequest(photoID:String, setID:String, lookData:LookData):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = SCENE_PHOTO;
		var data:URLVariables = new URLVariables();
		data.photoID	= photoID;
		data.setID		= setID;
		data.lookData	= lookData;
		instance.requestData = data;
		return instance;
	}
	
	public static function gameImageStorageRequest(imageData:ByteArray, imageFormat:String, xmlData:XML=null, campaignID:String=null):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = GAME_IMAGE;
		var data:URLVariables = new URLVariables();
		data.imageData		= imageData;
		data.imageFormat	= imageFormat;
		if (xmlData) {
			data.xmlData = xmlData;
		}
		if (campaignID) {
			data.campaign = campaignID;
		}
		instance.requestData = data;
		return instance;
	}

		// scenes

	public static function sceneVisitStorageRequest(scene:Scene, playerX:Number, playerY:Number, playerDirection:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = SCENE_VISIT;
		var data:URLVariables = new URLVariables();
		data.scene				= scene;
		data.playerX			= playerX;
		data.playerY			= playerY;
		data.playerDirection	= playerDirection;
		instance.requestData = data;
		return instance;
	}

		// user fields

	public static function userFieldStorageRequest(fieldID:String, fieldValue:*, islandName:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = USER_FIELDS;
		var data:URLVariables = new URLVariables();
		data.fieldID = fieldID;
		data.fieldValue = fieldValue;
		data.islandName = islandName;
		instance.requestData = data;
		return instance;
	}

	/**
	 * Retrieve a single field
	 * @param fieldID
	 * @param islandName
	 * @param fromServer
	 * @return 
	 * 
	 */
	public static function userFieldRetrievalRequest(fieldID:String, islandName:String = ""):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = USER_FIELDS;
		var data:URLVariables = new URLVariables();
		data.fieldID = fieldID;
		data.islandName = islandName;
		instance.requestData = data;
		return instance;
	}
	
	/**
	 * Retrieve multiple fields
	 * @param fieldIDs
	 * @param islandName
	 * @param fromServer
	 * @return 
	 */
	public static function userFieldsRetrievalRequest(fieldIDs:Array, islandName:String = ""):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = USER_FIELDS;
		var data:URLVariables = new URLVariables();
		data.fieldIDs = fieldIDs;
		data.islandName = islandName;
		instance.requestData = data;
		return instance;
	}

	public static function userTribeRetrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = USER_TRIBE;
		return instance;
	}

		// islands

	public static function islandStartStorageRequest(islandName:String, useAS2Format:Boolean = false):DataStoreRequest
	{
		var formattedIslandName:String = useAS2Format ? ProxyUtils.convertIslandToAS2Format(islandName) : ProxyUtils.convertIslandToServerFormat(islandName);
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = ISLAND_START;
		instance.requestData = new URLVariables('islandName=' + formattedIslandName);
		return instance;
	}

	public static function islandFinishStorageRequest(islandName:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = ISLAND_FINISH;
		instance.requestData = new URLVariables('islandName=' + islandName);
		return instance;
	}

	/**
	 *  
	 * @param islandName - id of island to reset
	 * @param useAS2Format - if true will convert islandName into AS2 format
	 * @return 
	 * 
	 */
	public static function islandResetStorageRequest(islandName:String, useAS2Format:Boolean=false):DataStoreRequest
	{
		var formattedIslandName:String = useAS2Format ? ProxyUtils.convertIslandToAS2Format(islandName) : ProxyUtils.convertIslandToServerFormat(islandName);
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = ISLAND_RESET;
		instance.requestData = new URLVariables('islandName=' + formattedIslandName);
		return instance;
	}

		// events

	public static function eventsCompletedStorageRequest(events:Array, islandName:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = COMPLETE_EVENT;
		var data:URLVariables = new URLVariables();
		data.events = events;
		data.islandName = islandName;
		instance.requestData = data;
		return instance;
	}

	public static function eventsDeletedStorageRequest(events:Array, islandName:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = DELETE_EVENT;
		var data:URLVariables = new URLVariables();
		data.events = events;
		data.islandName = islandName;
		instance.requestData = data;
		return instance;
	}

		// inventory

	public static function itemGainedStorageRequest(itemName:String, itemType:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = GAIN_ITEM;
		instance.requestData = new URLVariables('itemName=' + itemName + '&itemType=' + itemType);
		return instance;
	}

	public static function itemRemovedStorageRequest(itemName:String, itemType:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = REMOVE_ITEM;
		instance.requestData = new URLVariables('itemName=' + itemName + '&itemType=' + itemType);
		return instance;
	}

	public static function featureStatusRequest(featureName:String):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = FEATURE_STATUS;
		instance.requestData = new URLVariables('featureName=' + featureName);
		return instance;
	}

	public static function credentialsRequest(user:String, password:String):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = CREDENTIALS;
		instance.requestData = new URLVariables('username=' + user + '&password=' + password);
		return instance;
	}

	public static function userInfoRequest(bearerToken:String):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = USER_INFO;
		instance.requestData = new URLVariables('token=' + bearerToken);
		return instance;
	}

	public static function itemInfoRetrievalRequest(itemIDs:Array):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = INVENTORY_ITEM_INFO;
		var data:URLVariables = new URLVariables();
		data.item_ids = itemIDs;
		instance.requestData = data;
		return instance;
	}

	public static function meDataRequest(bearerToken:String=null):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = ME_DATA;
		//instance.requestData = new URLVariables('token=' + bearerToken);
		return instance;
	}

	public static function logoutRequest(bearerToken:String):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = LOGOUT;
		instance.requestData = new URLVariables('token=' + bearerToken);
		return instance;
	}

	/**
	 * Creates a <code>DataStoreRequest</code> which can be passed to <code>IDataStore::store()</code>.
	 * @param activityID		An Internationalized Resource Identifier (IRI) for the activity. An IRI takes the form of a URI, but allows Unicode characters
	 * @param verbID			A value from <code>ExperienceAPIConstants</code>
	 * @param experienceData	The collection of name-value pairs supplementing the basic "I did this" statement.
	 * If you are timestamping your statement (a good idea), <code>experienceData</code> should contain a <code>timestamp</code> property which is a <code>gov.adlnet.expapi.Timestamp</code>.
	 * If you are providing results with your statement (such as when storing quiz results), <code>experienceData</code> must contain a <code>results</code> property which is a <code>gov.adlnet.expapi.Results</code>.
	 * @return 
	 * 
	 */	
	public static function xAPIStatementStorageRequest(activityID:String, verbID:String, experienceData:URLVariables):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = XAPI_STATEMENT;
		instance.requestData = new URLVariables('verbID=' + verbID + '&activityID=' + activityID);
		for (var property:String in experienceData) {
			instance.requestData[property] = experienceData[property];
		}
		return instance;
	}

	// TODO: finish this monster
//	public static function resultStatementStorageRequest(activityID:String, verbID:String, minScore:Number, maxScore:Number, rawScore:Number, scale:Number, success:Boolean, completed:Boolean, response:String, duration:Number, extensions:Object):DataStoreRequest
//	{
//		var xAPIData:URLVariables = new URLVariables();
//		xAPIData.
//		return xAPIStatementStorageRequest(activityID:String, verbID:String, xAPIData);
//	}

	/**
	 * Creates a <code>DataStoreRequest</code> which can be passed to <code>IDataStore::store()</code>.
	 * NOTA BENE: this request is used ONLY by Poptropica English
	 * @param lookJSON	Should be the return value of <code>LookData::toJSONString()</code>
	 * @return	A properly initialized <code>DataStoreRequest</code>
	 */	
	public static function avatarLookStorageRequest(lookJSON:String):DataStoreRequest
	{trace("DataStoreRequest::playerLookStorageRequest() look", lookJSON);
/*		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = AVATAR_DATA;
		instance.requestData = new URLVariables("lookString=" + lookJSON);
		return instance;*/
		return profileStorageRequest(AVATAR_DATA, new URLVariables("lookString=" + lookJSON));
	}

	/**
	 * Creates a <code>DataStoreRequest</code> which can be passed to <code>IDataStore::retrieve()</code>.
	 * @param loginName
	 * @param avatarName
	 * @return A properly initalized <code>DataStoreRequest</code>
	 * 
	 */	
	public static function playerLookRetrievalRequest(loginName:String, avatarName:String=''):DataStoreRequest
	{
/*		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = AVATAR_DATA;
		instance.requestData = new URLVariables("userName=" + loginName);
		if (DataUtils.validString(avatarName)) {
			instance.requestData.avatarName = avatarName;
		}
		return instance;*/
		return profileRetrievalRequest(AVATAR_DATA, loginName, avatarName);
	}

	public static function playerPrefsRetrievalRequest(loginName:String, avatarName:String=''):DataStoreRequest
	{
		return profileRetrievalRequest(USER_PREFERENCES, loginName, avatarName);
	}

	public static function playerPrefsStorageRequest(musicVolume:Number, effectsVolume:Number, dialogSpeed:Number, language:String):DataStoreRequest
	{
		var prefsData:URLVariables = new URLVariables();
		prefsData.musicVolume	= musicVolume;
		prefsData.effectsVolume	= effectsVolume;
		prefsData.dialogSpeed	= dialogSpeed;
		prefsData.language		= language;

		return profileStorageRequest(USER_PREFERENCES, prefsData);
	}

	public static function playerInfoStorageRequest(scene:Scene, playerX:Number, playerY:Number, playerDirection:String):DataStoreRequest
	{
		var playerJSON:String = JSON.stringify({scene_name:(ClassUtils.getNameByObject(scene)), x:playerX, y:playerY, direction:playerDirection});
		return profileStorageRequest(PLAYER_INFO, new URLVariables('playerInfo=' + playerJSON));
	}

	public static function playerInfoRetrievalRequest(loginName:String, avatarName:String=''):DataStoreRequest
	{
		return profileRetrievalRequest(PLAYER_INFO, loginName, avatarName);
	}

	private static function profileStorageRequest(descriptor:uint, profileData:URLVariables):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = descriptor;
		instance.requestData = profileData;
		return instance;
	}

	private static function profileRetrievalRequest(descriptor:uint, loginName:String, avatarName:String=''):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = descriptor;
		instance.requestData = new URLVariables("userName=" + loginName);
		if (DataUtils.validString(avatarName)) {
			instance.requestData.avatarName = avatarName;
		}
		return instance;
	}

	/**
	 * Creates a <code>DataStoreRequest</code> which can be passed to <code>IDataStore::store()</code>.
	 * <p>When the <code>stateID</code> is <code>PopEnglishConstants.ISLAND_DATA_STATE_ID</code>, neither the activityID nor the stateData are important.
	 * These values will be filled in by the <code>ServerProxy</code>.</p>
	 * @param activityID	An Internationalized Resource Identifier (IRI) for the activity. An IRI takes the form of a URI, but allows Unicode characters
	 * @param stateID		An arbitrary <code>String</code> identifier for the data
	 * @param stateData		The collection of key-value pairs to store
	 * @return A properly initalized <code>DataStoreRequest</code>
	 * @see https://en.wikipedia.org/wiki/Internationalized_resource_identifier
	 * @see https://en.wikipedia.org/wiki/Uniform_resource_identifier
	 */	
	public static function activityStateStorageRequest(activityID:String, stateID:String, stateData:URLVariables):DataStoreRequest
	{
		var instance:DataStoreRequest = storageRequest();
		instance.dataDescriptor = ACTIVITY_STATE;
		instance.requestData = stateData;
		return instance;
	}

	/**
	 * Creates a <code>DataStoreRequest</code> which can be passed to <code>IDataStore::retrieve()</code>.
	 * @param activityID	An Internationalized Resource Identifier (IRI) for the activity. An IRI takes the form of a URI, but allows Unicode characters
	 * @param stateID		An arbitrary <code>String</code> identifier for the data
	 * @return A properly initalized <code>DataStoreRequest</code>
	 * 
	 */	
	public static function activityStateRetrievalRequest(activityID:String, stateID:String):DataStoreRequest
	{
		var instance:DataStoreRequest = retrievalRequest();
		instance.dataDescriptor = ACTIVITY_STATE;
		instance.requestData = new URLVariables("activityID=" + activityID + "&stateID=" + stateID);
		return instance;
	}

	/**
	 * Creates a <code>DataStoreRequest</code> of type <code>STORAGE_REQUEST_TYPE</code>. You must initialize the <code>dataDescriptor</code> and <code>requestData</code> properties before submitting the request to <code>IDataStore::store()</code>
	 * @return An empty <code>DataStoreRequest</code> of type <code>STORAGE_REQUEST_TYPE</code>
	 * 
	 */	
	public static function storageRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = new DataStoreRequest();
		instance.requestType = STORAGE_REQUEST_TYPE;
		return instance;
	}

	/**
	 * Creates a <code>DataStoreRequest</code> of type <code>RETRIEVAL_REQUEST_TYPE</code>. You must initialize the <code>dataDescriptor</code> and <code>requestData</code> properties before submitting the request to <code>IDataStore::retrieve()</code>
	 * @return An empty <code>DataStoreRequest</code> of type <code>RETRIEVAL_REQUEST_TYPE</code>
	 * 
	 */	
	public static function retrievalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = new DataStoreRequest();
		instance.requestType = RETRIEVAL_REQUEST_TYPE;
		return instance;
	}

	// it remains to be seen whether this requestType is useful at all
	public static function internalRequest():DataStoreRequest
	{
		var instance:DataStoreRequest = new DataStoreRequest();
		instance.requestType = INTERNAL_REQUEST_TYPE;
		return instance;
	}

	public var requestType:uint	= RETRIEVAL_REQUEST_TYPE;
	public var dataDescriptor:uint;
	public var requestData:URLVariables;
	public var requestTimeoutMillis:uint;

	//// CONSTRUCTOR ////

	public function DataStoreRequest(type:uint=RETRIEVAL_REQUEST_TYPE, descriptor:uint=0, data:URLVariables=null)
	{
		requestType = type;
		if (0 < descriptor) {
			dataDescriptor = descriptor;
		}
		if (data) {
			requestData = data;
		}
	}

}

}
