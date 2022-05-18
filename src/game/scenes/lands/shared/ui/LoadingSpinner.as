package game.scenes.lands.shared.ui {

	/**
	 * 
	 * A sprite that automatically displays a loading bitmap and spins it around
	 * until destroy() is called.
	 * 
	 * Placed inside sprite IconButtons that haven't loaded yet.
	 * 
	 */

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class LoadingSpinner extends Sprite {

		/**
		 * needs the input manager to turn spin the spinning load icon
		 * and to remove the onEnterFrame when it's done.
		 */
		private var inputMgr:InputManager;

		private var loadBitmap:Bitmap;

		/**
		 * spin rate in degrees per frame. (exact timing doesn't matter)
		 */
		private var spinRate:Number = 4;

		public function LoadingSpinner( uiGroup:LandUIGroup ) {

			super();

			this.mouseChildren = this.mouseEnabled = false;

			// put smoothing on to make sure the loadig icon looks okay while spinning?
			this.loadBitmap = new Bitmap( uiGroup.loadingBitmap, "auto", true );
			this.loadBitmap.x = -this.loadBitmap.width/2;
			this.loadBitmap.y = -this.loadBitmap.height/2;

			this.addChild( this.loadBitmap );

			this.inputMgr = uiGroup.inputManager;
			this.inputMgr.addEventListener( this, Event.ENTER_FRAME, this.doUpdate );

		} //

		public function doUpdate( e:Event ):void {

			this.rotation += this.spinRate;

		} //

		public function destroy():void {

			this.inputMgr.removeEventListener( this, Event.ENTER_FRAME, this.doUpdate );

			this.removeChild( this.loadBitmap );
			this.loadBitmap.bitmapData = null;
			this.loadBitmap = null;
			this.inputMgr = null;

		} //

	} // class

} // package