package game.scenes.lands.shared.tileLib.tileTypes {

	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.geom.Matrix;
	

	/**
	 * 
	 * Each LandTile has a type id which ultimately refers to an instance of TileType that gives
	 * special information about that tile.
	 * 
	 * Different subclasses of TileType can be used to define more specific types of tiles:
	 * building tiles, terrain tiles, decal tiles, etc.
	 * 
	 */

	public class TileType {

		/**
		 * background color for icons ( which are sometimes transparent )
		 */
		static public var ICON_FILL_COLOR:uint = 0x80CBFE;
		/**
		 * line outline color for tile icons.
		 */
		static public var ICON_LINE_COLOR:uint = 0x122654;

		/**
		 * this is the tile type's type code. tileTypes from different tile sets can have the same type code
		 * ( for instance a building tile and a terrain tile can have the same type code because they
		 *   are handled by separate tileSets and drawing routines )
		 * 
		 * Some tile sets need to have their type codes bitwise exclusive (powers of 2 ) to allow overlapping tiles -
		 * trees need this to overlay the trunks and the leaves.
		 */
		public var type:uint;
		public var name:String;					// display name.

		/**
		 * level when tile becomes available.
		 */
		public var level:int = 0;

		/**
		 * if false, tile type can't be destroyed in mining mode.
		 * water, air, lava for example, can't be destroyed in mining mode.
		 */
		public var allowMining:Boolean = true;

		/**
		 * possible values taken from TileLockState which indicate if the tileType can be edited.
		 */
		//public var lockState:int = TileLockState.UNLOCKED;

		/**
		 * if a tile type isn't editable, it doesn't show up as an option in the land editing ui.
		 */
		public var allowEdit:Boolean = true;

		/**
		 * unbreakable objects can't be destroyed by explosions/hammer effects.
		 */
		public var unbreakable:Boolean = false;

		/**
		 * if false, tile should not draw borders.
		 */
		public var drawBorder:Boolean = true;

		//public var viewFillColor:uint = 0x759236;
		public var viewLineColor:uint = 0x000000;
		public var viewLineAlpha:Number = 1;

		/**
		 * Size of the draw line when drawn for the viewable land.
		 */
		public var viewLineSize:Number = NaN;

		/**
		 * If non-null, this bitmap is used to fill the land view.
		 */
		public var viewBitmapFill:BitmapData;

		/**
		 * the source file ( image or swf ) that is used for the display of this tile type.
		 * subtypes might use the source file in different ways - some will convert it to a bitmap,
		 * others will use it as swf that gets drawn directly to the layer.
		 */
		public var viewSourceFile:String;

		/**
		 * Colors for wall, ceiling and ground hits for this tile type.
		 */
		public var hitCeilingColor:uint = 0xFFCC00;
		public var hitGroundColor:uint = 0x00FF00;
		public var hitWallColor:uint = 0xFF6600;

		/**
		 * Size of the hit-drawing line.
		 */
		public var hitLineSize:int = 10;

		/**
		 * whether to draw bitmap hits for this tileType.
		 */
		public var drawHits:Boolean = true;

		/**
		 * if true, bitmap hits for this type are drawn with a fill. if false,
		 * only the outline of the hits are drawn.
		 */
		public var fillHits:Boolean = true;

		/**
		 * Order in which terrain should be drawn. Lower numbers are drawn first.
		 */
		public var drawOrder:int = 1;

		/**
		 * amount of light emanating.
		 */
		//public var light:int;

		/**
		 * icon representing the bitmap in game. it will include a blue background, an outline
		 * and a lock.
		 */
		//public var icon:BitmapData;

		/**
		 * used to get colors for when the tile explodes or is destroyed in mining mode.
		 * for tiles with viewFills, this can be the same as the fill bitmap. Tiles
		 * that only have movieclips can draw a small 5x5 version and pick colors from that.
		 */
		private var _colorBitmap:BitmapData;

		public function TileType() {
		}

		/**
		 * colorBitmap is used to pick random colors from the tile - for blast or crumble effects.
		 */
		public function get colorBitmap():BitmapData {

			if ( !this._colorBitmap ) {

				if ( this.viewBitmapFill ) {
					this._colorBitmap = this.viewBitmapFill;
				} else {
					this.createColorMap();
				} //

			} //

			return this._colorBitmap;

		}

		/**
		 * if the tileType doesnt have a view bitmap to get colors from ( decals don't ) then instead
		 * get the image and scale it to a very tiny bitmap to save space. this tiny bitmap can then
		 * be used to pick colors from.
		 */
		private function createColorMap():void {

			this._colorBitmap = new BitmapData( 3, 3, false, 0 );
			var d:DisplayObject = this.image as DisplayObject;

			this._colorBitmap.draw( d, new Matrix( Number(3.0/d.width), 0, 0, Number(3.0/d.height) ) );

		} //

		public function get image():IBitmapDrawable {
			return this.viewBitmapFill;
		}

		public function destroy():void {

			this.viewBitmapFill.dispose();

		} //

		/*public function getIcon( s:Sprite=null, buttonSize:int=52, circle:Boolean=false ):BitmapData {

			if ( !this.icon ) {
				this.createIcon( s, buttonSize, circle );
			}

			return this.icon;

		} //

		private function createIcon( s:Sprite, buttonSize:int=52, circle:Boolean=false ):void {

			var bm:BitmapData = new BitmapData( buttonSize, buttonSize, true, 0 );
			bm.fillRect( bm.rect, 0 );

			var g:Graphics = s.graphics;

			// first draw a blue background
			g.beginFill( TileType.ICON_BACKGROUND );
			if ( circle ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //
			g.endFill();

			g.lineStyle( 1.5, 0x122654, 0.5 );

			if ( this.image != null ) {

				// this actually doesnt work for movieclips drawn inside circles.
				var b:BitmapData = LandUtils.getDrawBitmap( bm, this.image, buttonSize, buttonSize );

				// draw an outline.
				g.beginBitmapFill( b );

			} else {

				g.beginFill( this.color );

			} //

			// need to be careful on the range coordinates here because the lineStyle extends the draw past the bitmap boundaries.
			if ( circle ) {
				g.drawCircle( buttonSize/2, buttonSize/2, buttonSize/2-2 );
			} else {
				g.drawRect( 1, 1, buttonSize-2, buttonSize-2 );
			} //

			// draw the background onto the clip bitmap.
			g.endFill();
			bm.draw( s );
			g.clear();

			this.icon = bm;

		} //*/

		/*public function get color():uint {
			return this.viewFillColor;
		}*/

	} // class

} // package