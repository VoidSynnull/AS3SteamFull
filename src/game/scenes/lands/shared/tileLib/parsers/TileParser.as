package game.scenes.lands.shared.tileLib.parsers {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.classes.BiomeTileSwapper;
	import game.scenes.lands.shared.tileLib.classes.DetailType;
	import game.scenes.lands.shared.tileLib.classes.TileSetSwapList;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.BuildingTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TerrainTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	/**
	 * parses the tileSets and tileTypes for land. Not in the LandParser for organizational purposes.
	 */

	public class TileParser {

		private var tileSets:Dictionary;

		private var tileSwapper:BiomeTileSwapper;

		/**
		 * maps tileType to interaction objects.
		 */
		private var tileSpecials:Dictionary;

		// temp variable to prevent ad rooms from crashing.
		public var useLayerProps:Boolean = true;

		private var gameData:LandGameData;

		public function TileParser( gameData:LandGameData ) {

			this.tileSets = gameData.tileSets;

			this.gameData = gameData;

			if ( gameData.tileSwapper != null ) {
				this.tileSwapper = gameData.tileSwapper;
			} else {
				this.tileSwapper = gameData.tileSwapper = new BiomeTileSwapper();
			}

			this.tileSpecials = gameData.tileSpecials;

		} //

		public function parse( xml:XML ):void {

			var xmlList:XMLList = xml.child( "tileSet" )

			var child:XML;
			var len:int = xmlList.length();
			
			var tileSet:TileSet;

			for( var i:int = 0; i < len; i++ ) {
				
				tileSet = this.parseTileSet( xmlList[i] );
				/*if ( tileSet != null ) {
				this.tileSets[ tileSet.name ] = tileSet;
				}*/

			} // for-loop.

		} //

		/**
		 * Parse a list of tile sets with tiles that should only appear in
		 * a specific biome. Every tileType found is a patch or swappable tileType
		 * and is added to the BiomeTileSwap object.
		 * 
		 * This function is used for tileTypes defined outside the main tiles.xml
		 * and inside a biome.xml
		 */
		public function parseBiomeSets( xml:XML, biome:String ):void {

			var xmlList:XMLList = xml.child( "tileSet" )

			var child:XML;
			var len:int = xmlList.length();

			for( var i:int = 0; i < len; i++ ) {

				this.parseBiomeTileSet( xmlList[i], biome );

			} // for-loop.

		} //

		/**
		 * gets the tile set if it exists, or creates it otherwise.
		 * 
		 * used to forward-reference tile sets.
		 */
		private function getTileSet( setName:String ):TileSet {
			
			var tset:TileSet = this.tileSets[ setName ];
			
			if ( tset ) {
				return tset;
			}
			
			tset = new TileSet();
			tset.name = setName;
			this.tileSets[ setName ] = tset;
			
			return tset;
			
		} //

		/**
		 * xml is a <tileSet>
		 * 
		 * parse a set of tiles that should only appear in a single biome. the tiles are added
		 * to the biome's tileSwap set and are only added if tiles of the same type don't already
		 * exist in that set.
		 */
		private function parseBiomeTileSet( xml:XML, biome:String ):void {

			var setName:String = xml.attribute( "name" );
			var tileSet:TileSet = this.tileSets[ setName ];

			if ( tileSet == null ) {
				// this would be a case of a new biome trying to define tileSets that don't even exist in the base tiles.xml
				// not going to allow this for now, because it would add complications of completing removing
				// not just tileTypes, but entire tileSets when a biome changes.
				return;
			} //

			var swapSet:TileSetSwapList = this.tileSwapper.getSwapSet( biome, tileSet );
			swapSet.addSwapTypes( this.parseTypeList( xml ) );

		} //

		/**
		 * xml is a <tileSet>
		 */
		private function parseTileSet( xml:XML ):TileSet {

			var tileSet:TileSet = this.getTileSet( xml.attribute( "name" ) );

			tileSet.setType = xml.attribute( "type" );
			
			if ( xml.hasOwnProperty( "@allowMixedTiles" ) ) {
				tileSet.allowMixedTiles = ( xml.attribute( "allowMixedTiles" ) == "true" );
			}
			
			/**
			 * 
			 * Parse all the different types of tiles. This is no longer done by set but by the <tag> of the tile itself
			 * 
			 */
			tileSet.tileTypes = this.parseTypeList( xml );

			// COLLECT ANY TILE TYPES UNIQUE TO GIVEN BIOMES.
			var childList:XMLList = xml.child( "biome" );
			if ( childList.length() > 0 ) {
				this.parseBiomeSwaps( childList, tileSet );
			} //

			return tileSet;

		} //

		/**
		 * parse a list of tileType nodes.
		 * currently each list will only contain a single kind of tileType, so as soon
		 * as the correct tileType is found, it can be parsed and the rest can be ignored.
		 */
		private function parseTypeList( xml:XML ):Vector.<TileType> {

			var tileTypes:Vector.<TileType> = new Vector.<TileType>();

			// basic tile type, nothing fancy.
			var childList:XMLList = xml.child( "tileType" );
			if ( childList.length() > 0 ) {

				this.parseBasicTypes( childList, tileTypes );
				return tileTypes;

			} //
			childList = xml.child( "terrain" );
			if ( childList.length() > 0 ) {

				this.parseTerrainTypes( childList, tileTypes );
				return tileTypes;

			} //
			childList = xml.child( "material" );
			if ( childList.length() > 0 ) {

				this.parseBuildingTypes( childList, tileTypes );
				return tileTypes;

			} //
			childList = xml.child( "clipType" );
			if ( childList.length() > 0 ) {

				this.parseClipTypes( childList, tileTypes );
				return tileTypes;

			} //

			return tileTypes;

		} //

		private function parseSpecial( xml:XML, tileType:TileType ):void {
			
			var special:TileTypeSpecial = new TileTypeSpecial();

			// specialType is highly ambiguous at the moment. we might want to codify this at some point.
			var specType:String = special.specialType = xml.attribute( "type" );

			if ( specType == "swap" ) {

				special.clickable = true;
				special.swapTile = xml.attribute( "id" );
				if ( xml.hasOwnProperty( "@dx" ) ) {
					special.offsetX = xml.attribute( "dx" );
				}
				if ( xml.hasOwnProperty( "@dy" ) ) {
					special.offsetY = xml.attribute( "dy" );
				}

			} else if ( specType == "trap" ) {
				special.clickable = false;
				special.swapTile = xml.attribute( "id" );
				if ( xml.hasOwnProperty( "@dx" ) ) {
					special.offsetX = xml.attribute( "dx" );
				}
				if ( xml.hasOwnProperty( "@dy" ) ) {
					special.offsetY = xml.attribute( "dy" );
				}

			} else if ( specType == "food" ) {

				special.clickable = true;

			} else if ( specType == "race_start" ) {
				special.clickable = true;
			} else if ( specType == "race_finish" ) {
				special.clickable = true;
			} else if ( specType == "cannon" ) {
				special.clickable = true;
			} //

			if ( xml.hasOwnProperty( "@bonus" ) ) {
				special.bonus = xml.attribute( "bonus" );
			}
			if ( xml.hasOwnProperty( "@refund" ) ) {
				special.refund = xml.@refund;
			}
			if ( xml.hasOwnProperty( "@sound" ) ) {
				special.sound = xml.attribute( "sound" );
			}

			this.tileSpecials[ tileType ] = special;

		} //

		/*************************************************
		 * 
		 * PARSING GROUPS OF TILETYPES
		 * 
		 *************************************************/

		/**
		 * biomeList is a list of <biome></biome> nodes, each having the swap list for the current tileSet for that biome.
		 */
		private function parseBiomeSwaps( biomeList:XMLList, curSet:TileSet ):void {

			var len:int = biomeList.length();
			var data:TileType;

			var biomeSwapNode:XML;
			var tileSetSwap:TileSetSwapList;

			for( var i:int = 0; i < len; i++ ) {

				// e.g. <biome name="sand">  <terrain></terrain> <terrain></terrain>   </biome>
				biomeSwapNode = biomeList[i];

				// for the biome listed, create a tileSetSwap for the current tile set.
				// we then fill it with the tileTypes that will be swapped out.
				tileSetSwap = this.tileSwapper.createSetSwap( biomeSwapNode.attribute( "name" ), curSet );

				// list of tile types defined for this node.
				tileSetSwap.setSwapTypes( this.parseTypeList( biomeSwapNode ) );

			} // for-loop.

		} //

		/**
		 * parses tile types that are direct instances of the TileType class,
		 * and also intializes the basic tile variables for all subclasses of TileType
		 */
		private function parseBasicTypes( childList:XMLList, tileTypes:Vector.<TileType> ):void {
			
			var len:int = childList.length();
			var data:TileType;

			var nxt:int = tileTypes.length;
			tileTypes.length += len;

			for( var i:int = 0; i < len; i++ ) {

				data = new TileType();
				this.parseTileType( childList[i], data );
				this.insertTileType( tileTypes, data, nxt + i );

			} // for-loop
			
		} //
		
		private function parseClipTypes( childList:XMLList, tileTypes:Vector.<TileType> ):void {
			
			var len:int = childList.length();
			var data:ClipTileType;
			
			var nxt:int = tileTypes.length;
			tileTypes.length += len;
			
			for( var i:int = 0; i < len; i++ ) {
				
				data = new ClipTileType();
				this.parseClipTileType( childList[i], data );
				this.insertTileType( tileTypes, data, nxt + i );
				
			} // for-loop
			
		} //
		
		private function parseBuildingTypes( childList:XMLList, tileTypes:Vector.<TileType> ):void {
			
			var len:int = childList.length();
			var data:BuildingTileType;
			
			var nxt:int = tileTypes.length;
			tileTypes.length += len;
			
			for( var i:int = 0; i < len; i++ ) {
				
				data = new BuildingTileType();
				this.insertTileType( tileTypes, this.parseBuildingType( childList[i], data ), nxt+i );
				
			} //
			
		} // parseBuildingTypes()
		
		private function parseTerrainTypes( childList:XMLList, tileTypes:Vector.<TileType> ):void {
			
			var len:int = childList.length();
			var data:TerrainTileType;
			
			var nxt:int = tileTypes.length;
			tileTypes.length += len;
			
			for( var i:int = 0; i < len; i++ ) {
				
				data = new TerrainTileType();
				this.insertTileType( tileTypes, this.parseTerrainType( childList[i], data ), nxt+i );
				
			} //
			
		} // parseTerrainTypes()

		/*************************************************
		 * 
		 * INDIVIDUAL TILE TYPE PARSING
		 * 
		 *************************************************/

		public function parseTileType( node:XML, data:TileType ):void {
			
			if ( node.hasOwnProperty( "@type" ) ) {
				data.type = node.attribute( "type" );
			}
			if ( node.hasOwnProperty( "@name" ) ) {
				data.name = node.attribute( "name" );
			}
			if ( node.hasOwnProperty( "@drawHits" ) ) {
				data.drawHits = ( node.attribute( "drawHits" ) == "true" );
			} //
			if ( node.hasOwnProperty( "@drawBorder" ) ) {
				data.drawBorder = ( node.attribute( "drawBorder" ) == "true" );
			} //
			
			if ( node.hasOwnProperty("@fillHits" ) ) {
				data.fillHits = ( node.attribute("fillHits") == "true" );
			}
			
			if ( node.hasOwnProperty("@canMine") ) {
				data.allowMining = ( node.attribute("canMine") == "true" );
			} //
			if ( node.hasOwnProperty("@unbreakable") ) {
				data.unbreakable = true;
			} //

			if ( node.hasOwnProperty( "@canEdit" ) ) {
				data.allowEdit = ( node.attribute( "canEdit" ) == "true" );
			} //

			// Hit properties
			if ( node.hasOwnProperty( "hitCeilingColor" ) ) {
				data.hitCeilingColor = node.hitCeilingColor;
			}
			if ( node.hasOwnProperty("hitGroundColor" ) ) {
				data.hitGroundColor = node.hitGroundColor;
			}
			if ( node.hasOwnProperty("hitWallColor" ) ) {
				data.hitWallColor = node.hitWallColor;
			}
			
			if ( node.hasOwnProperty("@level") ) {
				data.level = node.attribute( "level" );
			}
			
			if ( node.hasOwnProperty( "@drawOrder" ) ) {
				data.drawOrder = node.attribute( "drawOrder" );
			}

			/*if ( node.hasOwnProperty( "@light" ) ) {
				data.light = node.@light;
			} else {
				data.light = 0;
			}*/

			// View Properties.
			/*if ( node.hasOwnProperty("viewFillColor" ) ) {
				data.viewFillColor = node.viewFillColor;
			}*/
			if ( node.hasOwnProperty("viewLineColor" ) ) {
				data.viewLineColor = node.viewLineColor;
			}
			
			if ( node.hasOwnProperty( "viewLineSize" ) ) {

				if ( this.useLayerProps ) {
					this.makeLayerProp( data, node.viewLineSize[0], "viewLineSize" );
				} else {
					data.viewLineSize = node.viewLineSize;
				}
				/*if ( node.hasOwnProperty( "viewLineSize" ) ) {
				data.viewLineSize = node.viewLineSize;
				} //*/

			}

			if ( node.hasOwnProperty("viewLineAlpha" )) {
				data.viewLineAlpha = node.viewLineAlpha;
			} //
			
			// file details and fills.
			if ( node.hasOwnProperty("viewBitmapFill" ) ) {
				data.viewSourceFile = node.viewBitmapFill;
			}

			if ( node.hasOwnProperty( "special" ) ) {
				this.parseSpecial( node.special[0], data );
			} //

			/*if ( node.hasOwnProperty("@hitLineSize") ) {
			data.hitLineSize = node.attribute( "hitLineSize" );
			}*/
			
			/*if ( node.hasOwnProperty( "require" ) ) {
			
			var child:XML = node.require[0];
			var amt:int = child.attribute( "amount" );
			
			if ( child.hasOwnProperty( "@resource" ) ) {
			
			this.gameData.tileRequirements.addRequirement( data, amt, child.attribute( "resource" ) );
			
			} else {
			
			this.gameData.tileRequirements.addRequirement( data, amt );
			
			} //
			
			} //*/

		} //

		public function parseClipTileType( node:XML, data:ClipTileType ):TileType {

			this.parseTileType( node, data );

			if ( node.hasOwnProperty( "clip" ) ) {
				data.viewSourceFile = node.clip;
			} //

			if ( node.hasOwnProperty( "cost" ) ) {
				data.cost = node.cost;
			} //

			/**
			 * note that the default hitGroundColor must be parsed FIRST in order for this to use default value.
			 */
			if ( node.hasOwnProperty( "hitFillColor" ) ) {
				data.hitFillColor = node.hitFillColor;
			} else {
				data.hitFillColor = data.hitGroundColor;
			} //
			
			return data;
			
		} //
		
		public function parseBuildingType( node:XML, data:BuildingTileType ):BuildingTileType {
			
			var child:XML;
			
			this.parseTileType( node, data );
			
			if ( node.hasOwnProperty("innerLineSize" ) ) {
				data.innerLineSize = node.innerLineSize;
			}
			if ( node.hasOwnProperty("outerLineSize" ) ) {
				data.outerLineSize = node.outerLineSize;
			}
			
			if ( node.hasOwnProperty("innerLineColor" ) ) {
				data.innerLineColor = node.innerLineColor;
			}
			if ( node.hasOwnProperty("outerLineColor" ) ) {
				data.outerLineColor = node.outerLineColor;
			}
			
			return data;
			
		} // parseBuildingType()
		
		public function parseTerrainType( node:XML, data:TerrainTileType ):TerrainTileType {
			
			// used to parse the viewHilite
			var child:XML;
			
			this.parseTileType( node, data );
			
			// setting the viewable hilight on the terrain.
			if ( node.hasOwnProperty( "viewHilite" ) ) {

				child = node.viewHilite[0];				// obnoxious as3 reference method.
				data.useHilite = true;

				if ( child.hasOwnProperty("alpha" ) ) {
					data.hiliteAlpha = child.alpha;
				}
				if ( child.hasOwnProperty("size" ) ) {
					data.hiliteSize = child.size;
				}
				if ( child.hasOwnProperty("angle" ) ) {
					data.hiliteAngle = child.angle;
				}

			} //

			if ( node.hasOwnProperty( "details" ) ) {
				data.details = this.parseDetails( node.details[0].child( "detail" ), data );
			} //

			return data;

		} // parseTerrainType()

		/*************************************************
		 * 
		 * UTILITY FUNCTIONS:
		 * 
		 *************************************************/

		/**
		 * New detail parser. Currently only one detail clip can be assigned to each side. They will override each other.
		 * The dictionary reference for a side detail is always LandTile.LEFT even though it works for both left and right.
		 * Perhaps in the future we can distinguish between left/right details. No reason to now.
		 */
		public function parseDetails( xmlList:XMLList, data:TerrainTileType ):Dictionary {
			
			var len:int = xmlList.length();
			var details:Dictionary = new Dictionary();
			//var details:Vector.<DetailType> = new Vector.<DetailType>( len, true );
			
			var node:XML;
			var sides:uint = 0;
			var xmlSides:String;			// sides as listed in the xml
			
			var detail:DetailType;
			
			for( var i:int = 0; i < len; i++ ) {
				
				node = xmlList[i];
				
				detail = new DetailType( node.attribute("url") );
				
				if ( node.hasOwnProperty( "@minDetails" ) ) {
					detail.minDetails = node.attribute( "minDetails" );
				} //
				if ( node.hasOwnProperty( "@maxDetails" ) ) {
					detail.maxDetails = node.attribute( "maxDetails" );
				} //
				
				sides = 0;
				// detail sides.
				xmlSides = node.attribute( "sides" );
				if ( xmlSides.indexOf( "top" ) != -1 ) {
					sides += LandTile.TOP;
					details[ LandTile.TOP ] = detail;
					
				}
				if ( xmlSides.indexOf( "sides" ) != -1 ) {
					sides += LandTile.LEFT + LandTile.RIGHT;
					details[ LandTile.LEFT ] = detail;
				}
				if ( xmlSides.indexOf( "bottom" ) != -1 ) {
					sides += LandTile.BOTTOM;
					details[ LandTile.BOTTOM ] = detail;
				}
				
				detail.sides = sides;
				
			} //
			
			return details;
			
		} //

		/**
		 * parse a tileType property that can be defined as layer-specific.
		 * this means the property stores separate values in the different layers
		 * that are used when that layer renders.
		 * 
		 * it's a bit complicated and not ideal but is used to change the visual appearance
		 * of tiles in the background.
		 * 
		 * Property currently must be a number or string. boolean needs special treatment.
		 */
		private function makeLayerProp( tileType:TileType, node:XML, varName:String ):void {
			
			if ( node.hasOwnProperty( "@fg" ) ) {

				this.gameData.getFGLayer().addLayerProp( tileType, varName, node.attribute( "fg" ) );

			} //
			if ( node.hasOwnProperty( "@bg" ) ) {
				
				this.gameData.getBGLayer().addLayerProp( tileType, varName, node.attribute( "bg" ) );

			} //

			tileType[ varName ] = node;

			
		} //

		/**
		 * insert index is only the starting index. the tile type will be moved down until it reaches
		 * its correct draw order - highest draw order at index 0. this function assumes the current list
		 * is already sorted.
		 */
		protected function insertTileType( tileTypes:Vector.<TileType>, type:TileType, insertIndex:int ):void {
			
			var nextType:TileType;
			
			for( var i:int = insertIndex-1; i >= 0; i-- ) {
				
				nextType = tileTypes[i];
				if ( nextType.drawOrder > type.drawOrder ) {
					
					// type cannot be moved down any further. insert it at the current insertIndex.
					break;
					
				} else {
					
					tileTypes[insertIndex] = nextType;
					insertIndex--;
					
				} //
				
			} // for-loop.
			
			tileTypes[ insertIndex ] = type;
			
		} //

	} // class
	
} // package