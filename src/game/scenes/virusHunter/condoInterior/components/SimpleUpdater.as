package game.scenes.virusHunter.condoInterior.components {

	import ash.core.Component;

	// Executes an update function within the game system. Gives basic onEnterFrames pause capability.
	public class SimpleUpdater extends Component {

		public var update:Function;
		public var paused:Boolean;

		public function SimpleUpdater( func:Function, pause:Boolean=false ) {

			super();

			this.paused = pause;
			this.update = func;

		} //

	} // End class

} // End package