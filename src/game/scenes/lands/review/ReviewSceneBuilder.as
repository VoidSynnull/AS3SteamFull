package game.scenes.lands.review {

	/**
	 * ReviewSceneBuilder is like the main land SceneBuilder, only doesn't deal with monsters, events, items,
	 * and scenes that aren't saved to the database.
	 * 
	 */

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.world.LandSceneData;
	import game.scenes.lands.shared.world.LandWorldManager;


	public class ReviewSceneBuilder {

		private var landData:LandGameData;
		private var worldMgr:LandWorldManager;
		public function getWorldManager():LandWorldManager { return this.worldMgr; }

		/**
		 * called after the current scene has been constructed.
		 * onSceneBuilt() no params.
		 */
		private var onSceneBuilt:Function;
		
		public function ReviewSceneBuilder( worldMgr:LandWorldManager, gameData:LandGameData ) {

			this.worldMgr = worldMgr;
			this.landData = gameData;

		} //

		/**
		 * call whenever the user moves to a new land scene location.
		 * 
		 * this should fire AFTER the world location has changed - and the current biome should have all its assets loaded.
		 * because this function might take time loading new resources, game is paused until it's complete.
		 * 
		 * callback( sceneBuildSuccess:Boolean )
		 * 
		 */
		public function tryBuildScene( onBuilt:Function=null ):void {

			var sceneData:LandSceneData = this.worldMgr.curSceneData;

			// set random maps for the new world location.
			this.landData.worldRandoms.refreshMaps();
			
			if ( sceneData == null && this.worldMgr.curRealm.hasSavedData( this.worldMgr.curLoc.x ) ) {

				this.onSceneBuilt = onBuilt;
				if ( this.worldMgr.tryLoadCurScene( this.worldMgr.curLoc.x, 0, this.sceneDataReady ) ) {
					Review.Shell.logWWW( "Loading scene data: " + this.worldMgr.curLoc.x );
					return;
				} //
				
			} //
			
			if ( sceneData && sceneData.hasTileData() ) {

				// REBUILD SCENE FROM SCENE DATA IN THE WORLD.
				sceneData.fillSceneMaps( this.landData.tileMaps );

				if ( onBuilt ) {
					onBuilt( true );
				}

			} else {

				if ( onBuilt ) {
					onBuilt( false );
				}

			} //

		} //()
		
		/**
		 * callback for when the scene data is available from the world source.
		 * if this is a local file, the scene data will always be ready instantly, but if the source
		 * is on the server, the game will pause waiting for data.
		 */
		private function sceneDataReady( sceneData:LandSceneData, success:Boolean ):void {

			Review.Shell.logWWW( "data loaded from server: " + sceneData.xmlData );

			if ( sceneData.hasTileData() ) {
				
			//	this.landGroup.shellApi.logWWW( "SCENE LOADED FROM SERVER" );
				
				// REBUILD SCENE FROM SCENE DATA IN THE WORLD.
				sceneData.fillSceneMaps( this.landData.tileMaps );

				if ( this.onSceneBuilt ) {
					this.onSceneBuilt( true );
				}
				
			} else {

				if ( this.onSceneBuilt ) {
					this.onSceneBuilt( false );
				}

			} //
			
		} //

	} // class
	
} // package