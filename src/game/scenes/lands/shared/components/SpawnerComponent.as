package game.scenes.lands.shared.components {
	
	import ash.core.Component;
	
	
	public class SpawnerComponent extends Component {

		public var maxMonsters:int = 12;

		/**
		 * current monster count. some system had better update this.
		 */
		public var monsterCount:int = 0;

		/**
		 * rate in frames, for efficiency, at which to test spawning monsters.
		 * float unnecessary, since its a fuzzy rate anyway.
		 */
		public var spawnTestRate:int = 16;

		/**
		 * count down til next spawn test.
		 */
		public var waitTime:int = 0;

		public function SpawnerComponent() {

		} //
		
	} // class
	
} // package