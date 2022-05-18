package game.scenes.lands.shared.components {

	import ash.core.Component;
	
	
	public class Disintegrate extends Component {

		public function Disintegrate( r:Number=64 ) {

			this.radius = r;

		} //

		/**
		 * radius of disintegration. tiles within this radius will
		 * be destroyed every few frames.
		 */
		public var radius:Number;

		public var timer:int = 0;

		/**
		 * disintegrating every frame is expensive. disintegrate will only
		 * repeat after waiting this number of frames.
		 */
		public var waitFrames:int = 12;

	} // class
	
} // package