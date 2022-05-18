package game.scenes.lands.shared.tileLib.painters {

	/**
	 * This is the same as OutlinePainter but optimized to draw hits only - no visuals.
	 * Currently used for rendering the border tiles of decals.
	 */

	import flash.display.Graphics;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class OutlineHitPainter extends BasePainter {

		//private var curTileType:TileType;
		private var hitGraphics:Graphics;

		public function OutlineHitPainter( rc:RenderContext ) {

			super( rc );

			// the whole point of this class is to draw hits.
			this._drawHits = true;

		} //

		public function startPaintBatch():void {

			//this.curTileType = null;
			this.hitGraphics = this.renderContext.hitGraphics;
			this.hitGraphics.clear();

		} // startPaintBatch()

		/**
		 * entire batch of painting is complete.
		 */
		public function endPaintBatch():void {

			this.renderContext.hitBitmap.draw( this.renderContext.hitPane, this.renderContext.hitMatrix, null, null, this.renderContext.hitPaintRect );

		} //

		public function startStroke( startX:Number, startY:Number ):void {

			this.hitGraphics.moveTo( startX, startY );

		} //

		public function lineStroke( nextX:Number, nextY:Number, tileBorders:uint, tileType:TileType ):void {

			if ( tileBorders & LandTile.BOTTOM && tileType.hitCeilingColor != 0 ) {

				this.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitCeilingColor );
				this.hitGraphics.lineTo( nextX, nextY );

			} else if ( tileBorders & ( LandTile.LEFT | LandTile.RIGHT ) && tileType.hitWallColor != 0 ) {
				
				this.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitWallColor );
				this.hitGraphics.lineTo( nextX, nextY );

			} else if ( tileType.hitGroundColor != 0 && tileBorders == LandTile.TOP ) {

				this.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitGroundColor );
				this.hitGraphics.lineTo( nextX, nextY );

			} else {
				this.hitGraphics.moveTo( nextX, nextY );
			} //

		} // lineStroke()

	} // class

} // package