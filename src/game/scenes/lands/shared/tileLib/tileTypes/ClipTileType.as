package game.scenes.lands.shared.tileLib.tileTypes {

	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;

	/**
	 * 
	 * this tile type define a movieclip that is painted directly to the view bitmap.
	 * the jiggleX, jiggleY of the LandTile can define the offset of the clip when its being drawn.
	 * these offsets must be saved and loaded with the tileMap.
	 * 
	 */
	public class ClipTileType extends TileType {

		/**
		 * when decals are drawn, the individual decal tiles are checked for empty squares.
		 * empty decal squares aren't placed in a tile map, but you need a bitmap to test this.
		 * its better to just use one bitmap than to make a new one for every decal.
		 */
		static public var TestBitmap:BitmapData;

		// to prevent duplicate loading.
		public var loading:Boolean = false;
		public var clip:MovieClip;

		/**
		 * decals can specify a cost other than the default cost of '1' per tile.
		 */
		public var cost:int = 0;

		/**
		 * defaults to hitGroundColor if not defined.
		 */
		public var hitFillColor:uint;

		//public var minFrame:int = 0;
		//public var maxFrame:int = -1;

		public function ClipTileType() {
		} //

		override public function destroy():void {

			super.destroy();

			this.clip = null;
			
		} //

		override public function get image():IBitmapDrawable {
			return this.clip;
		}

		/**
		 * clear this decal from the given tileMap -- only clear tiles having the same tileType.
		 */
		public function clearDecal( tileMap:TileMap, clearRect:Rectangle ):void {

			var decalTileSize:int = tileMap.tileSize;

			var dropCol:int = Math.floor( clearRect.x / decalTileSize );
			var dropRow:int = Math.floor( clearRect.y / decalTileSize );

			tileMap.clearTypeRange( dropRow, dropCol,
				dropRow + ( clearRect.height / decalTileSize ),
				dropCol + ( clearRect.width / decalTileSize ), this.type );

		} // clearDecal()

		public function dropDecal( tileMap:TileMap, decalRect:Rectangle ):void {

			var decalTileSize:int = tileMap.tileSize;

			var dropCol:int = Math.floor( decalRect.x / decalTileSize );
			if ( dropCol < 0 ) {
				dropCol = 0;
			}
			var dropRow:int = Math.floor( decalRect.y / decalTileSize );
			if ( dropRow < 0 ) {
				dropRow = 0;
			}

			var decalCols:int = decalRect.width / decalTileSize;
			// make sure the decal doesn't go off the edge of the tilemap.
			if ( dropCol + decalCols > tileMap.cols ) {
				decalCols = tileMap.cols - dropCol;
			} //

			var decalRows:int = decalRect.height / decalTileSize;
			if ( dropRow + decalRows > tileMap.rows ) {
				decalRows = tileMap.rows - dropRow;
			} //

			// user just dropped a decal somewhere. set the decal tiles in the current tileMap.
			var decalClip:MovieClip = this.clip;

			var bm:BitmapData = TestBitmap;
			var mat:Matrix = new Matrix();
			mat.a = mat.d = bm.width / decalTileSize;
			// the tile size for the matrix is the size of the test bitmap.
			decalTileSize = bm.width;

			var tile:LandTile;

			mat.ty = 0;
			for( var r:int = 0; r < decalRows; r++ ) {

				mat.tx = 0;

				for( var c:int = 0; c < decalCols; c++ ) {
					
					// check that the current decal square is non-empty.
					//trace( mat.tx + ", " + mat.ty );
					bm.fillRect( bm.rect, 0 );
					bm.draw( decalClip, mat );

					mat.tx -= decalTileSize;

					var visRect:Rectangle = bm.getColorBoundsRect( 0xFF000000, 0, false );
					if ( visRect.width == 0 || visRect.height == 0 ) {
						continue;
					}
					
					tile = tileMap.getTile( dropRow + r, dropCol + c );
					tile.type = this.type;
					//trace( "SETTING TYPE: " + tile.type );
					//trace( "ROW: " + tile.row + ", col: " + tile.col );

					// the tile jiggle stores the row,col offset of the decal, since a single decal
					// can span several tiles.
					tile.tileDataX = c;
					tile.tileDataY = r;

				} //

				mat.ty -= decalTileSize;

			} // for-loop.
			
		} //

		/**
		 * 'this' is the tile type being swapped - though the information also exists in the swapTile TileSelector.
		 * 
		 * tileLayer is the layer where the tile exists - so it can be re-rendered.
		 * 
		 * swapTile ONLY needs to have its 'tile' and 'tileMap' defined. the tileType MUST BE a ClipTileType.
		 * 
		 * swapId is the id of the new ClipTileType that the old type is being replaced with.
		 */
		public function swapClipTile( tileLayer:TileLayer, swapTile:TileSelector, swapId:uint, offsetX:int=0, offsetY:int=0):void {

			var tileMap:TileMap = swapTile.tileMap;

			//var oldType:ClipTileType = swapTile.tileType as ClipTileType;
			var newType:ClipTileType = tileMap.tileSet.getTypeByCode( swapId ) as ClipTileType;

			var tile:LandTile = swapTile.tile;
			var baseCol:int = tile.col - tile.tileDataX;
			var baseRow:int = tile.row - tile.tileDataY;

			var decalRect:Rectangle = new Rectangle( baseCol*tileMap.tileSize, baseRow*tileMap.tileSize,
				this.clip.root.loaderInfo.width, this.clip.root.loaderInfo.height );
			
			if ( tile.tileDataX >= 0 ) {
				
				// all the old area has to be cleared, since the new decal might have holes in it, so even spaces
				// that seem to be covered by the new area, might not really be.
				this.clearDecal( tileMap, decalRect );

				if ( newType != null ) {
					decalRect.width = newType.clip.root.loaderInfo.width;
					decalRect.height = newType.clip.root.loaderInfo.height;
				
					decalRect.x += offsetX*tileMap.tileSize;
					decalRect.y += offsetY*tileMap.tileSize;

					newType.dropDecal( tileMap, decalRect );
				}
				
			} else {
				
				decalRect.x -= decalRect.width;
				
				this.clearDecal( tileMap, decalRect );

				if ( newType != null ) {
					decalRect.width = newType.clip.root.loaderInfo.width;
					decalRect.height = newType.clip.root.loaderInfo.height;
				
					// ugh. align the right-side of the decals then move backwards by the swap-offset.
					decalRect.x += ( this.clip.root.loaderInfo.width - decalRect.width - offsetX*tileMap.tileSize );
					decalRect.y += offsetY*tileMap.tileSize;
				
					newType.dropFlippedDecal( tileMap, decalRect );
				}
				
			}

			// probaby should take the larger of the old type rect, new type rect here, to make sure everything gets rendered right.
			tileLayer.renderArea( decalRect );
		}

		public function dropFlippedDecal( tileMap:TileMap, decalRect:Rectangle ):void {
			
			var decalTileSize:int = tileMap.tileSize;

			// not using the focus tile here because it could be null.
			var dropCol:int = Math.floor( decalRect.x / decalTileSize );
			if ( dropCol < 0 ) {
				dropCol = 0;
			}
			var dropRow:int = Math.floor( decalRect.y / decalTileSize );
			if ( dropRow < 0 ) {
				dropRow = 0;
			}

			var decalCols:int = decalRect.width / decalTileSize;
			// make sure the decal doesn't go off the edge of the tilemap. c here starts at the max column offset.
			var c:int = decalCols-1;
			if ( dropCol + c >= tileMap.cols ) {
				c = tileMap.cols - dropCol - 1;
			} //
			
			var decalRows:int = decalRect.height / decalTileSize;
			if ( dropRow + decalRows > tileMap.rows ) {
				decalRows = tileMap.rows - dropRow;
			} //
			
			// user just dropped a decal somewhere. set the decal tiles in the current tileMap.
			var decalClip:MovieClip = this.clip;

			var bm:BitmapData = TestBitmap;
			var mat:Matrix = new Matrix();
			mat.a = mat.d = bm.width / decalTileSize;
			// the tile size for the matrix is the size of the test bitmap.
			decalTileSize = bm.width;

			var tile:LandTile;
			
			// c has to start at a decalCol clipped to tileMap.cols.
			for( ; c >= 0; c-- ) {
				
				mat.tx = -( decalCols-1 - c )*decalTileSize;
				
				for( var r:int = 0; r < decalRows; r++ ) {
					
					mat.ty = -r*decalTileSize;			// row doesn't flip.
					
					//trace( mat.tx + ", " + mat.ty );
					bm.fillRect( bm.rect, 0 );
					bm.draw( decalClip, mat );
					var visRect:Rectangle = bm.getColorBoundsRect( 0xFF000000, 0, false );
					if ( visRect.width == 0 || visRect.height == 0 ) {
						//trace( "EMPTY" );
						continue;
					}
					
					tile = tileMap.getTile( dropRow + r, dropCol + c );
					tile.type = this.type;
					
					// the tile jiggle stores the row,col offset of the decal, since a single decal
					// can span several tiles.
					// IMPORTANT: the jiggle can't be 0 because then we wouldn't know it was a flipped tile.
					// instead subtract an extra column to keep the jiggle negative
					tile.tileDataX = -(decalCols - c);
					tile.tileDataY = r;
					
				} //
				
			} //
			
		} //

	} // class

} // package