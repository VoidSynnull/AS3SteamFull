package game.scenes.lands.shared.world {

	import flash.utils.ByteArray;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.scenes.lands.shared.tileLib.classes.LandEncoder;

	/**
	 * represents a single data-source for a world.
	 * 
	 * subclasses override to provide implementations for server sources, file sources, etc.
	 * 
	 */

	public class WorldDataSource {

		protected var galaxy:LandGalaxy;

		public function WorldDataSource( galaxy:LandGalaxy ) {

			this.galaxy = galaxy;

		} //

		public function saveSceneLocation( realm:LandRealmData ):void {
		} //

		public function getWorldXml( galaxy:LandGalaxy, curTime:Number ):XML {

			return ( new LandEncoder() ).encodeWorld( galaxy, curTime );

		} //

		public function restoreFromXml( worldXML:XML, galaxy:LandGalaxy ):void {

			( new LandEncoder() ).decodeFileWorld( galaxy, worldXML );

		} //

		/**
		 * marks a realm visited for server.
		 */
		public function visitRealm( realm:LandRealmData ):void {
		} //

		/**
		 * marks a scene visited for server.
		 */
		public function visitScene( realm:LandRealmData ):void {
		} //

		public function createNewRealm( galaxy:LandGalaxy, biome:String, seed:uint, size:int, name:String, callback:Function ):void {}

		/**
		 * callback( err:String )
		 * default function simply removes the realm from the current galaxy.
		 */
		public function destroyRealm( realm:LandRealmData, callback:Function ):void {

			galaxy.removeRealm( realm );

			if ( callback ) {
				callback( null );
			}

		} //

		/**
		 * Save scene to to long-term storage.
		 * callback is onSaved( result.succeeded, result.status );
		 * empty if no error
		 */
		public function saveCurScene( onSaved:Function=null ):void {

			if ( onSaved != null ) {
				onSaved( true, 0 );
			}

		} //

		/**
		 * only used for RemoteWorldSource, but put here so you don't need a type-conversion.
		 */
		public function saveSceneAndThumbnail( thumbData:ByteArray, onSaved:Function ):void {

			if ( onSaved != null ) {
				onSaved( true, 0 );
			}

		}

		public function saveGalaxy():void {
		} //

		public function saveCurRealm():void {
		} //

		/**
		 * attempts to load a scene from the given realm.
		 * the data source can decide a load would be pointless - ( such as for a local file source )
		 * in which case 'false' is returned to indicate no load will occur and the callback will not be called.
		 * 
		 * callback is: onSceneLoaded( scene:LandSceneData, success:Boolean )
		 * 	-if there is a load error, scene will exist but have no xml data.
		 */
		public function tryLoadScene( realm:LandRealmData, sceneX:int, sceneY:int, callback:Function=null ):Boolean {

			// return false by default, no loading occurs.
			return false;

		} //

		/**
		 * load a user galaxy. for a remote source, this loads the user's default galaxy.
		 * for a local source, it lets the user pick the land file to load.
		 * 
		 * onLoaded( errType:String )
		 * 	- if no error, errType is null.
		 */
		public function loadGalaxy( onLoaded:Function=null ):void {
		} //

		/**
		 * load a specific galaxy from the server.
		 * for a remote source this could be a specific galaxy id from the database.
		 * for a file source, it is a land.xml file on the server side.
		 * 
		 * onLoaded( errType:String )
		 * 	- if no error, errType is null.
		 */
		public function loadServerGalaxy( shell:ShellApi, worldPath:String, onLoaded:Function=null ):void {

			galaxy.loadSource = "server";			
			shell.loadFile( worldPath, Command.create( this.serverWorldLoaded, onLoaded ) );

		} //

		protected function serverWorldLoaded( xml:XML, onLoaded:Function ):void {

			var error:String;

			if ( xml == null ) {
				error = "no data";
			} else {

				( new LandEncoder() ).decodeFileWorld( galaxy, xml );

			}

			if ( onLoaded ) {
				onLoaded( error );
			}

		} //

		/**
		 * print all the variables in an object.
		 */
		protected function getObjectString( obj:Object ):String {

			var result:String = "{\n";
			var sub:Object;

			for( var s:String in obj ) {
				
				sub = obj[s];

				if ( sub is Number ) {

					result += ( s + ": " + sub );

				} else if ( sub is String ) {

					result += ( s + ": " + sub );

				} else if ( sub is Array ) {
					
					result += s + ": " + this.getArrayString( sub as Array );

				} else if ( sub is Object ) {
					
					result += s + ": " + this.getObjectString( sub );
					
				} else {	
					result += s + ": " + sub;
				}

				result += "\n";

			} //

			return ( result + "}" );

		} //

		protected function getArrayString( a:Array ):String {

			var result:String = "[\n";
			var sub:Object;

			for( var i:int = a.length-1; i >= 0; i-- ) {

				sub = a[i];

				if ( sub is Number ) {
					
					result += sub;
					
				} else if ( sub is String ) {
					
					result += sub;
					
				} else if ( sub is Array ) {

					result += "\n" + this.getArrayString( sub as Array );

				} else if ( sub is Object ) {
					
					result += "\n" + this.getObjectString( sub );

				} else {

					result += sub;
				}

				if ( i > 0 ) {
					result += ", ";
				}

			} //

			return ( result + "]" );

		} //

		/*
			{
			realm_seed: 464395476
			realm_created_by: 21489377
			biome_name: snow
			file_data: <scene></scene>
			realm_name: Gusheatha
			realm_id: 250
			realm_rating: 0
			scene_created: 1426704237
			scene_shared: 0
			y_position: 1620
			realm_approved: 1
			realm_last_visited: 1430886418
			scenes_array: [
				0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
			scene_id: 6
			scene_created_by: 21489377
			realm_created: 1426704234
			thumbnail_file_path: http://s3.amazonaws.com/poptropica-realms-thumbnails/dev/21489377/250/thumbnail.jpg
			x_position: 978
			scene_approved: 1
			realm_visits_count: 7
			realm_shared: 1
			size: 13
		}*/
		protected function createGalaxyFromObject( galaxyObj:Object ):void {
			
			var realmObj:Object;
			var realm:LandRealmData;
			
			// find last visited realm.
			var lastVisitTime:Number = 0;
			var lastVisited:LandRealmData;
			
			var count:int = 0;
			for( var realmId:int in galaxyObj ) {
				
				realmObj = galaxyObj[ realmId ];
				if ( realmObj == null ) {
					continue;	// shouldn't happen. null data from server?
				}

				realm = this.makeRealm( realmObj, realmId );

				// check if last visited realm.
				if ( (lastVisited == null) || realm.last_visit_time > lastVisitTime ) {
					lastVisited = realm;
					lastVisitTime = realm.last_visit_time;
				} //

			} //

			if ( lastVisited != null ) {
				galaxy.setCurRealm( lastVisited );
			} else if ( galaxy.getRealmCount() > 0 ) {
				galaxy.setCurRealm( galaxy.getRealms()[0] );
			} //

		} //

		protected function makeRealm( realmObj:Object, realmId:int ):LandRealmData {

			var realm:LandRealmData;

			realm = galaxy.createNewRealm( realmObj.realm_seed, realmObj.biome_name, realmObj.size, realmObj.realm_name );
			realm.id = realmId;
			realm.thumbURL = realmObj.thumbnail_file_path;			// thumbnail url

			//	this.shellApi.logWWW( "scenes array: " + realmObj.scenes_array );
			if ( realmObj.scenes_array != null ) {
				realm.copySceneMap( realmObj.scenes_array );
			}

			if ( realmObj.realm_shared != null ) {
				realm.shareStatus = realmObj.realm_shared;
			}
			if ( realmObj.realm_approved != null ) {
				realm.approveStatus = realmObj.realm_approved;
			}

			realm.rating = realmObj.realm_rating;
			if ( realmObj.realm_created_by_login != null ) {
				realm.creator_login = realmObj.realm_created_by_login;
			} //
			if ( !isNaN( realmObj.realm_shared_date ) ) {
				realm.sharedDate = realmObj.realm_shared_date;
			}

			//	this.shellApi.logWWW( "scenes array: " + realmObj.scenes_array );
			if ( realmObj.scenes_array != null ) {
				realm.copySceneMap( realmObj.scenes_array );
			}

			if ( realmObj.realm_last_visited != null ) {
				realm.last_visit_time = realmObj.realm_last_visited;
			} //

			if ( realmObj.scene_id != null ) {
				
				realm.curLoc.setTo( realmObj.scene_id, 0 );
				if ( realmObj.file_data ) {
					
					// data of current scene.
					realm.setLocationData( realmObj.scene_id, 0, new XML( realmObj.file_data ) );
					
				} //
	
			} //
			
			realm.playerPosition.setTo( realmObj.x_position, realmObj.y_position );
			
			return realm;
			
		} //

	} // class

} // package