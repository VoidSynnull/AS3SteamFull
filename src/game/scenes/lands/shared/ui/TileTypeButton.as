package game.scenes.lands.shared.ui {

	/**
	 *
	 * Button sprite for displaying and selecting tileTypes. Might also be used for biomes and templates.
	 *
	 */

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.scenes.lands.shared.util.LandUtils;

	public class TileTypeButton extends Sprite {

		static public var LockBitmap:BitmapData;

		/**
		 * tileType represented by this icon button.
		 */
		private var _selector:TypeSelector;
		public function get typeSelector():TypeSelector {
			return this._selector;
		}

		/**
		 * child bitmap that displays the tileType.
		 */
		private var _bitmap:Bitmap;
		public function get bitmap():Bitmap {
			return this._bitmap;
		}

		/**
		 * true if the button has already drawn the tileType icon into its bitmap.
		 */
		private var _isCurrent:Boolean;
		public function get iconIsCurrent():Boolean {
			return this._isCurrent;
		}

		public function TileTypeButton( buttonSize:int, typeSel:TypeSelector=null ) {

			super();

			this.mouseChildren = false;

			var bm:BitmapData = new BitmapData( buttonSize, buttonSize, true, 0 );

			this._bitmap = new Bitmap( bm );
			this.addChild( this._bitmap );

			if ( typeSel ) {
				this._selector = typeSel;
			}

		} //

		/**
		 * display a loading icon while the button loads.
		 */
		public function addLoadIcon( group:LandUIGroup ):void {

			var leekSpin:LoadingSpinner = new LoadingSpinner( group );
			leekSpin.name = "leekSpin";

			leekSpin.x = this.width/2;
			leekSpin.y = this.height/2;

			this.addChild( leekSpin );

		} //

		public function removeLoadIcon():void {

			var leekSpin:LoadingSpinner = this.getChildByName( "leekSpin" ) as LoadingSpinner;
			if ( leekSpin ) {

				leekSpin.destroy();
				this.removeChild( leekSpin );

			} //

		} //

		public function setTileType( type:TypeSelector ):void {

			this._selector = type;
			this._isCurrent = false;		// icon is not current until it has been redrawn with the new tileType information.

		} //

		/**
		 * draws a copy of the given bitmap into this bitmap's icon.
		 * this can save trouble looking up the right tile type level etc.
		 */
		public function useIcon( bitmap:BitmapData ):void {

			var mat:Matrix = new Matrix( this._bitmap.width/bitmap.width, 0, 0, this._bitmap.height/bitmap.height );
			this._bitmap.bitmapData.fillRect( this.bitmap.bitmapData.rect, 0 );
			this._bitmap.bitmapData.draw( bitmap, mat );

			this._isCurrent = true;
			this.removeLoadIcon();

		} //

		/**
		 * attempts to redraw the button with the image propety of the current button tileType.
		 * returns false if it cannot draw the button because the image hasn't been preloaded.
		 */
		public function tryRedrawButton( curLevel:int ):Boolean {

			var tileLevel:int = this._selector.tileType.level;
			if ( tileLevel <= curLevel ) {

				// check if tileType clip has been loaded yet.
				if ( this._selector.tileType.image == null ) {
					return false;
				}

				// tileType already unlocked.
				this.drawRegularIcon();
				this.mouseEnabled = true;

			} else if ( tileLevel == curLevel + 1 ) {

				// check if tileType clip has been loaded yet.
				if ( this._selector.tileType.image == null ) {
					return false;
				}

				// tileType will be unlocked next level.
				this.drawPending();
				this.mouseEnabled = false;

			} else {

				this.drawLocked();
				this.mouseEnabled = false;

			} //

			this._isCurrent = true;
			return true;

		} // redrawButton

		/**
		 * redraws the button without any test to see if the tileType has been loaded.
		 * only call this if you're sure the tile bitmap has been loaded already.
		 */
		public function redrawButton( curLevel:int ):void {
			
			var tileLevel:int = this._selector.tileType.level;

			if ( tileLevel <= curLevel ) {

				// tileType already unlocked.
				this.drawRegularIcon();
				this.mouseEnabled = true;

			} else if ( tileLevel == curLevel + 1 ) {

				// tileType will be unlocked next level.
				this.drawPending();
				this.mouseEnabled = false;

			} else {
				
				this.drawLocked();
				this.mouseEnabled = false;
				
			} //
			
		} // redrawButton

		public function drawRegularIcon():void {

			var bm:BitmapData = this.bitmap.bitmapData;
			var buttonSize:int = bm.width;

			var g:Graphics = this.graphics;

			// first draw a blue background
			g.beginFill( TileType.ICON_FILL_COLOR );
			if ( this._selector.tileSet.setType == "natural" ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //
			g.endFill();

			bm.fillRect( bm.rect, 0 );

			// this actually doesnt work if tileType.image is a movieclip being drawn inside a circle.
			var b:BitmapData = LandUtils.getDrawBitmap( bm, this._selector.tileType.image, buttonSize, buttonSize );
			g.lineStyle( 1.5, TileType.ICON_LINE_COLOR, 0.5 );
			g.beginBitmapFill( b );

			// need to be careful on the range coordinates here because the lineStyle extends the draw past the bitmap boundaries.
			if ( this._selector.tileSet.setType == "natural" ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //

			// draw the background onto the clip bitmap.
			g.endFill();
			bm.draw( this );
			g.clear();

		} //

		public function drawLocked():void {

			var bm:BitmapData = this._bitmap.bitmapData;
			var buttonSize:int = bm.width;

			var g:Graphics = this.graphics;

			// black background.
			g.lineStyle( 1.5, TileType.ICON_LINE_COLOR, 0.5 );
			g.beginFill( 0, 0.8 );
			if ( _selector.tileSet.setType == "natural" ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //
			g.endFill();

			// draw the background onto the clip bitmap.
			bm.draw( this );
			g.clear();

			// ADD THE LOCK BITMAP.
			this.drawButtonLock( bm );

		} //

		public function drawPending():void {

			var bm:BitmapData = this.bitmap.bitmapData;
			var buttonSize:int = bm.width;

			var g:Graphics = this.graphics;

			// first draw a blue background
			g.beginFill( TileType.ICON_FILL_COLOR );
			if ( _selector.tileSet.setType == "natural" ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //
			g.endFill();

			g.lineStyle( 1.5, TileType.ICON_LINE_COLOR, 0.5 );
			bm.fillRect( bm.rect, 0 );

			// this actually doesnt work if tileType.image is a movieclip being drawn inside a circle.
			var b:BitmapData = LandUtils.getDrawBitmap( bm, this._selector.tileType.image, buttonSize, buttonSize );
			// draw an outline.
			g.beginBitmapFill( b );

			// need to be careful on the range coordinates here because the lineStyle extends the draw past the bitmap boundaries.
			if ( _selector.tileSet.setType == "natural" ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //

			// draw the background onto the clip bitmap.
			g.endFill();
			bm.draw( this );
			g.clear();

			// ADD THE LOCK BITMAP.
			this.drawButtonLock( bm );

		} //

		/**
		 * Draw the lock icon on the sprite of a locked tile button.
		 */
		private function drawButtonLock( bm:BitmapData ):void {
			
			bm.draw( TileTypeButton.LockBitmap,
				new Matrix( 1, 0, 0, 1,
					(bm.width-TileTypeButton.LockBitmap.width)/2, (bm.width-TileTypeButton.LockBitmap.height)/2 ) );
			
		} //

		public function destroy():void {

			if ( this._bitmap.bitmapData ) {
				this._bitmap.bitmapData.dispose();
			}
			this.removeLoadIcon();

			this.removeChild( this._bitmap );
			this._selector = null;

		} //

	} // class

} // package