package game.scenes.lands.shared.tileLib.painters {

	/**
	 * This is just like TerrainPainter.as but without any fill graphics - so its slightly more effiicent.
	 * Optional hits.
	 * Eventually maybe this class should be merged with LandPainter?
	 * 
	 * Simpler to do it this way for now.
	 * 
	 */

	import flash.geom.Point;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.tileTypes.TerrainTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class OutlinePainter extends BasePainter {

		/**
		 * Tracking prev,next draw points to determine hit colors and view effects.
		 * Calculate drawing slopes, etc.
		 */
		private var prevAnchor:Point;
		private var nextAnchor:Point;

		public var strokeSize:int = 4;

		private var curTileType:TileType;

		public function OutlinePainter( rc:RenderContext ) {

			super( rc );

			this.initPaintVars();

		} //

		/**
		 * All the views, rects, points, graphics needed for drawing.
		 */
		private function initPaintVars():void {

			this.prevAnchor = new Point();
			this.nextAnchor = new Point();

		} //

		/**
		 * borders is the OR-d borders of both tiles. since each tile has a single border on a draw-curve,
		 * each tile can be checked for its border-type.
		 */
		private function computeLineColors( tileType:TerrainTileType, borders:uint, ctrlPt:Point ):void {

			var slope:Number = this.nextAnchor.x - this.prevAnchor.x;
			if ( borders & LandTile.BOTTOM ) {

				// upside-down land or slope divide by zero.
				this.renderContext.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitCeilingColor );


			} else if ( Math.abs(slope) < 1 ) {

				// the change in x between tiles is very small, so the slope must be nearly vertical.
				// this means the line is effectively a wall.
				this.renderContext.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitWallColor );

			} else {

				slope = ( this.nextAnchor.y - this.prevAnchor.y ) / slope;
				if ( Math.abs(slope) < tileType.WallSlope ) {

					this.renderContext.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitGroundColor );

				} else {
					this.renderContext.hitGraphics.lineStyle( tileType.hitLineSize, tileType.hitWallColor );
				} //

			} //

		} //

		public function startPaintBatch():void {

			this.renderContext.viewStrokeGraphics.clear();
			this.curTileType = null;

			if ( this._drawHits ) {

				this.renderContext.hitGraphics.clear();

			}

		} // startPaintBatch()

		public function endTerrainPaint():void {

			this.renderContext.viewBitmap.draw( this.renderContext.viewStrokePane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );
			this.renderContext.viewStrokeGraphics.clear();

		} // endTerrainPaint()

		/**
		 * entire batch of painting is complete.
		 */
		public function endPaintBatch():void {

			if ( this._drawHits ) {
				this.renderContext.hitBitmap.draw( this.renderContext.hitPane, this.renderContext.hitMatrix, null, null, this.renderContext.hitPaintRect );
			}

		} //

		public function startStroke( startX:Number, startY:Number ):void {

			this.prevAnchor.x = startX;
			this.prevAnchor.y = startY;

			this.renderContext.viewStrokeGraphics.moveTo( startX, startY );

			if ( this._drawHits ) {
				this.renderContext.hitGraphics.moveTo( startX, startY );
			}

		} //

		public function curveStroke( ctrlPt:Point, nextX:Number, nextY:Number, tileBorders:uint, tileType:TileType ):void {

			if ( tileType != this.curTileType ) {

				this.renderContext.viewStrokeGraphics.lineStyle( this.strokeSize, tileType.viewLineColor, tileType.viewLineAlpha );

				this.curTileType = tileType;

			} //

			this.renderContext.viewStrokeGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );

			//this.nextAnchor.x = nextX;
			//this.nextAnchor.y = nextY;
			//this.computeLineColors( tileBorders, ctrlPt );
			if ( this._drawHits ) {
				this.renderContext.hitGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );
			}

			// save the anchor used to compute the slope for the next curve we draw.
			this.prevAnchor.x = nextX;
			this.prevAnchor.y = nextY;

		} //

		public function lineStroke( nextX:Number, nextY:Number, tileBorders:uint, tileType:TileType ):void {

			if ( tileType != this.curTileType ) {

				this.renderContext.viewStrokeGraphics.lineStyle( this.strokeSize, tileType.viewLineColor, tileType.viewLineAlpha );
				this.curTileType = tileType;

			} //

			this.renderContext.viewStrokeGraphics.lineTo( nextX, nextY );

			if ( this._drawHits ) {
				//this.computeLineColors( tileBorders, ctrlPt );
				this.renderContext.hitGraphics.lineTo( nextX, nextY );
			}

			// probably don't really need this, but it allows you to combine straight lines with curve lines.
			// why you would ever do this, I don't know.
			this.prevAnchor.x = nextX;
			this.prevAnchor.y = nextY;

		} // lineStroke()

	} // class

} // package