package game.scenes.lands.shared.classes {

	/**
	 * 
	 * identifies a tileType. tileSet optional but often useful.
	 * 
	 * this class is used to pass and store information about a tileType and the set its from,
	 * whereas the TileSelector is used to pass/store information about a specific tile in a tileMap.
	 * 
	 */

	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TypeSelector {

		public var tileType:TileType;
		public var tileSet:TileSet;

		public function TypeSelector( type:TileType=null, tset:TileSet=null ) {

			this.tileType = type;
			this.tileSet = tset;

		} //

	} // class

} // package