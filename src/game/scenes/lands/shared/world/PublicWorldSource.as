package game.scenes.lands.shared.world {
	
	/**
	 *
	 * Source for retrieval and access of public/shared realms.
	 *
	 */

	import flash.utils.ByteArray;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.data.comm.PopResponse;
	import game.proxy.DataStoreRequest;
	import game.proxy.PopDataStoreRequest;

	public class PublicWorldSource extends RemoteWorldSource {

		/**
		 * pageOffset when retrieving public realms from server.
		 */
		protected var pageOffset:int = 0;

		/**
		 * the total realms in the galaxy might be less if the existing realms arent divisible.
		 */
		protected var realmsPerPage:int = 10;

		public function PublicWorldSource( shell:ShellApi, galaxy:LandGalaxy ) {

			super( shell, galaxy );

		}

		/**
		 * by default, loading a galaxy just loads the public realms?
		 */
		/*override public function loadGalaxy( onLoaded:Function=null ):void {
			
			var req:DataStoreRequest = PopDataStoreRequest.publicRealmsRetrievalRequest( 10, this.pageOffset );
			shellApi.siteProxy.retrieve( req, this.onPublicRealmsRetrieved );

		} //*/

		public function loadPublicRealms( onLoaded:Function=null ):void {

			this.galaxy.isPublicGalaxy = true;

			var req:DataStoreRequest = PopDataStoreRequest.publicRealmsRetrievalRequest( this.realmsPerPage, this.pageOffset );
			this.shellApi.siteProxy.retrieve( req, Command.create( this.onPublicRealmsLoaded, onLoaded ) );

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
			shellApi.siteProxy.retrieve( PopDataStoreRequest.realmSceneRetrievalRequest( realm.id, sceneX, "public" ), Command.create( this.onSceneLoaded, scene, callback ));
			
			// return false by default, no loading occurs.
			return true;
			
		} //

		/**
		 * callback( avatarName ) -- later return a full data object.
		 */
		public function loadAvatarName( realm:LandRealmData, callback:Function ):void {

			var req:DataStoreRequest = PopDataStoreRequest.avatarDataRetrievalRequest( realm.creator_login );
			this.shellApi.siteProxy.retrieve( req, Command.create( this.onAvatarData, realm, callback ) );

		} //

		/**
		 * can't save a scene in a public realm: just save the player position instead.
		 * 
		 *  onSaved( success:Boolean, errorCode:int )
		 */
		override public function saveSceneAndThumbnail( thumbData:ByteArray, onSaved:Function ):void {

			var realm:LandRealmData = this.galaxy.curRealm;

			// for now, don't care about the callback. not that important to save player location
			// or inform the player if the location is lost in a shared realm.
			shellApi.siteProxy.store(PopDataStoreRequest.realmLocationStorageRequest(
				realm.id, realm.curLoc.x, realm.playerPosition.x, realm.playerPosition.y), null);

			if ( onSaved ) {
				onSaved( true, 0 );
			}

		} //

		/**
		 * can't save a scene in a public realm.
		 * just save the player position instead.
		 */
		override public function saveCurScene( onSaved:Function=null ):void {

			var realm:LandRealmData = this.galaxy.curRealm;

			shellApi.siteProxy.store(PopDataStoreRequest.realmLocationStorageRequest(
				realm.id, realm.curLoc.x, realm.playerPosition.x, realm.playerPosition.y), null);

			if ( onSaved ) {
				onSaved( true, 0);
			}

		} //

		/**
		 * the realm is returned as well, so the realm status can be updated
		 * if it's the selected realm.
		 * 
		 * callback( realm:LandRealmData, success:Boolean )
		 */
		public function likeRealm( realmId:uint, callback:Function=null ):void {

			//this.shellApi.logWWW( "Attempting to LIKE realm..." );
			var req:DataStoreRequest = PopDataStoreRequest.realmRatingStorageRequest( realmId, 1 );

			this.shellApi.siteProxy.store( req, Command.create( this.onRealmLiked, realmId, callback ) );

		} //

		public function flagRealm( realmId:uint ):void {
		} //

		public function setApproveStatus( realmId:uint, approveStatus:int ):void {

			var req:DataStoreRequest = PopDataStoreRequest.realmApprovalStatusStorageRequest( realmId, approveStatus );
			shellApi.siteProxy.retrieve( req, this.onApproveStatusSaved );

		} //

		private function onApproveStatusSaved( result:PopResponse ):void {

			if ( !result.succeeded ) {

				//this.shellApi.logWWW( "APPROVE STATUS FAIL: " + result.toString() );
				return;

			} //

			this.shellApi.logWWW( this.getObjectString( result.data ) );

		} //

		/**
		 * first_name, last_name and look fields in the data member of the PopResponse
		 */
		private function onAvatarData( result:PopResponse, realm:LandRealmData, callback:Function ):void {

			if ( result.succeeded ) {

				var data:Object = result.data;
				//this.shellApi.logWWW( "NAME DATA: " + this.getObjectString( data ) );
				if ( data && data.first_name && data.last_name ) {

					realm.avatar_name = data.first_name + " " + data.last_name;
					if ( callback ) {
						callback( realm.avatar_name );
						return;
					}

				}

			} // (success )

			//this.shellApi.logWWW( "ERROR: " + result.toString() );
			// fail.
			if ( callback ) {
				callback( null );
			}

		} //

		/**
		 * properties from server:
		 * public_realms: realm_shared: 1
			scene_shared: null
			x_position: 30
			realm_approved: 2
			y_position: 1814
			realm_rating: 100
			realm_created: 1425664625
			realm_seed: 4119406565
			realm_visits_count: 5
			biome_name: swamp
			scene_created_by: null
			realm_name: Oafou Houmeal
			realm_id: 128
			scenes_array: [ 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1]
			realm_last_visited: 1425665023
			scene_approved: null
			scene_created: null
			thumbnail_file_path: null
			realm_created_by: 101749715
			size: 16
			scene_id: 4

		 */
		protected function onPublicRealmsLoaded( result:PopResponse, onLoaded:Function ):void {

			if ( result.succeeded ) {

				// don't actually want to do this if the galaxyObj has no realms in it.
				this.galaxy.clearAllRealms();

				var galaxyObj:Object = result.data.public_realms;
				if ( galaxyObj == null ) {

					this.shellApi.logWWW( "ERROR: NO REALMS OBJECT FOUND" );

					if ( onLoaded ) {
						onLoaded( "" );
					}
					return;

				} //

				//this.shellApi.logWWW( "PUBLIC REALMS LOADED" );

				super.createGalaxyFromObject( galaxyObj );

				//this.shellApi.logWWW( this.getObjectString( result.data ) );

			} else {

				//this.shellApi.logWWW( "PUBLIC REALMS FAIL: " + result.toString() );

			} // success

			if ( onLoaded ) {
				onLoaded( result.error );
			}

		} //

		protected function onRealmLiked( result:PopResponse, realmId:int, callback:Function ):void {

			var realm:LandRealmData = this.galaxy.getRealmById( realmId );
			if ( realm == null ) {

				// no realm so no success.
				if ( callback ) {
					callback( null, false );
				}
				return;

			}//

			if ( result.succeeded ) {
				realm.rating++;
			} //

			if ( callback ) {
				callback( realm, result.succeeded );
			} //

		} //

	} // class

} // package