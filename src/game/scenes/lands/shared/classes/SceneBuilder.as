package game.scenes.lands.shared.classes {
	
	/**
	 * This class builds a land scene from the loaded scene data, or generates a random one
	 * if no scene data exists.
	 * 
	 * It also creates and removes objects, items and monsters associated with a scene.
	 */
	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.Node;
	import ash.core.NodeList;
	
	import engine.components.Display;
	
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Zone;
	import game.nodes.hit.ZoneHitNode;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.components.TriggerEvent;
	import game.scenes.lands.shared.monsters.MonsterBuilder;
	import game.scenes.lands.shared.monsters.systems.MonsterFollowSystem;
	import game.scenes.lands.shared.nodes.ItemNode;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.generation.generators.MapGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.MonsterGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.TemplateGenerator;
	import game.scenes.lands.shared.tileLib.templates.TemplateRegister;
	import game.scenes.lands.shared.util.LandUtils;
	import game.scenes.lands.shared.world.LandSceneData;
	import game.scenes.lands.shared.world.LandWorldManager;
	import game.systems.SystemPriorities;
	import game.systems.hit.ZoneHitSystem;
	
	public class SceneBuilder {
		
		private var landData:LandGameData;
		//private var baseScene:PlatformerGameScene;
		
		private var landGroup:LandGroup;
		
		private var _monsterBuilder:MonsterBuilder;
		public function get monsterBuilder():MonsterBuilder {
			return this._monsterBuilder;
		} //

		private var monsterGenerator:MonsterGenerator;
		
		/**
		 * called after the current scene has been constructed.
		 * onSceneBuilt() no params.
		 */
		private var onSceneBuilt:Function;

		/**
		 * used to generate templates from the server in new scenes.
		 */
		private var templateGenerator:TemplateGenerator;

		/**
		 * onBuild() callback when the scene is done building - no params.
		 */
		public function SceneBuilder( landGroup:LandGroup, onBuild:Function, monsterBuilder:MonsterBuilder, templaterRegister:TemplateRegister ) {
			
			this.landGroup = landGroup;
			this.landData = landGroup.gameData;

			this.onSceneBuilt = onBuild;

			this._monsterBuilder = monsterBuilder;
			this.templateGenerator = new TemplateGenerator( this.landGroup, templaterRegister, this.onGenerateTemplates );
			
			monsterBuilder.onMonstersLoaded = this.onMonstersLoaded;
			this.monsterGenerator = new MonsterGenerator( this.landGroup, monsterBuilder );
			
		} //

		/**
		 * caches the current scene to the curSceneData scene xml.
		 * called before leaving a scene to store all the tile data, and whichever monsters need to be saved.
		 * 
		 * followers are stored if the cache is meant to be a PERMA-SAVING cache to be restored later.
		 * otherwise the animals following the player are kept alive in memory and not written to the world data.
		 */
		public function cacheCurScene( changingScene:Boolean=false ):void {

			if ( !this.landData.sceneMustSave ) {
				// scene xml is up to date.
				return;
			}

			if ( changingScene ) {
				( this.landGroup.getSystem( MonsterFollowSystem ) as MonsterFollowSystem ).markFollowerMonsters();
			} //

			// have to store the cur scene this way first because the sceneData is null until the first save.
			this.landGroup.worldMgr.cacheCurScene( this.landGroup );
			var sceneData:LandSceneData = this.landGroup.worldMgr.curSceneData;

			// storing monsters.

			// first delete existing monster data (though if we use npcs in the future, need to preserve those. )
			var sceneXML:XML = sceneData.xmlData;
			delete sceneXML.npc;

			//var activeXML:XML = new XML();

			this._monsterBuilder.saveMonsterXML( sceneXML );

		} //

		/**
		 * call whenever the user moves to a new land scene location.
		 * 
		 * this should fire AFTER the world location has changed - and the current biome should have all its assets loaded.
		 * because this function might take time loading new resources, game is paused until it's complete.
		 */
		public function buildCurScene():void {
			
			this.landGroup.pauseGame();

			this.landData.preventSceneSave = false;
			this.landData.sceneMustSave = false;
			this.removeSceneObjects();

			var worldMgr:LandWorldManager = this.landGroup.worldMgr;
			var sceneData:LandSceneData = worldMgr.curSceneData;

			// set random maps for the new world location.
			this.landData.worldRandoms.refreshMaps();

			if ( sceneData == null && worldMgr.curRealm.hasSavedData( worldMgr.curLoc.x ) ) {

				if ( worldMgr.tryLoadCurScene( worldMgr.curLoc.x, worldMgr.curLoc.y, this.sceneDataReady ) ) {
					// scene data is loading from a world-source.
					return;
				} //

			} //
			
			// place all monsters currently following the player.
			( this.landGroup.getSystem( MonsterFollowSystem ) as MonsterFollowSystem ).placeFollowersInScene();
			
			if ( sceneData && sceneData.hasTileData() ) {

				//this.landGroup.shellApi.logWWW( "FOUND SCENE IN MEMORY: " + worldMgr.curLoc.x );

				this.makeSceneObjects( sceneData.xmlData );

				// SMALL CHANCE TO GENERATE A MONSTER WHEN REVISITING A SCENE.
				// REBUILD SCENE FROM SCENE DATA IN THE WORLD.
				sceneData.fillSceneMaps( this.landData.tileMaps );

				if ( this.monsterGenerator.makeMonsters( this.landData, 2, 0.02 ) ) {
					this.landData.sceneMustSave = true;
				}

				this.onSceneBuilt();

			} else {

				this.generateLand();
				
			} // end-if.
			
		} //()
		
		/**
		 * callback for when the scene data is available from the world source.
		 * if this is a local file, the scene data will always be ready instantly, but if the source
		 * is on the server, the game will pause waiting for data.
		 */
		private function sceneDataReady( sceneData:LandSceneData, success:Boolean ):void {

			if ( !success ) {

				// data should have existed on the server but didn't load.
				// display a warning message and make sure the scene doesn't save.

				// don't allow any saves to overwrite what's on the server.
				this.landData.preventSceneSave = true;
				this.landGroup.getUIGroup().showDialog(
					"There was an error loading your scene. Changes made to this scene will not be saved." );

			} //

			// place all monsters currently following the player.
			( this.landGroup.getSystem( MonsterFollowSystem ) as MonsterFollowSystem ).placeFollowersInScene();
			
			if ( sceneData.hasTileData() ) {

				//this.landGroup.shellApi.logWWW( "SCENE LOADED FROM SERVER" );

				// if the scene late-loaded, we know for a fact it was a remote-scene, hence the 'true' here
				this.makeSceneObjects( sceneData.xmlData );
				
				// REBUILD SCENE FROM SCENE DATA IN THE WORLD.
				sceneData.fillSceneMaps( this.landData.tileMaps );
				this.onSceneBuilt();
				
			} else {
				
				this.landGroup.pauseGame();
				this.generateLand();
				
			} // end-if.
			
		} //
		
		/**
		 * because the templates need to load before they can be placed on screen, and the trees
		 * need to generate AFTER the templates for visual reasons, this function is called
		 * several times with a different pass each time.
		 * currently only two passes are used. need a better loop for triple-quad pass etc.
		 */
		public function generateLand( pass:int = 1 ):void {
			
			var genList:Vector.<MapGenerator>;
			var generator:MapGenerator;
			var len:int;
			
			/**
			 * tricky problem. some generators need to run in a specific order. each generator can specify the 'pass'
			 * when it will run. currently only two passes.
			 */
			
			for each ( var tmap:TileMap in this.landData.tileMaps ) {
				
				genList = tmap.generators;
				
				if ( pass == 1 ) {
					// burned out ends of smokey days
					tmap.clearAllTiles();
				}
				
				if ( genList != null ) {
					
					len = genList.length;
					for( var i:int = 0; i < len; i++ ) {
						
						generator = tmap.generators[i];
						if ( generator.pass == pass ) {
							generator.generate( this.landData );
						}
						
					} //
				}
				
			} // end for-loop.
			
			if ( pass == 1 ) {
				
				// try to generate some templates.
				this.templateGenerator.generate( this.landData );
				
			} else {
				
				if ( this.monsterGenerator.makeMonsters( this.landData ) ) {
					this.landData.sceneMustSave = true;
				}
				
				this.onSceneBuilt();
				
			} // end-if
			
		} //
		
		/**
		 * land scenes can have items, zones, creatures, associated with them.
		 * this data is stored in the scene xml and initialized when you change land scenes.
		 * 
		 * eventually put this in a sub-parser class, why not.
		 */
		public function makeSceneObjects( sceneXML:XML ):void {
			
			// capabilities only scene files should have access to, because they could give items, set events, etc.
			this.loadSceneItems( sceneXML.items[0] );
			this.createSceneZones( sceneXML.zone );
			
			this._monsterBuilder.loadSceneMonsters( sceneXML.npc );
			
		} //
		
		/**
		 * monsters can (currently) be loaded in two ways:
		 * either from the monsters being generated
		 * or the monsters being loaded from existing scene data.
		 */
		private function onMonstersLoaded( monsterList:Vector.<Entity> ):void {

			var mainScene:PlatformerGameScene = this.landGroup.curScene;

			var parent:MovieClip = mainScene.hitContainer as MovieClip;
			
			parent.setChildIndex( ( mainScene.player.get(Display) as Display ).displayObject, 0 );
			
			for( var i:int = monsterList.length-1; i >= 0; i-- ) {
				
				parent.setChildIndex( ( monsterList[i].get(Display) as Display ).displayObject, 0 );
				
			} //
			
		} //
		
		/**
		 * template generator finished. didGenerate indicates if templates were generated
		 * (and hence the scene must be saved to ensure fidelity when templates change)
		 */
		private function onGenerateTemplates( didGenerate:Boolean ):void {
			
			this.landData.sceneMustSave = didGenerate;
			if ( didGenerate ) {
				this.landGroup.shellApi.logWWW( "SceneBuilder: Scene must save (Template)" );
			}
			// resume land generation with second pass.
			this.generateLand( 2 );
			
		} //
		
		private function createSceneZones( zoneList:XMLList ):void {
			
			var zoneXML:XML;
			var len:int = zoneList.length();

			var mainScene:PlatformerGameScene = this.landGroup.curScene;

			// the zone hit system will probably be null since removeSceneObjects() removes the system.
			if ( len > 0 ) {

				mainScene.addSystem( new ZoneHitSystem(), SystemPriorities.resolveCollisions );
				mainScene.getEntityById("player").add( new ZoneCollider(), ZoneCollider );

			} //
			
			var e:Entity;
			var zone:Zone;
			for( var i:int = len-1; i >= 0; i-- ) {
				
				zoneXML = zoneList[i];
				e = LandUtils.makeZone( mainScene, mainScene.hitContainer, zoneXML.@id, zoneXML.@x, zoneXML.@y, zoneXML.@w, zoneXML.@h );

				if ( zoneXML.hasOwnProperty( "@evt" ) ) {
					
					e.add( new TriggerEvent( zoneXML.@evt ), TriggerEvent );
					zone = e.get( Zone );
					zone.entered.add( this.landGroup.zoneEntered );
					
				} //
				
			} // for-loop.
			
		} //
		
		/**
		 * eventually should only remove items based on what's found in the current scene xml data.
		 * this could remove objects other than ones defined by lands - though its unlikely to happen.
		 */
		public function removeSceneObjects():void {
			
			// Remove all items
			var nodeList:NodeList = this.landGroup.systemManager.getNodeList( ItemNode );
			for( var n:Node = nodeList.head; n; n = n.next ) {
				this.landGroup.removeEntity( n.entity, true );
			} //
			
			nodeList = this.landGroup.systemManager.getNodeList( ZoneHitNode );
			for( n = nodeList.head; n; n = n.next ) {
				this.landGroup.removeEntity( n.entity, true );
			} //
			
			this.landGroup.parent.removeSystemByClass( ZoneHitSystem, false );
			
		} // removeSceneItems()
		
		/**
		 * when a scene loads, the items for that scene might change.
		 */
		private function loadSceneItems( itemsXML:XML ):void {
			
			if ( itemsXML == null ) {
				return;
			}
			
			var itemGroup:ItemGroup = this.landGroup.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.addItems( itemsXML, null );
			
		} //

		/**
		 * the template generator uses the 'largest' tile map to figure out where to place templates.
		 * templates must be aligned to boundaries of the largest tile so different tile maps remain
		 * in the same locations relative to each other.
		 */
		public function setBaseMap( terrainMap:TileMap ):void {

			this.templateGenerator.setMap( terrainMap );
			this.monsterGenerator.setMap( terrainMap );

		} //

	} // class
	
} // package