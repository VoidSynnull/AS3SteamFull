package game.managers
{
	import com.adobe.protocols.dict.Dict;
	import com.poptropica.AppConfig;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import engine.Manager;
	import engine.data.LanguageCode;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.data.PlayerLocation;
	import game.data.bundles.BundleData;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.comm.PopResponse;
	import game.data.dlc.DLCContentData;
	import game.data.dlc.DLCFileData;
	import game.data.profile.GlobalData;
	import game.data.profile.MembershipStatus;
	import game.data.profile.ProfileData;
	import game.managers.interfaces.IAdManager;
	import game.managers.interfaces.IItemManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.util.DataUtils;
	import game.util.GUID;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TribeUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	import engine.ShellApi;

	/**
	 * Tracks all data associated with a users progress through game including events completed and items obtained.  Also manages user data (age and gender).  
	 * This also works with the LongTermMemoryManager to serialize and save data.
	 */
	public class ProfileManager extends Manager
	{
		public function ProfileManager()
		{
			// register all classes we want to save to a bytearray.
			//registerClassAlias("game.data.profile.ProfileData", ProfileData);
			registerClassAlias("game.data.profile.Profile", ProfileData);
			registerClassAlias("game.data.character.PlayerLook", PlayerLook);
			registerClassAlias("game.data.profile.MembershipStatus", MembershipStatus);
			registerClassAlias("game.data.dlc.DLCContentData",DLCContentData);
			registerClassAlias("game.data.profile.GlobalData", GlobalData);
			registerClassAlias("game.data.dlc.DLCFileData", DLCFileData);
			registerClassAlias("game.data.bundles.BundleData", BundleData);	// Trying to get rid of this usage, see convertBundleData
			registerClassAlias("game.data.PlayerLocation", PlayerLocation);
			
			// instantiate signal
			onLookSaved = new Signal(LookData);
		}
		
		/**
		 * When ProfileManager is constructed profile and global data is restored from longterm storage. 
		 */
		override protected function construct():void
		{
			super.construct();
			
			if(shellApi.getManager(LongTermMemoryManager))
			{
				this.getLongTermMemoryManager(shellApi.getManager(LongTermMemoryManager));
			}
			else
			{
				shellApi.managerAdded.add(this.getLongTermMemoryManager);
			}
		}
		
		private function getLongTermMemoryManager(manager:Manager):void
		{
			if(manager is LongTermMemoryManager)
			{
				shellApi.managerAdded.remove(this.getLongTermMemoryManager);
				this.restore();
			}
		}
		
		/**
		 * Create a new player profile.
		 * @param   id : The players username/login.
		 * @param   [makeActive] : Make this new profile the active one.
		 */
		public function create(login:String, makeActive:Boolean = false):ProfileData
		{
			var newProfile:ProfileData = new ProfileData(login);
			
			add(newProfile, makeActive);
			
			save();
			
			return newProfile;
		}
		
		/**
		 * Clear the data for a players profile if an id is specified.  Otherwise clear all profiles and make a new "default" profile the active one.
		 * @param   id : The players username/login.
		 */
		public function clear(login:String = null):void
		{
			LongTermMemoryManager(shellApi.getManager(LongTermMemoryManager)).clear();
			
			if(login == null)
			{
				this._profiles = new Dictionary();
				create(defaultProfileId, true);
			}
			else
			{
				create(login, true);
			}
		}
		
		/**
		 * Add a new player profile.
		 * @param   profile : The player profile to add.
		 * @param   [makeActive] : Make the added profile the active one.
		 */
		public function add(profile:ProfileData, makeActive:Boolean = DONT_MAKE_ACTIVE):void
		{
			_profiles[profile.login] = profile;
			
			if(makeActive)
			{
				_active = profile;
			}
		}
		
		public function remove(profileData:ProfileData):void
		{
			if(_profiles[profileData.login])
			{
				delete _profiles[profileData.login];
				
				if(_active == profileData)
				{
					_active = null;
				}
				
				save();
			}
		}

		public function cloneProfile(oldLogin:String, newLogin:String, makeActive:Boolean=DONT_MAKE_ACTIVE):void 
		{
			var profileData:ProfileData = getProfile(oldLogin);
			if (profileData) {
				profileData.login = newLogin;
				add(profileData, makeActive);
				save();
			} else {
				throw new Error("Can't clone profile data for " + oldLogin + " because it doesn't exist");
			}
		}

		/**
		 * Returns a <code>ProfileData</code> for a given login name
		 * @param login	A <code>String</code> containing a Poptropica login name
		 * @return A <code>ProfileData</code> object containing information about the given login name
		 */		
		public function getProfile(login:String):ProfileData
		{
			var profile:ProfileData = _profiles[login];
			
			if(profile == null)
			{
				trace("ProfileManager :: ProfileData " + login + " does not exist.");
			}
			
			return(profile);
		}
		
		/**
		 * Restore all user profiles and global user data from a bytearray.
		 * @param   profiles : The bytearray to restore from.
		 */
		private function restore():void
		{
			var longTermMemoryManager:LongTermMemoryManager = LongTermMemoryManager(shellApi.getManager(LongTermMemoryManager));
			
			// Retrieve global data (data shared across all profiles) 
			// attempt retrieval from LSO first
			var globalDataEncoded:ByteArray = longTermMemoryManager.data("globalData") as ByteArray;
			if(globalDataEncoded != null && globalDataEncoded.length > 0)
			{
				globalDataEncoded.position = 0;
				_globalData = globalDataEncoded.readObject();
			}
			else if(AppConfig.mobile)
			{
				// if mobile device attempt retrieval from backup in App Storage
				recoverGlobalDataBackup();
			}
			
			if(_globalData == null)
			{
				_globalData = new GlobalData();
				_globalData.dlc = new Dictionary();
				_globalData.dlcFiles = new Dictionary();
				_globalData.appVersions = new Array();
				saveGlobalData();
			}

			// Retrieve data for all profiles
			// attempt retrieval from LSO first
			var profilesEncoded:ByteArray = longTermMemoryManager.data("profiles") as ByteArray;
			if(profilesEncoded != null)
			{
				profilesEncoded.position = 0;
				_profiles = profilesEncoded.readObject();
			}
			else if(AppConfig.mobile)
			{
				// if mobile device attempt retrieval from backup in App Storage
				recoverBackup();
			}
			
			// use the last login that played the game to look up the profileData if it exists.
			if(_globalData.lastLogin != null && _profiles[_globalData.lastLogin] != null)
			{
				_active = _profiles[_globalData.lastLogin];
			}
			else
			{
				// when profiles get restore, put a default one in place for active to start with.  
				// The active profile will get redefined in the profileRestore step in startup.
				for each(var profileData:ProfileData in _profiles)
				{
					_active = profileData;
					_globalData.lastLogin = _active.login;
					saveGlobalData();
				}
			}
			
			if(_active != null){
				// check if profile has a GUID stored, if not, create one and save
				if(_active.guid == null){
					_active.guid = GUID.create();
					saveGlobalData();
				}
			}
			
			if(_active == null)
			{
				create(defaultProfileId, true);
			}
		}
		
		/**
		 * Write the profiles dictionary to a bytearray for long-term storage.
		 */
		public function save():void
		{
			if(!buildingProfile)
			{
				// set the bytearray to the first position to overwrite the current contents.
				_profilesEncoded.position = 0;
				_profilesEncoded.writeObject(_profiles);
				
				LongTermMemoryManager(shellApi.getManager(LongTermMemoryManager)).save("profiles", _profilesEncoded);
				
				if(!PlatformUtils.isDesktop)
				{
					saveBackup();
				}
			}
		}

		public function saveGlobalData():void
		{
			// set the bytearray to the first position to overwrite the current contents.
			_globalDataEncoded.position = 0;
			_globalDataEncoded.writeObject(_globalData);
			
			LongTermMemoryManager(shellApi.getManager(LongTermMemoryManager)).save("globalData", _globalDataEncoded);
			
			if(!PlatformUtils.isDesktop)
			{
				saveGlobalDataBackup();
			}
		}
		
		/**
		 * Returns a <code>Boolean</code> indicating whether a given
		 * Poptropica login name has data stored with the <code>ProfileManager</code>
		 * @param login	A <code>String</code> containing a Poptropica login name
		 * @return A <code>Boolean</code> indicating whether the given login name can be found among the stored profiles
		 */		
		public function checkForProfile(login:String):Boolean
		{
			return(_profiles[login] != null);
		}
		
		/////////////////////////////// PROFILE UPGRADING ///////////////////////////////
		
		/**
		 * As we add features to profileData, this method can be updated to 'upgrade' old profiles with new properties.
		 */
		public function upgradeProfile(profile:ProfileData):void
		{
			if(profile)
			{
				if (!profile.profileVersion) {
					profile.profileVersion = '0';
				}
				profile.assertUserFields();
				if (profile.photos == null) {
					profile.photos = new Dictionary();
				}
				while (profile.profileVersion < CURRENT_PROFILE_VERSION) {
					switch (profile.profileVersion) {
						case '0':
							moveLooseUserFields(profile.userFields);
							profile.profileVersion = '1.1';
							break;
						case '1.1':
							convertBundleData(profile);
							profile.profileVersion = '1.2';
							break;
						case '1.2':
							updateLastSceneDict(profile);
							profile.profileVersion = '1.3';
							break;
							
						default:
							break;
					}
				}
				profile.profileVersion = CURRENT_PROFILE_VERSION;
			}
		}

		/**
		 * This method performs the actions necessary to update
		 * a version 0 <code>ProfileData</code> to version 1.1
		 * @param fields	An <code>Object</code> containing name-value pairs which describe Poptropolis User Fields
		 */		
		private function moveLooseUserFields(fields:Dictionary):void {
			for (var key:String in fields) {
				switch (key) {
					case 'TribalNpcs':
					case 'TribalRanks':
					case 'last_poptropolis_match':
						moveGlobalFieldToIsland(fields, key, 'poptropolis');
						break;
					case 'damage':
					case 'gunLevel':
					case 'activeWeapon':
						moveGlobalFieldToIsland(fields, key, 'virusHunter');
						break;
				}
			}
		}
		
		private function moveGlobalFieldToIsland(fields:Dictionary, fieldName:String, islandName:String):void 
		{
			if (!(islandName in fields)) {
				fields[islandName] = new Dictionary();
			}
			fields[islandName][fieldName] = fields[fieldName];
			delete fields[fieldName];
		}
		
		/**
		 * Convert BundleData classes stored in Profile to only their ids
		 * BundleData is a large class and all that is really needed for storage is its id.
		 * Performs the actions necessary to update a version 1.1 <code>ProfileData</code> to version 1.2
		 * @param profile
		 */
		private function convertBundleData(profile:ProfileData):void 
		{
			var ownedBundleIds:Array = [];
			for (var i:int = 0; i < profile.bundlesOwned.length; i++) 
			{
				if( profile.bundlesOwned[i] is BundleData )
				{
					ownedBundleIds.push( BundleData(profile.bundlesOwned[i]).id );
				}
				else
				{
					ownedBundleIds.push( String(profile.bundlesOwned[i]) );
				}
			}
			profile.bundlesOwned = ownedBundleIds;
		}

		private function updateLastSceneDict(profile:ProfileData):void
		{
			var updatedDict:Dictionary = new Dictionary();
			if (profile.lastScene)
			{
				trace(profile.avatarName, "Last scene dict is NOT null");
				
				for (var islandName:String in profile.lastScene)
				{
					trace("Last island/scene of", islandName);
					
					if (profile.lastScene[islandName] is String)
					{
						trace(profile.lastScene[islandName], "is String");
						
						var sceneName:String = profile.lastScene[islandName];
						var pl:PlayerLocation = new PlayerLocation();
						pl.type = sceneName.indexOf('.') > -1 ? PlayerLocation.AS3_TYPE : PlayerLocation.AS2_TYPE;
						pl.island = islandName;
						pl.scene = sceneName;
						updatedDict[islandName] = pl;
					}
					else if (profile.lastScene[islandName] is PlayerLocation)
					{
						trace(profile.lastScene[islandName], "is PlayerLocation");
						updatedDict[islandName] = profile.lastScene[islandName];
					}
					else if (profile.lastScene[islandName] is Object)
					{
						trace(profile.lastScene[islandName], "is Object");
					}
					else
					{
						trace("ProfileManager::updateLastSceneDict() WARNING found an unknown data type in profile.lastScene[" + islandName + "]");
					}
				}
			}
			else
			{
				trace(profile.avatarName, "Last scene dict is null");
			}
			profile.lastScene = updatedDict;
		}

		//////////////////////////////////////////////////////////////////////////////////

		/**
		 * Save the SharedObject to denoted mobile applicationStorageDirectory.
		 */ 
		private function saveBackup():void
		{
			try
			{
				var file:File = File.applicationStorageDirectory.resolvePath("profiles");
				var fileStream:FileStream = new FileStream(); 
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeBytes(_profilesEncoded);
				fileStream.close();
				trace("ProfileManager :: backup saved.");
			}
			catch(e:Error)
			{
				trace("ProfileManager :: save backup error : " + e);
			}
		}
		
		private function saveGlobalDataBackup():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath("globalData");
			var fileStream:FileStream = new FileStream(); 
			
			try
			{
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeBytes(_globalDataEncoded);
				fileStream.close();
				trace("ProfileManager :: backup saved.");
			}
			catch(e:Error)
			{
				trace("ProfileManager :: save backup error : " + e);
			}
		}
		
		private function recoverBackup():void
		{
			if(File.applicationStorageDirectory)
			{
				var file:File = File.applicationStorageDirectory.resolvePath("profiles");
				
				trace("ProfileManager :: application storage file : "+ file + " File.applicationStorageDirectory : "+File.applicationStorageDirectory);
				
				if(file)
				{
					if(file.exists)
					{
						var fileStream:FileStream = new FileStream(); 
						fileStream.open(file, FileMode.READ);
						fileStream.readBytes(_profilesEncoded);
						_profilesEncoded.position = 0;
						_profiles = _profilesEncoded.readObject();
						LongTermMemoryManager(shellApi.getManager(LongTermMemoryManager)).save("profiles", _profilesEncoded);
						fileStream.close(); 
					}
				}
			}
			else
			{
				trace("ProfileManager :: File.applicationStorageDirectory null");
			}
		}
		
		private function recoverGlobalDataBackup():void
		{
			if(File.applicationStorageDirectory)
			{
				var file:File = File.applicationStorageDirectory.resolvePath("globalData");
				
				trace("ProfileManager :: application storage file : "+ file + " File.applicationStorageDirectory : "+File.applicationStorageDirectory);
				
				if(file)
				{
					if(file.exists)
					{
						var fileStream:FileStream = new FileStream(); 
						fileStream.open(file, FileMode.READ);
						fileStream.readBytes(_globalDataEncoded);
						_globalDataEncoded.position = 0;
						_globalData = _globalDataEncoded.readObject();
						LongTermMemoryManager(shellApi.getManager(LongTermMemoryManager)).save("globalData", _globalDataEncoded);
						fileStream.close(); 
					}
				}
			}
			else
			{
				trace("ProfileManager :: File.applicationStorageDirectory null");
			}
		}
		
		/**
		 * Converts a language tag <code>String</code> in RFC5646 format
		 * to a <code>uint</code>
		 * @param theTag	A <code>String</code> in RFC5646 format
		 * @return 			A Poptropica-specific <code>uint</code> corresponding to the given language tag
		 * @see				http://tools.ietf.org/html/rfc5646
		 */		
		[Deprecated ("No longer needed, language consts are now strings")]
		public static function languageCodeForLanguageTag(theTag:String):uint 
		{
			var theCode:uint = 0;
			/*
			switch (theTag.toLowerCase().replace(/_/, '-')) {
				case 'en':
				case 'en-us':
					theCode = LanguageCode.LANGUAGE_EN;
					break;
				case 'fr':
				case 'fr-fr':
				case 'fr-ca':
					theCode = LanguageCode.LANGUAGE_FR;
					break;
				case 'es':
				case 'es-es':
				case 'es-mx':
					theCode = LanguageCode.LANGUAGE_ES;
					break;
				case 'pt':
				case 'pt-pt':
				case 'pt-br':
					theCode = LanguageCode.LANGUAGE_PT;
					break;
				case 'en-gb':
					theCode = LanguageCode.LANGUAGE_BR;
					break;				
				default:
					trace("There is no language code for RFC5646 tag", theTag);
			}
			*/
			return theCode;
		}
		
		[Deprecated ("No longer needed, language consts are now strings")]
		public static function languageCodeToString(code:uint):String
		{
			switch(code)
			{
				case LanguageCode.LANGUAGE_EN: return "en";
				case LanguageCode.LANGUAGE_ES: return "es";
				case LanguageCode.LANGUAGE_FR: return "fr";
				case LanguageCode.LANGUAGE_PT: return "pt";
				case LanguageCode.LANGUAGE_BR: return "br";
			}
			
			return "";
		}
		
		public static const CURRENT_PROFILE_VERSION:String = "1.3";
		
		public static const MAKE_ACTIVE:Boolean			= true;
		public static const DONT_MAKE_ACTIVE:Boolean	= false;
		
		public static const DEFAULT_MUSIC_VOLUME:Number		= 0.5;
		public static const DEFAULT_SFX_VOLUME:Number		= 0.5;
		
		public static const LANGUAGE_EN:uint	= 0;
		public static const LANGUAGE_FR:uint	= 1;
		public static const LANGUAGE_ES:uint	= 2;
		public static const LANGUAGE_PT:uint	= 3;
		public static const LANGUAGE_BR:uint	= 4;
		
		public function get inventoryType():String 						{ return _active.inventoryType; }	
		public function set inventoryType( cardType:String ):void 		
		{ 
			// if there is already a new card that is of type CUSTOM, do not change type
			// NOTE :: commenting this out, since custom cards are now included in island cards page
			//if( _active.newInventoryCard && _active.inventoryType == CardGroup.CUSTOM )	{ return; }
			
			_active.inventoryType = cardType; 
		}

		public function get inventorySubType():String 					{ return _active.inventorySubType; }	
		public function set inventorySubType( cardSubType:String ):void { _active.inventorySubType = cardSubType; }
		
		public function get active():ProfileData { return(_active); }
		public function get dlc() : Dictionary { return(_active.dlc);}

		/**
		 * Active profile is set from given login.
		 * Checks Dictionary of profiles using the login as key. 
		 * @param login
		 */
		public function set activeLogin(login:String):void 
		{
			var profileData:ProfileData = _profiles[login];
			
			if(profileData)
			{
				_active = profileData;
trace("check to see if profile needs upgrade");
				upgradeProfile(_active);
				_globalData.lastLogin = _active.login;
				saveGlobalData();
			}
		}
		
		public function updateLogin(oldLogin:String, newLogin:String):void
		{
			if(oldLogin != newLogin)
			{
				var profileData:ProfileData = _profiles[oldLogin];
				
				if(profileData != null)
				{
					profileData.login = newLogin;
					_profiles[newLogin] = profileData;
					delete _profiles[oldLogin];
					
					if(_active == profileData)
					{
						_globalData.lastLogin = _active.login;
						saveGlobalData();
					}
				}
			}
		}
		
		/**
		 * Sets dialog speed using based on age of player. 
		 */
		public function setDialogSpeedByAge( profileData:ProfileData = null ):void
		{
			if( profileData == null ) { profileData = this.active; }
			// RLH: force fastest speed for all players at onset
			profileData.dialogSpeed = Dialog.DEFAULT_DIALOG_SPEED;
		}
		
		public function updateCredits(handler:Function = null):void
		{
			trace("update credits");
			(shellApi.siteProxy as IDataStore2).call(DataStoreRequest.playerCreditsRetrievalRequest(), Command.create(handleCreditUpdate, handler));
		}
		
		private function handleCreditUpdate(response:PopResponse, handler:Function = null):void
		{
			if(response.succeeded)
			{
				if(response.data.credits)
				{
					var credits:Number = DataUtils.getNumber(response.data.credits);
					if(!isNaN(credits) && credits >= 0 && credits <= 999999)
					{
						shellApi.profileManager.active.credits = credits;
						trace("ProfileManager :: updateCredits() :  Credits updated for current profile to: " + credits);
					}
					else
					{
						trace("ProfileManager :: updateCredits() :  Error parsing credits" );
					}
				}
			}
			else
			{
				trace("ProfileManager :: updateCredits() : Credit update failed");
			}
			
			if(handler) handler();
		}
		
		public static function syncScores(data:Object, profile:ProfileData):void
		{
			var gameNames:Array = [];
			for (var p:String in data) {
				if ('Score' == p.slice(-5)) {
					//					trace("We found a score for", p.slice(0, -5));
					gameNames.push(p.slice(0, -5));
				}
			}
			//			trace("we have data for these games:", gameNames);
			while (gameNames.length) {
				var gameName:String = gameNames.pop();
				profile.scores[gameName] = {score:data[gameName+'Score'], wins:data[gameName+'Wins'], losses:data[gameName+'Losses']};
			}
		}
		
		public static function fillOutUserData(profile:ProfileData, data:Object):void
		{
			trace("fill out user data");
			if ( data.userData != null) 
			{
				var userData:Object = data.userData is String? JSON.parse(data.userData):data.userData;
				trace(userData);
				if( userData.hasOwnProperty(TribeUtils.TRIBE_FIELD) )
				{
					trace("tribe");
					var tribeObj:Object = userData[ TribeUtils.TRIBE_FIELD ];
					trace(tribeObj);
					var tribeServerIndex:int = int(tribeObj);
					if( !isNaN(tribeServerIndex) )
					{
						trace("get tribe data by index " + tribeServerIndex);
						profile.tribeData = TribeUtils.getTribeDataByIndex( tribeServerIndex );
					}
				}
				trace("settings");
				
				profile.assertUserFields();
				
				for (var p:String in userData) {
					if (TribeUtils.TRIBE_FIELD == p) {
						continue;
					}
					trace("SETTING userfield", p, "to", userData[p]);
					profile.userFields[p] = userData[p];
				}
				
				if (userData.hasOwnProperty('specialAbilities')) 
				{
					trace("special abilities");
					if(userData.specialAbilities is Array)
						profile.specialAbilities = userData.specialAbilities.concat();	// make a copy of the Array
				}
			}
		}
		
		public static function fillOutInventory(profile:ProfileData, data:Object, shellApi:ShellApi):void
		{
			if (data.inventory != null)
			{
				// get store items
				if(data.inventory.Store != null)
				{
					if(profile.items["store"] == null)
					{
						profile.items["store"] = new Array();
					}
					
					var item:Number;
					for each (item in data.inventory.Store)
					{
						// if not already in store and not suppressed
						if ((profile.items["store"].indexOf(item) < 0) && (ItemManager.isStoreItemConverted(int(item))))
						{
							profile.items["store"].push(item);
						}
					}
				}
				
				// get campaign items
				if(data.inventory.Early != null)
				{
					if( IAdManager(shellApi.adManager) != null )
					{
						trace("add ad cards");
						// pass inventory attached to Early island and pass list of currently active campaigns
						IAdManager(shellApi.adManager).AddCampaignCardsToProfile( data.inventory.Early, data.currentcampaigns );
					}
				}
			}
		}
		
		public static function fillOutGeneralData(profile:ProfileData, data:Object):void
		{
			profile.avatarFirstName = data.firstName;
			profile.avatarLastName = data.lastName;
			profile.age = data.age;
			profile.gender = data.gender == 0 ? SkinUtils.GENDER_FEMALE : SkinUtils.GENDER_MALE;
			profile.isGuest = ! data.Registred;
		}
		
		public function get profiles():Dictionary { return(_profiles); }
		public function get globalData():GlobalData { return(_globalData); }
		
		public static const MAX_CLOSET_LOOKS:int = 30;	// TODO :: This should get store somewhere else, in a game config type class for central access. - bard
		public const defaultProfileId:String = "default1";
		
		public var onLookSaved:Signal;	// Signal disptahced when look is saved
		public var buildingProfile:Boolean = false;

		private var _profilesEncoded:ByteArray = new ByteArray();
		private var _profiles:Dictionary = new Dictionary();	// dictionary of ProfileData instances.
		private var _active:ProfileData;    // The currently active profile
		private var _globalData:GlobalData; // data which is shared between all profiles.
		private var _globalDataEncoded:ByteArray = new ByteArray();
		
		// LookConverter converts look information between LookData and look string, we store one here for convenience
		//private var _lookConverter:LookConverter = new LookConverter();
	}
}
