package game.scenes.lands.shared.tileLib.painters {

	public class BasePainter {

		protected var renderContext:RenderContext;

		//protected var hitBitmap:BitmapData;
		//protected var viewBitmap:BitmapData;

		protected var _drawHits:Boolean = false;

		public function BasePainter( rc:RenderContext=null ) {

			this.setRenderContext( rc );

		} //

		public function setRenderContext( rc:RenderContext ):void {

			this.renderContext = rc;

		} //

		/*public function setViewBitmap( bm:BitmapData ):void {

			this.viewBitmap = bm;

		} //

		public function setHitBitmap( bm:BitmapData ):void {

			this.hitBitmap = bm;

		} //*/

		public function set drawHits( b:Boolean ):void {

			this._drawHits = b;

			/*if ( b == true && this.hitBitmap != null ) {
				
				this._drawHits = true;
				
			} else {
				
				this._drawHits = false;
				
			} //*/

		} //

	} // class

} // package