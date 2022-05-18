package game.scenes.lands.shared.world {

	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.data.comm.PopResponse;
	import game.proxy.DataStoreRequest;
	import game.proxy.PopDataStoreRequest;

	public class RemoteWorldSource extends WorldDataSource {

		protected var shellApi:ShellApi;

		public function RemoteWorldSource( shell:ShellApi, galaxy:LandGalaxy ) {

			super( galaxy );

			this.shellApi = shell;
			this.galaxy = galaxy;
			galaxy.loadSource = "remote";

		} //

		public function setShareStatus( realm:LandRealmData, shareStatus:int=1 ):void {

			// this appears to change the sharing status of a realm.
			var req:DataStoreRequest = PopDataStoreRequest.realmShareStatusStorageRequest( realm.id, shareStatus );
			shellApi.siteProxy.store( req, this.onShareStatusSaved );

			// STORE THE SHARE TIME because we won't get it back from the database til next reload.
			realm.sharedDate = new Date().time/1000;
			
		} //

		/**
		 * attempts to load a scene from the given realm.
		 * the data source can decide a load would be pointless - ( such as for a local file source )
		 * in which case 'false' is returned to indicate no load will occur and the callback will not be called.
		 * 
		 * callback is: onSceneLoaded( scene:LandSceneData, success:Boolean )
		 * 	-if there is a load error, scene will exist but have no xml data.
		 */
		override public function tryLoadScene( realm:LandRealmData, sceneX:int, sceneY:int, callback:Function=null ):Boolean {

			// create a stub to hold the new scene. this could also be done on callback instead.
			var scene:LandSceneData = realm.createEmptyScene( sceneX, sceneY );

		//	this.shellApi.logWWW( "attempting LOAD SCENE: " + sceneX + "   in realm: " + realm.id );
			shellApi.siteProxy.retrieve(PopDataStoreRequest.realmSceneRetrievalRequest(realm.id, sceneX), Command.create( this.onSceneLoaded, scene, callback ));

			// return false by default, no loading occurs.
			return true;

		} //

		/**
		 * load a user galaxy. for a remote source, this loads the user's default galaxy.
		 * for a local source, it lets the user pick the land file to load.
		 * 
		 * onLoaded( errType:String )
		 * 	- if no error, errType is null.
		 */
		override public function loadGalaxy( onLoaded:Function=null ):void {

			this.galaxy.isPublicGalaxy = false;

		//	this.shellApi.logWWW( "attempting to load galaxy for: " + shellApi.profileManager.active.login );
			shellApi.siteProxy.retrieve(PopDataStoreRequest.realmsRetrievalRequest(shellApi.profileManager.active.login), Command.create( this.onGalaxyLoaded, onLoaded ));

		} //

		/**
		 * onLoaded( data:LandRealmData )
		 */
		public function loadRealm( id:uint, onLoaded:Function=null ):void {

			this.shellApi.logWWW( "attempting to load realm: " + id );

			this.shellApi.siteProxy.retrieve(
				PopDataStoreRequest.realmInfoRetrievalRequest(id), Command.create( this.onRealmLoaded, onLoaded ));

		} //

		/**
		 *  onSaved( success:Boolean, errorCode:int )
		 */
		override public function saveSceneAndThumbnail( thumbData:ByteArray, onSaved:Function ):void {

			var curRealm:LandRealmData = this.galaxy.curRealm;
			//this.shellApi.logWWW( "attempt to save scene w/ thumbnail" );

			if ( curRealm == null ) {
				// ERROR CASE: realm is null. why?
				if ( onSaved ) {
					onSaved( true, 0 );
				} //
			}

			// !! the curScene or curScene xml being null is not necessarily an error.
			// if the user never made any changes to the scene, either set of data might be empty
			// and no save will be attempted.
			// however this MIGHT be an error so its a difficult case. not sure what the error callback should be.
			var curScene:LandSceneData = curRealm.curSceneData;
			if ( curScene == null || curScene.xmlData == null) {
			//	this.shellApi.logWWW( "NO SCENE DATA TO SAVE" );
				if ( onSaved ){
					onSaved( true, 0 );
				}
				return;
			}

			shellApi.siteProxy.store(PopDataStoreRequest.realmSceneStorageRequest(	curRealm.id,
																					curRealm.curLoc.x,
																					curRealm.biome,
																					curScene.xmlData,
																					thumbData,
																					curRealm.shareStatus,
																					curRealm.playerPosition.x,
																					curRealm.playerPosition.y), Command.create( this.onSceneSaved, curRealm, onSaved ));

		} //

		/**
		 * before the current scene is stored, all the scene xml should be valid - with includes <monster> and <item>
		 * tags etc.
		 * 
		 * onSaved( success:Boolean, errorCode:int )
		 */
		override public function saveCurScene( onSaved:Function=null ):void {

			var curRealm:LandRealmData = galaxy.curRealm;

			//this.shellApi.logWWW( "RemoteWorldSource: TRY SAVE SCENE: " + curRealm.curLoc.x );

			if ( curRealm == null ) {
				// ERROR CASE: realm is null. why?	
				if ( onSaved ) {
					onSaved( "no current realm" );
				} //
			}

			// !! the curScene or curScene xml being null is not necessarily an error.
			// if the user never made any changes to the scene, either set of data might be empty
			// and no save will be attempted.
			// however this MIGHT be an error so its a difficult case. not sure what the error callback should be.
			var curScene:LandSceneData = curRealm.curSceneData;
			if ( curScene == null || curScene.xmlData == null) {
				//this.shellApi.logWWW( "RemoteWorldSource: NO SCENE DATA TO SAVE." );
				if ( onSaved ){
					onSaved( null );
				}
				return;
			}

			//this.shellApi.logWWW( "RemoteWorldSource: CURSCENE IS SAVING" );

			shellApi.siteProxy.store(PopDataStoreRequest.realmSceneStorageRequest(	curRealm.id,
																					curRealm.curLoc.x,
																					curRealm.biome,
																					curScene.xmlData,
																					null,
																					curRealm.shareStatus,
																					curRealm.playerPosition.x,
																					curRealm.playerPosition.y), Command.create( this.onSceneSaved, curRealm, onSaved ));

		} //

		/**
		 *  onSaved( success:Boolean, errorCode:int )
		 */
		public function saveRealmScene( realm:LandRealmData, sceneX:int, onSaved:Function=null ):void {

		//	this.shellApi.logWWW( "attempt SAVE SCENE: " + sceneX );

			// !! the curScene or curScene xml being null is not necessarily an error.
			// if the user never made any changes to the scene, either set of data might be empty
			// and no save will be attempted.
			// however this MIGHT be an error so its a difficult case. not sure what the error callback should be.
			var curScene:LandSceneData = realm.getSceneData( sceneX, 0 );
			if ( curScene == null || curScene.xmlData == null) {
			//	this.shellApi.logWWW( "NO SCENE DATA TO SAVE." );
				if ( onSaved ){
					onSaved( null );
				}
				return;
			}

			shellApi.siteProxy.store(PopDataStoreRequest.realmSceneStorageRequest(	realm.id,
																					sceneX,
																					realm.biome,
																					curScene.xmlData,
																					null,
																					realm.shareStatus,
																					NaN,
																					NaN), Command.create( this.onSceneSaved, realm, onSaved ));

		} //

		/**
		 * this function will create a new realm on the server.
		 * the callback callback( realm:LandRealmData, errorCode:int ) will be triggered with the server response.
		 *
		 */
		override public function createNewRealm( galaxy:LandGalaxy, biome:String, seed:uint, size:int, name:String, callback:Function ):void {

			this.addNewRealm( galaxy, new LandRealmData( biome, seed, size, name ), callback );

		} //

		/**
		 * adds the realm passed as a parameter to the current galaxy,  and attempts to save it to the server.
		 * 
		 * onCreate( realm:LandRealmData, errorCode:int ) - triggered after result from server.
		 */
		public function addNewRealm( galaxy:LandGalaxy, realm:LandRealmData, onCreate:Function ):void {

			// !!! it might be possible to add the realm before the callback. this means the user could access the realm even
			// if it wasn't saved to server. that could be good or bad.

			//this.shellApi.logWWW( "ATTEMPTING TO CREATE NEW REALM" );

			shellApi.siteProxy.store(PopDataStoreRequest.newRealmStorageRequest(realm.name,
																				realm.biome,
																				realm.realmSize,
																				realm.seed), Command.create( this.onRealmCreated, realm, onCreate ));

		} //

		/**
		 * saves a realm with scenes that already exists on the client side, but has no yet been saved to the server.
		 * this is used for loading world files which are then uploaded to server.
		 */
		public function saveExistingRealm( realm:LandRealmData, onComplete:Function ):void {

			shellApi.siteProxy.store(PopDataStoreRequest.newRealmStorageRequest(realm.name,
																				realm.biome,
																				realm.realmSize,
																				realm.seed), Command.create( this.onExistingRealmSaved, realm, onComplete ));

		} //

		override public function visitRealm( realm:LandRealmData ):void {

			realm.last_visit_time = new Date().getTime()/1000;
			//this.shellApi.logWWW( "Attempting visit realm: " + realm.id + "   visit time: " +  realm.last_visit_time );

			shellApi.siteProxy.store(PopDataStoreRequest.visitRealmStorageRequest(realm.id), onRealmVisited);

		} //

		override public function visitScene( realm:LandRealmData ):void {

		//	this.shellApi.logWWW( "Attempting visit scene: " + realm.curLoc.x + "    of realm: " + realm.id );
			shellApi.siteProxy.store(PopDataStoreRequest.visitRealmSceneStorageRequest(	realm.id,
																						realm.curLoc.x,
																						realm.playerPosition.x,
																						realm.playerPosition.y), onSceneVisited);

		} //

		override public function saveSceneLocation( realm:LandRealmData ):void {

			shellApi.siteProxy.store(PopDataStoreRequest.realmLocationStorageRequest(realm.id, realm.curLoc.x, realm.playerPosition.x, realm.playerPosition.y), null);

		} //

		/**
		 * callback( err:String )
		 */
		public function destroyRealmById( galaxy:LandGalaxy, realmId:uint, callback:Function ):void {

		//	this.shellApi.logWWW( "attempting to destroy realm" );

			// go through the current galaxy and destroy the realm with matching id.
			galaxy.removeRealmById( realmId );
			shellApi.siteProxy.store(PopDataStoreRequest.realmDeletionRequest(realmId), Command.create( this.onRealmDestroyed, callback ));

		} //

		override public function destroyRealm( realm:LandRealmData, callback:Function ):void {

			//this.shellApi.logWWW( "attempting to destroy realm" );
			// go through the current galaxy and destroy the realm with matching id.
			galaxy.removeRealm( realm );
			shellApi.siteProxy.store(PopDataStoreRequest.realmDeletionRequest(realm.id), Command.create( this.onRealmDestroyed, callback ));

		} //

		override public function loadServerGalaxy( shell:ShellApi, worldPath:String, onLoaded:Function=null ):void {

			super.loadServerGalaxy( shellApi, worldPath, Command.create( this.onServerGalaxyLoaded, onLoaded ) );

			// file source would change the load source. need to set it back. too hacky though. fix this.
			this.galaxy.loadSource = "remote";

		}

		/**
		 * ######################### CALLBACKS #########################
		 */

		/**
		 * no PopResponse object here because this is the callback for a server-xml file load.
		 */
		protected function onServerGalaxyLoaded( error:String, cb:Function ):void {

			if ( error != null ) {

				if ( cb ) {
					cb( error );
				}
				return;

			}

			var realms:Vector.<LandRealmData> = this.galaxy.getRealms();

			for( var i:int = realms.length-1; i >= 0; i-- ) {

				this.saveExistingRealm( realms[i], null );

			} //

			// save all the newly loaded realms, and their scenes -- very annoying.
			if ( !this.galaxy.curRealm ) {
				this.galaxy.setCurRealm( realms[0] );
			} //

			if ( cb ) {
				cb( error );
			}

		} //

		/**
		 * pretty straight forward. sceneXML for a scene was recieved from the server. or fail.

 			here is the (possibly out of date) official data list:

		 	result.data.biome_name
		 	result.data.file_data
		 	result.data.scene_created
		 	result.data.scene_created_by
			result.data.scene_last_visited
			result.data.scene_last_visited_by
			result.data.scene_shared
			result.data.scenes_approved
			result.data.player_x
			result.data.player_y
		 *
		 */
		protected function onSceneLoaded( result:PopResponse, scene:LandSceneData, callback:Function ):void {

			if ( !result.succeeded ) {

				// no data (or corrupt data) was returned for the scene, so it should be cleared in the cur galaxy.
				this.galaxy.curRealm.deleteSceneData( this.galaxy.curRealm.curLoc.x, 0 );

			//	this.shellApi.logWWW( "scene load failed: " + result.toString() );
				if ( callback ) {
					callback( scene, result.succeeded );
				}
				return;

			}

			//this.shellApi.logWWW( "scene loaded from server" );

			var resultObj:Object = result.data;
			/*for( var s:String in resultObj ) {
				this.shellApi.logWWW( "scene prop: " + s );
			} //*/

			if ( result.data.file_data ) {
				scene.xmlData = new XML( result.data.file_data );
			}

			if ( callback ) {
				callback( scene, result.succeeded );
			}

		} //

		/**
		 *
		 * when the new realm is created, the realm passed in also has to be included in the callback,
		 * since the realm-id isn't known at the time of creation.
		 * 
		 */
		protected function onRealmCreated( result:PopResponse, realm:LandRealmData, callback:Function ):void {

			if ( !result.succeeded || result.data.realm_id == null ) {

				this.shellApi.logWWW( "realm created fail: " + result.toString() );
				if ( callback ) {
					callback( null, result.status );
				}
				return;

			}

			//this.shellApi.logWWW( "realm was created: " + result.toString() );

			realm.id = result.data.realm_id;
			this.galaxy.addRealm( realm );

			callback( realm, result.status );

		} //

		protected function onSceneSaved( result:PopResponse, realm:LandRealmData, callback:Function ):void {

			if ( !result.succeeded ) {
				this.shellApi.logWWW( "scene save failed: " + result.error );
			}

			var sceneData:Object = result.data;
			if ( sceneData != null ) {

				if ( sceneData.thumbnail_file_path != null ) {
					realm.thumbURL = sceneData.thumbnail_file_path;
				}

				/*for( var s:String in sceneData ) {
					this.shellApi.logWWW( "SCENE PROP: " + s );
				}*/

			} //

		//	this.shellApi.logWWW( "scene save success." );
			if ( callback ) {
				callback( result.succeeded, result.status );
			}

		} //

		protected function onRealmDestroyed( result:PopResponse, callback:Function ):void {

			if ( !result.succeeded ) {				
				this.shellApi.logWWW( "destroy realm failed: " + result.error );
			}

		//	this.shellApi.logWWW( "realm destroyed." );

			if ( callback ) {
				callback( result.error );
			}

		} //

		protected function onExistingRealmSaved( result:PopResponse, realm:LandRealmData, callback:Function ):void {

			if ( !result.succeeded || !result.isValid ) {
				this.shellApi.logWWW( "realm save failed: " + result.error );
				if ( callback ) {
					callback( null, result.error );
				}
			}

			if ( result.data && result.data.realm_id ) {
				realm.id = result.data.realm_id;
			} else {
				this.shellApi.logWWW( "ERROR: no realm id" );
			}

			//this.shellApi.logWWW( "realm save success" );
			// save all the realm scenes. there's currently no good way to tell when they're all saved.

			var scenes:Dictionary = realm.getScenes();
			for ( var id:int in scenes ) {

				// no real way to use the callback for this.
				this.saveRealmScene( realm, id, null );

			} //

			if ( callback ) {
				callback( result.error );
			}

		} //

		private function onShareStatusSaved( result:PopResponse ):void {

			if ( !result.succeeded ) {

				this.shellApi.logWWW( "SHARE STATUS FAIL: " + result.toString() );
				return;

			} //

			//this.shellApi.logWWW( "WORLD SHARED SUCCESS" );
			//this.shellApi.logWWW( this.getObjectString( result.data ) );
			
		} //

		/**
		 * return data:
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
		protected function onRealmLoaded( result:PopResponse, callback:Function ):void {

			if ( result.succeeded ) {

				this.shellApi.logWWW( "realm was loaded: " + result.data.name );

				var realmObj:Object = result.data;

				this.shellApi.logWWW( this.getObjectString( result.data ) );

				if ( realmObj == null ) {

					this.shellApi.logWWW( "ERROR: NO REALM OBJECT" );

				} else {

					var realmData:LandRealmData = this.makeRealm( realmObj, realmObj.realm_id );
					if ( callback ) {
						callback( realmData );
						return;
					}

				}

			} else {

				this.shellApi.logWWW( "realm load error : " + result.error );

			} //

			if ( callback ) {
				callback( null );
			}

		} //

		/**
		 *
		 * every property in result.data is the name of a realm in the galaxy.
		 * result.data[property] = realm-info object
		 * 
		 */
		protected function onGalaxyLoaded( result:PopResponse, callback:Function ):void {

			if ( !result.succeeded ) {

				this.shellApi.logWWW( "galaxy load fail: " + result.error );
				this.galaxy.clearAllRealms();

			} else {

				var galaxyObj:Object = result.data.realms;
				if ( galaxyObj == null ) {

					if ( callback ) {
						callback( "error: no realms returned." );
					}
					return;

				} //

				this.galaxy.clearAllRealms();
				shellApi.logWWW( this.getObjectString( galaxyObj ) );
				this.createGalaxyFromObject( galaxyObj );

			} //

			if ( callback ) {
				callback( result.error );
			}

		} //

		
		/**
		 * don't actually need these. just for testing.
		 */
		protected function onRealmVisited( result:PopResponse):void {
			this.shellApi.logWWW( "visted realm: " + result.toString() );
		} //
		protected function onSceneVisited( result:PopResponse ):void {
			this.shellApi.logWWW( "visit scene: " + result.toString() );
		} //

		/*protected function createGalaxyFromArray( galaxyArray:Array ):void {
			
			var realmObj:Object;
			var realm:LandRealmData;
			
			// find last visited realm.
			var lastVisitTime:Number = 0;
			var lastVisited:LandRealmData;
			
			var count:int = 0;
			for( var i:int = galaxyArray.length-1; i >= 0; i-- ) {

				realmObj = galaxyArray[ i ];
				if ( realmObj == null ) {
					continue;
				}
				
				realm = this.galaxy.createNewRealm( realmObj.realm_seed, realmObj.biome_name, realmObj.size, realmObj.realm_name );
				if ( realmObj.realm_id != null ) {
					realm.id = realmObj.realm_id;
				} else {
					realm.id = i;
				}
				realm.thumbURL = realmObj.thumbnail_file_path;			// thumbnail url
				
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
					
					// check if last visited realm.
					if ( (lastVisited == null) || realm.last_visit_time > lastVisitTime ) {
						lastVisited = realm;
						lastVisitTime = realm.last_visit_time;
					} //
					
				} //
				
				count++;
				realm.playerPosition.setTo( realmObj.x_position, realmObj.y_position );
				
			} //
			
			if ( count != 0 ) {
				
				if ( lastVisited != null ) {
					galaxy.setCurRealm( lastVisited );
				} else {
					galaxy.setCurRealm( galaxy.getRealms()[0] );
				} //
				
			} //
			
		} //*/

		/**
		 * server world was loaded from disk... need to initialize it and then save the first world to the server.
		 */
		//override protected function serverWorldLoaded( xml:XML, galaxy:LandGalaxy, onLoaded:Function ):void {
		//} //

	} // class

} // package