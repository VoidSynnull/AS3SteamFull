package game.scenes.lands.shared.tileLib.templates {

	/**
	 * after a template has been chosen from the templateRegister to be placed on the screen,
	 * its xml data still has to be loaded. the templateProc holds the location where it will
	 * go in the scene, and the file information, until the load completes.
	 */

	public class TemplateProc {

		/**
		 * complete path to template.
		 */
		public var file:String;

		/**
		 * position to place template in scene.
		 */
		public var templateX:int;
		public var templateY:int;

		public function TemplateProc( fileName:String, x:int, y:int ) {

			this.file = fileName;
			this.templateX = x;
			this.templateY = y;

		} //

	} // class

} // package