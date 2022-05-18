package game.scenes.mocktropica.robotBossBattle.components {

	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import ash.core.Component;

	public class RobotBoss extends Component {

		static public const Z_MIN:int = 180;
		static public const Z_MAX:int = 800;

		static public const IDLE:String = "idle";
		static public const BOULDER_IDLE:String = "boulder_idle";
		static public const THROW:String = "boulder_throw";
		static public const DODGE:String = "dodge";
		static public const FETCH_BOULDER:String = "fetch_boulder";
		//static public const FETCH_RETURN:String = "fetch_return";
		static public const MOVE:String = "move";
		static public const KILLED:String = "killed";
		static public const FIRE_MISSILE:String = "missile";

		/**
		 * timer used to pace the frequency of dodging behavior.
		 */
		public var dodgeTimer:Number = 0;
		public var timer:Number;			// timer for idle and wait states.

		public var hitpoints:int = 50;

		public var moveAcceleration:Number = 800;
		public var moveSpeed:Number = 1200;

		public var decceleration:Number = 4000;

		public var dodgeAcceleration:Number = 1000;		// accelerate much faster when dodging.
		public var dodgeSpeed:Number = 1600;

		public var fetchAnimation:Entity;

		public var boulder:Entity;
		public var leftHand:Entity;
		public var rightHand:Entity;

		/**
		 * Displays for the different states.
		 */
		private var stateDisplays:Dictionary;
		//private var defaultDisplay:MovieClip;

		public function RobotBoss() {

			super();

			this.stateDisplays = new Dictionary();

		} //

		public function addStateDisplay( state:String, mc:MovieClip ):void {

			this.stateDisplays[ state ] = mc;

		} //

		public function getStateDisplay( state:String ):MovieClip {

			return this.stateDisplays[ state ];

			/*if ( mc ) {
				return mc;
			}

			return null;
			//return this.defaultDisplay;*/

		} //

		/**
		 * Display to use for states with no display defined.
		 */
		/*public function setDefaultDisplay( state:String ):void {

			this.defaultDisplay = this.stateDisplays[ state ];

		} //*/

	} // End RobotBoss

} // End package