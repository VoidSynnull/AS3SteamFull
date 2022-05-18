package game.scenes.lands.shared.classes {

	/**
	 * specifies a land tile, the set being used, and the tile map.
	 * this can be used to pass or store information about a tile.
	 * 
	 * depending on what information is needed, some of these properties might be left null
	 * 
	 * this has the same properties as the FocusTileComponent, but is more general.
	 * The FocusTileComponent is only used to indicate the tile currently under the mouse cursor
	 * and is handled by the FocusTileSystem.
	 */

	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TileSelector {

		public var tileMap:TileMap;
		public var tile:LandTile;
		public var tileType:TileType;
		//public var tileLayer:TileLayer;

		public function TileSelector( tile:LandTile=null, type:TileType=null, tmap:TileMap=null ) {

			this.tile = tile;
			this.tileType = type;
			this.tileMap = tmap;
			//this.tileLayer = layer;

		}

	} // class
	
} // package