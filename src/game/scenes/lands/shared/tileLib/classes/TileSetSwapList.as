package game.scenes.lands.shared.tileLib.classes {

	/**
	 * contains a list of tileTypes that can be swapped in and out of a given tileSet
	 * (currently for when biomes change)
	 */
	import flash.utils.Dictionary;

	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TileSetSwapList {

		private var _tileSet:TileSet;
		private var swapTypes:Vector.<TileType>;

		/**
		 * the tileSet that these swapped tiles apply to.
		 */
		public function get tileSet():TileSet {
			return this._tileSet;
		}

		public function TileSetSwapList( targetSet:TileSet ) {

			this._tileSet = targetSet;
			this.swapTypes = new Vector.<TileType>();

		} //

		/**
		 * set the list of tileTypes that are swapped in and out of this tile set.
		 */
		public function setSwapTypes( swaps:Vector.<TileType> ):void {

			this.swapTypes = swaps;

		} //

		/**
		 * check if there is already a swap type with the given type code.
		 * this is to prevent multiple copies of a swap type being added when you revisit biomes.
		 */
		public function hasSwapType( type:uint ):Boolean {

			for( var i:int = this.swapTypes.length-1; i >= 0; i-- ) {

				if ( this.swapTypes[i].type == type ) {
					return true;
				}

			} //

			return false;

		} //

		public function addSwapType( type:TileType ):void {

			this.swapTypes.push( type );

		} //

		public function addSwapTypes( swaps:Vector.<TileType> ):void {

			var tileType:TileType;
			var type:uint;

			for( var i:int = swaps.length-1; i >= 0; i-- ) {

				tileType = swaps[i];
				type = tileType.type;

				// make sure not to duplicate any swaps by visiting the same biome over and over.
				for( var j:int = this.swapTypes.length-1; j >= 0; j-- ) {

					if ( this.swapTypes[j].type == type ) {

						// skip this type.
						type = 0;		// skip marker.
						break;

					} //

				} // for-loop.

				if ( type != 0 ) {
					this.swapTypes.push( tileType );
				} //

			} // for-loop.

		} //

		public function removeTilesFromSet():void {

			var tileTypes:Vector.<TileType> = this._tileSet.tileTypes;
			var tileDict:Dictionary = this._tileSet.typesByCode;

			var tileType:TileType;

			for( var i:int = this.swapTypes.length-1; i >= 0; i-- ) {

				tileType = this.swapTypes[ i ];

				for( var j:int = tileTypes.length-1; j >= 0; j-- ) {

					if ( tileTypes[j] == tileType ) {

						// remove the tileType from the type-id dictionary.
						// note that the dictionary entry is only deleted if the tile is actually found - since a new tileType might
						// have already taken its place under the same type-code.
						delete tileDict[ tileType.type ];

						// could probably just cut out-of-order and resort. might be faster than splice.
						tileTypes.splice( j, 1 );
						break;

					} //

				} //

			} // for-loop.

		} //

		public function addTilesToSet( replaced:Vector.<TypeSelector> ):void {

			var tileType:TileType;
			var oldType:TileType;

			for( var i:int = this.swapTypes.length-1; i >= 0; i-- ) {

				tileType = this.swapTypes[i];

				if ( this._tileSet.typesByCode[ tileType.type ] != null ) {

					oldType = this._tileSet.replaceTileType( tileType );
					replaced.push( new TypeSelector( oldType, this.tileSet ) );

				} else {

					// complicated because tiles have to be added in the correct
					// drawing sort-order.
					this._tileSet.addTileType( this.swapTypes[i] );

				} //

			} //

		} //

	} // class
	
} // package