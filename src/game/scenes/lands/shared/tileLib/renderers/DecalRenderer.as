package game.scenes.lands.shared.tileLib.renderers {

	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;

	/**
	 * TileClipRenderer fills every tile with a single frame from a source movie clip.
	 */
	public class DecalRenderer extends MapRenderer {

		private var drawHits:Boolean = false;

		/**
		 * when decals are rendered you need to offset them by a matrix that combines the layer's viewMatrix
		 * with the row,col offset of the decal.
		 */
		private var clipMatrix:Matrix;

		/**
		 * area of the bitmap that will actually be filled by a single decal tile.
		 */
		private var clipRect:Rectangle;

		/**
		 * same as clipMatrix but scaled by the hit bitmap scaling factor.
		 */
		private var hitMatrix:Matrix;
		private var hitRect:Rectangle;

		private var mapOffsetX:int;
		private var mapOffsetY:int;

		// color transforms performs the color change from the painted clip to the hit color for this tile.
		private var hitColorTrans:ColorTransform;

		/**
		 * by tracking the x,y offsets while rendering a grid area, this reduces the number of multiplation operations
		 * and results in a real measurable improvement in rendering - about 10ms for a full scene with an average number of decals.
		 */
		//private var baseXOffset:int;
		//private var baseYOffset:int;

		public function DecalRenderer( tmap:TileMap, rc:RenderContext ) {

			super( tmap );

			this.clipMatrix = new Matrix();
			this.clipRect = new Rectangle( 0, 0, this.tileSize, this.tileSize );

			if ( rc.drawHits ) {

				this.drawHits = tmap.drawHits;

				if ( this.drawHits ) {
					// these variables are separate from the render context because they get special offsets for each decal.
					this.hitColorTrans = new ColorTransform( 0, 0, 0, 1 );
					this.hitMatrix = new Matrix( 0.5, 0, 0, 0.5 );
					this.hitRect = new Rectangle( 0, 0, this.tileSize*0.5, this.tileSize*0.5 );
				}

			} else {
				this.drawHits = false;
			}

			this.setRenderContext( rc );

		} // constructor()

		override public function render():void {

			//var t1:Number = getTimer();

			this.renderRange( 0, this.tileMap.rows-1, 0, this.tileMap.cols-1 );

			//var t2:Number = getTimer();
			//trace( "DECAL RENDER TIME: " + (t2-t1) );

		} //

		override public function renderArea( eraseRect:Rectangle ):void {

			// unlike most renderers, the decal renderer does not need to render additional tiles
			// outside its bounds, since decals are guaranteed not to draw outside tile boundaries.
			var minRow:int = Math.floor( eraseRect.y / this.tileSize );
			var maxRow:int = Math.floor( eraseRect.bottom / this.tileSize );
			var minCol:int = Math.floor( eraseRect.x / this.tileSize );
			var maxCol:int = Math.floor( eraseRect.right / this.tileSize );

			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( maxRow > this.tileMap.rows ) {
				maxRow = this.tileMap.rows;
			} //
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol > this.tileMap.cols ) {
				maxCol = this.tileMap.cols;
			} //

			this.renderRange( minRow, maxRow, minCol, maxCol );

		} //

		private function renderRange( minRow:int, maxRow:int, minCol:int, maxCol:int ):void {

			var tile:LandTile;
			var clipType:ClipTileType;

			var baseYOffset:int = minRow*this.tileSize;
			var baseXOffset:int;

			for( var r:int = minRow; r < maxRow; r++ ) {

				baseXOffset = this.mapOffsetX + ( minCol - 1 )*this.tileSize;		// -1 because we're just going to add the tileSize back in the loop.

				for( var c:int = minCol; c < maxCol; c++ ) {

					baseXOffset += this.tileSize;

					tile = this.tileMap.getTile( r, c );
					if ( tile.type == 0 ) {
						continue;
					}

					clipType = this.tileSet.getTypeByCode( tile.type ) as ClipTileType;
					if ( clipType == null ) {
						continue;
					}

					// draw teh stupid clip.
					this.clipRect.x = this.clipMatrix.tx = baseXOffset;
					this.clipRect.y = this.clipMatrix.ty = baseYOffset;
					this.drawTileClip( tile, clipType );

				} // end for-loop.

				baseYOffset += this.tileSize;

			} // end for-loop.

		} // renderRange()

		private function drawTileClip( tile:LandTile, clipType:ClipTileType ):void {

			// correct for the offset within the decal -> which can cover several tiles.
			// IMPORTANT NOTE: jiggleX < 0 means flip the decal. since 0 cannot indicate a flip, column offsets have an extra -1
			// i.e. -1 jiggle means use the index-0 column in reverse, -2 means use the index-1 column in reverse.
			if ( tile.tileDataX < 0 ) {
				this.clipMatrix.a = -1;
			} else {
				this.clipMatrix.a = 1;
			}

			this.clipMatrix.tx -= tile.tileDataX*this.tileSize;
			this.clipMatrix.ty -= tile.tileDataY*this.tileSize;

			this.renderContext.viewBitmap.draw( clipType.clip, this.clipMatrix, null, null, this.clipRect );

			if ( this.drawHits && clipType.drawHits && clipType.fillHits ) {

				this.hitMatrix.a = this.clipMatrix.a/2;
				this.hitMatrix.tx = this.clipMatrix.tx/2;
				this.hitMatrix.ty = this.clipMatrix.ty/2;

				this.hitRect.setTo( this.clipRect.x/2, this.clipRect.y/2, this.clipRect.width/2, this.clipRect.height/2 );

				this.hitColorTrans.color = clipType.hitFillColor;
				this.renderContext.hitBitmap.draw( clipType.clip, this.hitMatrix, this.hitColorTrans, null, this.hitRect );

			} //

		} //

		override public function setRenderContext( rc:RenderContext ):void {
			
			this.renderContext = rc;

			this.mapOffsetX = rc.viewMatrix.tx;
			//this.mapOffsetY = rc.viewMatrix.ty;

			if ( this.hitMatrix && rc.drawHits ) {
				this.hitMatrix.copyFrom( rc.hitMatrix );
			}

		} //

	} // class

} // package