package game.scenes.lands.shared.tileLib.classes {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	/**
	 * Tile types for all biomes are now stored in a single xml file, but the different
	 * biomes can change what tiles are available in each tile set.
	 * 
	 * For every biome this class stores a list of TileSetSwap objects.
	 * Each TileSetSwap object stores a list of tileTypes that will be swapped into a given tileSet.
	 * 
	 */
	public class BiomeTileSwapper {

		/**
		 * maps biomeName -> vector of TileSetSwap objects.
		 * each tileSetSwap object in the list will swap out tileTypes for a single tileSet.
		 */
		private var biomeSwaps:Dictionary;

		/**
		 * tracks the name of the last biome whose patched-tile types were added,
		 * so these can be taken out again automatically
		 * ( we don't need to tell the swapper which biome is being swapped out )
		 */
		private var lastBiome:String;

		/**
		 * list of any default tiles that had been replaced by a swap. these need to be
		 * swapped back in when the biome changes, unless the next biome also replaces them.
		 */
		private var replaced:Vector.<TypeSelector>;

		public function BiomeTileSwapper() {

			this.biomeSwaps = new Dictionary();

			this.replaced = new Vector.<TypeSelector>();

		} //

		/**
		 * Creates a new tileType swap-out for the given tileSet in the given Biome.
		 */
		public function createSetSwap( biomeName:String, tileSet:TileSet ):TileSetSwapList {

			var swapList:Vector.<TileSetSwapList> = this.biomeSwaps[ biomeName ] as Vector.<TileSetSwapList>;
			if ( swapList == null ) {

				// create the tileSet swapList for the biome, if it doesn't yet exist.
				swapList = new Vector.<TileSetSwapList>();
				this.biomeSwaps[ biomeName ] = swapList;

			} //

			var tileSetSwap:TileSetSwapList = new TileSetSwapList( tileSet );
			swapList.push( tileSetSwap );

			return tileSetSwap;

		} //

		/**
		 * get the set of swappable tileTypes for the given biome and tileSet.
		 */
		public function getSwapSet( biomeName:String, tileSet:TileSet ):TileSetSwapList {

			var swapList:Vector.<TileSetSwapList> = this.biomeSwaps[ biomeName ] as Vector.<TileSetSwapList>;
			var swapSet:TileSetSwapList;

			var setName:String = tileSet.name;

			if ( swapList == null ) {

				// create the tileSet swapList for the biome, if it doesn't yet exist.
				swapList = new Vector.<TileSetSwapList>();
				this.biomeSwaps[ biomeName ] = swapList;

			} //

			// try to find a swapSet match for the given tileSet.
			for( var i:int = swapList.length-1; i >= 0; i-- ) {

				if ( swapList[i].tileSet.name == setName ) {
					return swapList[i];
				} //

			} //

			// no swap set for the given biome-tileSet combo. create a new swap set, add it to the list, and return it.
			swapSet = new TileSetSwapList( tileSet );
			swapList.push( swapSet );

			return swapSet;

		} //

		/*public function removeBiomeTiles():void {

			if ( lastBiome == null ) {
				return;
			}

			// get the list of all tileSets with swaps from the oldBiome and remove their tiles.
			var swapList:Vector.<TileSetSwapList> = this.biomeSwaps[ lastBiome ] as Vector.<TileSetSwapList>;
			
			if ( swapList != null ) {
				
				for( var i:int = swapList.length-1; i >= 0; i-- ) {
					swapList[i].removeTilesFromSet();
				}
				
			} //

		} //*/

		public function addBiomeTiles( newBiome:String ):void {

			// get the list of all tileSets with swaps from the oldBiome and remove their tiles.
			var swapList:Vector.<TileSetSwapList> = this.biomeSwaps[ newBiome ] as Vector.<TileSetSwapList>;

			if ( swapList != null ) {

				for( var i:int = swapList.length-1; i >= 0; i-- ) {
					swapList[i].addTilesToSet( this.replaced );
				}

			} //

			lastBiome = newBiome;

		} //

		public function swapTiles( newBiome:String ):void {

			// place back in any replaced tiles, as long as new tiles haven't already been put
			// into their positions.
			// doing this might entail some duplication of effort - a replaced tile might be put back into the list
			// only to get removed again by the new biome. it's possible to get around this, but it makes the code more confusing.
			if ( this.replaced ) {
				this.restoreReplaced();
			} //

			if ( this.lastBiome != null ) {

				// get the list of all tileSets with swaps from the oldBiome and remove their tiles.
				var swapList:Vector.<TileSetSwapList> = this.biomeSwaps[ lastBiome ] as Vector.<TileSetSwapList>;
				var i:int;

				if ( swapList != null ) {

					for( i = swapList.length-1; i >= 0; i-- ) {
						swapList[i].removeTilesFromSet();
					}

				} //

			} // ( this.lastBiome != null )

			// get the list of all tileSetSwaps for the new biome and add their tiles.
			swapList = this.biomeSwaps[ newBiome ] as Vector.<TileSetSwapList>;

			if ( swapList != null ) {

				for( i = swapList.length-1; i >= 0; i-- ) {
					swapList[i].addTilesToSet( this.replaced );
				}
				
			} //

			lastBiome = newBiome;

		} //

		/**
		 * restore any tiles that were replaced by a previous swap
		 * (and that haven't been replaced by a new swap)
		 */
		private function restoreReplaced():void {

			//var tileSet:TileSet;
			//var tileType:TileType;
			var sel:TypeSelector;

			//var max:int = this.replaced.length-1;

			for( var i:int = this.replaced.length-1; i >= 0; i-- ) {
				
				sel = this.replaced[i];
				//tileSet = sel.tileSet;
				//tileType = sel.tileType;

				sel.tileSet.replaceTileType( sel.tileType );

				// swap tile back in.
				/*tileSet.addTileType( tileType );
				if ( i == max ) {
					this.replaced.pop();
				} else {
					this.replaced[i] = this.replaced.pop();
				}
				max--;*/

			} // for-loop.

			this.replaced.length = 0;

		} // restoreReplaced()

	} // class
	
} // package