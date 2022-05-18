package game.scenes.lands.shared.tileLib.painters {

	/**
	 * 
	 * These are variables that can be re-used for every single renderer in every layer.
	 * 
	 * In the future, tile templates will probably use their own render contexts.
	 * 
	 * the shapes used for drawing tiles before they are mapped to bitmaps can obviously be shared.
	 * viewMatrix and hitMatrix are necessary to get the scene bitmaps and tileMaps to align correctly.
	 * 
	 */

	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.tileLib.LandTile;

	public class RenderContext {

		/**
		 * the viewMatrix holds the offset of the tileMap relative to the scene bitmap where the tiles are drawn.
		 * 
		 * scene bitmaps start at the visible edge of the screen to maximize viewable area, but tile maps
		 * begin offscreen so the land renders cleanly at the borders.
		 */
		public var viewMatrix:Matrix;

		public var viewBitmap:BitmapData;
		public var hitBitmap:BitmapData;

		/**
		 * The hitMatrix is scaled by the hitBitmap scaling size as well as offset by the tileMap x,y coordinate.
		 */
		public var hitMatrix:Matrix;

		/**
		 * The area of the bitmaps currently being painted.
		 */
		public var viewPaintRect:Rectangle;
		public var hitPaintRect:Rectangle;

		/**
		 * this is where the view fill is drawn before being copied to the view bitmap.
		 */
		public var viewFillPane:Shape;
		public var viewGraphics:Graphics;

		public var viewStrokePane:Shape;
		public var viewStrokeGraphics:Graphics;

		/**
		 * This is where the hits are drawn before being copied to the hit bitmap.
		 */
		public var hitPane:Shape;
		public var hitGraphics:Graphics;

		/**
		 * offset of the land tileMaps from the 0,0 scene bounds.
		 */
		public var mapOffsetX:int;
		public var mapOffsetY:int;

		/**
		 * easy way to pass information on the current tile being drawn.
		 */
		public var curTile:LandTile;

		public var drawHits:Boolean;

		/**
		 * used to set shape filters to empty when not being used.
		 * cheaper than having separate empty filters for every renderer.
		 */
		public var emptyFilters:Array = [];

		/**
		 * Most drawing objects are not provided in the constructor since these can be shared between render contexts,
		 * and so I use clone() to link the shared parts.
		 */
		public function RenderContext( viewBitmap:BitmapData, hitBitmap:BitmapData=null, drawHits:Boolean=true ) {

			this.viewBitmap = viewBitmap;
			this.hitBitmap = hitBitmap;

			if ( hitBitmap != null ) {
				this.drawHits = drawHits;
			} else {
				this.drawHits = false;
			}
			
		} //

		public function clearContext():void {

			this.viewBitmap.fillRect( this.viewBitmap.rect, 0 );
			// rects also have to be cleared to indicate to renderers the area being redrawn.
			this.viewPaintRect.setTo( 0, 0, this.viewBitmap.width, this.viewBitmap.height );

			if ( this.hitBitmap ) {
				this.hitBitmap.fillRect( this.hitBitmap.rect, 0 );
				this.hitPaintRect.setTo( 0, 0, this.hitBitmap.width, this.hitBitmap.height );
			} //

		} //

		public function clearMapRect( tileRect:Rectangle ):void {

			this.viewPaintRect.setTo( tileRect.x + this.mapOffsetX, tileRect.y, tileRect.width, tileRect.height );
			this.viewBitmap.fillRect( this.viewPaintRect, 0 );

			if ( this.hitBitmap ) {

				this.hitPaintRect.setTo( this.viewPaintRect.x>>1, this.viewPaintRect.y>>1,
					this.viewPaintRect.width>>1, this.viewPaintRect.height>>1 );

				this.hitBitmap.fillRect( this.hitPaintRect, 0 );
				
			} //

		} //

		/**
		 * the map should be positioned a bit to the left of the viewable bitmap to hide the terrain looping around.
		 */
		public function init( mapX:Number=0, mapY:Number=0, bitmapScale:Number=0.5 ):void {

			this.mapOffsetX = mapX;
			this.mapOffsetY = mapY;

			this.viewFillPane = new Shape();
			this.viewGraphics = this.viewFillPane.graphics;

			this.viewStrokePane = new Shape();
			this.viewStrokeGraphics = this.viewStrokePane.graphics;

			this.viewPaintRect = new Rectangle();
			this.viewMatrix = new Matrix( 1, 0, 0, 1, mapX, mapY );

			if ( this.hitBitmap != null && this.drawHits ) {
				this.initHitContext( bitmapScale );
			}

		} //

		private function initHitContext( bitmapScale:Number=0.5 ):void {

			this.hitPane = new Shape();
			this.hitGraphics = this.hitPane.graphics;
			this.hitPaintRect = new Rectangle();
			this.hitMatrix = new Matrix( bitmapScale, 0, 0, bitmapScale, bitmapScale*this.mapOffsetX, bitmapScale*this.mapOffsetY );

		} //

		/**
		 * most variables of a render context can be reused, as long as they're not being used simultaneously.
		 * even one render happening directly after another is usually okay.
		 */
		public function clone( rc:RenderContext, bitmapScale:Number=0.5 ):void {

			this.mapOffsetX = rc.mapOffsetX;
			this.mapOffsetY = rc.mapOffsetY;
			
			this.viewFillPane = new Shape();
			this.viewGraphics = this.viewFillPane.graphics;
			
			this.viewStrokePane = new Shape();
			this.viewStrokeGraphics = this.viewStrokePane.graphics;

			this.viewPaintRect = new Rectangle();
			this.viewMatrix = rc.viewMatrix;

			if ( this.hitBitmap != null && this.drawHits ) {

				if ( rc.hitBitmap != null && rc.drawHits ) {

					this.hitPane = rc.hitPane;
					this.hitGraphics = rc.hitGraphics;
					this.hitPaintRect = rc.hitPaintRect;
					this.hitMatrix = rc.hitMatrix;

				} else {
					this.initHitContext( bitmapScale );
				}

			} //

		} //

		/*public function setMapOffset( x:Number, y:Number ):void {

			this.viewMatrix.tx = x;
			this.viewMatrix.ty = y;

			this.hitMatrix.tx = x*this.hitMatrix.a;
			this.hitMatrix.ty = y*this.hitMatrix.d;

			this.mapOffsetX = x;
			this.mapOffsetY = y;

		} //*/

	} // class

} // package