package game.scenes.lands.shared.tileLib.painters {

	/**
	 * Border painter is like OutlinePainter but actually draws a thick border which itself has an outline.
	 * this is used for the borders of buildings.
	 */

	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import game.scenes.lands.shared.tileLib.tileTypes.BuildingTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class BorderPainter extends BasePainter {

		private var outStrokePane:Shape;
		private var outStrokeGraphics:Graphics;

		private var inStrokePane:Shape;
		private var inStrokeGraphics:Graphics;

		/**
		 * used to avoid changing the line styles in the middle of line drawing,
		 * which can make the image look wonky.
		 */
		private var lastTileType:TileType;

		/**
		 * This is where the hits are drawn before being copied to the hit bitmap.
		 */
		private var hitPane:Shape;
		private var hitGraphics:Graphics;
		private var hitMatrix:Matrix;

		/**
		 * The area of the bitmaps currently being painted.
		 */
		//private var hitPaintRect:Rectangle;

		/**
		 * Tracking prev,next draw points to determine hit colors and view effects.
		 * Calculate drawing slopes, etc.
		 */
		private var prevAnchor:Point;
		private var nextAnchor:Point;

		public var innerLineSize:Number = 7;
		// outer stroke size must be larger than inner and draw first, so its not covered.
		public var outerLineSize:Number = 10;
		public var outerLineColor:int = 0x000000;

		public function BorderPainter( rc:RenderContext ) {

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

		public function startPaintBatch():void {

			this.inStrokeGraphics.clear();
			this.outStrokeGraphics.clear();

			if ( this._drawHits ) {

				this.hitGraphics.clear();

			} //

		} // startPaintBatch()

		/**
		 * entire batch of painting is complete.
		 */
		public function endPaintBatch():void {

			this.renderContext.viewBitmap.draw( this.outStrokePane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );
			this.renderContext.viewBitmap.draw( this.inStrokePane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );

			if ( this._drawHits ) {
				this.renderContext.hitBitmap.draw( this.hitPane, this.hitMatrix, null, null, this.renderContext.hitPaintRect );
			}

		} //

		public function startStroke( startX:Number, startY:Number ):void {

			this.lastTileType = null;

			//this.prevAnchor.x = startX;
			//this.prevAnchor.y = startY;

			if ( this._drawHits ) {
				this.hitGraphics.moveTo( startX, startY );
			}

			this.outStrokeGraphics.moveTo( startX, startY );
			this.inStrokeGraphics.moveTo( startX, startY );

		} //

		public function curveStroke( ctrlPt:Point, nextX:Number, nextY:Number, tileBorders:uint, tileType:BuildingTileType ):void {

			if ( this.lastTileType != tileType ) {

				// keep the stroke all one color for now.
				if ( tileType.outerLineSize >= 0 ) {
					this.outStrokeGraphics.lineStyle( tileType.outerLineSize, tileType.outerLineColor, 1 );
				} else {
					this.outStrokeGraphics.lineStyle( this.outerLineSize, tileType.outerLineColor, 1 );
				}

				if ( tileType.innerLineSize >= 0 ) {
					this.inStrokeGraphics.lineStyle( tileType.innerLineSize, tileType.innerLineColor, 1 );
				} else {
					this.inStrokeGraphics.lineStyle( this.innerLineSize, tileType.innerLineColor, 1 );
				}

				this.lastTileType = tileType;

			} //

			if ( tileType.drawBorder ) {

				this.outStrokeGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );
				this.inStrokeGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );

			} else {

				this.outStrokeGraphics.moveTo( nextX, nextY );
				this.inStrokeGraphics.moveTo( nextX, nextY );

			} //

			//this.nextAnchor.x = nextX;
			//this.nextAnchor.y = nextY;

			if ( this._drawHits ) {
				//this.computeLineColors( tileBorders, ctrlPt );
				this.hitGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );
			}

			// save the anchor used to compute the slope for the next curve we draw.
			//this.prevAnchor.x = nextX;
			//this.prevAnchor.y = nextY;

		} //

		public function lineStroke( nextX:Number, nextY:Number, tileBorders:uint, tileType:BuildingTileType ):void {

			if ( tileType != this.lastTileType ) {

				if ( tileType.outerLineSize >= 0 ) {
					this.outStrokeGraphics.lineStyle( tileType.outerLineSize, tileType.outerLineColor, 1, false, "normal", CapsStyle.SQUARE );
				} else {
					this.outStrokeGraphics.lineStyle( this.outerLineSize, tileType.outerLineColor, 1, false, "normal", CapsStyle.SQUARE );
				}

				if ( tileType.innerLineSize >= 0 ) {
					this.inStrokeGraphics.lineStyle( tileType.innerLineSize, tileType.innerLineColor, 1, false, "normal", CapsStyle.SQUARE );
				} else {	
					this.inStrokeGraphics.lineStyle( this.innerLineSize, tileType.innerLineColor, 1, false, "normal", CapsStyle.SQUARE );
				}

				this.lastTileType = tileType;

			} //

			if ( tileType.drawBorder ) {

				this.outStrokeGraphics.lineTo( nextX, nextY );	
				this.inStrokeGraphics.lineTo( nextX, nextY );

			} else {

				this.outStrokeGraphics.moveTo( nextX, nextY );
				this.inStrokeGraphics.moveTo( nextX, nextY );

			} //

			if ( this._drawHits ) {
				//this.computeLineColors( tileBorders, ctrlPt );
				this.hitGraphics.lineTo( nextX, nextY );
			}

			// probably don't really need this, but it allows you to combine straight lines with curve lines.
			// why you would ever do this, I don't know.
			//this.prevAnchor.x = nextX;
			//this.prevAnchor.y = nextY;

		} // lineStroke()

		override public function setRenderContext( rc:RenderContext ):void {

			super.setRenderContext( rc );

			// need to convert the render context panes to in/out panes.

			this.inStrokePane = rc.viewFillPane;
			this.inStrokeGraphics = rc.viewGraphics;

			this.outStrokePane = rc.viewStrokePane;
			this.outStrokeGraphics = rc.viewStrokeGraphics;

			this.hitPane = rc.hitPane;
			this.hitGraphics = rc.hitGraphics;
			this.hitMatrix = rc.hitMatrix;

		} //

	} // class

} // package