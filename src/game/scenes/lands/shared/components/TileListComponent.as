package game.scenes.lands.shared.components {

	/**
	 * 
	 * provides a list of tiles for processing.
	 *
	 */

	import ash.core.Component;
	
	import game.scenes.lands.shared.classes.TileSelector;
	
	public class TileListComponent extends Component {

		public var tiles:Vector.<TileSelector>;

		public function TileListComponent() {

			super();

			this.tiles = new Vector.<TileSelector>();

		} // TileListComponent()

		public function addTile( tile:TileSelector ):void {

			this.tiles.push( tile );

		} //

	} // class

} // package