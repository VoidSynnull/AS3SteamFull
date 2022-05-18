package game.scenes.mocktropica.robotBossBattle.classes {

	public class State {

		public var id:String;

		/**
		 * Enter state and leave state functions, currently with no parameters.
		 */
		public var onEnter:Function;
		public var onLeave:Function;

		public function State( name:String, enter:Function=null, leave:Function=null ) {

			this.id = name;

			this.onEnter = enter;
			this.onLeave = leave;

		} //

	} // End State
	
} // End package