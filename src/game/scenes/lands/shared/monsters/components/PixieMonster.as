package game.scenes.lands.shared.monsters.components {

	import ash.core.Component;

	public class PixieMonster extends Component {

		public const WANDER:int = 1;
		public const ATTACK:int = 2;

		/**
		 * once the pixie has poptanium, it runs away.
		 */
		public const FLEE:int = 3;

		public const LEAVING:int = 4;

		public var state:int;

		/**
		 * marker to tell if pixie path-finding is blocked.
		 * doesn't really belong here but...
		 */
		public var blocked:Boolean;

		/**
		 * true if pixie is stuck inside a rock.
		 */
		//public var stuck:Boolean;

		/**
		 * waiting timer so pixies don't recalculate their actions too quickly.
		 */
		public var waitThink:int = 0;

		public function PixieMonster() {

			this.state = this.WANDER;

			super();

		} //

	} // class

} // package