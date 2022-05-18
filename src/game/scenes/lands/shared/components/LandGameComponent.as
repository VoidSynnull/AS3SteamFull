package game.scenes.lands.shared.components {

	/**
	 * 
	 * Component for entities to reference LandGameData of the current game.
	 * 
	 */
	import ash.core.Component;	
	import game.scenes.lands.shared.classes.LandGameData;
	
	public class LandGameComponent extends Component {

		public var gameData:LandGameData;

		public function LandGameComponent( gameData:LandGameData ) {

			this.gameData = gameData;

		} //

	} // class

} // package