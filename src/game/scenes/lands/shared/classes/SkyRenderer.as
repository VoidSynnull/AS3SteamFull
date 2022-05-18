package game.scenes.lands.shared.classes {

	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import game.scenes.lands.shared.tileLib.classes.RandomMap;

	/**
	 * 
	 * renders the dynamic backdrop over the whole scene.
	 * 
	 */

	public class SkyRenderer {

		/**
		 * percents for background mountains.
		 */
		private const minMountainPct:Number = 0.4;
		private const maxMountainPct:Number = 0.6;

		private var topSkyColors:Array = [ 0x1C6093, 0x2685B4, 0x31AAD5, 0x287D9E, 0x20526A, 0x112537, 0x0A0C1B, 0x0C192E, 0x1C6093 ];
		private var botSkyColors:Array = [ 0xECE3AA, 0x9EDDE1, 0x83DCF5, 0xA3C2B7, 0xEC872B, 0x1E526A, 0x0E1B2C, 0x194056, 0xECE3AA ];

		public function get topColors():Array { return this.topSkyColors; }
		public function get botColors():Array { return this.botSkyColors; }

		/**
		 * random seed -- not even being used. using perlin terrain and random maps instead...
		 */
		/*private var _seed:uint;
		public function get seed():uint { return this._seed; }
		public function set seed( s:uint ):void { this._seed = s; }*/

		/**
		 * all stars are drawn onto a single shape which is later then copied over to the backdrop bitmap
		 * with the correct alpha value for each time of day.
		 */
		private var starShape:Shape;

		/**
		 * scene backdrop bitmap.
		 */
		private var bdBitmap:BitmapData;

		public function SkyRenderer( bitmap:BitmapData ) {

			this.bdBitmap = bitmap;
			this.starShape = new Shape();

		} //

		public function init( randMap:RandomMap ):void {

			this.drawFixedStars( this.starShape, randMap );

		} //

		public function setSkyColors( newTops:Array, newBots:Array ):void {

			this.topSkyColors.length = newTops.length;
			this.botSkyColors.length = newBots.length;

			// the line-by-line conversion is done because the new colors might be formatted as strings,
			// especially if they come from xml -- which they do.
			for( var i:int = newTops.length-1; i>= 0; i-- ) {

				this.topSkyColors[i] = uint( newTops[i] );

			} //

			for( i = newBots.length-1; i>= 0; i-- ) {

				this.botSkyColors[i] = uint( newBots[i] );

			} //

		} //

		public function redraw( clock:LandClock, terrainMap:RandomMap ):void {

			var s:Shape = new Shape();

			var dayPct:Number = clock.getDayPercent();

			var topColor:uint = this.getGradientValue( this.topSkyColors, dayPct )

			this.drawSky( s, dayPct, topColor );
			this.drawMountains( s, terrainMap, topColor, minMountainPct, maxMountainPct, 0 );
			this.drawMountains( s, terrainMap, topColor, minMountainPct-0.1, maxMountainPct-0.1, 3 );

		} //

		private function drawMountains( s:Shape, terrainMap:RandomMap, topColor:uint, min:Number, max:Number, offset:uint ):void {

			var g:Graphics = s.graphics;
			g.clear();

			var xstep:Number = (20+this.bdBitmap.width)/ terrainMap.width;

			var h:Number = this.bdBitmap.height;

			var xprev:Number = -20;
			var yprev:Number = h * ( 1 - min - ( max - min)*( terrainMap.getNumberAt( 0, 37 + offset ) ) );

			var xcur:Number;
			var ycur:Number;

			var xmax:Number = this.bdBitmap.width+20;

			//g.beginFill( topColor );
			
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox( this.bdBitmap.width, h, Math.PI/2 );
			g.beginGradientFill( GradientType.LINEAR, [ topColor, 0x000000 ], [255,255], [max*255,255], matrix );


			/**
			 * draw bottom border of terrain.
			 */
			g.moveTo( xmax, h + 20 );
			g.lineTo( -20, h + 20 );

			var step:Number = 0;

			do {

				xcur = xprev + xstep;
				ycur = h * ( 1 - min - ( max - min)*( terrainMap.getNumberAt( step, 37 + offset ) ) );

				g.curveTo( xprev, yprev, (xcur+xprev)/2, (ycur+yprev)/2 );

				xprev = xcur;
				yprev = ycur;

				step += 1;

			} while ( xcur < xmax );

			g.endFill();

			this.bdBitmap.draw( s );

		} //

		private function drawSky( s:Shape, dayPct:Number, topColor:uint ):void {

			var g:Graphics = s.graphics;

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox( this.bdBitmap.width, this.bdBitmap.width/2, Math.PI/2 );
			
			g.beginGradientFill( GradientType.LINEAR, [ topColor, this.getGradientValue( this.botSkyColors, dayPct ) ], [255,255], [100,255], matrix );
			g.drawRect( 0, 0, this.bdBitmap.width, this.bdBitmap.height );
			
			this.bdBitmap.draw( s );

			g.clear();

			// pre-divide. i don't quite remember what this is.
			var alpha:Number = Math.abs(dayPct-0.75);

			if ( alpha > 0.25 ) {
				return;
			}
			alpha = 1 - alpha/0.25;
			this.bdBitmap.draw( this.starShape, null, new ColorTransform(1,1,1,alpha ) );

		} //

		private function drawFixedStars( s:Shape, randMap:RandomMap ):void {

			var g:Graphics = s.graphics;
			g.clear();

			for( var i:int=1; i <= 70; i++ ) {

				g.beginFill( 0xFFFFFF, randMap.getNumberAt( i*3, i )*0.75 );
				g.drawCircle( randMap.getNumberAt( i*5, i*3 )*this.bdBitmap.width,
					randMap.getNumberAt( i*2, i*5 )*this.bdBitmap.width/2,
					0.5 + 2*randMap.getNumberAt( i*7, i*2 ) );

			} // for-loop.

		} //

		/**
		 * gets a gradient value from an array of values. It basically treats the values in the array as
		 * fixed points in the gradient and returns the intepolated value at a given percent through the array.
		 * 
		 * pct - the percent of the way through the array at which to get the interpolated value.
		 * 
		 * currently assumes all the values are evenly spaced - need to fix that 'later.'
		 */
		private function getGradientValue( a:Array, pct:Number ):uint {

			var i:int = Math.floor( pct*(a.length-1) );

			// just math.
			var t:Number = pct*(a.length-1) - i;

			var c1:uint = a[i];
			var c2:uint = a[i+1];

			var r:int = (1-t)*( c1 >> 16 ) + t*( c2 >> 16 );
			var g:int = (1-t)*( (c1 >> 8)&0xFF ) + t*( (c2>>8)&0xFF );
			var b:int = (1-t)*( c1&0xFF ) + t*( c2&0xFF );

			return ( r << 16 ) + ( g << 8 ) + b;

		} //

	} // class
	
} // package