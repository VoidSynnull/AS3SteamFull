package game.scenes.lands.shared.tileLib.classes {

	import flash.display.MovieClip;
	
	import game.scenes.lands.shared.tileLib.LandTile;

	/**
	 * describes a detail clip that can be placed on a land stroke.
	 * 
	 * Note the difference between this and LandDetail.as which is information
	 * about a where a given detail is suppose to be rendered on the screen.
	 * 
	 */
	public class DetailType {

		public var url:String;
		public var clip:MovieClip;

		/**
		 * sides indicates which sides of a tile a detail can appear on - top, bottom, sides, etc.
		 */
		public var sides:uint = LandTile.TOP;

		/**
		 * minimum number of details per edge.
		 */
		public var minDetails:int = 0;

		/**
		 * maximum number of details per side or edge of a tile.
		 */
		public var maxDetails:int = 2;

		// note that the clip is assumed to be loaded at a later time from fileURL.
		public function DetailType( fileURL:String, tileSides:uint=0 ) {

			this.url = fileURL;
			this.sides = tileSides;

		} //

		public function setClip( detailClip:MovieClip ):void {

			this.clip = detailClip;
			this.url = null;

		} //

	} // class

} // package