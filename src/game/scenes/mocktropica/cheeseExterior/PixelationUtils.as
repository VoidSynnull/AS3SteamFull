package game.scenes.mocktropica.cheeseExterior {

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.filters.DisplacementMapFilter;
	import flash.filters.DisplacementMapFilterMode;

	/**
	 * This class will provide a variety of different pixelation methods. Different methods have different advantages/disadvantages.
	 * 
	 * Currently there are two: pixelation via DisplacementMapFilter - slower than bitmap pixelation but allows the pixelated clip
	 * to be animated, and allows using the same filter for mulitple pixelated images.
	 * 
	 * UPDATE: animating with a filter turns out not to work so well - because the pixels change color rather than animate naturally.
	 * 
	 * Bitmap Pixelation - faster but requires more memory for multiple pixelated images, and for pixelated animations.
	 */
	public class PixelationUtils {

		public function PixelationUtils() {
		} //

		static public function makePixelFilter( width:Number, height:Number, pixelSize:int=2 ):DisplacementMapFilter {

			var filterBitmap:BitmapData = new BitmapData( width, height, false, 0 );

			filterBitmap.lock();

			/**
			 * Fill the bitmap with the correct displacement colors. These can be calculated based on the displacementMapFilter equation.
			 * See adobe help files for the equation.
			 */
			var green:int;			// x-displacement-color (0-255)
			//var blue:int;			// y-displacement-color (0-255)
			var offx:int;
			var offy:int;

			/**
			 * Update: make the algorithm pick a center pixel for the test pixel, instead of an edge pixel.
			 * So with a pixelSize of 5, pixel 2 will be used for the test instead of pixel 0.
			 * This should better approximate the image since copied pixels are closer to their source pixels.
			 */
			var midPix:int = Math.floor( pixelSize / 2 );

			for( var x:int = 0; x < width; x++ ) {

				offx = ( x % pixelSize ) - midPix;
				if ( offx == 0 ) {
					green = 128 << 8;
				} else {
					// by choosing green for the x-displacement, the bit shift is only done on the outer circle.
					green = ( -( offx )*128/pixelSize + 128 ) << 8;
				}

				for( var y:int = 0; y < height; y++ ) {

					offy = (y % pixelSize) - midPix;
					if ( offy == 0 ) {

						filterBitmap.setPixel( x, y, green + 128 );

					} else {

						// The messy part on the end is the blue displacement color. no reason to use a variable here.
						filterBitmap.setPixel( x, y, green + -( offy )*128/pixelSize + 128 );
					}

				} //

			} //

			filterBitmap.unlock();

			/**
			 * the scaleX, scaleY values are set to 2*pixSize, because the maximum displacement from (bitmapColor-128)/256 is (1/2)
			 */
			var filter:DisplacementMapFilter = new DisplacementMapFilter( filterBitmap, null, BitmapDataChannel.GREEN, BitmapDataChannel.BLUE,
															2*(pixelSize), 2*(pixelSize), DisplacementMapFilterMode.CLAMP );

			return filter;

		} //

	} // End FilterPixelator

} // End package