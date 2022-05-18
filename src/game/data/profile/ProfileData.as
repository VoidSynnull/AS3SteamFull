package game.data.profile
{
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.data.LanguageCode;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.data.ads.PlayerContext;
	import game.data.character.PlayerLook;
	import game.managers.ProfileManager;
	import game.proxy.Connection;
	import game.util.DataUtils;
	import game.util.GUID;
	
	import org.osflash.signals.Signal;

	/**
	 * ProfileData encapsulates the set of player-specific values
	 * required for any Poptropica player.
	 * @author Billy Belfield/Rich Martin
	 */
	public class ProfileData
	{
		/**
		 * The version string for this <code>ProfileData</code>.
		 * Before versioning was installed, ProfileData slowly grew
		 * to accomodate the needs of the game.
		 * <p>When database user fields became available via AMFPHP
		 * and a public <code>Object</code> was created to hold
		 * their values, things began to happen. It became an
		 * easy target for freeform data storage, despite the
		 * fact that the database can hold only strings in
		 * user fields.</p>
		 * <p>Thus was born version 1.1, which introduced per-island
		 * user fields. Bundling each island's user fields in a
		 * separate container facilitates resetting an island.</p>
		 */
		public var profileVersion:String = ProfileManager.CURRENT_PROFILE_VERSION;
		/**
		 * A unique identifier which is the dictionary key for this profile.
		 * @default	The default value is 'default'.
		 */
		public var password:String;
		/**
		 * A <code>Dictionary</code> of completed events on a per-island basis.
		 * Each key is an island name, and each value is an Array of event IDs.
		 */
		public var events:Dictionary = new Dictionary();
		/**
		 * A <code>Dictionary</code> of acquired items on a per-island basis.
		 * Each key is an island name, and each value is an Array of item IDs.
		 */
		public var items:Dictionary = new Dictionary();
		/**
		 * A <code>Dictionary</code> of island completions.
		 * Each key is an island name, and each value is a number of completions.
		 */
		public var islandCompletes:Dictionary = new Dictionary();
		/**
		 * A <code>Dictionary</code> of photos taken on a per-island basis.
		 * Each key is an island name, and each value is an Array of photo IDs.
		 */
		public var photos:Dictionary = new Dictionary();
		/**
		 * An array of active campaign names for mobile
		 */
		public var campaigns:Array = new Array(); // ad campaigns
		/**
		 * A <code>Dictionary</code> of DLCContentData that holds all of the info
		 * regarding DLC and whether content is downloaded, purchased, or free and a checkSum
		 * for validating zips with the backend.
		 */
		public var dlc:Dictionary;
		
		/**
		 * Holds the current Special Abilities in an array of just the ids
		 */
		public var specialAbilities:Array = new Array();
		/**
		 * Stores alternate player looks
		 */
		public var closetLooks:Vector.<PlayerLook> = new Vector.<PlayerLook>();
		/**
		 * An Array of bundle ids that's been purchased/owned.
		 */
		public var bundlesOwned:Array = [];
		/**
		 * Stores the last scene visited as a String^H^H^H^H^H^H PlayerLoction for each island.
		 */
		public var lastScene:Dictionary = new Dictionary();

		public var scores:Dictionary = new Dictionary();		// keys are game names, e.g., 'RaceCon1RoofRace' and values are {'score':<String>, 'wins':<String>, 'losses':<String>}
		
		/**
		 * Stores custom parts for pets by pet ID. An empty object for an ID means there are no custom parts, but using all default parts.
		 */
		public var pets:Dictionary = new Dictionary();
		
		/**
		 * Properties saved from the 'Settings' screen.
		 */
		public var musicVolume:Number = ProfileManager.DEFAULT_MUSIC_VOLUME;
		public var ambientVolume:Number = ProfileManager.DEFAULT_MUSIC_VOLUME;
		public var effectsVolume:Number = ProfileManager.DEFAULT_SFX_VOLUME;
		public var dialogSpeed:Number = Dialog.DEFAULT_DIALOG_SPEED;
		/**
		 * Is defined used to override application quality setting.
		 * On mobile this is determined by device, unless qualityOverride is defined
		 * On web we default to max, unless qualityOverride is defined
		 */
		public var qualityOverride:Number = -1;	// NOTE :: -1 is preferable to NaN (JSON does not accept NaN)
		public var preferredLanguage:int = LanguageCode.NUMBER_EN;

		public var age:Number = PlayerContext.DEFAULT_AGE;
		private var _gender:String = "male";
		public var look:PlayerLook;
		public var island:String;
		//making sure previous island is formatted properly
		private var _previousIsland:String;
		public function get previousIsland():String
		{
			return _previousIsland;
		}
		public function set previousIsland(value:String):void
		{
			if(DataUtils.validString(value))
				_previousIsland = value.substr(0,1).toLowerCase()+value.substr(1);
			else
				_previousIsland = value;
		}
		public var scene:String;
		public var lastX:Number;
		public var lastY:Number;
		public var lastDirection:String;
		public var tribeData:TribeData;
		public var profileComplete:Boolean;
		public var memberStatus:MembershipStatus;
		public var avatarFirstName:String = "hamburger";
		public var avatarLastName:String = "hamburger";
		public var isGuest:Boolean = true;
		private var _login:String = "";
		private var _pass_hash:String = "";
		private var _dbid:Number;
		public var guid:String;
		
		private var _credits:Number = 0;
		private var _creditsChanged:Signal = new Signal(ProfileData, Number);
		
		// inventory
		public var inventoryType:String;		// stores the type that the inventory opens to, when a new card is earn inventory should open to its type
		public var inventorySubType:String;		// stores the sub-type the inventory opens to, currently only necessary for campaign cards
		public var newInventoryCard:Boolean;	// indicates if there is a new card in the inventory that has not yet been viewed, causes inventory to sparkle

		public function ProfileData(login:String = null)
		{
			this.login = login;
			this.guid = GUID.create(); // global unique identifer
		}
		
		public function get login():String { return _login; }
		public function set login(value:String):void
		{
			if(value != null)
			{
				if(_login != value)
				{
					_login = value;
				}
			}
		}
		
		public function get pass_hash():String { return _pass_hash; }
		public function set pass_hash(value:String):void
		{
			if(value != null)
			{
				if(_pass_hash != value)
				{
					_pass_hash = value;
				}
			}
		}
		
		public function get dbid():Number { return _dbid; }
		public function set dbid(value:Number):void
		{
			if(_dbid != value)
			{
				_dbid = value;
			}
		}
		
		public function get gender():String { return _gender; }
		public function set gender(value:String):void
		{
			if(value == "male" || value == "female")
			{
				if(_gender != value)
				{
					_gender = value;
				}
			}
		}
		
		public function get creditsChanged():Signal { return _creditsChanged; }
		public function get credits():Number { return _credits; }
		public function set credits(value:Number):void
		{
			//Only set and dispatch when the values are different and the new value is a valid number.
			if(_credits != value && !isNaN(value))
			{
				var previous:Number = _credits;
				_credits = value;
				_creditsChanged.dispatch(this, previous);
			}
		}
		
		public function RefreshMembershipStatus(shellApi:ShellApi, callback:Function = null):void
		{
			// refresh membership 
			var vars:URLVariables = new URLVariables;
			vars.login 			= login;
			vars.pass_hash 	= pass_hash;
			vars.dbid 			= dbid;
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/get_mem_status.php", vars, URLRequestMethod.POST, Command.create(OnRefreshMembershipStatus, callback));
		}
		
		private function OnRefreshMembershipStatus(event:Event, callback:Function = null):void
		{
			var vars:URLVariables = new URLVariables(event.currentTarget.data);
			if (vars.status != "nologin" && vars.status != "badpass" && vars.status != "dberror")
			{
				if(vars.memstatus == "active-renew")
					memberStatus.statusCode = MembershipStatus.MEMBERSHIP_EXTENDED;
				if(vars.memstatus == "active-norenew")
					memberStatus.statusCode = MembershipStatus.MEMBERSHIP_ACTIVE;
			}
			trace("ProfileData :: Membership status refreshed");
			if(callback)
			{
				callback();
			}
		}

		public function get isMember():Boolean
		{
			var result:Boolean = false;

			if(memberStatus)
			{
				result = (memberStatus.statusCode == MembershipStatus.MEMBERSHIP_ACTIVE || memberStatus.statusCode == MembershipStatus.MEMBERSHIP_EXTENDED);
			}

			return(result);
		}

		public function get schoolGrade():Number {	return age - 5; }

		public function get avatarName():String {	return avatarFirstName + ' ' + avatarLastName; }

		/////////////////////////////////// USERFIELDS ///////////////////////////////////

		/**
		 * Holds arbitrary key-value pairs for two
		 * domains. Properties named for AS3 islands
		 * are dictionaries of key-value pairs of
		 * island-specific user fields. Properties with
		 * other names are global key-value pairs
		 * which are not island-specific.
		 */
		public var _userFields:Dictionary;
		public function get userFields():Dictionary { return _userFields; }
		public function assertUserFields():void
		{
			if( _userFields == null )
			{
				_userFields = new Dictionary();
			}
		}

		public function getUserField(fieldName:String, islandName:String = ""):*
		{
			var value:*;
			if (_userFields != null)
			{
				if( DataUtils.validString(islandName) )
				{
					if (islandName in _userFields)
					{
						if (fieldName in _userFields[islandName])
						{
							value = _userFields[islandName][fieldName];
						}
					}
				}
				else
				{
					if (fieldName in _userFields)
					{
						value = _userFields[fieldName];
					}
				}
			}
			return value;
		}

		public function setUserField(fieldName:String, fieldValue:*, islandName:String = ""):void
		{
			if ( _userFields == null ) { _userFields = new Dictionary(); }

			if ( DataUtils.validString(islandName) )
			{
				if( !(islandName in _userFields) )
				{
					_userFields[islandName] = new Dictionary();
				}
				_userFields[islandName][fieldName] = fieldValue;
			}
			else
			{
				userFields[fieldName] = fieldValue;
			}
		}

		public function resetUserFieldsForIsland(islandName:String):void
		{
			if( _userFields )
			{
				if( _userFields[islandName] )
				{
					_userFields[islandName] = new Dictionary();
				}
			}
		}

		/////////////////////////////////// DEBUG ///////////////////////////////////

		public function toString():String
		{
			var summary:String = "[ProfileData v" + profileVersion + "\n";
			summary += "\tevents\n";
//			for (var islandName:String in events) {
//				summary += "\t\t" + islandName + "\t" + events[islandName] + "\n";
//			}
			summary += eventsToString();

			summary += "\titems\n";
//			for (islandName in events) {
//				summary += "\t\t" + islandName + "\t" + items[islandName] + "\n";
//			}
			summary += itemsToString();

			summary += "\tphotos\n";
			for (var key:String in photos) {
				summary += "\t\t" + key + "\t" + photos[key] + "\n";
			}

			summary += "\tscores\n";
			for (key in scores) {
				summary += "\t\t" + key + "\t" + scores[key].score + "\n";
			}
			summary += "\tlasts\n";
//			for (key in lastScene) {
//				summary += "\t\t" + key + "\t" + lastScene[key] + "\n";
//			}
			summary += lastScenesToString();

			summary += "\tuser fields\n";
			summary += userFieldsToString();

			summary += "\tcompletions\n";
			summary += completionsToString();

			summary += JSON.stringify(this, null, "\t");
			summary += "]\n";
			return summary;
		}

		public function eventsToString():String {
			var s:String = '';
			for (var islandName:String in events) {
				s += "\t\t" + islandName + "\t" + events[islandName] + "\n";
			}
			return s;
		}

		public function itemsToString():String {
			var s:String = '';
			for (var islandName:String in items) {
				s += "\t\t" + islandName + "\t" + items[islandName] + "\n";
			}
			return s;
		}

		public function lastScenesToString():String {
			var s:String = '';
			for (var key:String in lastScene) {
				s += "\t\t" + key + "\t" + lastScene[key] + "\n";
			}
			return s;
		}

		public function userFieldsToString():String {
			var s:String = '';
			for (var key:String in userFields) {
				var fieldValue:* = userFields[key];
				if (! DataUtils.isSimple(fieldValue)) {
					key += "\n";
					var summary:String = '';
					for (var p:String in fieldValue) {
						summary += "\t\t\t" + p + "\t" + fieldValue[p] + "\n";
					}
					fieldValue = summary.slice(0,-1);	// trim that last newline
				}
				s += "\t\t" + key + "\t" + fieldValue + "\n";
			}
			return s;
		}

		public function completionsToString():String
		{
			var s:String = '';
			for (var key:String in islandCompletes) {
				s += "\t\t" + key + "\t" + islandCompletes[key] + "\n";
			}
			return s;
		}

	}
}
