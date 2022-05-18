package game.scenes.lands.shared.tileLib.classes {

	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;

	/**
	 * 
	 * Uses a bitmap as a random number generator, both for generating consistent number sequences and
	 * for generating numbers at specific x,y locations.
	 * 
	 */

	public class RandomMap {

		private var _seed:uint;
		private var bitmapData:BitmapData;

		/**
		 * Random numbers can be returned in order, from the start of the bitmap.
		 */
		private var curPixel:uint;

		//public var isPerlin:Boolean = false;

		public function RandomMap( start_seed:uint, width:int, height:int ) {

			this._seed = start_seed;
			this.bitmapData = new BitmapData( width, height, false, 0 );
			this.curPixel = 0;

		} //

		/**
		 * the as3 perlin function does not give results between 0 and 1. The function must be normalized
		 * to get anything like expected values. I think each channel needs to be normalized independently
		 * because no channel seems to have the correct range.
		 */
		/**public function normalize():void {
		} //*/

		/*public function makePerlin( baseX:Number, baseY:Number, octaves:int=6, stitch:Boolean=true, fractal:Boolean=false, channels:uint=7, greyscale:Boolean=false, offsets:Array=null ):void {

			this.bitmapData.perlinNoise( baseX, baseY, octaves, this._seed, stitch, fractal, channels, greyscale, offsets );
			this.isPerlin = true;

		} //*/

		public function makeNoise():void {

			this.bitmapData.noise( this._seed );
			//this.isPerlin = false;

		} //

		/**
		 * Creates a perlin with given dx,dy offsets applied to all perlin octaves.
		 */
		public function makeOffsetPerlin( offset:Point, baseX:Number, baseY:Number, octaves:int=6 ):void {

			// create the offsets array.
			var offsets:Array = new Array( octaves );
			for( var i:int = octaves-1; i >= 0; i-- ) {

				offsets[ i ] = offset;

			} //

			this.bitmapData.perlinNoise( baseX, baseY, octaves, this._seed, false, false, 7, false, offsets );
			//this.isPerlin = true;

		} //

		/**
		 * uses different perlin offsets for the left and right sides of the perlin map and blends them together.
		 * this is used to wrap scenes at the world size: the final scene before world wrapping is treated as
		 * the left side of a perlin, while imaginary scene -1 is treated as the right side.
		 * they are then blended together, so when the user crosses back to scene 0, its left side will match this perlin's right side.
		 */
		public function interpolatePerlin( baseX:Number, baseY:Number, leftOffset:Point, rightOffset:Point, octaves:int=6 ):void {

			// create the offsets array.
			var rightOffsets:Array = new Array( octaves );
			var leftOffsets:Array = new Array( octaves );
			for( var i:int = octaves-1; i >= 0; i-- ) {

				rightOffsets[ i ] = rightOffset;
				leftOffsets[ i ] = leftOffset;

			} //

			var width:int = this.bitmapData.width;
			var height:int = this.bitmapData.height;

			this.bitmapData.perlinNoise( baseX, baseY, octaves, this._seed, false, false, 7, false, leftOffsets );

			var rightPerlin:BitmapData = new BitmapData( width, height, true, 0 );
			rightPerlin.perlinNoise( baseX, baseY, octaves, this._seed, false, false, 7, false, rightOffsets );

			// create the 0 to 1 blending alpha.
			var gradient:Shape = new Shape();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox( width, height );
			gradient.graphics.beginGradientFill( GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [0, 1], [0, 128], matrix );
			gradient.graphics.drawRect(0, 0, width, height );
			gradient.graphics.endFill();

			rightPerlin.draw( gradient, null, null, BlendMode.ALPHA );
			this.bitmapData.draw( rightPerlin );

			rightPerlin.dispose();

		} //

		/**
		 * blend another random map with this one.
		 */
		public function blendMap( otherMap:RandomMap ):void {

			this.bitmapData.draw( otherMap.getBitmapData(), null, null, BlendMode.DIFFERENCE );

		} //

		/**
		 * create a second perlin map and blend it with the current map.
		 */
		public function blendPerlin():void {

			var bm:BitmapData = new BitmapData( this.bitmapData.width, this.bitmapData.height, false, 0 );
			bm.perlinNoise( this.bitmapData.width*1.2, this.bitmapData.height*1.2, 5, this.seed+1, true, true );
			this.bitmapData.draw( bm, null, null, BlendMode.DIFFERENCE );

		} //

		/*public function incSeed():void {

			if ( this._seed == int.MAX_VALUE ) {
				this._seed = 0;
			} else {
				this._seed++;
			} //

			if ( this.isPerlin ) {
				this.bitmapData.perlinNoise( this.bitmapData.width, this.bitmapData.height, 6, this._seed, true, false );
			} else {
				this.bitmapData.noise( this._seed );
			} //

		} //*/

		/**
		 * restarts the random location at 0 so a sequence of getRandom() calls can be repeated.
		 */
		public function reset():void {

			this.curPixel = 0;

		} //

		public function getRandom():Number {

			if ( ++curPixel >= this.bitmapData.width*this.bitmapData.height ) {
				curPixel = 0;
			}

			return this.bitmapData.getPixel( curPixel % this.bitmapData.width, curPixel / this.bitmapData.width ) / 0x1000000;

		} //

		public function get width():int {
			return this.bitmapData.width;
		}

		public function get height():int {
			return this.bitmapData.height;
		}

		public function getIntAt( x:Number, y:Number ):int {

			return this.bitmapData.getPixel( x % this.bitmapData.width, y % this.bitmapData.height );

		} //

		public function getNumberAt( x:Number, y:Number ):Number {

			return this.bitmapData.getPixel( x % this.bitmapData.width, y % this.bitmapData.height ) / 0x1000000;

		} //

		public function getBitmapData():BitmapData {
			return this.bitmapData;
		}

		public function get seed():uint {
			return this._seed;
		}

		public function set seed( n:uint ):void {

			this._seed = n;

		} // seed()

		public function destroy():void {

			this.bitmapData.dispose();
			this.bitmapData = null;

		} //

	} // class

} // package