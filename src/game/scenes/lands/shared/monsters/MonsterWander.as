package game.scenes.lands.shared.monsters {
	
	import ash.core.Component;
	
	
	public class MonsterWander extends Component {

		/**
		 * maximum time to wait before choosing new destination.
		 */
		public var maxWaitTime:Number = 7;

		public var waitTimer:Number;

		public function MonsterWander() {

			super();

		}

	} // class
	
} // package