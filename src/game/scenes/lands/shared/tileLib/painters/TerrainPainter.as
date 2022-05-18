package game.scenes.lands.shared.tileLib.painters {

	/**
	 * This class paints land into a scene through several steps. These are fairly convoluted at the moment.
	 * 
	 * - startPaintBatch() is called so the render context views can be cleared for painting.
	 * 
	 * - startTerrainPaint() is called to begin fills/drawing for a new terrain type. All subsequent
	 *   drawing will use the colors/fills/hits for that terrain type.
	 * 
	 * - startStroke() is called to begin a new terrain border at a new location.
	 * 
	 * - curveStroke() or lineStroke() are called for every pen stroke of the given terrain type.
	 * 
	 * - endTerrainPaint() indicates all drawing of the given terrain is complete.
	 * 
	 * - endPaintBatch() indicates the entire paint update is complete.
	 * 
	 */
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;

	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TerrainTileType;

	public class TerrainPainter extends BasePainter {

		private var curTerrain:TerrainTileType;

		/**
		 * Tracking prev,next draw points to determine hit colors and view effects.
		 * Calculate drawing slopes, etc.
		 */
		private var prevAnchor:Point;
		private var nextAnchor:Point;

		private var hiliteFilter:DropShadowFilter;
		/**
		 * these arrays are applied to the view shapes before drawing.
		 */
		private var filterArray:Array;				// used so we don't need to redefine the array every frame.

		/**
		 * Draws stupid land details.
		 */
		private var detailer:LandDetailer;

		private var _drawOutlines:Boolean = false;

		/**
		 * randMap is a map for determining the random placement of terrain details.
		 * drawHits determines if hits are drawn to the hit bitmap.
		 */
		public function TerrainPainter( drawHits:Boolean, rc:RenderContext, randMap:RandomMap ) {

			this._drawHits = drawHits && rc.drawHits;

			this.detailer = new LandDetailer( randMap );

			this.initPaintVars();

			super( rc );

		} //

		/**
		 * Some variables needed for painting.
		 */
		private function initPaintVars():void {

			this.prevAnchor = new Point();
			this.nextAnchor = new Point();

			// true = inner shadow
			this.hiliteFilter = new DropShadowFilter( 4, 90, 0xFFFFFF, 1, 0, 0, 1, 2, true );
			this.filterArray = [ this.hiliteFilter ];

		} //

		/**
		 * borders is the OR-d borders of both tiles. since each tile has a single border on a draw-curve,
		 * each tile can be checked for its border-type.
		 */
		private function computeLineColors( borders:uint, ctrlPt:Point ):void {

			var slope:Number = this.nextAnchor.x - this.prevAnchor.x;
			if ( borders & LandTile.BOTTOM ) {

				// upside-down land.
				if ( this.renderContext.drawHits ) {

					if ( borders & LandTile.VISUAL_BORDER ) {
						this.renderContext.hitGraphics.lineStyle( this.curTerrain.hitLineSize, this.curTerrain.hitWallColor );
					} else {
						this.renderContext.hitGraphics.lineStyle( this.curTerrain.hitLineSize, this.curTerrain.hitCeilingColor );
					}

				}
				this.detailer.makeBottomDetails( this.prevAnchor, ctrlPt, this.nextAnchor );

			} else if ( Math.abs(slope) < 1 ) {

				// the change in x between tiles is very small, so the slope must be nearly vertical.
				// this means the line is effectively a wall.
				if ( this.renderContext.drawHits ) {
					this.renderContext.hitGraphics.lineStyle( this.curTerrain.hitLineSize, this.curTerrain.hitWallColor );
				}
				this.detailer.makeSideDetails( this.prevAnchor, ctrlPt, this.nextAnchor );

			} else {

				// use the actual slope to decide between a wall and the ground.
				slope = ( this.nextAnchor.y - this.prevAnchor.y ) / slope;
				if ( Math.abs(slope) < this.curTerrain.WallSlope ) {

					// small slope = ground.
					if ( this.renderContext.drawHits ) {
						this.renderContext.hitGraphics.lineStyle( this.curTerrain.hitLineSize, this.curTerrain.hitGroundColor );
					}
					this.detailer.makeTopDetails( this.prevAnchor, ctrlPt, this.nextAnchor );

				} else {

					// large slope = wall.
					if ( this.renderContext.drawHits ) {
						this.renderContext.hitGraphics.lineStyle( this.curTerrain.hitLineSize, this.curTerrain.hitWallColor );
					}
					this.detailer.makeSideDetails( this.prevAnchor, ctrlPt, this.nextAnchor );

				} //

			} //

		} //

		/**
		 * clears the render context (which is shared between painters) to begin painting.
		 */
		public function startPaintBatch():void {

			this.renderContext.viewGraphics.clear();
			if ( this._drawOutlines ) {
				this.renderContext.viewStrokeGraphics.clear();
			}

			if ( this._drawHits ) {

				this.renderContext.hitGraphics.clear();

			} //

		} //

		/**
		 * begin painting tiles of a given tile type.
		 */
		public function startPaintType( terrain:TerrainTileType ):void {

			this.curTerrain = terrain;

			if ( terrain.viewBitmapFill ) {
			//	this.renderContext.viewGraphics.lineStyle( NaN );
				this.renderContext.viewGraphics.beginBitmapFill( terrain.viewBitmapFill );
			} else {
				this.renderContext.viewGraphics.lineStyle( NaN );
				this.renderContext.viewGraphics.beginFill( 0 );
			}

			if ( this._drawOutlines ) {
				this.renderContext.viewStrokeGraphics.lineStyle( terrain.viewLineSize, terrain.viewLineColor, terrain.viewLineAlpha );
			}

			this.detailer.setDetailClips( terrain.details );

			if ( terrain.useHilite ) {

				this.hiliteFilter.alpha = terrain.hiliteAlpha;
				this.hiliteFilter.angle = terrain.hiliteAngle;
				this.hiliteFilter.distance = terrain.hiliteSize;
				this.renderContext.viewFillPane.filters = this.filterArray;

			}

			//this.viewStrokeGraphics.lineStyle( this.curTerrain.viewLineSize, this.curTerrain.viewLineColor );
			if ( this._drawHits && terrain.drawHits ) {

				if ( terrain.fillHits ) {
					this.renderContext.hitGraphics.beginFill( terrain.hitGroundColor );
				}

			}

		} //

		/**
		 * end painting a certain type of terrain.
		 */
		public function endPaintType():void {

			this.renderContext.viewGraphics.endFill();

			if ( this._drawHits && this.curTerrain.drawHits && this.curTerrain.fillHits ) {
				this.renderContext.hitGraphics.endFill();
			}

			/**
			 * Need to draw these after each terrain because higher terrains could have different hilites
			 * and their outlines could be completely covered by later terrains as well.
			 */
			this.renderContext.viewBitmap.draw( this.renderContext.viewFillPane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );
			if ( this.drawOutlines ) {

				this.renderContext.viewBitmap.draw( this.renderContext.viewStrokePane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );
				this.renderContext.viewStrokeGraphics.clear();

			}

			this.detailer.drawDetails( this.renderContext.viewBitmap, this.renderContext.viewMatrix, this.renderContext.viewPaintRect );
			this.renderContext.viewGraphics.clear();

			// Remove the hilite used for terrain, if any.
			this.renderContext.viewFillPane.filters = this.renderContext.emptyFilters;

		} //

		/**
		 * only simple drawings without hilites or details will ever be left pending.
		 */
		/*public function flushDrawing():void {
				
			this.renderContext.viewBitmap.draw( this.renderContext.viewFillPane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );
			if ( this.drawOutlines ) {
					
				this.renderContext.viewBitmap.draw( this.renderContext.viewStrokePane, this.renderContext.viewMatrix, null, null, this.renderContext.viewPaintRect );
				this.renderContext.viewStrokeGraphics.clear();
					
			}
			this.renderContext.viewGraphics.clear();

			this.drawPending = false;

		} //*/

		public function endPaintBatch():void {

			//this.viewBitmap.draw( this.viewFillPane, null, null, null, this.paintRect );
			//this.viewBitmap.draw( this.viewStrokePane, null, null, null, this.paintRect );

			if ( this._drawHits ) {
				this.renderContext.hitBitmap.draw( this.renderContext.hitPane, this.renderContext.hitMatrix, null, null, this.renderContext.hitPaintRect );
			}

		} //

		public function startStroke( startX:Number, startY:Number ):void {

			this.prevAnchor.x = startX;
			this.prevAnchor.y = startY;

			if ( this._drawOutlines ) {
				this.renderContext.viewStrokeGraphics.moveTo( startX, startY );
			}
			this.renderContext.viewGraphics.moveTo( startX, startY );

			if ( this._drawHits && this.curTerrain.drawHits ) {
				this.renderContext.hitGraphics.moveTo( startX, startY );
			}

		} //

		/**
		 * tile borders are an OR'd combination of LandTile.TOP, LandTile.BOTTOM, LandTile.LEFT, LandTile.RIGHT
		 * and indicate which hit types and tile details to draw.
		 */
		public function curveStroke( ctrlPt:Point, nextX:Number, nextY:Number, tileBorders:uint, fakeEdge:Boolean=false ):void {

			this.renderContext.viewGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );
			if ( this._drawOutlines ) {
				this.renderContext.viewStrokeGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );
			}

			if ( !fakeEdge ) {
				this.nextAnchor.x = nextX;
				this.nextAnchor.y = nextY;
				this.computeLineColors( tileBorders, ctrlPt );
			}
			if ( this._drawHits && this.curTerrain.drawHits ) {
				this.renderContext.hitGraphics.curveTo( ctrlPt.x, ctrlPt.y, nextX, nextY );					
			}

			// save the anchor used to compute the slope for the next curve we draw.
			this.prevAnchor.x = nextX;
			this.prevAnchor.y = nextY;

		} //

		/**
		 * tile borders are an OR'd combination of LandTile.TOP, LandTile.BOTTOM, LandTile.LEFT, LandTile.RIGHT
		 * and indicate which hit types and tile details to draw.
		 * WARNING: line strokes currently dont work in combination with curveStrokes.
		 */
		public function lineStroke( nextX:Number, nextY:Number, tileBorders:uint, fakeEdge:Boolean = false ):void {

			//this.nextAnchor.x = nextX;
			//this.nextAnchor.y = nextY;
			
			/*if ( !fakeEdge && this.drawHits ) {
				// this won't work yet.
			//	this.computeLineColors( tileBorders, ctrlPt );
			}*/

			if ( this._drawOutlines ) {
				this.renderContext.viewGraphics.lineTo( nextX, nextY );
			}

			if ( this._drawHits && this.curTerrain.drawHits ) {
				this.renderContext.hitGraphics.lineTo( nextX, nextY );
			}
			
			// save the anchor used to compute the slope for the next curve we draw.
			this.prevAnchor.x = nextX;
			this.prevAnchor.y = nextY;

		} //

		override public function setRenderContext( rc:RenderContext ):void {

			this.renderContext = rc;
			this.detailer.renderContext = rc;

		} //

		/**
		 * if true, land details are sorted by y-value before they're drawn. (like a painter canvas)
		 * this is important for details on terrain, but pointless for drawing leaves.
		 */
		public function set sortDetails( b:Boolean ):void {
			this.detailer.sortDetails = b;
		} //

		public function set drawOutlines( b:Boolean ):void {

			this._drawOutlines = b;

		} //

		public function get drawOutlines():Boolean {
			return this._drawOutlines;
		}

	} // class

} // package