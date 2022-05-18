package game.scenes.virusHunter.heart.components {

	import ash.core.Component;

	/**
	 * Gives systems information on what the arm might be doing without explicitly
	 * removing components to disable subsystems.
	 */
	public class RigidArmMode extends Component {

		static public const INACTIVE:uint = 0;
		static public const TARGET:uint = 1;
		static public const EXTEND:uint = 2;
		static public const RETRACT:uint = 4;
		static public const SWAY:uint = 8;
		static public const RESTORE:uint = 16;			// move arms to the angles defined in segment baseTheta.

		public var curMode:uint;

		public function RigidArmMode( mode:uint=INACTIVE ) {

			super();
			curMode = mode;

		} //

		public function addMode( mode:uint ):void {

			curMode |= mode;

		} //

		public function removeMode( mode:uint ):void {

			curMode &= ~mode;

		} //

	} // End RigidArmMode

} // End package