package game.scenes.lands.shared.tileLib.painters {

	import flash.display.MovieClip;

	/**
	 * 
	 * Describes a land detail to be placed at a given location on the stroke line.
	 * 
	 */
	public class LandDetail {

		public var x:Number;
		public var y:Number;

		public var angle:Number;

		public var detail:MovieClip;
		public var detailFrame:int;

		/**
		 * Order is used to determine the order in which to paint the land detail.
		 * higher draw orders are drawn later.
		 * details painted in incorrect order relative to their land-edge and x,y coordinate
		 * will look like they're floating above other details.
		 */
		public var drawOrder:Number;

		public function LandDetail( detail:MovieClip, dx:Number, dy:Number, angle:Number=0, frame:int=1, order:Number=0 ) {

			this.x = dx;
			this.y = dy;

			this.angle = angle;

			this.detail = detail;
			this.detailFrame = frame;

			this.drawOrder = order;

		} //

	} // class

} // package