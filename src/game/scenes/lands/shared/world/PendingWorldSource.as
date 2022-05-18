package game.scenes.lands.shared.world {
	
	/**
	 *
	 * This is the source used to get groups of realms waiting for approval to be shared/made public.
	 *
	 */

	import engine.ShellApi;
	import engine.util.Command;
	
	import game.data.comm.PopResponse;
	import game.proxy.DataStoreRequest;
	import game.proxy.PopDataStoreRequest;

	public class PendingWorldSource extends RemoteWorldSource {

		/**
		 * realmOffset when retrieving public realms from server.
		 */
		protected var realmOffset:int = 0;

		/**
		 * the total realms in the galaxy might be less if the existing realms arent divisible.
		 */
		protected var realmsPerPage:int = 10;

		/**
		 * total realms still pending according to the server.
		 * this is the total number the server thinks it has available - NOT the local realm count.
		 */
		public var totalPendingRealms:int;

		public function PendingWorldSource( shell:ShellApi, galaxy:LandGalaxy ) {

			super( shell, galaxy );

		}

		public function advancePage( onLoaded:Function=null ):void {

			this.realmOffset += this.realmsPerPage;
			this.loadPendingRealms( onLoaded );

		} //

		public function resetPage():void {
			this.realmOffset = 0;
		} //

		public function loadPendingRealms( onLoaded:Function=null ):void {

			var req:DataStoreRequest = PopDataStoreRequest.pendingRealmsRetrievalRequest( this.realmsPerPage, this.realmOffset );
			shellApi.siteProxy.retrieve( req, Command.create( this.onPendingRealmsRetrieved, onLoaded ) );

		} //

		override public function tryLoadScene( realm:LandRealmData, sceneX:int, sceneY:int, callback:Function=null ):Boolean {

			var req:DataStoreRequest = PopDataStoreRequest.pendingRealmScenesRetrievalRequest( realm.id, sceneX, sceneX );
			shellApi.siteProxy.retrieve( req, Command.create( this.onPendingScenesLoaded, realm, callback ) );

			return true;

		} //

		/**
		 * the realm is returned as well, so the realm status can be updated
		 * if it's the selected realm.
		 * 
		 * callback( realm:LandRealmData, success:Boolean )
		 */
		public function markPopular( realmId:uint, callback:Function=null ):void {
			
			var req:DataStoreRequest = PopDataStoreRequest.realmRatingStorageRequest( realmId, 100 );
			this.shellApi.siteProxy.store( req, Command.create( this.onRealmLiked, realmId, callback ) );
			
		} //

		public function loadPendingScenes( realm:LandRealmData, callback:Function ):void {

			var req:DataStoreRequest = PopDataStoreRequest.pendingRealmScenesRetrievalRequest( realm.id, 0, realm.realmSize-1 );
			shellApi.siteProxy.retrieve( req, Command.create( this.onPendingScenesLoaded, realm, callback ) );

		} //

		/**
		 * callback( success:Boolean )
		 */
		public function approveRealm( realmId:uint, callback:Function=null ):void {

			this.shellApi.logWWW( "ATTEMPTING TO APPROVE REALM" );

			var req:DataStoreRequest = PopDataStoreRequest.realmApprovalStatusStorageRequest( realmId, LandRealmData.REALM_STATUS_APPROVED );
			shellApi.siteProxy.store( req, Command.create( this.onRealmStatusChanged, callback) );

		} //

		/**
		 * callback( success:Boolean )
		 */
		public function rejectRealm( realmId:uint, callback:Function=null ):void {

			this.shellApi.logWWW( "ATTEMPTING TO REJECT REALM" );

			var req:DataStoreRequest = PopDataStoreRequest.realmApprovalStatusStorageRequest( realmId, LandRealmData.REALM_STATUS_REJECTED );
			shellApi.siteProxy.store( req, Command.create( this.onRealmStatusChanged, callback ) );

		} //

		/**
		 * callback( success:Boolean )
		 */
		private function onRealmStatusChanged( result:PopResponse, callback:Function=null ):void {

			if ( !result.succeeded ) {

				this.shellApi.logWWW( "APPROVE STATUS FAIL: " + result.toString() );

			} else {
				this.totalPendingRealms--;
			}

			if ( callback ) {
				callback( result.succeeded );
			}

		} //

		private function onPendingScenesLoaded( result:PopResponse, realm:LandRealmData, callback:Function ):void {

			if ( result.succeeded ) {

				this.shellApi.logWWW( "PENDING SCENE LOG:\n" + this.getObjectString( result.data ) );

				var scenes:Object = result.data.scenes;
				var sceneData:LandSceneData;

				if ( scenes != null ) {

					for( var i:int in scenes ) {

						sceneData = realm.getSceneData( i, 0 );
						if ( !sceneData ) {
							sceneData = realm.createEmptyScene( i, 0 );
						}
						sceneData.xmlData = new XML( scenes[i].file_data );

					} //

				} else {

					this.shellApi.logWWW( "ERROR: NO SCENES OBJECT" ); 

				} //

			} else {

				this.shellApi.logWWW( "ERROR LOADING REALM SCENES: " + result.error );

			} //

			if ( callback ) {
				callback( result.succeeded );
			}

		} //

		private function onPendingRealmsRetrieved( result:PopResponse, onLoaded:Function ):void {

			if ( result.succeeded ) {

				//this.shellApi.logWWW( this.getObjectString( result.data ) );

				// don't actually want to do this if the galaxyObj has no realms in it.
				this.galaxy.clearAllRealms();

				if ( result.data.pending_realm_count != null ) {
					this.totalPendingRealms = result.data.pending_realm_count;
				} else {
					this.shellApi.logWWW( "ERROR: NO PENDING REALM COUNT" );
				}

				// not a consistent object name...
				var galaxyObj:Object = result.data.realms;
				if ( galaxyObj == null ) {

					this.shellApi.logWWW( "ERROR: NO REALMS OBJECT FOUND" );

					if ( onLoaded ) {
						onLoaded( false );
					}
					return;

				} //

				super.createGalaxyFromObject( galaxyObj );


			} else {

				this.shellApi.logWWW( "PENDING REALMS FAIL: " + result.toString() );

			} // end success

			if ( onLoaded ) {
				onLoaded( result.succeeded );
			}

		} //

		protected function onRealmLiked( result:PopResponse, realmId:int, callback:Function ):void {

			if ( callback ) {
				callback( result.succeeded );
			} //
			
		} //

	} // class

} // package