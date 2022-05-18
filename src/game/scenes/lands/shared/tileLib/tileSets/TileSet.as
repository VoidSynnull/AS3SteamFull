package game.scenes.lands.shared.tileLib.tileSets {

	/**
	 * Combines a tileMap with all the information about its tile types, display information,
	 * renderer, etc.
	 * 
	 * TileSet can be subclassed for more specific types of tile set - but for the moment
	 * it turned out this was unnecessary.
	 * 
	 */

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TileSet {

		public var name:String;

		/**
		 * true when all tileTypes for this set have been loaded.
		 */
		protected var _loadedCount:Boolean;
		public function get loaded():Boolean {
			return ( this._loadedCount == this.tileTypes.length );
		}

		/**
		 * not to be confused with tile types, this is the set type - such as natural, building, decal.
		 * there currently isn't a strict, formal definition of the differences and it's kind of vague what this means in practice.
		 * For example, 'terrain' icons are drawn inside circles, other type icons are drawn inside squares.
		 * 'decal' type is actually used to mark special encoding/decoding rules -- this should probably be changed to something more precise.
		 */
		public var setType:String;

		protected var _tileTypes:Vector.<TileType>;

		/**
		 * Maps type ids to tileType objects.
		 */
		public var typesByCode:Dictionary;

		public var tileSize:int = 64;

		/**
		 * if true, tiles from this set can have multiple tile types by OR'ing together
		 * their bit codes - which should be bitwise disjoint: 1,2,4,8,16 etc.
		 * 
		 * if false, tiles from this set can have one and only one tile type.
		 * 
		 */
		public var allowMixedTiles:Boolean = false;

		public function TileSet() {
		} //

		public function getTypeByCode( typeCode:uint ):TileType {

			return this.typesByCode[ typeCode ];

		} //

		/**
		 * Get all tile types associated with a given tileCode.
		 * Usually this is only a single tile, but if the tile set allows mixed tiles,
		 * several tile types might be combined in the code.
		 */
		public function getTileTypes( tileCode:uint ):Array {

			if ( this.allowMixedTiles == true ) {
				
				var a:Array = new Array();
				var codeBit:uint = 1;

				// tileCodes are OR-d combinations.
				while ( tileCode > 0 ) {
					
					if ( codeBit & tileCode ) {
						a.push( this.typesByCode[ codeBit ] );
						tileCode ^= codeBit;
					}
					codeBit += codeBit;

				} //
				
				return a;
				
			} else {
				
				return [ this.typesByCode[ tileCode ] ];
				
			} //

		} //

		/**
		 * gets the tile type at a given tile, or if mixed tiles are allowed,
		 * returns the first tile type found.
		 */
		[Inline]
		final public function getType( tile:LandTile ):TileType {

			var tileCode:uint = tile.type;

			if ( this.allowMixedTiles == true ) {

				var codeBit:uint = 0x80000000;  // remember: 0x8 is the high bit, not 0xF

				// tileCodes are OR-d combinations.
				while ( codeBit > 0 ) {

					if ( codeBit & tileCode ) {
						return this.typesByCode[ codeBit ];
					}

					codeBit /= 2;
					
				} //
				
				return null;
				
			} else {
				
				return this.typesByCode[ tileCode ];
				
			} //

		} //

		public function get tileTypes():Vector.<TileType> {
			return this._tileTypes;
		}

		public function set tileTypes( v:Vector.<TileType> ):void {

			this.typesByCode = new Dictionary();

			for( var i:int = v.length-1; i >= 0; i-- ) {

				this.typesByCode[ v[i].type ] = v[i];

			} //

			this._tileTypes = v;

		} //

		/**
		 * the tile type will be moved down until it reaches
		 * its correct draw order - highest (last) draw order at index 0.
		 * 
		 * NOTE: there must not be an existing tile with matching tileType since it will not
		 * be removed from the tileTypes vector.
		 */
		public function addTileType( type:TileType ):void {

			// add the tile to the typesByCode dictionary.
			this.typesByCode[ type.type ] = type;

			// insertion search:
			var nextType:TileType;

			var insertIndex:int = this.tileTypes.length;
			this.tileTypes.length = insertIndex;			// expand the vector.

			for( var i:int = insertIndex-1; i >= 0; i-- ) {

				nextType = this.tileTypes[i];
				if ( nextType.drawOrder > type.drawOrder ) {

					// type cannot be moved down any further. insert it at the current insertIndex.
					break;

				} else {

					this.tileTypes[insertIndex] = nextType;
					insertIndex--;

				} //

			} // for-loop.

			this.tileTypes[ insertIndex ] = type;

		} //

		/**
		 * replaces the tileType with type code matching the new tileType.
		 * returns the tileType that was replaced.
		 * 
		 * note: this doesn't work if the new tileType has a different draw order...
		 */
		public function replaceTileType( newType:TileType ):TileType {

			// add the tile to the typesByCode dictionary.
			this.typesByCode[ newType.type ] = newType;

			var oldType:TileType;
			var typeCode:uint = newType.type;

			// since the type is being replaced, it already has a position in the index somewhere.
			for( var i:int = this.tileTypes.length-1; i >= 0; i-- ) {

				if ( this.tileTypes[i].type == typeCode ) {

					oldType = this.tileTypes[i];
					this.tileTypes[i] = newType;
					return oldType;

				} //
				
			} // for-loop.

			return null;

		} //

		public function destroy():void {

			if ( this._tileTypes == null ) {
				return;
			}

			for( var i:int = this._tileTypes.length-1; i >= 0; i-- ) {
				this._tileTypes[i].destroy();
			} //

			this._tileTypes = null;
			this.typesByCode = null;

		} //

	} // class

} // package