package game.scenes.lands.shared.components {
	
	import ash.core.Component;
	
	/**
	 * marker class for the player's thrown hammer in realms.
	 */

	public class ThrowHammer extends Component {

		/**
		 * called when hammer returns to player.
		 * hammer entity is only param.
		 */
		public var onHammerReturn:Function;

		/**
		 * need to wait a few frames before checking for the hammer returning.
		 * otherwise it will be marked as returning the moment it's thrown.
		 */
		public var waitCount:int = 0;

		public function ThrowHammer( onReturn:Function=null ):void {

			this.onHammerReturn = onReturn;

		} //

	} // class
	
} // package