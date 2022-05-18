package game.scenes.lands.shared.components {

	import ash.core.Component;
	import ash.core.Entity;
	
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	
	import org.osflash.signals.Signal;

	/**
	 * Represents a tile being targetted by the entity for Interaction, and a signal that is triggered
	 * when the interaction occurs.
	 *
	 */
	public class TileInteractor extends Component {

		public var target:TileSelector;

		// onTileReached( Entity, TileTypeSpecial )
		// tileTypeSpecial is the special ability that was triggered at the tile, if any.
		public var onInteracted:Signal = new Signal( Entity, TileTypeSpecial );

		/**
		 * USED IN REALMS.
		 * 
		 * Component targetting a specific tile in a tileMap.
		 */
		public function TileInteractor( target:TileSelector ) {

			this.target = target;

		} //
		
	} // class
	
} // package