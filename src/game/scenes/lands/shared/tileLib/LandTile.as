package game.scenes.lands.shared.tileLib {

	public class LandTile {

		/**
		 * Different terrain types for a filled tile. All should be powers of 2.
		 * EMPTY will always be used for a cleared/empty tile.
		 * FILLED is being phased out in favor of xml/data defined terrain types.
		 */
		static public const EMPTY:int = 0;
		static public const FILLED:int = 1;

		/**
		 * Tile border directions.
		 * 
		 * For each non-empty tile, tile.border is set to the sum of all borders the tile shares
		 * with tiles of a different type.
		 * for example:
		 * tile.border = Tile.TOP + Tile.RIGHT indicates that the tiles directly above and to the right
		 * have different tile types. This information can then be used to draw the outlines of regions.
		 */
		static public const TOP:uint = 1;
		static public const RIGHT:uint = 2;
		static public const BOTTOM:uint = 4;
		static public const LEFT:uint = 8;

		/**
		 * when drawing terrain, some borders are merely visual - such as at the seam between dirt and rock,
		 * or grass and dirt. a border has to be drawn, but the hits are drawn differently. (they arent't affected by the border )
		 */
		static public const VISUAL_BORDER:uint = 16;

		static public const BORDERS_ALL:uint = 15;

		/**
		 * The type of the tile - taken from the tilemap's current tile set.
		 */
		public var type:uint;

		/**
		 * This is just a variable to make it easier to draw the borders of a region of tiles.
		 * The variable indicates which sides of a tile have already been drawn.
		 */
		public var drawnBorders:uint = 0;

		/**
		 * Can be used by tile-search algorithms to mark that a tile has already been visited
		 * by the search.
		 * Instead of clearing all search_ids for every Tile, use the tileMap's cur_search
		 * variable and check that the search_id of a tile is less than the cur_search. This
		 * means the tile hasn't been visited by that search. Remember to increment tileMap's 
		 * cur_search, and never perform two searches simultaneously on the same TileMap.
		 * 
		 */
		public var search_id:uint = 0;

		public var row:int;
		public var col:int;

		/**
		 * Numbers that can be added to the points of a tile while drawing to make
		 * each tile look a little different. Since tiles need to appear the same every
		 * time they're loaded, the jiggle factors are stored with the TileMap information.
		 * In ClipTileTypes, the data factors are used to define the tile-offsets of the
		 * decal clip when drawn into this tile.
		 */
		public var tileDataX:Number;
		public var tileDataY:Number;

		public function LandTile( row:int=0, col:int=0  ) {

			this.row = row;
			this.col = col;

			this.type = 0;

		} //

		// create new random jiggle values.
		public function jiggle( amt:Number ):void {

			this.tileDataX = -amt + Math.round( 2*amt*Math.random() );
			this.tileDataY = -amt + Math.round( 2*amt*Math.random() );

		} //

	} // End Tile
	
} // End package