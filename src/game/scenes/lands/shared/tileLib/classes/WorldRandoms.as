package game.scenes.lands.shared.tileLib.classes {

	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	
	import game.scenes.lands.shared.classes.Location;
	import game.scenes.lands.shared.world.LandGalaxy;

	/**
	 * class that combines all the different random number maps that the tile world, generators, renderers, use.
	 */

	public class WorldRandoms {

		/**
		 * these values are used to get the correct perlin offsets for adjacent scenes. if the perlin offsets
		 * don't move by the correct perlin amounts, terrains in adjacent scenes won't line up.
		 * 
		 * they should be the row/col size of the terrain tileMap, decreased slightly to ensure a strong overlap.
		 */
		private var _mapCols:int = 0;
		//private var _mapRows:int = 0;

		private const mapWidth:int = 128;
		private const mapHeight:int = 128;

		/**
		 * this is actually the seed for the current biome.
		 */
		protected var _curSeed:uint = 0;

		/**
		 * setting the seed will not automatically rebuild the random maps.
		 * this is because very often the seed changes before the current scene location
		 * or tile row,col size has been set.
		 * 
		 * call refreshMaps() or setLoc() to actually refresh the random maps.
		 */
		public function set seed( s:uint ):void {
			
			this._curSeed = s;

			this.terrainMap.seed = s;
			this.randMap.seed = this.sceneSeed;
			
		} //
		
		public function get seed():uint {
			
			return this._curSeed;
			
		} //

		public var terrainMap:RandomMap;
		public var randMap:RandomMap;

		public var treeMap:RandomMap;

		private var galaxy:LandGalaxy;

		/**
		 * a random place to put these variables. probably will move them.
		 * used to create the tree and forest maps.
		 */
		private const treeSpacingScale:uint = 4;
		private const forestScale:uint = 180;

		public function WorldRandoms( g:LandGalaxy ) {

			this.galaxy = g;

			this.terrainMap = new RandomMap( 0, this.mapWidth, this.mapHeight );
			this.randMap = new RandomMap( 0, this.mapWidth, this.mapHeight );
			this.treeMap = new RandomMap( 0, this.mapWidth, this.mapHeight );

		} //

		/*public function setCurGalaxy( g:LandGalaxy ):void {
			this.galaxy = g;
		} //*/

		/**
		 * this sets the rows,cols in the terrain tileMap, not the size of the perlin map itself.
		 */
		public function setMapSize( rows:int, cols:int ):void {

			// rows, cols are adjusted a bit to ensure overlap in the perlins of adjacent scenes.
			//this._mapRows = rows - 4;
			this._mapCols = cols - 4;

		} //

		public function refreshMaps():void {

			var curLoc:Location = this.galaxy.curLoc;
			var offsetPoint:Point = new Point( curLoc.x*this._mapCols );

			if ( curLoc.x == this.galaxy.maxSceneX ) {

				// the last point here is just the point for scene= -1 -- an imaginary scene only used for terrain interpolation.
				this.terrainMap.interpolatePerlin( mapWidth/2, mapHeight/2, offsetPoint, new Point( -this._mapCols, 0 ) );

			} else {

				this.terrainMap.makeOffsetPerlin( offsetPoint, mapWidth/2, mapHeight/2 );

			} //

			this.refreshTreeMap( offsetPoint );

			this.terrainMap.reset();
			this.randMap.reset();

			this.randMap.seed = this.sceneSeed;
			this.randMap.makeNoise();

		} //

		private function refreshTreeMap( offsetPoint:Point ):void {

			var offsets:Array = [ offsetPoint ];

			var bmd:BitmapData = this.treeMap.getBitmapData();
			bmd.perlinNoise( treeSpacingScale, treeSpacingScale, 1, seed, false, true, 1, true, offsets );

			//overlay second perlin to reverse tunnel values and add variation
			var bmd2:BitmapData = new BitmapData( mapWidth, mapHeight, false, 0xFFFFFF );
			bmd2.perlinNoise( forestScale, forestScale, 1, seed + 1, false, true, 1, true, offsets );
			bmd.draw( bmd2, null, null, "multiply" );

			//add contrast to bring out tunnels
			bmd.applyFilter( bmd, bmd.rect, new Point(0, 0), makeContrastFilter(1) );

			bmd2.dispose();

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

		/**
		 * returns a seed modified by the current x,y location so that different x,y locations
		 * can generate different randMaps. The modified seed should NOT be used for
		 * terrain however, because terrain should be seamless.
		 */
		public function get sceneSeed():uint {

			return ( this._curSeed + this.galaxy.curLoc.x ) % uint.MAX_VALUE;
			//return ( this._curSeed + this.worldLocX + this.mapWidth*this.worldLocY ) % uint.MAX_VALUE;

		} //

		public function destroy():void {

			this.terrainMap.destroy();
			this.randMap.destroy();

		} //

		public function get perlinOffset():Point {

			return new Point( this.galaxy.curLoc.x*this._mapCols, 0 );

		} //

		/**
		 * offsetX and offsetY give the perlin map offsets for the current x,y scene location.
		 * Each scene location has an x,y location so its perlin needs to be offset by the correct amount.
		 * Using these offsets, generators can make their own perlin maps with the same offsets.
		 */
		public function get offsetX():int {

			return this.galaxy.curLoc.x*this._mapCols;

		}

		public function get mapCols():int {
			return this._mapCols;
		}

		/**
		 * not currently used.
		 */
		/*public function get offsetY():int {

			return this.galaxy.curLoc.y*this._mapRows;

		}

		public function get mapRows():int {
			return this._mapRows;
		}*/

	} // class

} // package