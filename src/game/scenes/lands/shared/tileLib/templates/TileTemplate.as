package game.scenes.lands.shared.tileLib.templates {

	/**
	 * a TileTemplate needs to allow tiles defined for every tileMap in the level.
	 * for instance, the template could include the tiles to place in the fg terrain map,
	 * the bg building map, the fg tree map, etc.
	 * 
	 * this is done by including a dictionary of sub-maps that are included in the template.
	 */

	/**
	 * notes: wanted to use 'TemplateGrids' for simple storage but they won't render right.
	 * Maybe use templateGrid for the base storage and transfer to a tileMap when its
	 * time to render.
	 */
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.map.map.Map;

	public class TileTemplate {

		/**
		 * width,height in screen pixels.
		 */
		private var _width:int;
		private var _height:int;

		/**
		 * might not use biome. probably not...
		 */
		//public var biome:String;

		// tileMap objects of the template indexed by tileMap name.
		private var grids:Dictionary;

		/**
		 * number of rows to offset from baseGround.
		 * only used for automated template generation.
		 */
		public var rowOffset:int = 0;

		public function TileTemplate() {
		} //

		public function createTemplate( maps:Dictionary, startX:int, startY:int, width:int, height:int, specials:Dictionary ):void {

			this.grids = new Dictionary();

			this._width = width;
			this._height = height;

			var tsize:int;

			var newMap:TileMap;

			for each ( var map:TileMap in maps ) {

				tsize = map.tileSize;

				newMap = this.makeTemplateGrid( map, startY/tsize, Math.ceil( (startY+height)/tsize )-1, startX/tsize, Math.ceil( (startX+width)/tsize ) - 1 );
				if ( newMap == null ) {
					continue;
				} else if ( newMap.tileSet.setType == "decal" ) {
					// ^ note that the new map won't have a tileSet since it's just being stored as a template. it doesn't need that information.
					this.removeTreasures( newMap, specials );
				}

			} // end for-loop.

		} //

		/**
		 * called when template is loaded from file or database data.
		 */
		public function setTemplateData( template_grids:Dictionary, twidth:int, theight:int ):void {

			this.grids = template_grids;
			this._width = twidth;
			this._height = theight;

		} //

		public function getGrids():Dictionary {
			
			return this.grids;
			
		} //

		/**
		 * paste a template onto the world.
		 * caller must redraw the appropriate layers afterwards.
		 */
		public function pasteTemplate( maps:Dictionary, startX:int, startY:int ):void {

			var tempMap:TileMap;			// map from the template.

			if ( startX < 0 ) {
				startX = 0;
			}
			if ( startY < 0 ) {
				startY = 0;
			}

			for each ( var map:TileMap in maps ) {

				tempMap = this.grids[ map.name ];
				if ( tempMap == null ) {
					continue;					// template doesn't use this tileMap
				}

				if ( map.tileSet.setType == "decal" ) {
					tempMap.copyToWithJiggle( map, startY/map.tileSize, startX/map.tileSize );
				} else {
					tempMap.copyTo( map, startY/map.tileSize, startX/map.tileSize );
				}

			} // end for-loop.

		} //

		/**
		 * older version using templateGrids
		 */
		/*public function pasteTemplate( maps:Dictionary, startX:int, startY:int ):void {
			
			var grid:TemplateGrid;
			
			for each ( var map:TileMap in maps ) {
				
				grid = this.grids[ map.name ];
				if ( grid == null ) {
					continue;
				}
				
				grid.copyTo( map, startY/map.tileSize, startX/map.tileSize );
				
			} // end for-loop.
			
		} */

		private function makeTemplateGrid( map:TileMap, minRow:int, maxRow:int, minCol:int, maxCol:int ):TileMap {

			// note that minRow,minCol cant be less than zero as long as StartX,startY are > 0
			if ( maxRow >= map.rows ) {
				maxRow = map.rows-1;
			} //
			if ( maxCol >= map.cols ) {
				maxCol = map.cols-1;
			}

			if ( !nonEmptyInRect( map, minRow, maxRow, minCol, maxCol ) ) {
				return null;				// nothing in map at this location.
			}

			var grid:TileMap = new TileMap( map.name );//new TemplateGrid( maxRow - minRow + 1, maxCol - minCol + 1 );
			grid.tileSet = map.tileSet;
			grid.init( maxRow - minRow + 1, maxCol - minCol + 1 );

			grid.tileSize = map.tileSize;

			// copy the map tiles into the grid tiles.
			if ( map.tileSet.setType == "decal" ) {

				grid.copyFromDecal( map, minRow, minCol );

			} else {

				grid.copyFrom( map, minRow, minCol );
			}
			

			this.grids[ map.name ] = grid;

			return grid;

		} //

		private function removeTreasures( grid:TileMap, specials:Dictionary ):void {

			// note: also need to remove any "treasures"
			// haven't gotten to this yet.

			var tiles:Vector.<Vector.<LandTile>> = grid.getTiles();
			var tile:LandTile;
			var type:ClipTileType;

			var special:TileTypeSpecial;

			for( var r:int = tiles.length-1; r >=0; r-- ) {

				for( var c:int = grid.cols-1; c >= 0; c-- ) {

					tile = tiles[r][c];
					if ( tile.type == 0 ) {
						continue;
					}

					type = grid.getType( tile ) as ClipTileType;

					if ( type.cost > 1 ) {
						tile.type = 0;
					} else {

						// check that there is no associated treasure.
						special = specials[ type ];
						if ( special != null && (special.bonus > 0 || special.refund) ) {
							tile.type = 0;
						}

					} //

				} // for-loop.

			} // for-loop.

		} //

		/**
		 * returns true if any tile in the region has a non-zero type.
		 * the ranges given must be valid for the tile map.
		 */
		private function nonEmptyInRect( tMap:TileMap, minRow:int, maxRow:int, minCol:int, maxCol:int ):Boolean {

			for( var r:int = minRow; r <= maxRow; r++ ) {

				for( var c:int = minCol; c <= maxCol; c++ ) {

					if ( tMap.getTileType( r, c ) != 0 ) {
						return true;
					}

				} //

			} // for-loop.

			return false;

		} // ()

		public function get width():int {
			return this._width;
		}

		public function get height():int {
			return this._height;
		}

	} // class

} // package