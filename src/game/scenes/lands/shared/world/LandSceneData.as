package game.scenes.lands.shared.world {

	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.LandEncoder;
	import game.util.Base64;

	public class LandSceneData {

		static private const COMPRESSION:String = CompressionAlgorithm.ZLIB;
		//private const ENCODING:String = "base64";

		/**
		 * the xml encoding of the scene.
		 */
		protected var _xml:XML;

		public function LandSceneData( sceneXML:XML=null ) {

			if ( sceneXML ) {

				this._xml = sceneXML;

			} //

		} // LandSceneData

		public function cacheSceneXML( data:LandGameData ):void {

			var tileMaps:Dictionary = data.tileMaps;

			if ( this._xml == null ) {

				this._xml = <scene/>;

			} else {

				// remove all the xml elements that can change based on the user, but not ones
				// that are constant ( like maybe items? )
				delete this._xml.map;			// remove all maps.

			} //

			var mapXML:XML;
			var bytes:ByteArray = new ByteArray();

			var encoder:LandEncoder = new LandEncoder();

			for each ( var tmap:TileMap in tileMaps ) {
				
				// write tileMap name.
				// not going to currently specify encoding and compression, unless it changes.
				mapXML = <map name={ tmap.name} rows={tmap.rows} cols={tmap.cols} />;

				this._xml.appendChild( mapXML );

				bytes.length = 0;

				if ( tmap.tileSet.setType == "decal" ) {
					encoder.encodeDecalMap( tmap, bytes );
				} else {
					encoder.encodeTileMap( tmap, bytes );
				}

				bytes.compress( LandSceneData.COMPRESSION );
				mapXML.appendChild( Base64.encodeByteArray(bytes) );

			} // for-each

		} // storeSceneXML()

		/**
		 * add a scene xml node that will get stored with this scene.
		 */
		/*public function addNodeData( node:XML ):void {

			if ( this._xml == null ) {
				this._xml = <scene />;
			}

			this._xml.appendChild( node );

		} //*/

		/**
		 * retrieve the data from this scene data and put it back into the current tileMaps.
		 */
		public function fillSceneMaps( tileMaps:Dictionary ):void {

			// used to store tile map data from the xml before decoding it into the tileMaps.
			var mapData:ByteArray;

			//var sceneMaps:XMLList = this._xml.child( "map" );
			//var len:int = sceneMaps.length();					// number of scene maps in xml.

			var searchList:XMLList;		// search result for matching name=tileMap.name
			var mapXML:XML;
			var compression:String;
			var encoder:LandEncoder = new LandEncoder();

			// check for maps defined in scene but not in xml.
			for each ( var tileMap:TileMap in tileMaps ) {

				// find an xml node that has the information for this map.
				searchList = this._xml.map.( @name == tileMap.name );
				if ( searchList.length() == 0 ) {

					// no stored data for this tile map. clear everything.
					tileMap.clearAllTiles();
					continue;

				} //

				mapXML = searchList[0];		// there should be only one for each tilemap.

				// set the tileMap size to match the loaded tile map xml.
				tileMap.resize( mapXML.@rows, mapXML.@cols );

				// get the text-encoded map data and place it in the buffer for decoding.
				mapData = Base64.decodeToByteArray( mapXML.text() );

				compression = mapXML.@compression;
				if ( compression == null || compression == "" ) {
					mapData.uncompress( LandSceneData.COMPRESSION );
				} else if ( compression != "none" ) {
					mapData.uncompress( compression );
				}

				if ( tileMap.tileSet.setType == "decal" ) {
					encoder.decodeDecalMap( tileMap, mapData );
				} else {
					encoder.decodeTileMap( tileMap, mapData );
				}

			} // for-loop.

		} //

		public function getItemData():XML {

			if ( this._xml.hasOwnProperty( "items" ) ) {

				return this._xml.items[0];

			} else {

				return null;
			}

		}

		public function hasTileData():Boolean {

			return ( this._xml != null && this._xml.child( "map" ).length() > 0 );

		} //

		public function get xmlData():XML {
			return this._xml;
		}

		/**
		 * eventually this might set byte data instead.
		 */
		public function set xmlData( xml:XML ):void {

			this._xml = xml;

		} //

	} // TileScene

} // package