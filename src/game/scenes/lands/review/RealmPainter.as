package game.scenes.lands.review {

	import flash.geom.ColorTransform;

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.classes.LandAssetLoader;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.world.LandRealmData;
	import game.scenes.lands.shared.world.LandWorldManager;
	import game.scenes.lands.shared.world.PendingWorldSource;

	public class RealmPainter {

		/**
		 * id of the current realm being displayed.
		 */
		private var curSceneId:int;

		/**
		 * count of scene being painted. not a scene id.
		 */
		private var curSceneNum:int;
		/**
		 * used to print progress: curScene/totalScenes
		 */
		private var totalScenes:int;

		/**
		 * the realm being displayed.
		 */
		private var curRealm:LandRealmData;
		public function set currentRealm( realm:LandRealmData ):void {
			this.curRealm = realm;
		}

		/**
		 * called after the current realm has been displayed. no parameters.
		 */
		private var onRealmDisplayed:Function;

		private var builder:ReviewSceneBuilder;

		private var assetLoader:LandAssetLoader;
		private var gameData:LandGameData;

		//private var worldMgr:LandWorldManager;

		/**
		 * bitmap where the scene is drawn
		 */
		//private var sceneBitmap:BitmapData;

		private var realmDisplay:RealmDisplay;

		/**
		 * used for logging progress.
		 */
		private var reviewUI:ReviewUI;

		// need to clean up all this data passing. some day...
		public function RealmPainter( review:ReviewUI, worldMgr:LandWorldManager, display:RealmDisplay, 
									  assetLoader:LandAssetLoader, gameData:LandGameData ) {

			//this.worldMgr = worldMgr;
			this.reviewUI = review;

			this.realmDisplay = display;
			this.gameData = gameData;
			this.assetLoader = assetLoader;

			this.builder = new ReviewSceneBuilder( worldMgr, gameData );

		}

		/**
		 * draw/display all user-edited scenes from the current realm.
		 *
		 *  callback() - no parameters.
		 */
		public function displayAllScenes( realm:LandRealmData=null, onComplete:Function=null ):void {

			if ( realm != null ) {
				this.curRealm = realm;
			}

			if ( onComplete != null ) {
				this.onRealmDisplayed = onComplete;
			}

			if ( this.curRealm != null ) {

				this.totalScenes = curRealm.getSceneCount();
				
				this.curSceneNum = 0;
				this.curSceneId = -1;		// next scene will be scene 0.

				this.realmDisplay.lock();

				// first try to load EVERY available scene.
				var source:PendingWorldSource = this.builder.getWorldManager().worldSource as PendingWorldSource;
				if ( source != null ) {

					source.loadPendingScenes( this.curRealm, this.scenesLoaded );

				} else {

					this.displayNextScene();

				}

			} else {

				if ( onComplete ) {
					onComplete();
				}

			} //

		} //

		/**
		 * ignore success. i dont care.
		 */
		private function scenesLoaded( success:Boolean ):void {

			this.displayNextScene();

		} //

		/**
		 * cancel the display of the current realm. a lot of callbacks are involved so this might be tricky.
		 */
		public function cancelDisplay():void {
		} //

		private function displayCurrentScene():void {

			this.curSceneNum++;

			this.reviewUI.showMessage( "Painting scene id: " + this.curSceneId + "  (" + this.curSceneNum + "/" + this.totalScenes + ")" );

			// still need to SET the current scene.
			this.curRealm.setCurLocation( this.curSceneId, 0 );

			// load the scene data into the game tile maps.
			this.builder.tryBuildScene( this.onSceneBuilt );

		} //

		private function onSceneBuilt( success:Boolean ):void {

			if ( !success ) {

				this.reviewUI.showMessage( "NO SCENE DATA. SKIPPING SCENE" );
				this.displayNextScene();

			} else {
	
				/**
				 * try to redraw the whole screen, but first check that all the props used in the scene
				 * have their assets loaded. If all assets are known to be loaded, use refreshScreen() instead.
				 */
				// checks if any decals need to be preloaded and if so, waits for a callback to refresh the screen.
				if ( this.assetLoader.loadMapDecals( this.gameData.tileMaps, this.drawScene ) ) {
					//Review.Shell.logWWW( "waiting for decal loads." );
					return;
				}
				this.drawScene();

			} //

		} //

		/**
		 * Redraws the screen without any checks to make sure props have been loaded.
		 * Call when all props in the map are known to be up to date.
		 */
		private function drawScene():void {

			// layers need to render in order here.
			var layer:TileLayer = this.gameData.getBGLayer();

			var rc:RenderContext = layer.getRenderContext();
			rc.clearContext();

			layer.renderReview();

			rc.viewBitmap.colorTransform( rc.viewBitmap.rect, new ColorTransform( 1, 1, 1, 0.7 ) );

//			this.realmDisplay.drawScene( layer.getRenderContext().viewBitmap );

			layer = this.gameData.getFGLayer();
			layer.renderReview();

			this.realmDisplay.drawScene( rc.viewBitmap );
			this.displayNextScene();

		} //

		/**
		 * after a scene has finished painting, go to the next scene and attempt to paint that one,
		 * if it exists.
		 */
		private function displayNextScene():void {

			var sceneMap:Array = this.curRealm.sceneMap;

			do {

				this.curSceneId++;
				if ( this.curSceneId >= sceneMap.length ) {

					// all scenes have been displayed.
					if ( this.onRealmDisplayed != null ) {

						this.onRealmDisplayed();
						this.realmDisplay.unlock();

					}

					return;
				}

			} while ( !( this.curRealm.hasSceneData( this.curSceneId ) || this.curRealm.hasSavedData( this.curSceneId ) ) );

			this.displayCurrentScene();

		} //

	} // class
	
} // package