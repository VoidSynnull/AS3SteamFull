package game.scenes.lands.shared.components {

	/**
	 * class for mapping button clicks to the right tileset, tiletype
	 */
	
	import ash.core.Component;
	
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TileTypeComponent extends Component {

		public var type:TileType;
		public var tileMap:TileMap;

		public function TileTypeComponent( data:TileType, tmap:TileMap ) {

			this.type = data;
			this.tileMap = tmap;

		} //

	} //

} //