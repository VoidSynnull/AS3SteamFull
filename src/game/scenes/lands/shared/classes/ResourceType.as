package game.scenes.lands.shared.classes {

	public class ResourceType {

		/**
		 * display name for user.
		 */
		public var name:String;

		/**
		 * internal type string.
		 */
		public var type:String;

		/**
		 * sort of a bad idea to keep active count data in something
		 * that's more of an abstract type. just a short-cut for now.
		 */
		public var count:int = 0;

		/**
		 * might use this eventually instead of the global inventory signal.
		 * onChanged( resource:ResourceType )
		 */
		//public var onChanged:Signal;

		public function ResourceType() {

			//this.onChanged = new Signal( ResourceType );

		} //

	} // class

} // package