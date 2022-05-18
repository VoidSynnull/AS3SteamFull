package game.scenes.lands.shared.components {
	
	import ash.core.Component;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	/**
	 * tracks the tileType and tileLocation currently under the mouse pointer.
	 * handles the hiliting of Realms tiles.
	 */

	public class FocusTileComponent extends Component {

		public var tile:LandTile;
		public var type:TileType;

		public var tileMap:TileMap;

		/**
		 * if focus is disabled, no hilite occurs and the tile focused by the mouse is not tracked.
		 */
		public var enabled:Boolean;
		// not using this at the moment but might in the future.
		//public var map:TileMap;

		public function FocusTileComponent() {

			super();

		} //

	} // class

} // package