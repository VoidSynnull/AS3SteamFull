package game.scenes.mocktropica.robotBossBattle.components {

	import ash.core.Component;
	
	public class RobotMissile extends Component {

		public static const MISSILE_SPEED:Number = 1500;

		/**
		 * The missile is either a hand-missile or a thrown boulder.
		 * It's not currently necessary to know this. Oh well.
		 */
		public var isMissile:Boolean;

		/**
		 * Missiles are reused so they can be active or inactive.
		 */
		public var active:Boolean = false;

		public function RobotMissile( isMissile:Boolean=true  ) {

			super();

			this.isMissile = isMissile;

		} //

	} // End RobotMissile

} // End package