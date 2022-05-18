package game.scenes.mocktropica.cheeseExterior.components {

	import ash.core.Component;

	public class GlitchSign extends Component {

		/**
		 * time since last glitch switch.
		 */
		public var timer:Number;

		public function GlitchSign() {

			// timer starts high to make sure they actually see the sign flickering.
			this.timer = 3;

		} //

	} // End GlitchSign

} // End package