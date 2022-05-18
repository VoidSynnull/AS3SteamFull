package game.scenes.lands.shared.classes {

	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.IBitmapDrawable;
	import flash.display.Shape;

	import game.scenes.lands.shared.util.LandUtils;

	/**
	 * used for passing an object associated with an icon, as in leveling up or maybe
	 * status effects.
	 */

	public class ObjectIconPair {

		//public var type:TileType;
		//public var tileSet:TileSet;

		public var object:*;

		public var icon:IBitmapDrawable;
		// true if the icon is a circle.
		public var isCircle:Boolean;

		public function ObjectIconPair( obj:*, useIcon:IBitmapDrawable=null, circle:Boolean=false ) {

			this.object = obj;

			if ( useIcon == null ) {

				if ( obj is IBitmapDrawable ) {
					this.icon = obj;
				}

			} else {

				this.icon = useIcon;

			}

			this.isCircle = circle;

		} //

		public function draw( s:Shape, iconSize:int ):void {

			var g:Graphics = s.graphics;

			if ( this.icon == null ) {
				return;
			}

			// If tileType.image is NOT a bitmap then this function here is inefficient
			// since we create a new bitmap every time - fix this.
			var b:BitmapData = LandUtils.prepareBitmap( this.icon, iconSize, iconSize );
	
			// draw an outline.
			g.lineStyle( 2, 0, 0.5 );
			g.beginBitmapFill( b );

			// need to be careful on the range coordinates here because the lineStyle extends the draw past the bitmap boundaries.
			if ( this.isCircle ) {
				g.drawCircle( iconSize/2, iconSize/2, iconSize/2-2 );
			} else {
				g.drawRect( 1, 1, iconSize-2, iconSize-2 );
			} //

			// draw the background onto the clip bitmap.
			g.endFill();
			
		} //

	} // class

} // package