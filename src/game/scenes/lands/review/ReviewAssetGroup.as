package game.scenes.lands.review {

	/**
	 * this is basically a stripped down version of LandGroup in order to load all the data necessary
	 * to display shared user scenes for review.
	 */

	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.LandAssetLoader;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.classes.WorldRandoms;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.parsers.LandParser;
	import game.scenes.lands.shared.tileLib.parsers.TileParser;
	import game.scenes.lands.shared.tileLib.templates.TemplateRegister;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.world.LandWorldManager;
	import game.scenes.lands.shared.world.PendingWorldSource;
	
	import org.osflash.signals.Signal;

	public class ReviewAssetGroup extends Group {

		public const BITMAP_SIZE:int = 2800;

		private var curScene:Scene;

		private var _loadBiome:String = "";
		public function get loadBiome():String {
			return this._loadBiome;
		}

		/**
		 * called after a new biome's assets have loaded.
		 * onBiomeChanged() - no parameters
		 */
		public var onBiomeChanged:Signal;

		/**
		 * onWorldLoaded() - no params
		 */
		public var onGalaxyLoaded:Signal;

		private var _sceneBitmapData:BitmapData;
		public function get sceneBitmapData():BitmapData {
			return this._sceneBitmapData;
		} //

		private var _gameData:LandGameData;
		public function get gameData():LandGameData { return this._gameData; } //
		
		/**
		 * handles saving and loading of worlds or 'galaxies' of realms.
		 */
		private var _worldMgr:LandWorldManager;
		public function get worldMgr():LandWorldManager {
			return this._worldMgr;
		}

		/**
		 * loads land assets at the start and when the biome changes.
		 */
		private var _assetLoader:LandAssetLoader;
		public function get assetLoader():LandAssetLoader {
			return this._assetLoader;
		}

		private var realmDisplay:RealmPainter;

		// amount to pad tiles on EACH side of the screen. (left/right) not up-down.
		private var offscreenTilePadding:int = 40;

		public function ReviewAssetGroup( scene:Scene ) {

			super();

			this.curScene = scene;

			this.onBiomeChanged = new Signal();
			this.onGalaxyLoaded = new Signal( Boolean );

		} //

		/**
		 * callback: onInitComplete( inProgress:Boolean )
		 * if inProgress is true in the callback, it means lands is continuing from
		 * an ad-scene and a world file does not need to be loaded.
		 */
		public function init( onInitComplete:Function=null ):void {

			this._worldMgr = new LandWorldManager();

			this.initGameData();
			this.initTileLayers();
			
			// cutting out the this.islandDataURL + "resources.xml" file, since everything about it is hard-coded anyway.
			super.shellApi.loadFiles( [ this.islandDataURL + "monsters.xml",
				this.islandDataURL + "tiles.xml", this.islandDataURL + "templates.xml" ],
				Command.create( this.dataFilesLoaded, onInitComplete ) );

			/*var saveBtn:Entity = (super.getGroupById( Hud.GROUP_ID ) as Hud).getButtonById( Hud.SAVE );
			if ( saveBtn ) {
				( saveBtn.get( Display ) as Display ).visible = false;
			}*/
			
		} //

		/**
		 * data files used in Realms like tileTypes, collectibles, template definitions, have been loaded.
		 * 
		 * at this point no biome-specific data has been loaded.
		 */
		private function dataFilesLoaded( onInitComplete:Function ):void {

			if ( this._assetLoader == null ) {
				this._assetLoader = new LandAssetLoader( this.shellApi, this.shellApi.assetPrefix + "scenes/lands/", this.gameData );
			}
			
			// !!! tileSets must be parsed before layers because the layers and maps reference tile set data.
			// forward referencing in this context is possible, but very difficult.
			var xml:XML = this.shellApi.getFile( this.islandDataURL + "tiles.xml", true );
			( new TileParser( this.gameData ).parse( xml ) );
			
			var register:TemplateRegister = new TemplateRegister();
			xml = this.shellApi.getFile( this.islandDataURL + "templates.xml", true );
			if ( xml ) {
				register.parseRegistry( xml, ( this.gameData.tileSets["decal"] as TileSet ).typesByCode, assetLoader );
			} //

			this.groupReady();

		} //

		public function loadCurBiome():void {

			super.shellApi.loadFile( this.islandDataURL + "biomes/" + this._loadBiome + ".xml", this.biomeDataLoaded );
			
		} //

		protected function biomeDataLoaded( biomeXML:XML ):void {
			
			if ( biomeXML == null ) {
				return;
			} //

			var screenRect:Rectangle = this.curScene.sceneData.cameraLimits;
			var tileBounds:Rectangle = new Rectangle( 0, 0, screenRect.width + 2*this.offscreenTilePadding, screenRect.height + this.offscreenTilePadding/2 );

			var parser:LandParser = new LandParser( tileBounds, this._gameData );
			parser.parseBiome( biomeXML, this._loadBiome );

			// swap in the tile types specific to this biome.
			this.gameData.tileSwapper.swapTiles( this._loadBiome );
				
			// load any new assets for the biome-specific tile types.
			this._assetLoader.loadTileFiles( this.biomeAssetsLoaded );

		} //
		
		/**
		 * called after both the xml files defining the land types, and the land type files themselves
		 * have been loaded.
		 */
		protected function biomeAssetsLoaded():void {
			
			/**
			 * find the tileMap with the largest tiles. this is used to set the WorldRandom map sizes,
			 * and to find how far the map should be shifted offscreen. +template stuff.
			 * 
			 * perhaps a better idea would just be to take the terrain map and use that...
			 */
			var fgLayer:TileLayer = this.gameData.getFGLayer();
			var terrainMap:TileMap = fgLayer.findBiggestTiles();

			// messy. several scene builder objects require knowing the base terrain map.
			//this._sceneBuilder.setBaseMap( terrainMap );
	
			this._gameData.worldRandoms.setMapSize( terrainMap.rows, terrainMap.cols );
			
			this._gameData.worldRandoms.seed = this.worldMgr.curRealmSeed;
			this._gameData.worldRandoms.refreshMaps();
			
			/*if ( firstLoad ) {
				
				this.runFirstLoad();
				
			} else {
				
				this._sceneBuilder.buildCurScene();
				// the uiGroup was paused during the switch.
				this.uiGroup.resume();
				
			}*/

			this.onBiomeChanged.dispatch();

		} //

		public function loadLocalWorld():void {

			this.worldMgr.loadLocalWorld( this._onGalaxyLoaded );

		} //

		public function loadPendingWorlds():void {

			var pending:PendingWorldSource = new PendingWorldSource( this.shellApi, this.worldMgr.galaxy );

			this.worldMgr.setWorldSource( pending );

			pending.loadPendingRealms( this._onGalaxyLoaded );

		} //

		public function reloadPendingWorlds():void {

			var pending:PendingWorldSource = this.worldMgr.worldSource as PendingWorldSource;
			pending.resetPage();
			pending.loadPendingRealms( this._onGalaxyLoaded );

		} //

		/*private function localWorldLoaded( err:String ):void {
		} //*/

		/**
		 * this function is called after new galaxy data has been loaded from a harddrive, server, or database.
		 */
		private function _onGalaxyLoaded( success:Boolean ):void {
			
			//this.shellApi.logWWW( "realms have loaded" );
			this.onGalaxyLoaded.dispatch( success );

		} //

		/**
		 * returns true if the current realm is ready to be loaded;
		 * returns false if the biome data needs to load first.
		 * the biome data will then begin loading automatically.
		 */
		public function prepareCurrentRealm():Boolean {

			var newBiome:String = this.worldMgr.getCurBiome();
			if ( newBiome == this._loadBiome ) {

				// Get the random seed from the newly loaded world and use it to recreate the random maps.
				// if the biome changed, this will be done after the assets load.
				this._gameData.worldRandoms.seed = this.worldMgr.curRealmSeed;
				this.gameData.worldRandoms.refreshMaps();

				return true;

			} else {
				
				this.changeBiome( newBiome );
				
			} //

			return false;
		} //

		/**
		 * 
		 * saveCurScene means to save the current scene in the previous biome. always true unless
		 * the biome changed because a saved game was loaded.
		 */
		public function changeBiome( newBiome:String ):void {
			
			this._loadBiome = newBiome;
			
			//this.clearBiome();
			this.loadCurBiome();
			
		} //

		/**
		 * resets all the groups and data when the current biome has changed.
		 *  destroy tileSets and reload the curLandFile (xml file)
		 */
		public function clearBiome():void {

			this.gameData.fgLayer.reset();
			this.gameData.bgLayer.reset();

			//this.onLeaveScene.dispatch();
			this.gameData.tileMaps = new Dictionary();

		} //

		/**
		 * Create an entity for the LandGame itself, to facilitate data passing
		 * and dynamic object 'stuff'.
		 */
		private function initGameData():void {

			var gameData:LandGameData = this._gameData = new LandGameData();

			gameData.mapOffsetX = -this.offscreenTilePadding;
			gameData.worldRandoms = new WorldRandoms( this._worldMgr.galaxy );

		} //

		protected function initTileLayers():void {

			//var bgEntity:Entity = this.curScene.getEntityById( "background" );
			//var display:Display = bgEntity.get( Display ) as Display;

			// put a shadow on the background.
			//var clip:DisplayObjectContainer = display.displayObject;
			//var ct:ColorTransform = new ColorTransform( 0.65, 0.65, 0.65 );
			//clip.transform.colorTransform = ct;

			this._sceneBitmapData = new BitmapData( this.BITMAP_SIZE, this.BITMAP_SIZE, false );

			// for the review program, both the foreground and background can use the same renderContext.
			var renderContext:RenderContext = new RenderContext( this._sceneBitmapData );
			renderContext.init( -this.offscreenTilePadding, 0 );

			this.gameData.bgLayer = new TileLayer( "background", renderContext );

			// shouldn't need to mark the randOffset here because only non-random scenes are reviewed.
			//layer.randOffset = 3;
			
			// FOREGROUND LAYER STUFF
			this.gameData.fgLayer = new TileLayer( "foreground", renderContext );

		} //

		public function get sceneDataURL():String		{ return super.shellApi.dataPrefix + "lab1/"; }
		public function get islandDataURL():String		{ return super.shellApi.dataPrefix + "scenes/lands/"; }
		public function get sharedAssetURL():String			{ return super.shellApi.assetPrefix + "scenes/lands/shared/"; }

	} // class

} // package