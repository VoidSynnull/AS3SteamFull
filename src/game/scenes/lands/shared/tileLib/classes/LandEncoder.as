package game.scenes.lands.shared.tileLib.classes {

	/**
	 * The land-xml encoding has now changed for version: 1.10
	 * version 1.00 land encodings are not compatible, but I included a legacy decoding function which will still work,
	 * though some functionality may be lost.
	 * 
	 * here is a rough schematic of how things changed:
	 * 
	 * old structure:  <world> <biome name="" ><scene><scene><scene></biome>  <biome name="" ><scene><scene><scene></biome> </world>
	 * 
	 * new structure: <world> <realm id="" biome=""><scene><scene><scene></realm> <realm id="" biome=""><scene><scene><scene></realm> </world>
	 * 
	 * 
	 * - each world now has its own unqiue unsigned integer 'id', wheras before it was sufficient to refer to a biome name.
	 * - each world now has its own time, whereas there used to be a global time for all biomes.
	 */

	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Dictionary;

	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.templates.TileTemplate;
	import game.scenes.lands.shared.world.LandGalaxy;
	import game.scenes.lands.shared.world.LandRealmData;
	import game.scenes.lands.shared.world.LandSceneData;
	import game.util.Base64;

	public class LandEncoder {

		//private const CHAR_SET:String = "iso-8859-1";
		private const COMPRESSION:String = "none";
		private const CURRENT_VERESION:String = "1.10";

		private const MAP_COMPRESSION:String = CompressionAlgorithm.ZLIB;
		private const MAP_ENCODING:String = "base64";

		/**
		 * version of decoded data.
		 */
		private var version:String;

		public function LandEncoder() {
		}

		private function encodeHeader( xml:XML ):void {

			xml.@version = this.CURRENT_VERESION;
			xml.@compression = this.COMPRESSION;

		} //

		private function decodeHeader( xml:XML ):void {

			this.version = xml.attribute( "version" );

			// we could also add file-wide compression here. compress/decompress everything
			// inside the opening <land> tag.

		} //

		public function encodeWorld( galaxy:LandGalaxy, time:Number=0 ):XML {

			var landXML:XML = <land />;

			var scene:LandSceneData;

			this.encodeHeader( landXML );

			// world xml.
			var dayPct:Number = time;
			var worldXML:XML = <world time={ dayPct.toFixed(2) } />;
			landXML.appendChild( worldXML );

			// this is a temp fix because file-planets don't currently have any concept
			// of an 'id'  going to program a way to assign them ids in a week or so.
			var curRealm:LandRealmData = galaxy.curRealm;
			if ( curRealm ) {

				if ( curRealm.id != 0 ) {
					worldXML.@curRealm = curRealm.id;
				} else {

					worldXML.@curRealm = curRealm.name;

				} //

			}

			// encode each biome.
			var worldData:Vector.<LandRealmData> = galaxy.getRealms();

			for( var i:int = worldData.length-1; i >= 0; i-- ) {

				this.encodeRealm( worldData[i], worldXML );

			} // end for-loop.

			return landXML;

		} // encodeWorld()

		/**
		 * decode an entire Land world stored in a file.
		 * 
		 * TO-DO: restore clock setting from world file - might need it to start a world with a thematic time.
		 */
		public function decodeFileWorld( galaxy:LandGalaxy, xml:XML ):void {

			this.decodeHeader( xml );

			// !!!! very messy way to do old-version conversions ->but i dont want to make new classes
			// and this should be removed relatively quickly.
			if ( this.version == "1.00" ) {
				this.decodeLegacyXML( galaxy, xml );
				return;
			}

			// curRealm will either be realmName or realmId.
			// temp fix until file worlds have realm ids.
			var curRealm:String = xml.world.@curRealm;
			var realmId:int = parseInt( curRealm );

			/**
			 * !!temporarily removing time until I can find a better way to do this.
			 */
			/*if ( xml.world.hasOwnProperty( "@time" ) ) {

				worldMgr.clock.setStartTime( xml.world.@time );

			} //*/

			var realms:Vector.<LandRealmData> = galaxy.getRealms();
			realms.length = 0;		// a bit inefficient. might be possible to re-use the current biomes, though its risky.

			// <world> <biome /> <biome /> ... </world>
			var childList:XMLList = xml.world.child( "realm" );
			var len:int = childList.length();
			for( var i:int = 0; i < len; i++ ) {

				realms.push( this.decodeRealm( childList[i] ) );

			} // end-while.

			// this is a temp fix because file-planets don't currently have any concept
			// of an 'id'  going to program a way to assign them ids in a week or so.
			if ( isNaN( realmId ) ) {

				galaxy.setRealmByName( curRealm );

			} else {

				galaxy.setRealmById( realmId );

			} //

		} // decodeWorld()

		/**
		 * !!!!!!!!
		 * LEGACY FUNCTION FOR 1.00 files only. This function should be phased out
		 * in about six months time to a year at most.
		 * 
		 * this uses the old terminology for 'world' as 'galaxy' and 'biome' for 'realm'
		 * users probably won't be able to load these files anymore, but we might
		 * want to keep this function around for converting old files to online files.
		 */
		public function decodeLegacyXML( galaxy:LandGalaxy, xml:XML ):void {

			// biomes are now planets.
			var curPlanet:String = xml.world.@curBiome;

			/**
			 * !!temporarily removing time until I can find a better way to do this.
			 */
			/*if ( xml.world.hasOwnProperty( "@time" ) ) {
			worldMgr.clock.setStartTime( xml.world.@time );
			} //*/

			var biomes:Vector.<LandRealmData> = galaxy.getRealms();
			biomes.length = 0;		// a bit inefficient. might be possible to re-use the current biomes, though its risky.

			// <world> <biome /> <biome /> ... </world>
			var childList:XMLList = xml.world.child( "biome" );
			var len:int = childList.length();
			for( var i:int = 0; i < len; i++ ) {

				biomes.push( this.decodeRealm( childList[i] ), 10 );

			} // end-while.

			galaxy.setRealmByName( curPlanet );

		} //

		public function encodeTemplate( template:TileTemplate ):XML {

			var grids:Dictionary = template.getGrids();

			var compression:String = this.MAP_COMPRESSION;
			var xml:XML = <template width={template.width} height={template.height} />;

			var gridXML:XML;
			var bytes:ByteArray = new ByteArray();

			for each ( var tmap:TileMap in grids ) {

				// write tileMap name.
				gridXML = <map name={tmap.name} rows={tmap.rows} cols={tmap.cols} />;

				xml.appendChild( gridXML );

				bytes.length = 0;
				// template maps don't have tileSets...
				if ( tmap.name.indexOf( "decal" ) != -1 ) {		// temp fix.
					this.encodeDecalMap( tmap, bytes );
				} else {
					this.encodeTileMap( tmap, bytes );
				}

				bytes.compress( compression );
				gridXML.appendChild( Base64.encodeByteArray(bytes) );

			} // for-each

			return xml;

		} // encodeTemplate()

		/**
		 * decode the template xml data and the bytearray compressed tile maps
		 * and store them in a template object.
		 * 
		 * returns false if decoding failed.
		 */
		public function decodeTemplate( template:TileTemplate, xml:XML ):Boolean {

			var grids:Dictionary = new Dictionary();		// template grids.

			// template width,height.
			var width:int;
			var height:int;

			var tileMap:TileMap;

			// used to store tile map data from the xml before decoding it into tileMaps.
			var mapData:ByteArray;

			var compression:String
			if ( xml.hasOwnProperty( "@compression" ) ) {
				compression = xml.attribute( "compression" );
			} else {
				compression = this.MAP_COMPRESSION;
			} //

			if ( !xml.hasOwnProperty( "@width" ) ||  !xml.hasOwnProperty("@height" ) ) {
				return false;
			}
			height = xml.attribute( "height" );
			width = xml.attribute( "width" );
			if ( isNaN( height ) || height <= 0 || isNaN(width) || width <= 0 ) {
				return false;
			}
			if ( xml.hasOwnProperty( "@rowOffset" ) ) {
				template.rowOffset = xml.@rowOffset;
			}

			var templateMaps:XMLList = xml.children();
			var len:int = templateMaps.length();
			var mapXML:XML;

			for( var i:int = 0; i < len; i++ ) {

				mapXML = templateMaps[i];

				tileMap = new TileMap( mapXML.@name.toString() );
				grids[ tileMap.name ] = tileMap;

				// set the tileMap size to match the loaded tile map xml.
				tileMap.init( mapXML.@rows, mapXML.@cols );

				// get the text-encoded map data and place it in the buffer for decoding.
				mapData = Base64.decodeToByteArray( mapXML.text() );
				mapData.uncompress( compression );

				if ( tileMap.name.indexOf( "decal" ) != -1 ) {			// temp fix.
					this.decodeDecalMap( tileMap, mapData );
				} else {
					this.decodeTileMap( tileMap, mapData );
				}

			} // for-loop.

			template.setTemplateData( grids, width, height );

			return true;

		} // decodeTemplate()

		/*public function encodeMonster():void {
		} //*/

		public function encodeTileMap( tileMap:TileMap, data:ByteArray ):void {

			var tiles:Vector.< Vector.<LandTile> > = tileMap.getTiles();
			var rows:int = tileMap.rows;
			var cols:int = tileMap.cols;

			for( var r:int = rows-1; r >= 0; r-- ) {

				for( var c:int = cols-1; c >= 0; c-- ) {

					data.writeUnsignedInt( tiles[r][c].type );

				} //

			} // for-loop.

		} //

		/**
		 * decal tiles need to encode their offset within the decal clip - which is split into rows,cols
		 */
		public function encodeDecalMap( tileMap:TileMap, data:ByteArray ):void {

			var tiles:Vector.< Vector.<LandTile> > = tileMap.getTiles();
			var cols:int = tileMap.cols;

			var tile:LandTile;
			var decalCode:uint;

			for( var r:int = tileMap.rows-1; r >= 0; r-- ) {

				for( var c:int = cols-1; c >= 0; c-- ) {

					tile = tiles[r][c];
					if ( tile.type == 0 ) {
						data.writeUnsignedInt( 0 );
					} else {
						// row,col offsets make up the two high bytes.
						// OR does not work here.. it seems to mix up the unsigned and signed results. << and + preserve sign.
						decalCode = tile.type | (tile.tileDataY << 24) | (0x00FF0000&(tile.tileDataX << 16));

						//trace( "DECAL CODE: " + decalCode.toString( 16 ) );
						data.writeUnsignedInt( decalCode );
					}

				} //

			} // for-loop.

		} //

		/**
		 * decal tiles need to decode their offset within the decal clip - which is split into rows,cols
		 */
		public function decodeDecalMap( tileMap:TileMap, data:ByteArray ):void {

			var tiles:Vector.< Vector.<LandTile> > = tileMap.getTiles();
			var decalCode:uint;
			var tile:LandTile;

			for( var r:int = tileMap.rows-1; r >= 0; r-- ) {
				
				for( var c:int = tileMap.cols-1; c >= 0; c-- ) {

					tile = tiles[r][c];
					decalCode = data.readUnsignedInt();			// decal data is encoded with row,col offsets in the first two bytes.

					if ( decalCode == 0 ) {
						tile.type = 0;
						continue;
					}

					tile.type = 0x0000FFFF & decalCode;

					//trace( "type: " + tile.type );

					tile.tileDataY = ( decalCode >> 24 );
					tile.tileDataX = 0xFF&(decalCode >> 16);
					if ( tile.tileDataX >= 128 ) {
						tile.tileDataX -= 256;
					}

					//trace( "Y JIGG:E " + tile.jiggleY );
					//trace( "X JIGG:E: " + tile.jiggleX );

				} //
				
			} // for-loop.
			
		} //

		public function decodeTileMap( tileMap:TileMap, data:ByteArray ):void {
			
			var tiles:Vector.< Vector.<LandTile> > = tileMap.getTiles();
			
			for( var r:int = tileMap.rows-1; r >= 0; r-- ) {
				
				for( var c:int = tileMap.cols-1; c >= 0; c-- ) {
					
					tiles[r][c].type = data.readUnsignedInt();
					
				} //
				
			} // for-loop.
			
		} //

		public function decodeTiles( tiles:Vector.< Vector.<LandTile> >, data:ByteArray ):void {

			var tileRow:Vector.<LandTile>;

			for( var r:int = tiles.length-1; r >= 0; r-- ) {

				tileRow = tiles[r];

				for( var c:int = tileRow.length-1; c >= 0; c-- ) {

					tileRow[c].type = data.readUnsignedInt();

				} //

			} // for-loop.

		} //

		public function encodeTiles( tiles:Vector.< Vector.<LandTile> >, data:ByteArray ):void {

			var rows:int = tiles.length;
			if ( rows == 0 ) {
				return;
			}

			var cols:int = tiles[0].length;
			var tileRow:Vector.<LandTile>;

			for( var r:int = rows-1; r >= 0; r-- ) {

				tileRow = tiles[r];

				for( var c:int = cols-1; c >= 0; c-- ) {

					data.writeUnsignedInt( tileRow[c].type );

				} //
				
			} // for-loop.
			
		} //

		public function encodeRealm( realm:LandRealmData, worldXML:XML ):void {

			var realmNode:XML =
				<realm name={ realm.name } id={ realm.id } seed={ "0x" + realm.seed.toString(16) } size={ realm.realmSize }
							curScene={ "0x" + realm.curLoc.x.toString(16) } playerLoc={ realm.playerPosition.toString() }
							biome={ realm.biome } scenes={realm.sceneMap.join()} />;

			if ( realm.thumbURL != null && realm.thumbURL != "" ) {
				realmNode.@thumb = realm.thumbURL;
			} //
			if ( realm.last_visit_time > 0 ) {
				realmNode.@last_visit = realm.last_visit_time;
			}

			// creator name, share status, realm rating, pending status
			if ( realm.creator_login != null ) {
				realmNode.@creator = realm.creator_login;
			}
			if ( realm.avatar_name != null ) {
				realmNode.@avatar = realm.avatar_name;
			}

			if ( realm.shareStatus != 0 ) {
				realmNode.@shareStatus = realm.shareStatus;
			}
			if ( realm.approveStatus != 0 ) {
				realmNode.@approveStatus = realm.approveStatus;
			}
			if ( realm.sharedDate != 0 ) {
				realmNode.@sharedDate = realm.sharedDate;
			}
			if ( realm.rating != 0 ) {
				realmNode.@rating = realm.rating;
			}

			worldXML.appendChild( realmNode );

			var myScenes:Dictionary = realm.getScenes();
			var sceneData:LandSceneData;
			var scene:XML;

			// each scene is indexed by a byte-packed y,x coordinate.
			for ( var n:int in myScenes ) {

				sceneData = myScenes[n];

				// y,x packed bytes.
				scene = sceneData.xmlData;

				if ( scene == null ) {
					continue;
				}

				// need to append scene location information.
				scene.@x = n;
				//<scene x={ n & 0xFF } y={ n >> 8 } />;

				realmNode.appendChild( scene );

			} // for-loop.

		} //

		/**
		 * posRadix is legacy for old files and will be removed in the future.
		 */
		public function decodeRealm( realmNode:XML, posRadix:int=16 ):LandRealmData {

			var realm:LandRealmData;

			if ( realmNode.hasOwnProperty( "@size" ) ) {
				realm = new LandRealmData( realmNode.@biome, realmNode.@seed, realmNode.@size, realmNode.@name );
			} else {
				// legacy worlds do not have size or biome information.
				realm = new LandRealmData( realmNode.@name, realmNode.@seed );
			}

			if ( realmNode.hasOwnProperty( "@id" ) ) {
				realm.id = realmNode.@id;
			}

			if ( realmNode.hasOwnProperty( "@thumb" ) ) {
				realm.thumbURL = realmNode.@thumb;
			} //
			if ( realmNode.hasOwnProperty( "@last_visit" ) ) {
				realm.last_visit_time = realmNode.@last_visit;
			}

			if ( realmNode.hasOwnProperty( "@scenes" ) ) {
				var str:String = realmNode.@scenes;
				realm.copySceneMap( str.split( "," ) );
			} //

			// creator name, share status, realm rating, pending status
			if ( realmNode.hasOwnProperty( "@shareStatus" ) ) {
				realm.shareStatus = realmNode.@shareStatus;
			}
			if ( realmNode.hasOwnProperty( "@approveStatus" ) ) {
				realm.approveStatus = realmNode.@approveStatus;
			}
			if ( realmNode.hasOwnProperty( "@rating" ) ) {
				realm.rating = realmNode.@rating;
			}
			if ( realmNode.hasOwnProperty( "@sharedDate" ) ) {
				realm.sharedDate = realmNode.@sharedDate;
			}

			if ( realmNode.hasOwnProperty( "@creator" ) ) {
				realm.creator_login = realmNode.@creator;
			}
			if ( realmNode.hasOwnProperty( "@avatar" ) ) {
				realm.avatar_name = realmNode.@avatar;
			}

			// current scene location of the player within this biome.
			realm.curLoc.x = ( realmNode.@curScene );
			realm.playerPosition.fromString( realmNode.@playerLoc, posRadix );

			var sceneList:XMLList = realmNode.child( "scene" );
			var sceneXML:XML;
			var len:int = sceneList.length();

			var x:int, y:int;

			for( var i:int = 0; i < len; i++ ) {

				sceneXML = sceneList[ i ];

				// scene location within biome.
				x = sceneXML.@x;
				if ( sceneXML.hasOwnProperty( "@y" ) ) {
					y = sceneXML.@y;
				}

				realm.setSceneData( x, y, new LandSceneData( sceneXML ) );

			} // while-loop.

			return realm;

		} //

		/*/**
		* this function should basically be the same as encodeTileMap()
		* templates just access the tile type code directly, without a landtile.
		public function encodeTemplateGrid( grid:TemplateGrid, data:ByteArray ):void {

			var tiles:Vector.< Vector.<uint> > = grid.getGrid();
			var rows:int = grid.rows;
			var cols:int = grid.cols;

			for( var r:int = rows-1; r >= 0; r-- ) {

				for( var c:int = cols-1; c >= 0; c-- ) {
					
					data.writeUnsignedInt( tiles[r][c] );
					
				} //
				
			} // for-loop.
			
		} //

		/**
		 * same as decodeTileMap() they should yield the same data, but have it assigned
		 * to different objects.

		public function decodeTemplateGrid( grid:TemplateGrid, data:ByteArray ):void {
			
			var tiles:Vector.< Vector.<uint> > = grid.getGrid();
			
			for( var r:int = grid.rows-1; r >= 0; r-- ) {
				
				for( var c:int = grid.cols-1; c >= 0; c-- ) {
					
					tiles[r][c] = data.readUnsignedInt();
					
				} //
				
			} // for-loop.
			
		} //*/

	} // class

} // package