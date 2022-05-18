package game.scenes.lands.shared.classes {
	
	import flash.utils.ByteArray;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.components.entity.character.Profile;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.proxy.DataStoreRequest;
	import game.proxy.PopDataStoreRequest;

	public class LandServerGateway {

		private const LAND_DATA_FIELD:String = "landData";

		/**
		 * the object from the user fields. Must be converted to a string before sent to the network.
		 */
		private var savedData:Object;
		private var shellApi:ShellApi;

		public function LandServerGateway( shell:ShellApi ) {

			this.shellApi = shell;

		} //

		/**
		 * load user variables like poptanium, experience.
		 * 
		 * callback( dataObj:Object, err:String )
		 */
		public function loadUserVars( callback:Function ):void {

			// NOTE: USER FIELD DATA NO LONGER SEEMS TO BE WORKING. ALWAYS FETCH FROM SITEPROXY.

			//var profile:ProfileData = this.shellApi.profileManager.active;
			//this.savedData = this.shellApi.getUserField( this.LAND_DATA_FIELD, this.shellApi.island );
			//profile.getUserFieldForIsland( this.shellApi.island, this.LAND_DATA_FIELD ) as Object;
			if ( this.savedData ) {

				this.shellApi.logWWW( "FOUND USER VARS IN LSO" );
				for( var s:String in this.savedData ) {
					this.shellApi.logWWW("prop: " + s + ": " + this.savedData[s] );
				} //

				if ( this.savedData.poptanium == null ) {
					this.savedData.poptanium = 0;
					this.savedData.savedPoptanium = 0;
				} else if ( this.savedData.savedPoptanium == null ) {
					this.savedData.savedPoptanium = this.savedData.poptanium;
				}

				if ( this.savedData.experience == null ) {
					this.savedData.experience = 0;
					this.savedData.savedExperience = 0;
				} else if ( this.savedData.savedExperience == null ) {
					this.savedData.savedExperience = this.savedData.experience;
				}

				if ( callback ) {
					callback( this.savedData, null );
				}

			} else {

				//this.shellApi.logWWW( "LOADING USER VARS FROM SERVER" );
				this.savedData = new Object();

				this.savedData.savedPoptanium = this.savedData.poptanium = 0;
				this.savedData.savedExperience = this.savedData.experience = 0;

				// at the moment this has to be done in two separate calls.
//				( this.shellApi.siteProxy as DataStoreProxyPop ).getUserStats( Command.create( this.userVarsLoaded, callback ) );
				shellApi.siteProxy.retrieve(PopDataStoreRequest.userStatsRetrievalRequest(), Command.create( this.userVarsLoaded, callback ));

			} //

		} //

		private function userVarsLoaded( response:PopResponse, callback:Function ):void {

			if ( !response.isValid || !response.succeeded ) {

				this.shellApi.logWWW( "USER VARS CALL FAILED: " + response.error );
				if ( callback ) {
					callback( this.savedData, response.error );
				}
				return;

			} //

			// need to track the last values since the database wants only the CHANGES??? in values for some reason.
			if ( response.data.poptanium != null ) {
				this.savedData.poptanium = this.savedData.savedPoptanium = response.data.poptanium;
			}
			if ( response.data.experience != null ) {
				this.savedData.experience = this.savedData.savedExperience = response.data.experience;
			}

			this.shellApi.setUserField( this.LAND_DATA_FIELD, this.savedData, this.shellApi.island );
			//this.shellApi.profileManager.active.setUserFieldForIsland( this.shellApi.island, this.LAND_DATA_FIELD, this.savedData );

			if ( callback ) {
				callback( this.savedData, null );
			}

		} //
		
		/**
		 * send the server all the user's game data.
		 */
		public function sendOrwellData( img:ByteArray, gameXML:XML ):void {
			shellApi.siteProxy.store(DataStoreRequest.gameImageStorageRequest(img, 'jpg', gameXML));
		} //

		public function saveResources( poptanium:int, experience:int ):void {

			var popChange:int = poptanium - this.savedData.savedPoptanium;
			var expChange:int = experience - this.savedData.savedExperience;

			if ( popChange == 0 && expChange == 0 ) {
				return;
			}

			this.savedData.poptanium = this.savedData.savedPoptanium = poptanium;
			this.savedData.experience = this.savedData.savedExperience = experience;
//			( this.shellApi.siteProxy as DataStoreProxyPop ).saveUserStats( popChange, expChange, this.onUserVarSaved );
			shellApi.siteProxy.store(PopDataStoreRequest.userStatsStorageRequest(popChange, expChange), this.onUserVarSaved);

			this.shellApi.setUserField( this.LAND_DATA_FIELD, this.savedData, this.shellApi.island );

			//var profile:ProfileData = this.shellApi.profileManager.active;
			//profile.setUserFieldForIsland( this.shellApi.island, LAND_DATA_FIELD, this.savedData );
			//this.shellApi.profileManager.save();

		} //

		/**
		 * cache a resource in the LSO without updating on the server.
		 */
		public function cacheResourceType( type:ResourceType ):void {

			//this.savedData[ type.type ] = type.count;
			if ( type.type == "poptanium" ) {
				this.savedData.poptanium = type.count;
			} else if ( type.type == "experience" ) {
				this.savedData.experience = type.count;
			} //

			this.shellApi.setUserField( this.LAND_DATA_FIELD, this.savedData, this.shellApi.island, false, null, false );

			//var profile:ProfileData = this.shellApi.profileManager.active;
			//profile.setUserFieldForIsland( this.shellApi.island, LAND_DATA_FIELD, this.savedData );
			//this.shellApi.profileManager.save();

			/*this.shellApi.setUserField( this.LAND_DATA_FIELD, this.serverData.getString(),
			this.shellApi.island, true, this.onLandFieldSaved );*/
			
		} //

		public function saveResourceType( type:ResourceType ):void {

			//this.savedData[ type.type ] = type.count;

			//this.shellApi.logWWW( "INVENTORY: " + type.type + ": " + type.count );
			//this.shellApi.logWWW( "change amt: " + (type.count-this.savedData[ type.type ]) );

			var change:int;

			if ( type.type == "poptanium" ) {

				change = type.count - this.savedData.savedPoptanium;
				if ( change == 0 ) {
					return;
				}
//				( this.shellApi.siteProxy as DataStoreProxyPop ).saveUserPoptanium( change, this.onUserVarSaved );
				shellApi.siteProxy.store(PopDataStoreRequest.userPoptaniumChangeRequest(change), this.onUserVarSaved);
				this.savedData.poptanium = this.savedData.savedPoptanium = type.count;

			} else if ( type.type == "experience" ) {

				change = type.count - this.savedData.savedExperience;
				if ( change == 0 ) {
					return;
				}
//				( this.shellApi.siteProxy as DataStoreProxyPop ).saveUserExperience( change, this.onUserVarSaved );
				shellApi.siteProxy.store(PopDataStoreRequest.userExperienceChangeRequest(change), this.onUserVarSaved);
				this.savedData.experience = this.savedData.savedExperience = type.count;

			} //

			this.shellApi.setUserField( this.LAND_DATA_FIELD, this.savedData, this.shellApi.island );

			/*var profile:ProfileData = this.shellApi.profileManager.active;
			profile.setUserField( LAND_DATA_FIELD, this.savedData, this.shellApi.island );
			this.shellApi.profileManager.save();*/

		} //

		private function onUserVarSaved( result:PopResponse ):void {

			if ( !result.succeeded ) {
				this.shellApi.logWWW( "USER VARS SAVE FAIL: " + result.error );
			} else {
				this.shellApi.logWWW( "USER VARS SAVED: " + result.toString() );
			} //
			
		} //

	} // class
	
} // package