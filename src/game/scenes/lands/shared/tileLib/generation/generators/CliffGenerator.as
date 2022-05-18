package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * This class is basically an updated version of the old cave generator. Eventually it might replace it outright.
	 * Class uses perlin to define areas of the map that should be made empty.
	 */

	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.classes.WorldRandoms;

	public class CliffGenerator extends MapGenerator {

		public var perlinWidth:int = 64;
		public var perlinHeight:int = 64;
		public var perlinBase:int = 12;		// perlin feature size.

		// values higher than this amount will be cut.
		public var cutThreshold:int = 0xD20000;

		public function CliffGenerator( tmap:TileMap ) {

			super( tmap );

		} // CliffGenerator()

		override public function generate( gameData:LandGameData=null ):void {

			// create the map to cut out bits of the existing map.
			var cutMap:RandomMap = this.makeCutBitmap( this.perlinWidth, this.perlinHeight, this.perlinBase, gameData.worldRandoms );

			var tiles:Vector.< Vector.<LandTile> > = this.tileMap.getTiles();

			for( var r:int = tiles.length-1; r >= 0; r-- ) {

				for( var c:int = this.tileMap.cols-1; c >= 0; c-- ) {

					if ( cutMap.getIntAt( c, r ) > this.cutThreshold ) {

						this.tileMap.clearTileAt( r, c );

					} //

				} //

			} //

			cutMap.destroy();

		} // generate()

		/**
		 * jordan's function for making a tunnel bitmap, modified to use RandomMaps and all that.
		 */
		private function makeCutBitmap( width:int, height:int, baseSize:int, randoms:WorldRandoms ):RandomMap {

			var rm:RandomMap = new RandomMap( randoms.seed, width, height );

			/**
			 * Offset in the land world.
			 */
			var scrollArray:Array = [ randoms.perlinOffset ];

			var bmd:BitmapData = rm.getBitmapData();
			bmd.perlinNoise( baseSize, 3*baseSize, 1, randoms.seed, false, true, 1, true, scrollArray );

			//overlay second perlin to reverse tunnel values and add variation
			var bmd2:BitmapData = new BitmapData( width, height, false, 0 );
			bmd2.perlinNoise( baseSize, 3*baseSize, 1, randoms.seed + 1, false, true, 1, true, scrollArray );
			bmd.draw( bmd2, null, null, BlendMode.MULTIPLY );
			
			//overlay third perlin to decrease cliff frequency and add more shape variation
			bmd2.perlinNoise( 20*baseSize, 20*baseSize, 1, randoms.seed + 2, false, true, 1, true, scrollArray );
			bmd2.applyFilter( bmd2, bmd2.rect, new Point( 0, 0 ), this.makeContrastFilter(2) );
			bmd.draw( bmd2, null, null, BlendMode.DARKEN );

			bmd2.dispose();

			//add contrast to bring out tunnels
			bmd.applyFilter( bmd, bmd.rect, new Point( 0, 0 ), this.makeContrastFilter(2) );

			return rm;

		} //

		/**
		 * this is jordan's function slightly modified. i don't know what it's doing
		 * but you could figure it out, if you really cared.
		 */
		private function makeContrastFilter( contrast:Number ):ColorMatrixFilter {

			var s:Number = contrast + 1;
			var o:Number = 128*( 1 - contrast );

			var m:Array = new Array(

				s, 0, 0, 0, o,
				0, s, 0, 0, o,
				0, 0, s, 0, o,
				0, 0, 0, 1, 0
			);

			return new ColorMatrixFilter( m );

		} //

	} // class

} // package