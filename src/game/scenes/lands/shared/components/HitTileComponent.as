package game.scenes.lands.shared.components {

	/**
	 * 
	 * gives entities information about designated tiles.
	 * not all variables of the component have to be set, if they aren't needed.
	 * 
	 * tileSet might be included too, but is (currently) easily obtainable through the tileMap.
	 * 
	 */

	import ash.core.Component;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class HitTileComponent extends Component {

		public var tile:LandTile;
		public var tileMap:TileMap;

		public var tileType:TileType;

		public var hitChanged:Boolean = false;

		public function HitTileComponent() {
		}

		public function setTile( new_tile:LandTile=null, new_map:TileMap = null, new_type:TileType = null ):void{

			this.tile = new_tile;
			this.tileMap = new_map;
			this.tileType = new_type;

		} //

	} // class

} // package