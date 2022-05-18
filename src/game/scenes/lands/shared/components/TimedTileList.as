package game.scenes.lands.shared.components {

	import ash.core.Component;
	
	import game.scenes.lands.shared.classes.TimedTile;

	public class TimedTileList extends Component {

		public var timedTiles:Vector.<TimedTile>;

		public function TimedTileList() {

			this.timedTiles = new Vector.<TimedTile>();

		} //

		public function addTile( tile:TimedTile ):void {

			this.timedTiles.push( tile );

		} //

	} // class

} // package