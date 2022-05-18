package game.scenes.lands.shared {

	import com.poptropica.AppConfig;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.JPEGEncoderOptions;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.MovieClipHit;
	import game.components.scene.SceneInteraction;
	import game.data.TimedEvent;
	import game.data.ads.AdData;
	import game.data.profile.ProfileData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManagerBrowser;
	import game.nodes.entity.character.CharacterMotionControlNode;
	import game.proxy.ITrackingManager;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.LandsEvents;
	import game.scenes.lands.adMixed1.AdMixed1;
	import game.scenes.lands.shared.classes.CollectibleResource;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.LandInventory;
	import game.scenes.lands.shared.classes.LandServerGateway;
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.classes.ResourceType;
	import game.scenes.lands.shared.classes.SaveAndLoadFile;
	import game.scenes.lands.shared.classes.SceneBuilder;
	import game.scenes.lands.shared.classes.SkyRenderer;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.components.HitTileComponent;
	import game.scenes.lands.shared.components.LandCollectible;
	import game.scenes.lands.shared.components.LandGameComponent;
	import game.scenes.lands.shared.components.LandHiliteComponent;
	import game.scenes.lands.shared.components.LandInteraction;
	import game.scenes.lands.shared.components.LandWeatherCollider;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.components.SharedToolTip;
	import game.scenes.lands.shared.components.SpawnerComponent;
	import game.scenes.lands.shared.components.TileBlaster;
	import game.scenes.lands.shared.components.TimedTileList;
	import game.scenes.lands.shared.components.TriggerEvent;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.monsters.MonsterBuilder;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.monsters.systems.MonsterFollowSystem;
	import game.scenes.lands.shared.monsters.systems.MonsterSpawnSystem;
	import game.scenes.lands.shared.monsters.systems.MonsterUpdateSystem;
	import game.scenes.lands.shared.monsters.systems.MonsterWanderSystem;
	import game.scenes.lands.shared.monsters.systems.SpiderSystem;
	import game.scenes.lands.shared.plugins.RealmsAdPlugin;
	import game.scenes.lands.shared.popups.worldManagementPopup.WorldManagementPopup;
	import game.scenes.lands.shared.systems.BarSystem;
	import game.scenes.lands.shared.systems.BlastTileSystem;
	import game.scenes.lands.shared.systems.DecalDropSystem;
	import game.scenes.lands.shared.systems.FocusTileSystem;
	import game.scenes.lands.shared.systems.InputManagerSystem;
	import game.scenes.lands.shared.systems.LandCollectibleSystem;
	import game.scenes.lands.shared.systems.LandEditSystem;
	import game.scenes.lands.shared.systems.LandHazardSystem;
	import game.scenes.lands.shared.systems.LandHitSystem;
	import game.scenes.lands.shared.systems.LandInteractionSystem;
	import game.scenes.lands.shared.systems.LifeSystem;
	import game.scenes.lands.shared.systems.LightningStrikeSystem;
	import game.scenes.lands.shared.systems.LightningTargetSystem;
	import game.scenes.lands.shared.systems.SimpleWaveSystem;
	import game.scenes.lands.shared.systems.SpecialTilesSystem;
	import game.scenes.lands.shared.systems.TimedTileSystem;
	import game.scenes.lands.shared.systems.weather.RealmsWeatherSystem;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.LandAssetLoader;
	import game.scenes.lands.shared.tileLib.classes.LandProgress;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.classes.WorldRandoms;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.parsers.LandParser;
	import game.scenes.lands.shared.tileLib.parsers.MonsterParser;
	import game.scenes.lands.shared.tileLib.parsers.TileParser;
	import game.scenes.lands.shared.tileLib.templates.TemplateRegister;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.scenes.lands.shared.ui.FadeText;
	import game.scenes.lands.shared.util.LandUtils;
	import game.scenes.lands.shared.world.LandRealmData;
	import game.scenes.lands.shared.world.LandWorldManager;
	import game.scenes.lands.shared.world.RealmBiomeData;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.scenes.virusHunter.heart.systems.ColorBlinkSystem;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.systems.SystemPriorities;
	import game.systems.hit.MovieClipHitSystem;
	import game.ui.hud.Hud;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;

	public class LandGroup extends Group {

		public static const CAMPAIGN:String = "Realms";

		/**
		 * snapshot size when sending a snapshot of the user's land to the server.
		 */
		private const SNAPSHOT_SIZE:int = 800;
		/**
		 * size of thumnail sent to server for a realm.
		 */
		private const THUMBNAIL_SIZE:int = 150;

		/**
		 * rate at which current scene should be saved to the server, in milliseconds.
		 */
		private const GAME_SAVE_RATE:uint = 1000*30;

		private const TELEPORT_SOUND:String = "event_06.mp3";
		private const UI_GROUP:String = "landUIGroup";

		/**
		 * saves the default gravity so motionUtils.GRAVITY can be safely overwritten
		 * and restored later on.
		 */
		public var DEFAULT_GRAVITY:Number;

		private var _curScene:PlatformerGameScene;
		public function get curScene():PlatformerGameScene { return this._curScene; }

		private var _sceneBuilder:SceneBuilder;
		public function get sceneBuilder():SceneBuilder { return this._sceneBuilder; }

		/**
		 * handles transfer of land user data to the LSO and the server.
		 */
		private var gateway:LandServerGateway;

		private var _gameEntity:Entity;
		public function get gameEntity():Entity { return this._gameEntity; }

		private var _gameData:LandGameData;
		[Inline]
		final public function get gameData():LandGameData { return this._gameData; }

		/**
		 * handles saving and loading of worlds or 'galaxies' of realms.
		 */
		private var _worldMgr:LandWorldManager;
		public function get worldMgr():LandWorldManager { return this._worldMgr; }

		/**
		 * this is the biome currently loaded, or if newly set, it will be the biome that is loaded next.
		 */
		private var _loadBiome:String = "grass";
		public function get loadBiome():String { return this._loadBiome; }

		/**
		 * This property sets the next biome to be loaded. You should load the new biome immediately,
		 * since the set biome will now be out of sync with the actual biome.
		 */
		public function set loadBiome( s:String ):void { this._loadBiome = s; } //

		/**
		 * loads land assets at the start and when the biome changes.
		 */
		private var _assetLoader:LandAssetLoader;
		public function get assetLoader():LandAssetLoader { return this._assetLoader; }

		/**
		 * doors for moving to next land tile scene. doesn't actually use the as3 door system.
		 */
		private var leftDoor:Entity, rightDoor:Entity;

		private var player:Entity;

		/**
		 * lastTick is used to compute how much processing time a frame took. if a frame didn't take much time,
		 * then the group can perform rare update operations - like changing the sky backdrop.
		 */
		private var lastTick:uint;
		/**
		 * time game was last saved on server.
		 */
		private var lastGameSave:uint;

		// amount to pad tiles on EACH side of the screen. (left/right) not up-down.
		private var offscreenTilePadding:int = 40;

		private var uiGroup:LandUIGroup;

		private var _skyRenderer:SkyRenderer;
		public function get skyRenderer():SkyRenderer { return this._skyRenderer; }

		/**
		 * called after a new biome's assets have loaded.
		 * onBiomeChanged() - no parameters
		 */
		public var onBiomeChanged:Signal;

		/**
		 * called when leaving a land scene and before the new scene is constructed.
		 * onLeaveScene()
		 */
		public var onLeaveScene:Signal;

		private var plugins:Vector.<RealmsAdPlugin>;
		public function getPlugins():Vector.<RealmsAdPlugin> { return this.plugins; }

		/**
		 * signal triggers when a biome is first left.
		 * since the tilemaps of a biome will be destroyed when a biome is left, some systems will need to delete their objects.
		 */
		//public var onLeaveBiome:Signal;

		public function LandGroup( scene:PlatformerGameScene ) {

			super();

			this.id = "landGroup";

			this._curScene = scene;

			this.onLeaveScene = new Signal();
			this.onBiomeChanged = new Signal();

			this.DEFAULT_GRAVITY = MotionUtils.GRAVITY;

		} //

		/**
		 * callback: onInitComplete( inProgress:Boolean )
		 * if inProgress is true in the callback, it means lands is continuing from
		 * an ad-scene and a world file does not need to be loaded.
		 */
		public function init( onInitComplete:Function=null, pluginList:Vector.<RealmsAdPlugin>=null ):void {

			this.plugins = pluginList;

			var sys:LandCollectibleSystem = new LandCollectibleSystem( this );
			sys.onCollected.add( this.onLandCollect );

			this.addSystem( new InputManagerSystem(), SystemPriorities.preUpdate );

			this.addSystem( new MovieClipHitSystem(), SystemPriorities.update );
			this.addSystem( sys, SystemPriorities.postUpdate );
			this.addSystem( new SimpleWaveSystem(), SystemPriorities.update );
			this.addSystem( new BlastTileSystem( this._curScene.hitContainer ), SystemPriorities.update );

			this._worldMgr = new LandWorldManager();

			this.player = this.parent.getEntityById( "player" );

			this.createGameEntity();
			this.initTileLayers();
			this.initBackdrop();

			// cutting out the this.islandDataURL + "resources.xml" file, since everything about it is hard-coded anyway.
			super.shellApi.loadFiles( [ this.islandDataURL + "monsters.xml",
				this.islandDataURL + "tiles.xml", this.islandDataURL + "templates.xml" ],
				Command.create( this.dataFilesLoaded, onInitComplete ) );

			//( this.player.get( Sleep ) as Sleep ).
			player.add( new MovieClipHit( "player" ), MovieClipHit );

			var life:Life = new Life( 100, 2.5 );
			player.add( life, Life );
			player.add( new ColorBlink( 0x880000, 0.43, 0.5 ), ColorBlink );

			player.add( new HitTileComponent(), HitTileComponent );
			( player.get( Sleep ) as Sleep ).sleeping = true;

			player.add( new LandWeatherCollider(), LandWeatherCollider );
			this.gateway = new LandServerGateway( this.shellApi );

			// NOTE :: Shouldn't have to do this, since you can't be in Realms as a guest. -bard
			Hud( super.getGroupById( Hud.GROUP_ID ) ).hideButton( Hud.SAVE );
		}

		public function playLocally( biome:String=null ):void {

			if ( biome != null ) {
				this.worldMgr.createNewLocalWorld( biome );
			} else {
				this.worldMgr.createNewLocalWorld( this._loadBiome );
			}
				
			this.visitCurRealm();

		} //

		/**
		 * load a user's world from a live poptropica database.
		 * the onLoaded() function used here is currently shared.. but it could be split so that different
		 * actions can be taken when the different types of loads fail.
		 */
		public function loadFromDatabase():void {

			// try getting a policy file.
			Security.loadPolicyFile( "https://s3.amazonaws.com/poptropica-realms-thumbnails/crossdomain.xml" );

			this.worldMgr.loadDatabaseGalaxy( this.shellApi, this.onDatabaseLoad );

		} //

		/**
		 * loads a world file located in the server file structure.
		 * if absolutePath is false, the xml world file is located in the currente scene's data directory.
		 * if absolutePath is true, then worldFile must be an absolute path on the server to the world file.
		 */
		public function loadServerWorld( worldFile:String, absolutePath:Boolean=false ):void {

			if ( !absolutePath ) {

				this.worldMgr.loadServerFile( this, this.sceneDataURL + worldFile, this.onGalaxyLoaded );

			} else {

				this.worldMgr.loadServerFile( this, worldFile, this.onGalaxyLoaded );

			} //

		} //

		/**
		 * land loaded from data.
		 */
		private function onDatabaseLoad( error:String ):void {

			if ( error || this.worldMgr.curRealm == null ) {

				// no realms in the current galaxy. load one from a server file and save it.
				// if THIS fails, the user should go into local mode.
				this.worldMgr.worldSource.loadServerGalaxy( this.shellApi, this.sceneDataURL + "start_world.xml",
					this.onGalaxyLoaded );

			} else {
				this.onGalaxyLoaded();
			}

		} //

		/*private function serverFileLoaded( error:String ):void {

			// a world was loaded - most likely server.xml world, before any biome had been loaded.
			if ( !this.curScene.isReady ) {

				this.loadBiome = this.worldMgr.getCurBiome();
				this.loadCurBiome();

			} else {

				this.onGalaxyLoaded();

			}

		} //*/

		public function loadCurBiome():void {

			this.pauseGame();
			super.shellApi.loadFile( this.islandDataURL + "biomes/" + this.loadBiome + ".xml", this.biomeDataLoaded );

		} //

		/**
		 * data files used in Land like tileTypes, collectibles, template definitions.
		 * this does not include the biome.xml files however, which are loaded as needed.
		 */
		private function dataFilesLoaded( onInitComplete:Function ):void {

			// cutting out the resources.xml file since there's already so much that's hardcoded.
			/*var xml:XML = this.shellApi.getFile( this.islandDataURL + "resources.xml", true );
			if ( xml ) {
				this.collectibleDataLoaded( xml );
			}*/

			this.initGameInventory();

			if ( this._assetLoader == null ) {
				this._assetLoader = new LandAssetLoader( this.shellApi, this.shellApi.assetPrefix + "scenes/lands/", this.gameData );
			}

			// !!! tileSets must be parsed before layers because the layers and maps reference tile set data.
			// forward referencing in this context is possible, but very difficult.
			var xml:XML = this.shellApi.getFile( this.islandDataURL + "tiles.xml", true );
			( new TileParser( this.gameData ).parse( xml ) );
 
			var monsterBuilder:MonsterBuilder = new MonsterBuilder( this, this.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup );
			xml = this.shellApi.getFile( this.islandDataURL + "monsters.xml", true );
			if ( xml ) {
				new MonsterParser().parse( xml, monsterBuilder );
			}

			var templateRegister:TemplateRegister = new TemplateRegister();
			xml = this.shellApi.getFile( this.islandDataURL + "templates.xml", true );
			if ( xml ) {
				templateRegister.parseRegistry( xml, ( this.gameData.tileSets["decal"] as TileSet ).typesByCode, assetLoader );
			} //

			this._sceneBuilder = new SceneBuilder( this, this.landGenerated, monsterBuilder, templateRegister );

			// might want to make sure collectible assets are also loaded etc. can fix more of this later.

			var uiGroup:LandUIGroup = this.uiGroup = new LandUIGroup( this, this._curScene );
			uiGroup.id = this.UI_GROUP;
			this.addChildGroup( uiGroup );

			uiGroup.ready.addOnce( Command.create( this.onUIGroupReady, onInitComplete ) );

			if ( this.plugins != null ) {

				var plugin:RealmsAdPlugin;
				var ui_swf:String = "land_ui.swf";

				for( var i:int = this.plugins.length-1; i>=0; i-- ) {

					plugin = this.plugins[i];
					plugin.init( this );
					if ( plugin.uiFileName != null ) {
						ui_swf = this.plugins[i].uiFileName;
					}

				}
				uiGroup.init( this.gameData, ui_swf );

			} else {

				uiGroup.init( this.gameData, "land_ui.swf" );

			} //

		} //

		/**
		 * called after the UIGroup has loaded and initialized all its panes and resources.
		 */
		private function onUIGroupReady( group:Group, onInitComplete:Function ):void {

			this.uiGroup.onUIModeChanged.add( this.onUIModeChanged );

			// check if the world is loading from an LSO cache after visiting an Ad-scene.
			var cachedLoad:Boolean = this._worldMgr.tryCachedLoad( this );

			if ( cachedLoad ) {

				// instead call onGalaxyLoaded() here?
				if ( this.worldMgr.galaxy.isPublicGalaxy ) {
					this.uiGroup.setPublicMode();
				} else {
					this.uiGroup.setPrivateMode();
				} //

				var tryBiome:String = this._worldMgr.getCurBiome();
				if ( tryBiome != null && tryBiome != "" ) {
					this.loadBiome = tryBiome;
				}
				this.loadCurBiome();

			} //

			if ( onInitComplete ) {
				onInitComplete( cachedLoad );
			} //

		} //

		private function initGameInventory():void {

			this._gameData.inventory = new LandInventory();

			var resourceTypes:Dictionary = this._gameData.inventory.getResources();

			var fileList:Array = new Array();

			for each ( var type:ResourceType in resourceTypes ) {
				
				var collectible:CollectibleResource = type as CollectibleResource;
				if ( collectible == null ) {
					continue;
				}

				// this is only for resources that use a single bitmap for all instances.
				if ( collectible.useBitmap && collectible.swf != null ) {
					fileList.push( this.sharedAssetURL + collectible.swf );
				}
				
			} // end for-loop.
			
			if ( fileList.length > 0 ) {
				this.shellApi.loadFiles( fileList, this.collectibleAssetsLoaded );
			} else {
				// nothing to load.
				this.collectibleAssetsLoaded();
			}

			//this.shellApi.logWWW( "loading land user vars..." );
			this.gateway.loadUserVars( this.onUserVarsLoaded );

		} //

		/**
		 * this is from when the collectibles were defined in an xml file. but right now there is only experience and poptanium
		 * and not enough variety to bother.
		 */
		/*private function collectibleDataLoaded( xml:XML ):void {

			var parser:CollectibleParser = new CollectibleParser();
			var resourceTypes:Dictionary = parser.parse( xml );

			this._gameData.inventory = new LandInventory( resourceTypes );

			var fileList:Array = new Array();

			for each ( var type:ResourceType in resourceTypes ) {

				var collectible:CollectibleResource = type as CollectibleResource;
				if ( collectible == null ) {
					continue;
				}

				// this is only for resources that use a single bitmap for all instances.
				if ( collectible.useBitmap && collectible.swf != null ) {
					fileList.push( this.sharedURL + collectible.swf );
				}

			} // end for-loop.
			if ( fileList.length > 0 ) {
				this.shellApi.loadFiles( fileList, this.collectibleAssetsLoaded );
			} else {
				// nothing to load.
				this.collectibleAssetsLoaded();
			}
			this.gateway.loadUserVars( this.onUserVarsLoaded );
		} //*/

		private function onUserVarsLoaded( savedData:Object, error:String ):void {

			this.shellApi.logWWW( "USER VARS LOADED..." );

			if ( savedData.poptanium ) {
				//this.shellApi.logWWW( "SERVER POPTANIUM: " + savedData.poptanium );
				this.gameData.inventory.addResource( "poptanium", savedData.poptanium );
			} else {
				this.shellApi.logWWW( "No poptanium loaded from server." );
			}
			if ( savedData.experience ) {
				//this.shellApi.logWWW( "SERVER EXPERIENCE: " + savedData.experience );
				this.gameData.progress.recalculateLevel( savedData.experience );
				this.gameData.inventory.addResource( "experience", savedData.experience );
			} else {
				this.shellApi.logWWW( "No experience loaded from server." );
			}

			this.gameData.progress.onLevelUp.add( this.onLevelUp );
			this.gameData.inventory.onUpdate.add( this.onInventoryChanged );

		} //

		private function collectibleAssetsLoaded():void {

			var clip:MovieClip;
			var types:Dictionary = this._gameData.inventory.getResources();

			for each ( var type:ResourceType in types ) {

				var collectible:CollectibleResource = type as CollectibleResource;
				if ( collectible == null ) {
					continue;
				}

				if ( collectible.useBitmap && collectible.swf != null ) {

					clip = this.shellApi.getFile( this.sharedAssetURL + collectible.swf );

					if ( clip ) {
						collectible.bitmap = LandUtils.prepareBitmap( clip, clip.width, clip.height );
					}

				}

			} // end for-loop.

		} //

		protected function biomeDataLoaded( biomeXML:XML ):void {

			if ( biomeXML != null ) {

				var screenRect:Rectangle = this._curScene.sceneData.cameraLimits;
				var tileBounds:Rectangle = new Rectangle( 0, 0, screenRect.width + 2*this.offscreenTilePadding, screenRect.height + this.offscreenTilePadding/2 );

				var parser:LandParser = new LandParser( tileBounds, this._gameData );
				parser.parseBiome( biomeXML, this.loadBiome );

				var biomeData:RealmBiomeData = this.gameData.biomeData;
				this.skyRenderer.setSkyColors( biomeData.topSkyColors, biomeData.bottomSkyColors );

				if ( !isNaN( biomeData.gravity ) && biomeData.gravity != MotionUtils.GRAVITY ) {
					this.setSceneGravity( biomeData.gravity );
				} else if ( this.DEFAULT_GRAVITY != MotionUtils.GRAVITY ) {
					this.setSceneGravity( this.DEFAULT_GRAVITY );
				}

				// swap in the tile types specific to this biome.
				this.gameData.tileSwapper.swapTiles( this.loadBiome );

				// load any new assets for the biome-specific tile types.
				this._assetLoader.loadTileFiles( this.biomeAssetsLoaded );

			} else {

				this.uiGroup.showDialog( "Oops! Biome data not found." );

			} //

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
			/**
			 * add lights for the foreground layer.
			 */
			//fgLayer.addLightRenderer( this.gameData );

			// messy. several scene builder objects require knowing the base terrain map.
			this._sceneBuilder.setBaseMap( terrainMap );

			this._gameData.worldRandoms.setMapSize( terrainMap.rows, terrainMap.cols );
			this.worldMgr.resetPlayerPosition( this.player );

			var firstLoad:Boolean = ( !this._curScene.isReady );
			if ( firstLoad == false ) {

				// i'm not sure why this has to happen here instead of below. in future attempt to move this down.
				this.onBiomeChanged.dispatch();

			} //

			this._gameData.worldRandoms.seed = this.worldMgr.curRealmSeed;
			this._gameData.worldRandoms.refreshMaps();
			this._skyRenderer.init( this._gameData.worldRandoms.randMap );

			this.lastTick = getTimer();

			this.worldMgr.worldSource.visitRealm( this.worldMgr.curRealm );

			if ( firstLoad ) {

				this.runFirstLoad();

			} else {

				this._sceneBuilder.buildCurScene();
				// the uiGroup was paused during the switch.
				this.uiGroup.resume();

			}

		} //

		/**
		 * Runs ONCE whenever the user first comes to the Lands (including visiting ad scenes and returning)
		 * Runs directly after biomeAssetsLoaded()
		 * This is AFTER the UiGroup has loaded.
		 * TileLayers and TileMaps also exist at this point.
		 */
		private function runFirstLoad():void {

			this.initDoors();

			if ( this._skyRenderer ) {
				this.systemManager.updateComplete.add( this.gameUpdateLoop );
			}

			var tileBlaster:TileBlaster = this.gameEntity.get( TileBlaster );
			tileBlaster.onTileBlasted.add( this.onTileBlasted );

			this.gameEntity.add( new LandInteraction() );

			// some more systems to add on first load.
			var sys:LifeSystem = new LifeSystem();
			sys.onEntityDied.add( this.onEntityDied );
			this.addSystem( sys, SystemPriorities.postUpdate );

			this.addSystem( new LightningTargetSystem( this.uiGroup.inputManager ), SystemPriorities.update );

			this.addSystem( new ColorBlinkSystem(), SystemPriorities.update );

			this.addSystem( new RealmsWeatherSystem(), SystemPriorities.update );

			// postUpdate so drop occurs after mouse movement.
			this.addSystem( new DecalDropSystem(), SystemPriorities.postUpdate );
			
			// used to find the location of mouse clicks.
			var bgEntity:Entity = this._curScene.getEntityById( "background" );
			var backDisplay:DisplayObject = ( bgEntity.get( Display ) as Display ).displayObject;
			this.addSystem( new LandEditSystem( this, backDisplay ), SystemPriorities.update );

			// postUpdate so cursor strike location is already updated when the lightning draws.
			this.addSystem( new LightningStrikeSystem(), SystemPriorities.postUpdate );
			this.addSystem( new FocusTileSystem( this.gameData.mapOffsetX ), SystemPriorities.preUpdate );

			this.addSystem( new BarSystem(), SystemPriorities.postUpdate );
			this.addSystem( new LandHazardSystem( this ), SystemPriorities.update );
			this.addSystem( new VariableTimelineSystem(), SystemPriorities.timelineControl );
			this.addSystem( new LandHitSystem( this.gameData.getFGLayer() ), SystemPriorities.checkCollisions );
			this.addSystem( new SpecialTilesSystem(), SystemPriorities.update );
			this.addSystem( new TimedTileSystem(), SystemPriorities.update );
			this.addSystem( new SpiderSystem( this ), SystemPriorities.update );
			this.addSystem( new LandInteractionSystem( this ), SystemPriorities.update );

			// UGH: monster systems need to access the land interaction system. for now.
			this.addSystem( new MonsterWanderSystem( this ), SystemPriorities.update );
			this.addSystem( new MonsterFollowSystem( this ), SystemPriorities.update );
			this.addSystem( new MonsterUpdateSystem( this ), SystemPriorities.update );

			var cameraSys:CameraSystem = this.getSystem(CameraSystem) as CameraSystem;
			this.addSystem( new MonsterSpawnSystem( this, cameraSys.viewport ),	SystemPriorities.lowest );

			//this.addSystem( new RegionUpdateSystem( this ), SystemPriorities.update );

			//add light with range to make it get darker the lower you get.
			/*var lightCreator:LightCreator = new LightCreator();
			lightCreator.setupLight( this.curScene, this.curScene.overlayContainer, 0.45, true );
			lightCreator.addLight( this.player, 150, 0.45, 0.2, true, 0, 0, true, this.sceneBounds.bottom, 2100 );*/

			this._sceneBuilder.buildCurScene();
			this.uiGroup.resume();

		} //

		/**
		 * TEMP. test putting the world management popup here. see what happens.
		 * 
		 * NOTE: should also pause game.
		 */
		public function showWorldManagementScreen():void {

			this.uiGroup.hideUI();
			//this.uiGroup.getQuickBar().hide();

			this.saveCurrentData( false, true, false, this.onThumbSaved );

			AudioUtils.stop( this, null, SceneSound.SCENE_SOUND);
			var myUrl:String = "realms_theme.mp3";
			AudioUtils.play( this, SoundManager.AMBIENT_PATH + myUrl, 1, true, [SoundModifier.FADE, SoundModifier.AMBIENT], SceneSound.SCENE_SOUND);
			this.biomePlaying = '';

			AudioUtils.play( this, SoundManager.EFFECTS_PATH + this.TELEPORT_SOUND, 1, false, SoundModifier.EFFECTS );
			//super.shellApi.triggerEvent( "set_ambient_world_management" );

			this.uiGroup.zoomOut();

			SceneUtil.showHud( this._curScene, false );
			SceneUtil.lockInput(this, true);

		} //

		/**
		 * Have to wait for the thumb-save because they want the thumbnail available before the management popup
		 * opens.  might end up putting the wait inside the management popup, but i'm not sure how that would work.
		 */
		private function onThumbSaved( success:Boolean, errorCode:int ):void {

			var popup:WorldManagementPopup = new WorldManagementPopup( this._curScene.overlayContainer );
			popup.ready.addOnce( this.onManagementReady );
			popup.popupRemoved.addOnce( this.onManagementClosed );
			
			super.addChildGroup( popup );

		} //

		private function onManagementReady( popup:Popup ):void {

			this.pauseGame();			// pause is delayed because it hides the player.
			SceneUtil.lockInput(this, false);

		} //
		
		protected function onManagementClosed():void {

			this.uiGroup.showUI();
			SceneUtil.showHud( this._curScene, true );

			if ( this.worldMgr.publicMode ) {
				this.uiGroup.setPublicMode();
			} else {
				this.uiGroup.setPrivateMode();
			} //

			this.unpauseGame();

		} //

		/**
		 * leavingScene saves following monsters to the scene as well.
		 * 
		 * saveThumbnail saves a small screenshot of the current scene.
		 * 
		 * callback is error string, or null.
		 */
		public function saveCurrentData( changingScene:Boolean=true, saveThumbnail:Boolean=false, showSaveIcon:Boolean=true, saveCallback:Function=null ):void {

			var pSpatial:Spatial = this.player.get( Spatial ) as Spatial;
			this.worldMgr.savePlayerPosition( pSpatial.x, pSpatial.y );

			if ( this.gameData.saveDataPending || saveThumbnail ) {

				//this.shellApi.logWWW( "LandGroup: SAVING DATA" );
				
				this._sceneBuilder.cacheCurScene( changingScene );

				if ( saveThumbnail ) {
					// get screen bitmap.
					var bm:BitmapData = this.getSceneBitmap( this.THUMBNAIL_SIZE, this.THUMBNAIL_SIZE );
					this.worldMgr.worldSource.saveSceneAndThumbnail( bm.encode( bm.rect,new flash.display.JPEGEncoderOptions() ), saveCallback );

				} else {

					this.worldMgr.worldSource.saveCurScene( saveCallback );

				}
				this.gameData.saveDataPending = false;

				if ( showSaveIcon ) {
					SceneUtil.createSaveIcon( this._curScene );
				}

			} else {

				super.shellApi.track( "saveRealmLocation", null, null, LandGroup.CAMPAIGN );
				this.worldMgr.worldSource.saveSceneLocation( this.worldMgr.curRealm );

			} //

			this.gateway.saveResources( this.gameData.inventory.getResourceCount("poptanium"),
				this.gameData.inventory.getResourceCount("experience") );

		} //

		private function onLevelUp( newLevel:int, unlocked:Vector.<ObjectIconPair> ):void {
			this.saveCurrentData( false, false );
		} //

		/**
		 * used to update the backdrop in uneventful render frames and save the scene to the database at regular intervals.
		 */
		protected function gameUpdateLoop():void {

			if ( this.gameEntity.sleeping || player.sleeping ) {
				return;
			}

			var newTick:uint = getTimer();
			var delta:Number = newTick - this.lastTick;

			if ( (newTick - this.lastTick) < 15 ) {
				this._skyRenderer.redraw( this.gameData.clock, this.gameData.worldRandoms.terrainMap );	
			} else if ( ( newTick - this.lastGameSave ) > this.GAME_SAVE_RATE ) {

				this.lastGameSave = newTick;
				this.saveCurrentData();

			} //

			this.lastTick = newTick;

			this.updateDoors();

		} //

		private function onUIModeChanged( newMode:uint ):void {

			if ( newMode & LandEditMode.MINING ) {
				( this.getSystem( LightningTargetSystem ) as LightningTargetSystem ).unpauseSystem();
			} else {
				( this.getSystem( LightningTargetSystem ) as LightningTargetSystem ).pauseSystem();
			} //

			if ( newMode == LandEditMode.EDIT || newMode == LandEditMode.DECAL || newMode == LandEditMode.TEMPLATE ) {

				this.leftDoor.sleeping = this.rightDoor.sleeping = true;

			} else {

				( leftDoor.get( Display ) as Display ).visible = ( rightDoor.get( Display ) as Display ).visible = true;
				this.leftDoor.sleeping = this.rightDoor.sleeping = false;

			} //

		} // onUIModeChanged()

		/**
		 * only remaining purpose for this is to spawn poptanium and play the spawn sound.
		 * this should be handled somewhere else.
		 */
		protected function onTileBlasted( tile:LandTile, type:TileType, tileMap:TileMap ):void {

			if ( tileMap.name != "terrain" ) {
				return;
			}

			var mode:uint = this.uiGroup.uiMode;
			if ( mode == LandEditMode.MINING ) {

				if ( Math.random() < 0.1 ) {
					
					/**
					 * play some stupid spawn sound. need better organization for this obviously.
					 */
					( this.gameEntity.get( Audio ) as Audio ).playCurrentAction( "spawn_poptanium" );
					
					this.spawnPoptanium( -this.offscreenTilePadding + tileMap.tileSize*( tile.col + 0.5 ),
						tileMap.tileSize*( tile.row + 0.5 ), 10 );
					
				} //

			} else if ( mode == LandEditMode.SPECIAL ) {

				if ( Math.random() < 0.125 ) {

					/**
					 * play some stupid spawn sound. need better organization for this obviously.
					 */
					( this.gameEntity.get( Audio ) as Audio ).playCurrentAction( "spawn_poptanium" );
					
					this.spawnPoptanium( -this.offscreenTilePadding + tileMap.tileSize*( tile.col + 0.5 ),
						tileMap.tileSize*( tile.row + 0.5 ), 10 );

				} //

			} //

		} //

		/**
		 * spawn some poptanium at the given x,y location, for the given amount of poptanium.
		 */
		public function spawnPoptanium( x:Number, y:Number, amount:int ):void {

			var resource:CollectibleResource = this.gameData.inventory.getResource( "poptanium" ) as CollectibleResource;
			var spatial:Spatial = new Spatial( x, y );
			if ( amount > 10 ) {
				spatial.scale = 1 + ( amount - 10 )/100;
			} //

			var collectible:LandCollectible = new LandCollectible( resource, amount );

			if ( resource.useBitmap ) {

				LandUtils.makeBitmapCollectible( this, spatial, collectible, this._curScene.hitContainer );

			} else {

				this.shellApi.loadFile( this.sharedAssetURL + resource.swf,
					LandUtils.makeClipCollectible, this, spatial, collectible, this._curScene.hitContainer );				

			} //

		} //

		private function onEntityDied( e:Entity ):void {

			if ( e == this.player ) {

				// lose pane needs a callback to resawpn the player somewhere.
				this.player.sleeping = ( this.player.get( Sleep ) as Sleep ).sleeping = true;
				this.gameEntity.sleeping = true;

				var sp:Spatial = player.get( Spatial ) as Spatial;
				this.losePoptanium( sp.x, sp.y, 50 );

				// short delay before showing player-died dialog.
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( this.uiGroup.showLosePane, this.respawnDeadPlayer ), true ) );

				super.shellApi.track( "Died", null, null, LandGroup.CAMPAIGN );

			} else {

				// must be a monster... for now
				e.remove( LandMonster );
				e.remove( Life );
				CharUtils.freeze( e );

				TweenUtils.globalTo( this, e.get( Display ) as Display, 3.0, {alpha:0, onComplete:this.removeEntity, onCompleteParams:[e] } );

			} //

		} //

		/**
		 * Respawn a player after they've died and clicked "ok" on the lose pane.
		 */
		private function respawnDeadPlayer():void {

		//	this.resetPlayerLights();

			// check if the current scene data needs to be saved.
			this._sceneBuilder.cacheCurScene();
			this.worldMgr.worldSource.saveCurScene();

			this.onLeaveScene.dispatch();

			var life:Life = this.player.get( Life ) as Life;
			life.respawn( 100 );

			this.worldMgr.respawnPlayer( this.player );

			this._sceneBuilder.buildCurScene();

		} //

		/**
		 * Object collected. Right now just poptanium. In fact it's expected to be poptanium.
		 */
		private function onLandCollect( e:Entity, collectible:LandCollectible ):void {

			if ( collectible.type.type == "poptanium" ) {

				var sp:Spatial = e.get(Spatial);
				this.collectPoptanium( sp.x, sp.y, collectible.amount, false );

			} else {
				this._gameData.inventory.collectResource( collectible.type, collectible.amount );
			}

			// really doing this EVERY TIME you collect?
			//this.gateway.saveResourceType( collectible.type );
			// this won't work for multiple collection types.
			( this.gameEntity.get( Audio ) as Audio ).playCurrentAction( "collect" );

		} //

		public function onInventoryChanged( resource:ResourceType ):void {

			this.gateway.cacheResourceType( resource );
			//this.gateway.saveResourceType( resource );

		} //

		/**
		 * soundURL is the url of an optional sound to play with the displayed text.
		 */
		public function displayFadeText( x:Number, y:Number, string:String, color:uint=0xAA0000, soundURL:String="" ):void {

			var text:FadeText = new FadeText( this.uiGroup, string, color );
			text.x = x;
			text.y = y;
			this._curScene.hitContainer.addChild( text );

			if ( soundURL != "" ) {
				( this.gameEntity.get( Audio ) as Audio ).play( soundURL );
			}

		} //

		/**
		 * x,y is the location where the -poptanium message will appear in-scene.
		 * 
		 * loseAmt is a positive number - the amount of poptanium to lose.
		 *  ( there would have been confusion either way. )
		 */
		public function losePoptanium( x:Number, y:Number, loseAmt:int, soundURL:String="effects/crab_explode_01.mp3" ):void {

			var count:int = this.gameData.inventory.getResourceCount( "poptanium" );
			if ( count < loseAmt ) {
				loseAmt = count;
			}
			if ( loseAmt == 0 ) {
				// nothing left to lose.
				return;
			}

			var text:FadeText = new FadeText( this.uiGroup, "-"+loseAmt.toString(), 0xAA0000 );
			text.x = x;
			text.y = y;
			this._curScene.hitContainer.addChild( text );

			if ( soundURL != "" ) {
				( this.gameEntity.get( Audio ) as Audio ).play( soundURL );
			}

			this.gameData.inventory.addResource( "poptanium", -loseAmt );

		} //

		/**
		 * x,y is the location where the +poptanium message will appear in-scene.
		 * 
		 */
		public function collectPoptanium( x:Number, y:Number, amt:int, playSound:Boolean=true ):void {
			
			var text:FadeText = new FadeText( this.uiGroup, "+"+amt.toString() );
			text.x = x;
			text.y = y;
			this._curScene.hitContainer.addChild( text );

			if ( playSound ) {
				( this.gameEntity.get( Audio ) as Audio ).play( SoundManager.EFFECTS_PATH + "points_ping_01c.mp3" );
			}

			this.gameData.inventory.addResource( "poptanium", amt );
			
			//show helpful hint if first poptanium
			//if ( !this.shellApi.checkEvent( (this.landGroup.mainScene.events as LandsEvents).GOT_REALMS_HINT ) ) {
			if ( !this.shellApi.checkEvent( (this.curScene.events as LandsEvents).GOT_SOME_POPTANIUM ) ) {
				this.shellApi.completeEvent( (this.curScene.events as LandsEvents).GOT_SOME_POPTANIUM )
				this.uiGroup.showHelpfulHint(1);
			}

		} //

		/**
		 * called after the land has been generated.
		 */
		private function landGenerated():void {

			// and soon, it will be morning.
			this.tryRefreshScreen();

			// close enough...
			//this.onSceneChanged.dispatch();

			// set background ambient track for biome
			this.setBiomeAmbientSound();

			this.worldMgr.worldSource.visitScene( this.worldMgr.curRealm );
			super.shellApi.track( "SceneLoaded", this.loadBiome, this.worldMgr.curLoc.x, LandGroup.CAMPAIGN );

			if (PlatformUtils.inBrowser) {
				var eventTracker:ITrackingManager = shellApi.trackManager;
				if (eventTracker) {
					eventTracker.trackPageView(shellApi.island, loadBiome);
				}
			}

			// RLH: off-main wrapper impression on scene change
			if(this.shellApi.adManager)
			{
				if(super.shellApi.adManager is AdManagerBrowser)
				{
					(super.shellApi.adManager as AdManagerBrowser).handleWrapper( !this.worldMgr.isLandingScene());
				}
			}
		} //

		private function initDoors():void {

			var sharedTip:SharedToolTip = this.uiGroup.sharedTip;

			var si:SceneInteraction = new SceneInteraction();

			this.leftDoor = SimpleUtils.makeBoxEntity( 4, 0, 260, 200, this._curScene.hitContainer )
				.add( new Id("leftDoor"), Id );

			InteractionCreator.addToEntity( this.leftDoor, [ InteractionCreator.CLICK ] );
			this.addEntity( this.leftDoor );
			this.leftDoor.add( si, SceneInteraction );
			si.reached.add( this.doorReached );
			si.minTargetDelta.x = 50;

			sharedTip.addClipTip( ( this.leftDoor.get(Display) as Display ).displayObject as DisplayObjectContainer,
				ToolTipType.EXIT_LEFT );

			si = new SceneInteraction();
			this.rightDoor = SimpleUtils.makeBoxEntity( this.sceneBounds.right-4, 0, 260, 200, this._curScene.hitContainer )
				.add( new Id("rightDoor"), Id );

			InteractionCreator.addToEntity( this.rightDoor, [ InteractionCreator.CLICK ] );
			this.addEntity( this.rightDoor );
			this.rightDoor.add( si, SceneInteraction );
			si.reached.add( this.doorReached );
			si.minTargetDelta.x = 50;

			sharedTip.addClipTip( ( this.rightDoor.get(Display) as Display ).displayObject as DisplayObjectContainer,
				ToolTipType.EXIT_RIGHT );

			this.leftDoor.managedSleep = this.rightDoor.managedSleep = true;

		} // initDoors()

		/**
		 * match the door spatials to the player's y so they are always available for clicking.
		 */
		private function updateDoors():void {

			var ps:Spatial = this.player.get( Spatial ) as Spatial;

			if ( this.uiGroup.getEditContext().curEditMode == LandEditMode.MINING ) {

				var hilite:LandHiliteComponent = this.uiGroup.getHiliteComponent();

				// this is all a messy check to make sure you can still mine without triggering the left/right doors.
				if ( !hilite.hiliteBox.visible ) {
					( this.leftDoor.get(Spatial) as Spatial ).y = ( this.rightDoor.get(Spatial) as Spatial ).y = ps.y;
				}//

				( this.leftDoor.get(Display) as Display ).visible =
					( this.rightDoor.get(Display) as Display ).visible = !hilite.hiliteBox.visible;

			} else {

				( this.leftDoor.get(Spatial) as Spatial ).y = ( this.rightDoor.get(Spatial) as Spatial ).y = ps.y;

			} //

		} //

		/**
		 * player reached left/right door to next land tile scene.
		 */
		private function doorReached( interactor:Entity, interactedWith:Entity ):void {

			if ( interactedWith.sleeping || this.uiGroup.isPainting() ) {
				// first test has to do this because sceneInteractions are broken.
				// need to cancel the sceneInteraction if they started painting again.
				return;
			}

			this.leftDoor.sleeping = this.rightDoor.sleeping = true;

			// check if the current scene data needs to be saved.
			this._sceneBuilder.cacheCurScene( true );
			this.worldMgr.worldSource.saveCurScene();
			this.gameData.saveDataPending = false;

			// AD ROOM STUFF
			var hasAd:Boolean = AdManagerBrowser(this.shellApi.adManager).hasMainStreetAd();
			if ((hasAd) && (this.worldMgr.shouldShowAdScene(interactedWith == this.rightDoor)))
			{
				this.visitAdScene( interactedWith == rightDoor );
				return;
			}

			// reposition the player above all the land. do this AFTER the scene changes?
			var sp:Spatial = this.player.get( Spatial ) as Spatial;
			if ( interactedWith == this.leftDoor ) {

				this.worldMgr.moveLeft();
				this.worldMgr.savePlayerPosition( this.sceneBounds.right - 30, sp.y );

			} else {

				// right door.
				this.worldMgr.moveRight();
				this.worldMgr.savePlayerPosition( 30, sp.y );

			} //

			this.doSceneSwitch();

		} //

		/**
		 * leave the current land scene and go to an advertisement scene.
		 * before this happens, information about the land state must be cached
		 * so nothing gets lost. animal followers?
		 */
		private function visitAdScene( rightDoor:Boolean ):void {

			// stop a lot of stuff such as the save-data loop right away.
			this.gameEntity.sleeping = true;

			this.worldMgr.cacheLandState( this, rightDoor );

			if ( rightDoor ) {
				this.shellApi.loadScene( AdMixed1, 40, 1030, "right" );
			} else {
				this.shellApi.loadScene( AdMixed1, 1560, 1030, "left" );
			} //

		} //

		protected function initTileLayers():void {

			// Need to get the scene's bitmap so hits can be drawn to it dynamically.
			var collisionGroup:CollisionGroup = this._curScene.getGroupById( "collisionGroup" ) as CollisionGroup;
			var hitBitmap:BitmapData = collisionGroup.hitBitmapData;
			
			if ( collisionGroup.hitBitmapData == null ) {
				trace( "ERROR: missing hit bitmap." );
				return;
			}
			
			var bgEntity:Entity = this._curScene.getEntityById( "background" );
			var display:Display = bgEntity.get( Display ) as Display;
			
			// put a shadow on the background.
			var backgroundClip:DisplayObjectContainer = display.displayObject;
			
			var bounds:Rectangle = this._curScene.sceneData.cameraLimits;
			
			// BITMAP THE BACKGROUND DISPLAY. THIS MUST BE DONE MANUALLY BECAUSE OF NEW QUALITY SETTINGS.
			var bmd:BitmapData = new BitmapData( bounds.width, bounds.height, true, 0 );
			bmd.draw( backgroundClip );
			
			var bgSprite:Sprite = new Sprite();
			bgSprite.mouseChildren = false;
			bgSprite.mouseEnabled = false;
			bgSprite.transform.colorTransform = new ColorTransform( 0.65, 0.65, 0.65 );
			bgSprite.addChild( new Bitmap( bmd ) );
			
			display.displayObject = bgSprite;
			display.setContainer( backgroundClip.parent, backgroundClip.parent.getChildIndex( backgroundClip ) );
			backgroundClip.parent.removeChild( backgroundClip );
			

			var bgContext:RenderContext = new RenderContext( bmd );
			bgContext.init( -this.offscreenTilePadding, 0 );
			
			var layer:TileLayer = this.gameData.bgLayer = new TileLayer( "background", bgContext );
			
			// quick fix to give the tile layers different features.
			// the value must now STAY 3, wherever it's defined, since saved user games depend on this value
			// to look the same when generating from the same seed.
			layer.randOffset = 3;
			
			// FOREGROUND LAYER STUFF
			bmd = new BitmapData( bounds.width, bounds.height, true, 0 );
			
			var fgBitmap:Bitmap = new Bitmap( bmd );
			fgBitmap.name = "foreground";

			var fgContext:RenderContext = new RenderContext( bmd, hitBitmap, true );
			// clone some of the basic render objects for re-use.
			fgContext.clone( bgContext );
			
			this._curScene.hitContainer.addChild( fgBitmap );

			this.gameData.fgLayer = layer = new TileLayer( "foreground", fgContext );
			this.gameData.tileHits = new TileBitmapHits( hitBitmap, 0.5, this.offscreenTilePadding );

		} //

		/**
		 * bitmap the scene for a scene snapshot.
		 */
		public function getSceneBitmap( imgWidth:int, imgHeight:int ):BitmapData {

			var hideEditGrid:Boolean = this.uiGroup.hasEditGrid();
			if ( hideEditGrid ) {
				this.uiGroup.hideEditGrid();
			}

			var weather:RealmsWeatherSystem = this.getSystem( RealmsWeatherSystem ) as RealmsWeatherSystem;
			weather.hideWeather();

			var bm:BitmapData = new BitmapData( imgWidth, imgHeight, false, 0xD4FFFF );
			
			var mat:Matrix = new Matrix( 1, 0, 0, 1, -_curScene.hitContainer.x, -_curScene.hitContainer.y );
			mat.scale(imgWidth/this.sceneBounds.width, imgHeight/this.sceneBounds.height );

			var bdEntity:Entity = this._curScene.getEntityById( "backdrop" );
			if ( bdEntity ) {
					
				var display:Display = bdEntity.get( Display ) as Display;
				if ( display ) {

					var clip:DisplayObject = display.displayObject as DisplayObject;
					clip.width = this.sceneBounds.width;
					clip.height = this.sceneBounds.height;
					clip.x = this._curScene.hitContainer.x;
					clip.y = this._curScene.hitContainer.y;

				} //

			} //

			bm.draw( _curScene.container, mat );

			if ( hideEditGrid ) {
				this.uiGroup.showEditGrid();
			}
			weather.showWeather();

			return bm;

		} //

		/**
		 * create a snapshot of the land that the user can save to disk.
		 */
		public function snapshot():void {

			var bm:BitmapData = this.getSceneBitmap( this.sceneBounds.width, this.sceneBounds.height );
			var data:ByteArray = bm.encode( bm.rect,  new flash.display.JPEGEncoderOptions() );

			var save:SaveAndLoadFile = new SaveAndLoadFile();
			save.save( data, "land.jpg" );

			bm.dispose();

		} //

		private function initBackdrop():void {

			var bdEntity:Entity = this._curScene.getEntityById( "backdrop" );
			if ( bdEntity == null ) {
				return;
			}
			var display:Display = bdEntity.get( Display ) as Display;
			if ( !display ) {
				return;
			} //

			var bm:BitmapData = display.bitmapWrapper.bitmap.bitmapData;
			this._skyRenderer = new SkyRenderer( bm );

		} //

		/**
		 */
		public function saveDataToDisk():void {

			// save current scene first so it gets included in the world.
			this._sceneBuilder.cacheCurScene( true );

			 // save the player's position in the current biome.
			var pSpatial:Spatial = this.player.get( Spatial ) as Spatial;
			this.worldMgr.savePlayerPosition( pSpatial.x, pSpatial.y );

			var xmlData:XML = this.worldMgr.saveLocalWorld( this._gameData, this.onSaveComplete );

		} //

		/**
		 * this function shouldn't be needed anymore now that the new share functionality has been added.
		 */
		public function shareWorld():void {

			// check share limit
			var profile:ProfileData = this.shellApi.profileManager.active;
			var obj:Object = profile.getUserField( "landShareInfo" );

			if ( obj != null ) {

				if ( obj.shareCount >= 4 ) {

					// check if its been over 24 hours.
					var curTime:Number = new Date().getTime();
					if ( (curTime - obj.shareTime) > 24*3600*1000 ) {

						// it's been long enough. reset the share counts.
						obj.shareTime = curTime;
						obj.shareCount = 0;

					} else {

						// hasn't been long enough since 5 shares.
						//this.uiGroup.showDialog( "You can only share 5 worlds per day. Be sure to save your world and then try again tomorrow." );
						return;

					} //

				} //

			} else {

				obj = new Object();
				obj.shareCount = 0;
				obj.shareTime = new Date().getTime();

			} //

			obj.shareCount++;
			profile.setUserField( "landShareInfo", obj );

			var hilite:LandHiliteComponent = this.uiGroup.getHiliteComponent();
			var vis:Boolean = hilite.tileGrid.visible;		// save the grid visibility for after the share.

			hilite.tileGrid.visible = false;

			// save current scene first so it gets included in the world. --> don't need to since this happens from popup.
			//this.sceneBuilder.cacheCurScene( true );
			//this.worldMgr.worldSource.saveCurScene( this.worldMgr );

			var xmlData:XML = this.worldMgr.getWorldEncoding();
			var bm:BitmapData = this.getSceneBitmap( this.SNAPSHOT_SIZE, this.SNAPSHOT_SIZE );

			this.gateway.sendOrwellData( bm.encode( bm.rect,  new flash.display.JPEGEncoderOptions() ),
							xmlData );

			bm.dispose();

			hilite.tileGrid.visible = vis;

		} //

		private function onSaveComplete( errType:String ):void {

			if ( errType != null && errType != "" && errType != Event.CANCEL ) {

				this.uiGroup.showDialog( "Sorry, there was an error saving your world data." );

			} //

		} //

		public function loadWorldFromDisk():void {

			this.worldMgr.loadLocalWorld( this.onGalaxyLoaded );

		} //

		/**
		 * this function is called after new galaxy data has been loaded from a harddrive, server, or database.
		 *
		 * NOTE: unfortunately there is now a second galaxy-loading path from the WorldManagementPopup that does NOT call this function.
		 * these two paths need to be integrated somehow to reduce future confusion and inconsistencies. Probably in the WorldManager.
		 */
		private function onGalaxyLoaded( error:String=null ):void {

			if ( error != null && error != "" ) {

				if ( error == Event.CANCEL ) {		// user cancelled.
					return;
				}

				this.uiGroup.showDialog( "Oops. There was an error loading your world." );

				if ( AppConfig.debug ) {
					this.worldMgr.createNewLocalWorld( this._loadBiome );
				} //

			} //

			if ( this.worldMgr.galaxy.isPublicGalaxy ) {
				this.uiGroup.setPublicMode();
			} else {
				this.uiGroup.setPrivateMode();
			} //

			//this.shellApi.logWWW( "realms have loaded" );
			this.visitCurRealm();

		} //

		/**
		 * call when the current scene has changed but the biome HAS NOT Changed.
		 */
		public function doSceneSwitch( fade:Boolean=true ):void {

			if ( fade ) {
				this.gameEntity.sleeping = true;
				this._curScene.screenEffects.fadeToBlack( 0.5, this.continueBuild );
			} else {
				this.continueBuild();
			}

			// temporarily disable character control.
			CharacterMotionControl(this.player.get(CharacterMotionControl)).allowAutoTarget = false;

		} //

		private function continueBuild():void {

			this.onLeaveScene.dispatch();
			this._sceneBuilder.buildCurScene();

		} //

		public function changeCurRealm( newRealm:LandRealmData ):void {

			// make the screen black until the next realm loads.
			//this.curScene.screenEffects.fadeToBlack( 0.1 );
			this.uiGroup.zoomBase();

			this.worldMgr.visitRealm( newRealm );
			visitCurRealm();

			// play a teleporty sound
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + TELEPORT_SOUND, 1, false, SoundModifier.EFFECTS );

		} //

		public function visitCurRealm():void {

			var newBiome:String = this.worldMgr.getCurBiome();

			// if the current scene isn't ready yet, then no biome data has been loaded at all.
			// the game can't start until the biome assets have loaded.
			if ( !this._curScene.isReady ) {

				this.loadBiome = newBiome;
				this.loadCurBiome();

			} else if ( newBiome == this._loadBiome ) {
				
				// Get the random seed from the newly loaded world and use it to recreate the random maps.
				// if the biome changed, this will be done after the assets load.
				this._gameData.worldRandoms.seed = this.worldMgr.curRealmSeed;
				this.gameData.worldRandoms.refreshMaps();
				if ( this._skyRenderer ) {
					this._skyRenderer.init( this.gameData.worldRandoms.randMap );
				}

				this.worldMgr.resetPlayerPosition( this.player );				
			//	this.resetPlayerLights();

				// change the current scene?
				this.doSceneSwitch( false );

			} else {

				this.changeBiome( newBiome );

			} //

		} //

		/**
		 * 
		 * saveCurScene means to save the current scene in the previous biome. always true unless
		 * the biome changed because a saved game was loaded.
		 */
		public function changeBiome( newBiome:String ):void {

			this._loadBiome = newBiome;

			this.clearBiome();
			this.loadCurBiome();

		} //

		/**
		 * made public just so the sceneBuilder can hook back to the function. fix later? :P
		 */
		public function zoneEntered( zoneId:String, entityId:String ):void {

			if ( entityId != "player" ) {
				return;
			} //

			var zone:Entity = super.parent.getEntityById( zoneId );
			this.shellApi.triggerEvent( (zone.get(TriggerEvent) as TriggerEvent ).event, false );

		} //

		/**
		 * pause a game during loading and unloading of assets and levels, not just for scene change.
		 */
		public function pauseGame():void {

			//this.pause( false ); // <-- this breaks things
			this.gameEntity.sleeping = true;
			( this.player.get( Display ) as Display ).isStatic = true;
			( this.player.get( Sleep ) as Sleep ).sleeping = true;
			//this.player.sleeping = true;

		} //

		public function unpauseGame():void {

			this.gameEntity.sleeping = false;
			( this.player.get( Display ) as Display ).isStatic = false;
			( this.player.get( Sleep ) as Sleep ).sleeping  = false;

		} //

		public function setSceneGravity( g:Number ):void {

			MotionUtils.GRAVITY = g;

			var objList:NodeList = this.systemManager.getNodeList( CharacterMotionControlNode );

			for( var node:CharacterMotionControlNode = objList.head; node; node = node.next ) {
				node.charMotionControl.gravity = g;
			} //

		} //

		/**
		 * Create an entity for the LandGame itself, to facilitate data passing
		 * and dynamic object 'stuff'.
		 */
		private function createGameEntity():void {

			var gameData:LandGameData = this._gameData = new LandGameData();
			this.worldMgr.clock = gameData.clock;			// temp, i think.

			gameData.mapOffsetX = -this.offscreenTilePadding;
			gameData.progress = new LandProgress( this );
			gameData.worldRandoms = new WorldRandoms( this._worldMgr.galaxy );
			gameData.worldMgr = this.worldMgr;

			var grp:AudioGroup = this.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;

			var e:Entity = this._gameEntity = new Entity( "landGameEntity" )
				.add( new LandGameComponent( gameData ), LandGameComponent )
				.add( new TimedTileList(), TimedTileList )
				.add( new SpawnerComponent(), SpawnerComponent );

			// probably link this from the collectible xml in the future. blah blah blah.
			grp.addAudioToEntity( e, "gameAudio" );

			// lightning strike stuff.
			var target:LightningTarget = new LightningTarget( this.shellApi.backgroundContainer );
			target.enabled = false;
			this.gameEntity.add( target, LightningTarget );
			
			LandUtils.addLightningStrike( this.gameEntity, this.player, this._curScene.hitContainer );


			this.addEntity( e );

		} //

		/**
		 * resets all the groups and data when the current biome has changed.
		 *  destroy tileSets and reload the curLandFile (xml file)
		 */
		public function clearBiome():void {

			this.pauseGame();

			// clear the edit group.
			this.uiGroup.reset();

			// clear all the tilesets in the tileLayers
			this.gameData.fgLayer.reset();
			this.gameData.bgLayer.reset();

			/*for each ( var tlayer:TileLayer in this.gameData.tileLayers ) {
				tlayer.reset();
			} //*/

			this.onLeaveScene.dispatch();
			this.gameData.tileMaps = new Dictionary();

		} //

		/*private function resetPlayerLights():void {

			var light:Light = player.get( Light ) as Light;
			if ( light == null ) {
				return;
			}
			light.lightAlpha = 0;
			light.radius = 0;

			var lightOverlayEntity:Entity = this.parent.getEntityById( "lightOverlay" );
			if ( lightOverlayEntity == null ) {
				return;
			}
			( lightOverlayEntity.get( LightOverlay ) as LightOverlay ).darkAlpha = 0;

		} //*/

		/**
		 * try to redraw the whole screen, but first check that all the props used in the scene
		 * have their assets loaded. If all assets are known to be loaded, use refreshScreen() instead.
		 */
		public function tryRefreshScreen():void {

			// checks if any decals need to be preloaded and if so, waits for a callback to refresh the screen.
			if ( this.assetLoader.loadMapDecals( this.gameData.tileMaps, this.refreshScreen ) ) {
				return;
			}
			this.refreshScreen();

		} //

		/**
		 * Redraws the screen without any checks to make sure props have been loaded.
		 * Call when all props in the map are known to be up to date.
		 */
		private function refreshScreen():void {

			/*for each ( var layer:TileLayer  in this.gameData.tileLayers ) {
				layer.render();
			} //*/
			this.gameData.fgLayer.render();
			this.gameData.bgLayer.render();

			this._skyRenderer.redraw( this.gameData.clock, this.gameData.worldRandoms.terrainMap );

			if ( !this.isReady ) {
				// callback to main scene to lift the poptropica loading screen.
				// currently for some reason this has to happen BEFORE buildCurScene.
			//	this.resetPlayerLights();
				super.groupReady();
			}
			this.unpauseGame();

			this.leftDoor.sleeping = this.rightDoor.sleeping = false;

			this.worldMgr.resetPlayerPosition( this.player );
			//( this.getSystem( CameraSystem ) as CameraSystem ).jumpToTarget

			this._curScene.screenEffects.fadeFromBlack( 0.5 );

		} //

		public function getUIGroup():LandUIGroup {
			return this.uiGroup;
		}

		override public function destroy():void {

			//this.shellApi.logWWW( "LandGroup Destroy" );

			this.systemManager.updateComplete.remove( this.gameUpdateLoop );

			if ( this.player != null && this._worldMgr.worldSource != null ) {
				this.saveCurrentData( false, false );
			}

			MotionUtils.GRAVITY = this.DEFAULT_GRAVITY;

			this.gameData.destroy();

			this._gameData.progress.destroy();

			this.onBiomeChanged.removeAll();
			this.onLeaveScene.removeAll();

			// all alone with the memory.
			super.destroy();

		} //

		public function getPoptanium( amt:int ):void {

			this._gameData.inventory.addResource( "poptanium", amt );

		} //

		public function getExperience( amt:int ):void {
			
			this._gameData.inventory.addResource( "experience", amt );
			this._gameData.progress.recalculateAndLevelUp( this._gameData.inventory.getResourceCount("experience" ) );

		}

		/**
		 * displays the hammer editing icon that brings up the tile palette.
		 */
		public function enableEditing():void {

			this.uiGroup.enableEditing();

		} //
		
		/**
		 * Sets the background ambient track for current biome
		 */
		private var biomePlaying:String = ''; // relocate - here just for testing
		public function setBiomeAmbientSound():void {
			
			if(biomePlaying != this.worldMgr.getCurBiome()){
				AudioUtils.stop( this, null, SceneSound.SCENE_SOUND );
				var myUrl:String = "realms_"+this.worldMgr.getCurBiome()+".mp3";

				AudioUtils.play( this, SoundManager.AMBIENT_PATH + myUrl, 1, true, SoundModifier.MUSIC, SceneSound.SCENE_SOUND );
			}

			biomePlaying = this.worldMgr.getCurBiome();

		} //
		
		public function getPlayer():Entity {
			return this.player;
		}

		public function get sceneBounds():Rectangle		{ return this._curScene.sceneData.cameraLimits; }

		public function get sceneDataURL():String		{ return super.shellApi.dataPrefix + this._curScene.groupPrefix; }
		/**
		 * prefix location for template.xml data.
		 */
		public function get templateDataURL():String 	{ return this.islandDataURL + "templates/"; }
		public function get islandDataURL():String		{ return super.shellApi.dataPrefix + "scenes/lands/"; }
		public function get pluginAssetURL():String		{ return super.shellApi.assetPrefix + "scenes/lands/plugins/"; }

		//public function get islandAssetURL():String		{ return super.shellApi.assetPrefix + "scenes/lands/"; }
		public function get sharedAssetURL():String			{ return super.shellApi.assetPrefix + "scenes/lands/shared/"; }

	} // class

} // package
