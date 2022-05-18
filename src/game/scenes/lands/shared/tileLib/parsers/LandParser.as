package game.scenes.lands.shared.tileLib.parsers {

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.renderers.BuildingOutliner;
	import game.scenes.lands.shared.tileLib.renderers.BuildingRenderer;
	import game.scenes.lands.shared.tileLib.renderers.DecalHitRenderer;
	import game.scenes.lands.shared.tileLib.renderers.DecalRenderer;
	import game.scenes.lands.shared.tileLib.renderers.MapRenderer;
	import game.scenes.lands.shared.tileLib.renderers.TerrainOutliner;
	import game.scenes.lands.shared.tileLib.renderers.TerrainRenderer;
	import game.scenes.lands.shared.tileLib.renderers.TreeRenderer;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.world.BiomeWeatherType;
	import game.scenes.lands.shared.world.RealmBiomeData;

	public class LandParser {

		private var tileSets:Dictionary;
		private var tileMaps:Dictionary;

		/**
		 * bounary of the visual area. Tile maps will go slightly off screen in each direction.
		 */
		private var screenBounds:Rectangle;

		private var gameData:LandGameData;

		private var generatorParser:GeneratorParser;

		/**
		 * need the scene bounds to create tileMaps of the correct size.
		 * randoms is needed to initialize the tileSet randoms. need a better way to do this.
		 */
		public function LandParser( tileBounds:Rectangle, gameData:LandGameData ) {

			this.screenBounds = tileBounds;

			this.gameData = gameData;
			this.tileSets = gameData.tileSets;
			this.tileMaps = gameData.tileMaps;

		} // LandParser()

		/**
		 * xml is the root xml element of the loaded biome xml file.
		 */
		public function parseBiome( xml:XML, biomeName:String ):void {

			var tileParser:TileParser = new TileParser( this.gameData );
			tileParser.parseBiomeSets( xml, biomeName );

			this.generatorParser = new GeneratorParser();

			this.parseSky( xml.child( "sky" )[0] );

			// TODO: old version. no need for a dictionary of layers because a mid-ground is unlikely to be added.
			var tileLayers:Dictionary = new Dictionary();
			tileLayers["foreground"] = this.gameData.fgLayer;
			tileLayers["background"] = this.gameData.bgLayer;

			this.parseTileLayers( xml.child( "tileLayer" ), tileLayers );

			if ( xml.hasOwnProperty( "@gravity" ) ) {
				this.gameData.biomeData.gravity = xml.@gravity;
			} else {
				this.gameData.biomeData.gravity = NaN;
			}

			this.parseWeather( xml.child( "weather" )[0] );

		} // parse()

		public function parseWeather( xml:XML ):void {

			var childs:XMLList = xml.children();
			var node:XML;

			var biomeData:RealmBiomeData = this.gameData.biomeData;
			biomeData.weatherTypes.length = childs.length();

			for( var i:int = childs.length()-1; i >= 0; i-- ) {

				node = childs[i];
				if ( node.hasOwnProperty( "@rarity" ) ) {
					biomeData.weatherTypes[i] = new BiomeWeatherType( node.name(), node.@rarity );
				} else {
					biomeData.weatherTypes[i] = new BiomeWeatherType( node.name() );
				}

			} // for-loop.

		} //

		public function parseSky( xml:XML ):void {

			if ( xml == null ) {
				return;
			}

			var tops:String = xml.top;
			var bots:String = xml.bottom;

			this.gameData.biomeData.bottomSkyColors = bots.split( "," );
			this.gameData.biomeData.topSkyColors = tops.split("," );

		} //

		/**
		 * 'foreground' and 'background' layers should already exist in gameData.layers.
		 * this just defines the tileMaps and tileSets used by each layer.
		 */
		public function parseTileLayers( xmlList:XMLList, layers:Dictionary ):void {

			var layerNode:XML;
			var len:int = xmlList.length();

			var layer:TileLayer;
			var name:String;

			var maps:XMLList;
			var mapCount:int;			// tile maps in this layer.

			var tileMaps:Vector.<TileMap>;

			for( var i:int = 0; i < len; i++ ) {

				layerNode = xmlList[i];

				name = layerNode.attribute( "name" );

				layer = layers[ name ];
				if ( layer == null ) {
					continue;
				}

				maps = layerNode.child( "tileMap" );
				mapCount = maps.length();

				// fixed size tileMaps.
				tileMaps = new Vector.<TileMap>( mapCount, true );

				for( var j:int = 0; j < mapCount; j++ ) {
					this.insertTileMap( tileMaps, this.parseTileMap( maps[j], layer ), j );
				} //

				layer.setTileMaps( tileMaps );

			} // end for-loop.

		} //*/

		public function parseTileMap( xml:XML, layer:TileLayer ):TileMap {

			var tmap:TileMap = new TileMap( xml.attribute( "name" ) );
			this.tileMaps[ tmap.name ] = tmap;

			// get the tile set used by this tileMap
			var setName:String = xml.attribute( "tileSet" );
			var tset:TileSet = this.tileSets[ setName ];
			if ( tset == null ) {
				trace( "Unknown set in LandParser: " + setName );
			} //

			tmap.tileSet = tset;
			tmap.layer = layer;

			// Map properties.

			if ( xml.hasOwnProperty( "@drawOrder" ) ) {
				tmap.drawOrder = xml.attribute( "drawOrder" );
			} //

			if ( xml.hasOwnProperty( "@tileSize" ) ) {
				tmap.setTileSize( xml.attribute( "tileSize" ) );
				//tmap.tileSize = xml.attribute( "tileSize" );
			} //

			if ( xml.hasOwnProperty( "@drawHits" ) ) {
				tmap.drawHits = ( xml.attribute( "drawHits" ) == "true" );
			}

			/**
			 * probably don't need this +2 any more, but the scenes are already saved this way...
			 */
			var rows:int = Math.ceil( this.screenBounds.height / tmap.tileSize );
			var cols:int = Math.ceil( this.screenBounds.width / tmap.tileSize );

			tmap.init( rows, cols );

			tmap.renderers = this.parseRenderers( xml["renderers"].children(), tmap, layer );
			tmap.generators = this.generatorParser.parseGenerators(  xml["generators"].children(), tmap, layer );

			return tmap;

		} //

		
		/**
		 * xmlList is a list of specific tile renderer classes.
		 */
		public function parseRenderers( xmlList:XMLList, tileMap:TileMap, layer:TileLayer ):Vector.<MapRenderer> {

			var child:XML;
			var len:int = xmlList.length();

			var renderList:Vector.<MapRenderer> = new Vector.<MapRenderer>();
			var renderer:MapRenderer;

			var renderContext:RenderContext = layer.getRenderContext();

			var s:String;

			for( var i:int = 0; i < len; i++ ) {

				child = xmlList[i];

				// for some reason, switch on child.name() directly does not work.
				s = child.name();

				/**
				 * eventually allow individual property assignments for each renderer.
				 */
				switch ( s ) {

					case "terrainRenderer":
						renderList.push( this.parseTerrainRenderer( child, tileMap, layer ) )
						break;
					case "buildingRenderer":
						renderList.push( new BuildingRenderer( tileMap, renderContext ) );
						break;
					case "terrainOutliner":
						renderList.push( this.parseTerrainOutliner( child, tileMap, layer ) );
						break;
					case "buildingOutliner":
						renderList.push( this.parseBuildingOuliner( child, tileMap, layer ) );
						break;
					case "treeRenderer":
						renderList.push( this.parseTreeRenderer( child, tileMap, layer ) );
						break;
					case "decalRenderer":
						renderList.push( new DecalRenderer( tileMap, renderContext ) );
						break;
					case "decalHitRenderer":
						if ( renderContext.drawHits ) {
							renderList.push( new DecalHitRenderer( tileMap, renderContext ) );
						}
						break;

					default:
						trace( "Unknown renderer in LandParser: " + s );
						continue;

				} // switch

			} //

			return renderList;

		} //

		/*public function parseDecalHitRenderer( xml:XML, tmap:TileMap, layer:TileLayer ):DecalHitRenderer {

			var r:DecalHitRenderer = new DecalHitRenderer( tmap, layer.getHitBitmap() );

			return r;

		} //*/

		public function parseTreeRenderer( xml:XML, tmap:TileMap, layer:TileLayer ):TreeRenderer {
			
			var r:TreeRenderer = new TreeRenderer( tmap, layer.getRenderContext(), gameData.worldRandoms.randMap );

			if ( xml.hasOwnProperty( "@drawOutlines" ) ) {
				r.drawOutlines = ( xml.attribute( "drawOutlines" ) == "true" );
			} //
			if ( xml.hasOwnProperty( "@sortDetails" ) ) {
				r.sortDetails = ( xml.attribute( "sortDetails" ) == "true" );
			} //

			return r;
			
		} //

		public function parseTerrainRenderer( xml:XML, tileMap:TileMap, layer:TileLayer ):TerrainRenderer {

			var r:TerrainRenderer = new TerrainRenderer( tileMap, layer.getRenderContext(), gameData.worldRandoms.randMap );

			if ( xml.hasOwnProperty( "@drawOutlines" ) ) {
				r.drawOutlines = ( xml.attribute( "drawOutlines" ) == "true" );
			} //

			return r;

		} //

		public function parseTerrainOutliner( xml:XML, tmap:TileMap, layer:TileLayer ):TerrainOutliner {

			var r:TerrainOutliner = new TerrainOutliner( tmap, layer.getRenderContext() );

			if ( xml.hasOwnProperty( "@strokeSize" ) ) {
				r.strokeSize = xml.attribute( "strokeSize" );
			} //

			return r;
			
		} //

		public function parseBuildingOuliner( xml:XML, tileMap:TileMap, layer:TileLayer ):BuildingOutliner {

			var r:BuildingOutliner = new BuildingOutliner( tileMap, layer.getRenderContext() );

			if ( xml.hasOwnProperty( "@outerLineSize" ) ) {
				r.outerLineSize = xml.attribute( "outerLineSize" );
			} //
			if ( xml.hasOwnProperty( "@innerLineSize" ) ) {
				r.innerLineSize = xml.attribute( "innerLineSize" );
			}
			if ( xml.hasOwnProperty( "@outerLineColor" ) ) {
				r.outerLineColor = xml.attribute( "outerLineColor" );
			}
			if ( xml.hasOwnProperty( "@drawHits" ) ) {
			} //

			return r;

		} //

		/**
		 * insert index is only the starting index. the tile map will be moved down until it reaches
		 * its correct draw order - lowest draw order at index 0. this function assumes the current list
		 * is already sorted.
		 */
		protected function insertTileMap( tileMaps:Vector.<TileMap>, map:TileMap, insertIndex:int ):void {

			var nextMap:TileMap;

			for( var i:int = insertIndex-1; i >= 0; i-- ) {

				nextMap = tileMaps[i];
				if ( nextMap.drawOrder <= map.drawOrder ) {

					// type cannot be moved down any further. insert it at the current insertIndex.
					break;

				} else {

					tileMaps[insertIndex] = nextMap;
					insertIndex--;

				} //

			} // for-loop.

			tileMaps[ insertIndex ] = map;

		} //

		// old method of defining tileSpecials
		/*private function parseSpecialTiles( xml:XML ):void {

			if ( xml == null ) {
				return;
			}

			var d:Dictionary = this.gameData.specialTiles = new Dictionary();

			var childs:XMLList = xml.child( "type" );
			var child:XML;
			for( var i:int = childs.length()-1; i >= 0; i-- ) {

				child = childs[i];
				d[ child.attribute("name") ] = child.text().toString();

			} //

		} //*/

	} // class

} // package