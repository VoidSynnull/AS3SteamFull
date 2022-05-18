package game.scenes.mocktropica.shared {

	public class Achievement {

		/**
		 * The name of the achievement, eg. High Scorer
		 */
		public var name:String;

		/**
		 * Short description of achievement. 
		 */
		public var description:String;

		/**
		 * Right now it's actually an event string.
		 */
		public var id:String;

		/**
		 * Cheat. Frame to display in the achievement popup. Guess I could write all the labels with the event names
		 * but I'm lazy.
		 */
		public var frame:int;

		public function Achievement( index:int, the_id:String, name:String, desc:String="" ) {

			this.frame = index;

			this.id = the_id;

			this.name = name;
			this.description = desc;

		} //

	} // End Achievement

} // End package