package game.scenes.lands.shared.world {
	
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.Location;

	public class LandRealmData {

		/**
		 * constants for realm share status.
		 */
		static public const REALM_STATUS_NONE:int = 0;
		static public const REALM_STATUS_SHARED:int = 1;

		/**
		 * constants for approveStatus ( plus REALM_STATUS_NONE )
		 */
		static public const REALM_STATUS_APPROVED:int = 2;
		static public const REALM_STATUS_REJECTED:int = 4;

		/**
		 * maximum number of scenes in the realm, also the max sceneX before the realm loops.
		 */
		protected var _realmSize:int;
		public function get realmSize():int { return this._realmSize; }

		/**
		 * simple name of realm. these should be unique per galaxy. in old land xml files,
		 * each realm will be named the same as its biome.
		 */
		protected var realmName:String;
		public function get name():String { return this.realmName; }

		protected var _biomeType:String;
		public function get biome():String { return this._biomeType };

		/**
		 * There might be realm ids different from simple realm names,
		 * in order to specify a unique realm on the server.
		 */
		protected var _id:uint;
		public function get id():uint { return this._id; }

		/**
		 * the id shouldn't be changed after you set it once, though you might use this
		 * to re-use existing realmData objects.
		 */
		public function set id( n:uint ):void { this._id = n; }

		/**
		 * maps scene point locations on the island to byteArray data.
		 * If no byteArray is found for a given scene, it is generated
		 * using the default randSeed.
		 * 
		 * the index will be based on the x,y coordinate of the scene in the island.
		 */
		protected var realmScenes:Dictionary;

		/**
		 * location in the biome of the current scene. x,y coordinates are positive, one byte each. ( 0->255,0->255)
		 */
		protected var sceneLoc:Location;
		public function get curLoc():Location { return this.sceneLoc; }

		/**
		 * curScene is null unless there is data stored for that scene.
		 */
		protected var _curSceneData:LandSceneData;
		public function get curSceneData():LandSceneData { return this._curSceneData; }

		/**
		 * x,y position of the player when last on this realm.
		 * used to return the player to their exact spot in the realm when it's reloaded.
		 */
		protected var _playerPosition:Location;
		public function get playerPosition():Location { return this._playerPosition; }

		/**
		 * url for the thumbnail image of the realm, if available.
		 */
		public var thumbURL:String;

		/**
		 * this has to be kept in local memory?
		 */
		public var shareStatus:int = 0;

		/**
		 * date when realm was last shared.
		 */
		public var sharedDate:int = 0;

		public var approveStatus:int = 0;

		/**
		 * map of which scenes exist in the database.  must be array so data can be quickly sent to db.
		 */
		public var sceneMap:Array;

		/**
		 * the number of likes for the realm.
		 */
		public var rating:int;

		/**
		 * the seed used to generate the realm.
		 */
		private var _realmSeed:uint;
		public function get seed():uint { return this._realmSeed; }
		public function set seed( n:uint ):void { this._realmSeed = n; }

		public var last_visit_time:Number = 0;

		public var creator_login:String;
		/**
		 * creator display name.
		 */
		public var avatar_name:String;

		public function LandRealmData( biomeType:String, realmSeed:uint=0, size:int=256, newName:String="" ) {

			if ( newName == "" || newName == null ) {
				this.realmName = biomeType;
			} else {
				this.realmName = newName;
			}

			this._realmSize = size;
			this._biomeType = biomeType;
			this.realmScenes = new Dictionary();

			this._realmSeed = realmSeed;

			// should actually be center of the screen in x-coordinate.
			this._playerPosition = new Location( 1400, 100 );
			this.sceneLoc = new Location( size/2 );

			this.initSceneMap();

		} // LandRealmData

		public function initSceneMap():void {

			this.sceneMap = new Array( this.realmSize );
			for( var i:int = this.realmSize-1; i >= 0; i-- ) {
				this.sceneMap[i] = 0;
			} //

		} //

		public function copySceneMap( newMap:Array ):void {

			var len:int = newMap.length;
			this.sceneMap.length = len;

			for( var i:int = 0; i < len; i++ ) {

				this.sceneMap[i] = Number( newMap[i] );

			} //

		} //

		/**
		 * returns true if the given scene has data cached locally.
		 */
		public function hasSceneData( sceneNum:int ):Boolean {

			return ( this.realmScenes[ sceneNum ] != null );

		} //

		/**
		 * returns number of scenes with saved data.
		 */
		public function getSceneCount():int {

			var count:int = 0;

			for( var i:int = this.sceneMap.length-1; i >= 0; i-- ) {
				
				if ( this.sceneMap[i] != 0 ) {
					count++;
				}
				
			} //

			return count;

		} //

		public function hasSavedScenes():Boolean {

			for( var i:int = this.sceneMap.length-1; i >= 0; i-- ) {

				if ( this.sceneMap[i] != 0 ) {
					return true;
				}

			} //

			return false;

		} //

		/**
		 * indicates if the given scene has data available in the database
		 * ( according to the scene map )
		 */
		public function hasSavedData( sceneNum:int ):Boolean {

			return ( this.sceneMap[sceneNum] != 0 );

		} //

		/**
		 * performs the translation from realmCode to user-readable string.
		 * the encoding skips: 1,L,0,O
		 * also extra letters and all vowels have been removed to make it harder to form swear words.
		 */
		public function getRealmCode():String {

			const encode:String = "23456789bcdhjmpqrtvwxyz";
			var base:uint = encode.length;

			var num:uint = this.id;
			var codeString:String = "";

			while ( num > 0 ) {

				codeString = encode.charAt(num % base) + codeString;
				num /= base;

			} //

			return codeString;

		} //

		static public function GetRealmIdFromCode( code:String ):uint {

			const encode:String = "23456789bcdhjmpqrtvwxyz";

			var new_id:uint = 0;
			var i:int = 0;
			var base:int = encode.length;
			var len:int = code.length;

			var ind:int;

			while ( i < len ) {

				new_id *= base;
				ind = encode.indexOf( code.charAt( i++ ) );
				if ( ind == -1 ) {
					// error in code
					return 0;
				}
				new_id += ind;

			} //

			return new_id;

		}

		public function reset():void {

			this.realmScenes = new Dictionary();
			this.sceneLoc.setTo( this._realmSize/2, 0 );
			this._curSceneData = null;

		} //

		/**
		 * sets the curSceneData to the data stored for the curLoc location.
		 * used after the realm is just loaded to prepare the correct sceneData
		 */
		public function goCurrentLoc():void {

			this._curSceneData = this.getSceneData( this.curLoc.x, this.curLoc.y );

		} //

		/**
		 * creates an empty scene marker with nothing in it. scenes are created empty even
		 * when there is no saved data for them, so the data loaders know not to attempt
		 * any scene loading - we can see locally there's nothing there.
		 */
		public function createEmptyScene( x:int, y:int ):LandSceneData {

			var sceneData:LandSceneData = new LandSceneData();
			this.setSceneData( x, y, sceneData );

			return sceneData;

		} //

		/**
		 * removed the cached data for the scene at the given x,y location.
		 */
		public function deleteSceneData( x:int, y:int ):void {

			delete this.realmScenes[x];

		} //

		/**
		 * sets the current location within the realm and makes it the current scene.
		 */
		public function setCurLocation( sceneX:int, sceneY:int ):void {

			this.curLoc.setTo( sceneX, sceneY );
			this._curSceneData = this.getSceneData( sceneX, sceneY );

		} //

		public function setLocationData( sceneX:int, sceneY:int, sceneXML:XML ):void {

			var sceneData:LandSceneData = this.getSceneData( sceneX, sceneY );
			if ( sceneData == null ) {
				sceneData = new LandSceneData( sceneXML );
				this.setSceneData( sceneX, sceneY, sceneData );
			} else {
				sceneData.xmlData = sceneXML;
			} //

		} //

		/**
		 * stores the current scene in the realm's data - but does not save it to disk.
		 */
		public function cacheCurScene( data:LandGameData ):void {

			if ( this._curSceneData == null ) {

				this._curSceneData = new LandSceneData();
				this.setSceneData( this.sceneLoc.x, this.sceneLoc.y, this._curSceneData );

			} //

			this.sceneMap[ this.sceneLoc.x ] = 1;
			this.curSceneData.cacheSceneXML( data );

		} //

		/**
		 * returns true if tileData has been stored for the current scene.
		 * if true, the scene doesn't use the seed to generate.
		 */
		/*public function hasTileData():Boolean {

			return ( this._curSceneData != null && this._curSceneData.hasTileData() );

		} //*/

		public function getSceneData( x:int, y:int ):LandSceneData {

			return this.realmScenes[ x ];

		} //

		public function setSceneData( x:int, y:int, scene:LandSceneData ):void {

			this.realmScenes[ x ] = scene;

		} //

		public function moveLeft():void {

			this.sceneLoc.x--;
			if ( this.sceneLoc.x < 0 ) {
				this.sceneLoc.x = this.realmSize-1;
			}
			this._curSceneData = this.realmScenes[ this.curLoc.x ];

		} //

		public function moveRight():void {

			if ( this.sceneLoc.x == this.realmSize-1 ) {
				this.sceneLoc.x = 0;
			} else {
				this.sceneLoc.x++;
			}
			this._curSceneData = this.realmScenes[ this.curLoc.x ];

		} //

		public function getScenes():Dictionary {
			return this.realmScenes;
		}

	} // class

} // package