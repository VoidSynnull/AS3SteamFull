package game.scenes.lands.shared.components {

	import ash.core.Component;

	public class LandWeatherCollider extends Component {

		/**
		 * true if player is currently getting rained on.
		 */
		public var isHit:Boolean = false;

		/**
		 * the saved value of their original regeneration rate
		 * for after they get out of the rain.
		 */
		public var saveRegen:Number = -1;

		public function LandWeatherCollider() {

			super();

		} //

	} // class

} // package