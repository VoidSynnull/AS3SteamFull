package game.scenes.lands.shared.world {
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandClock;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.Location;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.systems.RaceSystem;
	import game.scenes.lands.shared.tileLib.classes.LandEncoder;
	import game.systems.SystemPriorities;

	public class LandWorldManager {

		/**
		 * used to restore land world after visiting an ad scene.
		 */
		/*static private var WorldObject:Object;
		static public function HasWorldSnapshot():Boolean {
			return LandWorldManager.WorldObject != null;
		}*/

		private const AD_FREQUENCY:uint = 4;
		public var clock:LandClock;
		public var worldSource:WorldDataSource;

		private var _galaxy:LandGalaxy;
		public function get galaxy():LandGalaxy { return this._galaxy; }

		/**
		 * marks where the data came from. only 'server' data can spawn
		 * poptropica items, since otherwise users could give themselves
		 * any item in the game.
		 *  -- values are: server or local
		 */
		public function get loadSource():String { return this._galaxy.loadSource; }

		public function get curRealm():LandRealmData { return this._galaxy.curRealm; }
		public function getCurBiome():String { return this.curRealm.biome; }
		public function get curRealmSeed():uint { return this.curRealm.seed; }
		public function get curSceneData():LandSceneData { return this.curRealm.curSceneData; }
		public function get curLoc():Location { return this.curRealm.curLoc; }

		/**
		 * set to true when the loaded galaxy is a shared, public realm.
		 */
		//public var _publicMode:Boolean = false;
		public function get publicMode():Boolean { return this.galaxy.isPublicGalaxy; }
		//public function set publicMode( b:Boolean ):void { this._publicMode = b; }

		/**
		 * apparently we need to track which realms have been liked to avoid re-likes
		 * within a single session. this is annoying.
		 */
		protected var likedRealms:Array;

		public function LandWorldManager() {

			this._galaxy = new LandGalaxy();

		} //

		public function createNewLocalWorld( biome:String ):void {

			this.useLocalSource();

			this.galaxy.clearAllRealms();

			var realm:LandRealmData = this._galaxy.createNewRealm( 0, biome );
			realm.id = 1;

			this._galaxy.setCurRealm( realm );

		} //

		/**
		 * check for land data in the local shared object.
		 * if land information is stored there, load the world from the land cache.
		 * this happens when the user leaves the main land scene for an ad scene and returns.
		 * 
		 * this is messy and awful. we could have either a signal or a registry for this type
		 * of thing, but it should be noted that some of these things have to take place in
		 * a very particular order.
		 */
		public function tryCachedLoad( landGroup:LandGroup ):Boolean {

			var cacheObj:Object = landGroup.shellApi.getUserField( "realmsCache", landGroup.shellApi.island );
			//landGroup.shellApi.profileManager.active.getUserFieldForIsland( landGroup.shellApi.island, "realmsCache" );
			//var so:SharedObject  SharedObject.getLocal( "landCache" );
			//var cacheObj:Object = so.data.cacheObj;

			if ( cacheObj == null ) {
				return false;
			}

			// TEMP FIX to get Jason's race timer. need a better system for doing all these changes.
			if ( cacheObj.race_active ) {
				var raceSys:RaceSystem = landGroup.addSystem( new RaceSystem(), SystemPriorities.update ) as RaceSystem;
				raceSys.currentTime = cacheObj.race_time;
			} //

			landGroup.gameData.clock.setStartTime( cacheObj.worldTime );

			// bring back the state from the world source.
			if ( cacheObj.realmSource == "remote" ) {

				// unfortunate bit about marking public shared realms.
				this.galaxy.isPublicGalaxy = cacheObj.isPublicGalaxy;

				if ( this.galaxy.isPublicGalaxy ) {
					this.usePublicSource( landGroup.shellApi );
				} else {
					this.useRemoteSource( landGroup.shellApi );
				}

			} else {

				this.useLocalSource();

			} //

			if ( cacheObj.likedRealms != null ) {
				this.likedRealms = cacheObj.likedRealms;
			}

			// this is the world at the previous scene. the player will then either stay put or move to the next scene
			// depending on which ad door they took.
			this.worldSource.restoreFromXml( XML(cacheObj.cachedWorld), this.galaxy );

			var player:Entity = landGroup.getPlayer();
			( player.get( Life ) as Life ).setCurrentLife( cacheObj.playerLife );

			var playerPos:Location = this.galaxy.curRealm.playerPosition;
			// change scene based on the direction the player took when they left lands
			// and the direction they took from the previous ad scene.
			// for example: if the player left lands to the "left" and the lastDirection
			// is now right, then clearly they haven't changed land scenes.
			if ( landGroup.shellApi.profileManager.active.lastDirection == "right" ) {

				if ( cacheObj.exitedRight ) {
					playerPos.x = 30;
					this.galaxy.curRealm.moveRight();
				}

			} else {

				if ( !cacheObj.exitedRight ) {
					playerPos.x = landGroup.sceneBounds.width - 30;
					this.galaxy.curRealm.moveLeft();
				}

			} //

			var monsterXML:XML = cacheObj.monsterXML;
			if ( monsterXML != null ) {
				landGroup.sceneBuilder.monsterBuilder.loadMultiSceneMonsters( monsterXML, playerPos.x, playerPos.y );
			} //

			// might check here if we actually NEED to do this.
			// complete restoration for stuff that needs loaded tiles.
			landGroup.ready.addOnce( this.completeCacheLoad );

			return true;

		} //

		/**
		 * some parts of the cache load can't be completed until tiles have loaded for the current biome.
		 * for example - setting up the quickBar.
		 * 
		 * the group is the landgroup after cast.
		 */
		private function completeCacheLoad( group:Group ):void {

			var landGroup:LandGroup = group as LandGroup;
			//var so:SharedObject = SharedObject.getLocal( "landCache" );
			//var cacheObj:Object = so.data.cacheObj;

			var cacheObj:Object = landGroup.shellApi.getUserField( "realmsCache", landGroup.shellApi.island );;
			//landGroup.shellApi.profileManager.active.getUserFieldForIsland( landGroup.shellApi.island, "realmsCache" );

			// QUICK BAR AND CURRENT EDIT STATE.
			// NOTE: this can't work unless the land group is loaded and the tile types are loaded.
			var uiGroup:LandUIGroup = landGroup.getUIGroup();
			uiGroup.getQuickBar().restoreQuickBar( landGroup, cacheObj );

			uiGroup.uiMode = cacheObj.uiMode;

			// kill the cached object so land doesn't load from cache if the user simply leaves the island and returns.
			//so.clear();
			landGroup.shellApi.profileManager.active.setUserField( "realmsCache", null, landGroup.shellApi.island );

		} //

		/**
		 * cache land state information to the LSO so an ad scene can be displayed
		 * before returning back to land.
		 * - need to know if the player used a left or right door so the door used can be compared
		 * with the direction of the player when they return to lands. this will tell the manager
		 * if the player left a scene and came right back to it.
		 */
		public function cacheLandState( landGroup:LandGroup, usedRightDoor:Boolean ):void {

			var cacheObj:Object = new Object();

			cacheObj.exitedRight = usedRightDoor;

			var player:Entity = landGroup.getPlayer();
			cacheObj.playerLife = int( ( player.get( Life ) as Life ).curLife );

			// TEMP FIX to get Jason's race timer. need a better system for doing all these changes.
			var raceSys:RaceSystem = landGroup.getSystem( RaceSystem ) as RaceSystem;
			if ( raceSys != null && raceSys.isRunning ) {

				cacheObj.race_active = true;
				cacheObj.race_time = raceSys.currentTime;
	
			} //

			// used to display terrain in ad scene:
			cacheObj.curBiome = this.getCurBiome();
			cacheObj.sceneSeed = landGroup.gameData.worldRandoms.sceneSeed;
			cacheObj.perlinOffsetX = landGroup.gameData.worldRandoms.perlinOffset.x;
			cacheObj.curSeed = landGroup.gameData.worldRandoms.seed;

			cacheObj.worldTime = landGroup.gameData.clock.getDayPercent();

			// list of realms user has liked so they cant spam likes in single session. (annoying)
			if ( this.likedRealms != null ) {
				cacheObj.likedRealms = this.likedRealms;
			}

			// player position.
			var sp:Spatial = player.get( Spatial ) as Spatial;
			// save the player position so it can be restored if the player returns to this scene, or
			// the y-coord can be matched if they leave the ad room into another scene.
			//landGroup.shellApi.logWWW( "saving player pos: " + sp.x + "," + sp.y );

			this.savePlayerPosition( sp.x, sp.y );
			//cacheObj.playerPos = new Point( sp.x, sp.y );

			// QUICK BAR AND CURRENT EDIT STATE.
			var uiGroup:LandUIGroup = landGroup.getUIGroup();
			cacheObj.uiMode = uiGroup.uiMode;
			uiGroup.getQuickBar().cacheQuickBarState( cacheObj );


			// find and store xml for any multi-scene monsters.
			cacheObj.monsterXML = landGroup.sceneBuilder.monsterBuilder.getMultiSceneMonsterXML();

			// let the world source store anything it needs to bring its state back.
			cacheObj.realmSource = this.loadSource;
			cacheObj.cachedWorld = this.worldSource.getWorldXml( this.galaxy, this.clock.getDayPercent() );
			// unfortunate bit about marking public shared realms.
			cacheObj.isPublicGalaxy = this.galaxy.isPublicGalaxy;

			landGroup.shellApi.setUserField( "realmsCache", cacheObj, landGroup.shellApi.island );

			//var shellApi:ShellApi = landGroup.shellApi;
			//shellApi.profileManager.active.setUserFieldForIsland( shellApi.island, "realmsCache", cacheObj );

		} //

		/**
		 * attempts to load data from the current scene from the world-loading source.
		 * 
		 * if this function returns false, the world-source does not think there is any data
		 * to load. if it returns true, you must wait for the callback for the scene data.
		 * 
		 * callback is: onSceneLoaded( scene:LandSceneData, success:Boolean )
		 * 	-if there is a load error, scene will exist but have no xml data.
		 */
		public function tryLoadCurScene( sceneX:int, sceneY:int, callback ):Boolean {

			return this.worldSource.tryLoadScene( this.curRealm, sceneX, sceneY, callback );

		} //

		/**
		 * begin using a file source to load galaxies, realms and scenes.
		 * this file source may be an xml file on the server, but typically
		 * represents a user's local file.
		 */
		public function useLocalSource():void {

			if ( this.worldSource is FileWorldSource ) {
				return;
			}
			this.galaxy.loadSource = "local";			// messy fix.
			this.worldSource  = new FileWorldSource( this.galaxy );

		} //

		/**
		 * sets the world source to the specified type.
		 */
		public function setWorldSource( source:WorldDataSource ):void {

			this.worldSource = source;

		} //

		/**
		 * world source returns pending worlds - use to approve shared realms.
		 */
		public function usePendingSource( shell:ShellApi ):void {

			if ( this.worldSource is PendingWorldSource ) {
				return;
			}
			this.worldSource = new PendingWorldSource( shell, this.galaxy );

		} //

		/**
		 * galaxy source is a collection of public realms.
		 */
		public function usePublicSource( shell:ShellApi ):void {

			if ( this.worldSource is PublicWorldSource ) {
				return;
			}
			this.worldSource = new PublicWorldSource( shell, this.galaxy );

		} //

		/**
		 * begin using a remote data source to load galaxies, realms and scenes.
		 */
		public function useRemoteSource( shell:ShellApi ):void {

			if ( !this.publicMode && (this.worldSource is RemoteWorldSource) ) {
				return;
			}
			this.worldSource = new RemoteWorldSource( shell, this.galaxy );

		} //

		public function loadDatabaseGalaxy( shell:ShellApi, onLoaded:Function ):void {

			this.useRemoteSource( shell );
			this.worldSource.loadGalaxy( onLoaded );

		} //

		/**
		 * callback( err:String )
		 */
		public function destroyRealm( realm:LandRealmData, callback:Function ):void {

			this.worldSource.destroyRealm( realm, callback );

		} //

		/**
		 * shellApi doesn't seem to give much fail information.
		 * onLoaded( error:String )
		 */
		public function loadServerFile( landGroup:LandGroup, worldPath:String, onLoaded:Function=null ):void {

			this.useLocalSource();
			this.worldSource.loadServerGalaxy( landGroup.shellApi, worldPath, onLoaded );

		} //

		/**
		 * onLoaded( error:String )
		 * -error is null if no error.
		 */
		public function loadLocalWorld( onLoaded:Function=null ):void {

			this.useLocalSource();
			this.worldSource.loadGalaxy( onLoaded );

		} //

		public function hasLikedRealm( id:int ):Boolean {

			if ( this.likedRealms == null ) {
				return false;
			}

			for( var i:int = this.likedRealms.length-1; i >= 0; i-- ) {
				if ( this.likedRealms[i] == id ) {
					return true;
				}
			} //

			return false;

		} //

		/**
		 * this is an annoying fix to make sure a user can't like the same realm twice
		 * in the same session.
		 */
		public function markLikedRealm( realm:LandRealmData ):void {

			if ( this.likedRealms == null ) {
				this.likedRealms = new Array();
			}

			this.likedRealms.push( realm.id );

		} //

		/**
		 * this function returns the xml data of the saved world. there used to be a reason for it, but it's not being used now.
		 * might change this in the future.
		 */
		public function saveLocalWorld( gameData:LandGameData, onSaved:Function=null ):XML {

			var fileSource:FileWorldSource = this.worldSource as FileWorldSource;
			if ( fileSource == null ) {
				fileSource = new FileWorldSource( this._galaxy );
				this.worldSource = fileSource;
			}

			return fileSource.saveWorldToDisk( this.galaxy, this.clock.getDayPercent(), onSaved );
			
		} //

		public function createStartingRealm():LandRealmData {

			return this._galaxy.createNewRealm();

		} //

		public function getWorldEncoding():XML {

			return ( new LandEncoder() ).encodeWorld( this.galaxy, this.clock.getDayPercent() );

		} //

		public function moveLeft():void {

			this.curRealm.moveLeft();

		} //

		public function moveRight():void {

			this.curRealm.moveRight();

		} //

		public function setLocation( sceneX:int, sceneY:int ):void {

			this.curRealm.setCurLocation( sceneX, sceneY );

		} //

		public function getRealms():Vector.<LandRealmData> {

			return this._galaxy.getRealms();

		}

		/*public function resetRealms():void {

			//this._galaxy.resetRealms();

		} //*/

		/**
		 * Encode the current scene to a byte array.
		 */
		public function cacheCurScene( landGroup:LandGroup ):void {

			this.curRealm.cacheCurScene( landGroup.gameData );

			// currently won't use a callback.
			//this.worldSource.saveCurScene( this );

		} //

		/**
		 * saves the position of the player to the current planet.
		 */
		public function savePlayerPosition( playerX:int, playerY:int ):void
		{
			if(this.curRealm)
			{
				this.curRealm.playerPosition.setTo( playerX, playerY );
			}

		} //

		public function respawnPlayer( player:Entity ):void {

			var loc:Location = this.curRealm.playerPosition;

			var pSpatial:Spatial = player.get( Spatial ) as Spatial;
			pSpatial.x = loc.x;
			pSpatial.y = loc.y;

		} //

		/**
		 * resets the player position to the current planet's saved player position.
		 */
		public function resetPlayerPosition( player:Entity ):void {

			var pos:Location = this._galaxy.curRealm.playerPosition;

			var pSpatial:Spatial = player.get( Spatial ) as Spatial;
			pSpatial.x = pos.x;
			pSpatial.y = pos.y;

		} //

		public function visitRealm( realm:LandRealmData ):void {

			/*if ( this.curRealm != null && realm != this.curRealm ) {

				// check to delete realm data to save memory.

			} //*/

			this._galaxy.setCurRealm( realm );
			this.worldSource.visitRealm( realm );

		} //

		public function isLandingScene():Boolean {

			return this._galaxy.isLandingScene();

		}

		/**
		 * knowing the current scene number isn't enough to tell if an ad scene should be displayed:
		 * whether you exit to the left or right matters.
		 */
		public function shouldShowAdScene( isRightDoor:Boolean ):Boolean {

			var landingScene:int = this._galaxy.landingScene;
			var deltaX:int = this.curLoc.x - landingScene;

			// since there are both ad rooms to left and right of landing scene,
			// the math moving in the negative and positive directions is different
			// for computing the next ad room.
			if ( deltaX == 0 ) {
				return true;
			} else if ( deltaX < 0 ) {

				if ( isRightDoor ) {
					deltaX++;
				}

			} else {

				if ( !isRightDoor ) {
					deltaX--;
				}

			} //

			if ( deltaX % AD_FREQUENCY == 0 ) {
				return true;
			}
			return false;

		} //

	} // LandWorldManager

} // package