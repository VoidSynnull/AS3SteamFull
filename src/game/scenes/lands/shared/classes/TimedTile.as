package game.scenes.lands.shared.classes {

	public class TimedTile {

		/**
		 * timer counting down to destroy
		 */
		public var timer:Number;

		/**
		 * tile whose contents are being destroyed.
		 */
		public var selector:TileSelector;

		//public var cancel:Boolean = false;

		/**
		 * crumble will generate small particles while the destroy timer
		 * is counting down.
		 */
		public var crumble:Boolean = true;

		public var blastOnComplete:Boolean = false;
		public var destroyOnComplete:Boolean = false;

		/**
		 * set to indicate what should be done with the tile
		 * when the timer is complete.
		 */
		public var timerType:String;

		public function TimedTile( selectedTile:TileSelector, time:Number ) {

			this.selector = selectedTile;
			this.timer = time;

		} //

	} // class
	
} // package