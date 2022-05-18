package game.scenes.lands.shared.tileLib.generation.generators {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;

	public class TunnelGenerator extends MapGenerator {

		// tiles waiting to be checked for cave extension.
		private var fringe:Vector.<LandTile>

		/**
		 * these are the various probabilities that a cave will continue to extend
		 * in one of the given directions.
		 */
		public var digSideChance:Number = 0.75;
		public var digUpChance:Number = 0.35;
		public var digDownChance:Number = 0.45;

		/**
		 * maximum number of tunnels to start at distinct generating points.
		 * note that these tunnels could end up intersecting as they extend
		 * making fewer actual independent cave systems.
		 */
		public var maxTunnels:int = 8;

		public function TunnelGenerator( tmap:TileMap=null ) {

			super( tmap );

		} // CaveGenerator()

		override public function generate( gameData:LandGameData=null ):void {

			this.randomMap = gameData.worldRandoms.randMap;

			this.tileMap.beginSearch();

			this.fringe = new Vector.<LandTile>();

			var count:int = this.randomMap.getRandom()*this.maxTunnels;
			var tile:LandTile;
			while ( this.fringe.length < count ) {

				tile = this.getRandomTile();
				if ( tile.type != 0 ) {
					this.fringe.push( tile );
				}

			} //

			var curSearch:uint = this.tileMap.cur_search;

			var maxRow:int = this.tileMap.rows-1;
			var maxCol:int = this.tileMap.cols-1;

			var r:int;
			var c:int;
			var nxt:LandTile;

			while ( fringe.length > 0 ) {

				tile = fringe.pop();
				tile.type = 0;

				r = tile.row;
				c = tile.col;

				if ( r > 0 ) {

					nxt = this.tileMap.getTile( r-1, c );
					if ( nxt.search_id < curSearch && nxt.type != 0 &&  this.randomMap.getRandom() < this.digUpChance ) {
						nxt.search_id = curSearch;
						fringe.push( nxt );
					}
					
				} else if ( r < maxRow ) {

					nxt = this.tileMap.getTile( r+1, c );
					if ( nxt.search_id < curSearch && nxt.type != 0 &&  this.randomMap.getRandom() < this.digDownChance ) {
						nxt.search_id = curSearch;
						fringe.push( nxt );
					}

				} //

				if ( c > 0 ) {
					
					nxt = this.tileMap.getTile( r, c-1 );
					if ( nxt.search_id < curSearch && nxt.type != 0 &&  this.randomMap.getRandom() < this.digSideChance ) {
						nxt.search_id = curSearch;
						fringe.push( nxt );
					}

				} else if ( c < maxCol ) {
					
					nxt = this.tileMap.getTile( r, c+1 );
					if ( nxt.search_id < curSearch && nxt.type != 0 &&  this.randomMap.getRandom() < this.digSideChance ) {
						nxt.search_id = curSearch;
						fringe.push( nxt );
					}
					
				} //

			} // end-while-loop.

		} // generate()

	} // class

} // package