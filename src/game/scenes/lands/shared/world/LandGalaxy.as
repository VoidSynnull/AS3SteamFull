package game.scenes.lands.shared.world {

	/**
	 * The LandGalaxy contains all the worlds/realms currently available to the user.
	 * 
	 * In the new system, realms are created by the user and stored on the server side.
	 * 
	 * Under the old system, each 'galaxy' contains 3 realms - one for each basic biome.
	 * These can be stored to the users computer.
	 */

	import game.scenes.lands.shared.classes.Location;

	public class LandGalaxy {

		public var loadSource:String;

		/**
		 * true if the realms of the galaxy are shared realms - not the user's own realm.
		 * editing and saving is restricted in shared realms.
		 */
		private var _isPublic:Boolean = false;
		public function get isPublicGalaxy():Boolean {
			return this._isPublic;
		}
		public function set isPublicGalaxy( b:Boolean ):void {
			this._isPublic = b;
		}

		protected var realmList:Vector.<LandRealmData>;

		protected var _curRealm:LandRealmData;
		public function get curRealm():LandRealmData { return this._curRealm; }

		public function get curRealmSize():int { return this._curRealm.realmSize; }

		public function get maxSceneX():int { return this._curRealm.realmSize-1; }

		public function get curRealmSeed():uint { return this._curRealm.seed; }

		public function get curSceneData():LandSceneData { return this._curRealm.curSceneData; }

		public function get curLoc():Location { return this._curRealm.curLoc; }

		/**
		 * the scene number of the first loaded scene in the current realm.
		 * this will most likely be the number of scenes divided by two. scenes will start in the 'center'
		 * of each realm to avoid thrashing the perlin blending that must occur at -1
		 * 
		 * Landing scene needs to be tracked soley for advertising reasons - both to place the side banner ads
		 * and to place ad billboards in the adjacent scenes.
		 */
		public function get landingScene():int { return this.curRealm.realmSize/2; }

		/**
		 * scene location within the current realm which player reverts to if they die.
		 * the player's x,y position can be retrieved from the realm data.
		 */
		protected var _saveLoc:Location;
		public function get saveLoc():Location { return this._saveLoc; } //

		public function LandGalaxy() {

			this.realmList = new Vector.<LandRealmData>();
			this._saveLoc = new Location();

		}

		public function getRealms():Vector.<LandRealmData> {
			
			return this.realmList;
			
		}

		public function getRealmCount():int {
			return this.realmList.length;
		}

		/**
		 * If information about the current scene already exists in memory, it is returned.
		 * The scene data may still be empty.
		 * 
		 * If no information exists in memory, an attempt is made to load the scene data from
		 * the current world source. The callback is then called with the loaded scene data
		 * which may still be empty - if no data exists for that scene.
		 * 
		 **/
		/*public function tryGetScene( x:int, y:int=0 ):LandSceneData {

			var sceneData:LandSceneData = this.curRealm.curSceneData;
			if ( sceneData != null ) {

				return sceneData;

			}

			if ( this.worldSource ) {

				// scene is being loaded.
				return null;

			} //

			// the world source says there is no scene data anywhere.
			// create a scene stub and return that.
			sceneData = this.curRealm.createEmptyScene( x, y );

			return sceneData;

		} //*/

		public function setCurRealm( realm:LandRealmData ):void {

			this._curRealm = realm;
			this._curRealm.goCurrentLoc();

			// set the save location to the starting loc of the current realm.
			this.saveLoc.x = this._curRealm.curLoc.x;
			this.saveLoc.y = this._curRealm.curLoc.y;

		} //

		public function setRealmByIndex( realmIndex:int ):void {

			if ( realmList.length == 0 ) {
				this._curRealm = null;
				return;
			}

			if ( realmIndex > this.realmList.length || realmIndex < 0 ) {
				realmIndex = 0;
			}
			this.setCurRealm( this.realmList[ realmIndex ] );

		} //

		/**
		 * LEGACY function - and for local files without valid world ids.
		 * sets the current realm by realm name, but realm names are no longer guaranteed to be unique.
		 */
		public function setRealmByName( name:String ):LandRealmData {

			this._curRealm = this.getRealmByName( name );
			if ( this._curRealm == null ) {
				this._curRealm = this.createNewRealm( Math.random()*uint.MAX_VALUE, name );
			}

			this._curRealm.goCurrentLoc();
			
			// set the save location to the starting loc of the current realm.
			this.saveLoc.x = this._curRealm.curLoc.x;
			this.saveLoc.y = this._curRealm.curLoc.y;
			
			return this._curRealm;

		} //

		/**
		 * sets the current realm by realm id
		 * realms used to have individual names corresponding to biomes. these names were replaced by unique realm id numbers.
		 * realm ids are the preferred method for accessing realms.
		 * returns null if no such realm exists.
		 */
		public function setRealmById( id:uint ):LandRealmData {
			
			this._curRealm = this.getRealmById( id );
			if ( this._curRealm == null ) {
				return null;
			}

			this._curRealm.goCurrentLoc();

			// set the save location to the starting loc of the current realm.
			this.saveLoc.x = this._curRealm.curLoc.x;
			this.saveLoc.y = this._curRealm.curLoc.y;

			return this._curRealm;
			
		} //

		/**
		 * DEPRECATED. Remove eventually.
		 * finds the data for the named realm, or null if it doesn't exist.
		 * 
		 * this is a legacy function because the old realm-biomes used
		 * to have unique names, but this is no longer guaranteed.
		 * 
		 * use realm id instead.
		 */
		public function getRealmByName( realmName:String ):LandRealmData {
			
			for( var i:int = this.realmList.length-1; i >= 0; i-- ) {

				if ( this.realmList[i].name == realmName ) {
					
					return this.realmList[i];
					
				} //
				
			} // for-loop.

			return null;

		} //

		public function getRealmById( id:uint ):LandRealmData {

			for( var i:int = this.realmList.length-1; i >= 0; i-- ) {

				if ( this.realmList[i].id == id ) {

					return this.realmList[i];

				} //

			} // for-loop.

			return null;

		} //

		public function addRealm( realm:LandRealmData ):void {

			this.realmList.push( realm );

		} //

		public function removeRealm( realm:LandRealmData ):void {

			for( var i:int = this.realmList.length-1; i >= 0; i-- ) {
				
				if ( this.realmList[i] == realm ) {

					this.realmList[i] = this.realmList[ this.realmList.length-1 ];
					this.realmList.pop();
					
				} //

			} // for-loop.

		} //

		public function removeRealmById( realmId:uint ):void {

			for( var i:int = this.realmList.length-1; i >= 0; i-- ) {

				if ( this.realmList[i].id == realmId ) {

					this.realmList[i] = this.realmList[ this.realmList.length-1 ];
					this.realmList.pop();

				} //
				
			} // for-loop.

		} //

		public function createNewRealm( seed:uint=0, biomeType:String="grass", size:int=256, realmName:String=null ):LandRealmData {

			if ( seed == 0 ) {
				seed = Math.random()*uint.MAX_VALUE;
			}

			var realm:LandRealmData = new LandRealmData( biomeType, seed, size, realmName );
			this.realmList.push( realm );

			return realm;

		} //

		public function clearAllRealms():void {

			/*for( var i:int = this.realmList.length-1; i >= 0; i-- ) {

				this.realmList[i].reset();

			} // for-loop.*/

			this.realmList.length = 0;
			this._curRealm = null;

			this._saveLoc.setTo( 0, 0 );

		} //

		/**
		 * used to get a unique id for local worlds, which don't get
		 * ids assigned from a database.
		 */
		public function getUniqueId():uint {

			var id:uint = 1;
			for( var i:int = this.realmList.length-1; i >= 0; i-- ) {

				if ( this.realmList[i].id == id ) {
					id++;
				} //

			} //

			return id;

		} //

		/**
		 * reset all the scenes and realms from the current galaxy and sets a new seed.
		 * currently this function is used to make a new world when the user is using local xml worlds.
		 */
		public function resetRealms():void {

			for( var i:int = this.realmList.length-1; i >= 0; i-- ) {

				this.realmList[i].reset();

			} // for-loop.

			this._curRealm.seed = Math.random()*uint.MAX_VALUE;

			this._saveLoc.setTo( 0, 0 );

		} //

		public function isLandingScene():Boolean {
			
			if ( this.curLoc == null ) {
				return false;
			}
			
			return ( this.curLoc.x == this.landingScene );
		}

	} // class

} // package