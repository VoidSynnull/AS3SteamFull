package game.scenes.lands.review {

	/**
	 * Draws scenes from a realm into a single bitmap. The display takes single bitmaps of a scene,
	 * scales them down, and draws them into the next location on the display.
	 */

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.ui.Keyboard;
	
	import game.scenes.lands.review.ui.InputPane;
	import game.scenes.lands.shared.components.InputManager;

	public class RealmDisplay extends InputPane {

		/**
		 * use up the visible width before going offscreen.
		 */
		public const DEST_BITMAP_WIDTH:int = 960;

		/**
		 * height of EACH destination bitmap. the total drawing height available
		 * is the dest bitmap height times the number of destination bitmaps.
		 */
		public const DEST_BITMAP_HEIGHT:int = 1920;

		public const SCENES_PER_ROW:int = 4;
		public const SCENES_PER_COL:int = 16;

		/**
		 * need to use multiple destination bitmaps because of an insane flash error
		 * that i've verified in many separate tests:
		 * 
		 * if you offset a src bitmap too far and draw it into the dest bitmap, the
		 * dest bitmap will not scale before being drawn. amazing.
		 */
		public const DEST_BITMAP_COUNT:int = 2;

		/**
		 * SCENE_DISPLAY_HEIGHT = bitmapSize / SCENES_PER_ROW
		 */
		public var SCENE_DISPLAY_HEIGHT:int;
		public var SCENE_DISPLAY_WIDTH:int;

		/**
		 * called when a scene has finished displaying.
		 */
		public var onSceneComplete:Function;
		/**
		 * called when an entire realm has finished displaying.
		 */
		public var onRealmComplete:Function;

		private var containers:Vector.<Bitmap>;
		private var bitmaps:Vector.<BitmapData>;

		/**
		 * all bitmap containers are held in THIS container to make
		 * events and scrolling simpler.
		 */
		private var mainContainer:Sprite;

		/**
		 * the next available spot to draw a scene. scenes are drawn into the displayBitmap sequentially
		 * in rows and columns.
		 */
		private var sceneDisplayIndex:int = 0;

		/**
		 * putting scroll variables here for the time being.
		 */
		private var scroll_dy:int;
		private var scrolling:Boolean;

		public function RealmDisplay( input:InputManager, parent:DisplayObjectContainer ) {

			super( null, input, false );

			this.mainContainer = new Sprite();
			parent.addChild( this.mainContainer );

			this.initBitmaps( this.mainContainer );

			this.SCENE_DISPLAY_WIDTH = this.DEST_BITMAP_WIDTH / this.SCENES_PER_ROW;

			// the denominator division is because each dest bitmap can only hold half the displayed scenes.
			this.SCENE_DISPLAY_HEIGHT = Math.floor( this.DEST_BITMAP_HEIGHT / (this.SCENES_PER_COL/this.DEST_BITMAP_COUNT) );

			this.initInput();

		} //

		/**
		 * clear the bitmap for a new realm.
		 */
		public function clear():void {

			for( var i:int = this.bitmaps.length-1; i >= 0; i-- ) {
				this.bitmaps[i].fillRect( this.bitmaps[i].rect, 0 );
			} //

			// reset the position for the next scene being drawn.
			this.sceneDisplayIndex = 0;
			this.mainContainer.y = 0;

		} //

		/**
		 * Draw a complete-scene rendering into the realm display. The scene is scaled down
		 * and fitted into the next spot on the large bitmap that displays all scenes.
		 */
		public function drawScene( sceneBitmap:BitmapData ):void {

			var row:int = this.sceneDisplayIndex / this.SCENES_PER_ROW;
			var col:int = this.sceneDisplayIndex % this.SCENES_PER_ROW;

			var scaleX:Number = this.SCENE_DISPLAY_WIDTH / sceneBitmap.width;
			var scaleY:Number = this.SCENE_DISPLAY_HEIGHT / sceneBitmap.height;

			var drawY:int = row*this.SCENE_DISPLAY_HEIGHT;
			var bitmapIndex:int = ( drawY ) / this.DEST_BITMAP_HEIGHT;
			if ( bitmapIndex >= this.bitmaps.length ) {
				this.sceneDisplayIndex++;
				return;
			}
			// offset for the bitmap selected.
			drawY -= bitmapIndex*this.DEST_BITMAP_HEIGHT;

			var mat:Matrix = new Matrix( scaleX, 0, 0, scaleY, col*this.SCENE_DISPLAY_WIDTH, drawY );

			//trace( "DRAW SCENE LOC: " + mat.tx + "," + mat.ty );
			this.bitmaps[ bitmapIndex ].draw( sceneBitmap, mat );

			// advance counter so the next scene is drawn in a new location.
			this.sceneDisplayIndex++;

		} //

		public function lock():void {
			
			for( var i:int = this.bitmaps.length-1; i >= 0; i-- ) {
				this.bitmaps[i].lock();
			}
			
		}
		
		public function unlock():void {
			
			for( var i:int = this.bitmaps.length-1; i >= 0; i-- ) {
				this.bitmaps[i].unlock();
			}
			
		} //

		/**
		 * initialize all the bitmaps being drawn.
		 */
		private function initBitmaps( parent:DisplayObjectContainer ):void {

			this.bitmaps = new Vector.<BitmapData>( this.DEST_BITMAP_COUNT );
			this.containers = new Vector.<Bitmap>( this.DEST_BITMAP_COUNT );

			var bmd:BitmapData;
			var bm:Bitmap;

			for( var i:int = 0; i <= this.DEST_BITMAP_COUNT; i++ ) {

				bmd = new BitmapData( this.DEST_BITMAP_WIDTH, this.DEST_BITMAP_HEIGHT, false, 0 );

				bm = new Bitmap( bmd );
				parent.addChild( bm );
				bm.y = i*this.DEST_BITMAP_HEIGHT

				this.bitmaps[i] = bmd;
				this.containers[i] = bm;

			} //

		} //

		private function initInput():void {

			this.inputManager.addEventListener( this.mainContainer.stage, KeyboardEvent.KEY_DOWN, this.onKeyDown );
			this.inputManager.addEventListener( this.mainContainer.stage, KeyboardEvent.KEY_UP, this.onKeyUp );

		} //

		private function onKeyDown( e:KeyboardEvent ):void {

			var k:uint = e.keyCode;
			/*if ( k == Keyboard.LEFT ) {

				this.scroll_dx = 32;

			} else if ( k == Keyboard.RIGHT ) {

				this.scroll_dx = -32;
			}*/

			if ( k == Keyboard.DOWN ) {

				this.scroll_dy = -32;

			} else if ( k == Keyboard.UP ) {

				this.scroll_dy = 32;

			} //

			this.startScroll();

		} //

		private function onKeyUp( e:KeyboardEvent ):void {

			var k:uint = e.keyCode;
			if ( k == Keyboard.DOWN || k == Keyboard.UP ) {

				this.scroll_dy = 0;

			} //

			if ( this.scroll_dy == 0 ) {

				this.stopScroll();

			} //

		} //

		private function startScroll():void {

			if ( !this.scrolling ) {
				this.inputManager.addEventListener( this.mainContainer, Event.ENTER_FRAME, this.doScroll );
				this.scrolling = true;
			} //

		} //

		private function stopScroll():void {

			if ( this.scrolling ) {
				this.inputManager.removeEventListener( this.mainContainer, Event.ENTER_FRAME, this.doScroll );
				this.scrolling = false;
			}

		} //

		private function doScroll( e:Event ):void {

			/*this.containerBitmap.x += this.scroll_dx;
			if ( this.containerBitmap.x > 0 ) {
				this.containerBitmap.x = 0;
			} else if ( this.containerBitmap.x < -this.containerBitmap.width ) {
				this.containerBitmap.x = -this.containerBitmap.width;
			} //*/

			this.mainContainer.y += this.scroll_dy;
			if ( this.mainContainer.y > 0 ) {
				this.mainContainer.y = 0;
			} else if ( this.mainContainer.y < -this.mainContainer.height ) {
				this.mainContainer.y = -this.mainContainer.height;
			} //

		} //

		override public function destroy():void {

			super.destroy();

			this.stopScroll();

			this.inputManager.removeEventListener( this.mainContainer.stage, KeyboardEvent.KEY_DOWN, this.onKeyDown );
			this.inputManager.removeEventListener( this.mainContainer.stage, KeyboardEvent.KEY_UP, this.onKeyUp );

			if ( this.mainContainer ) {

				if ( this.mainContainer.parent ) {
					this.mainContainer.parent.removeChild( this.mainContainer );
				}
				this.mainContainer = null;

				// dispose all bitmaps.
				for( var i:int = 0; i < this.DEST_BITMAP_COUNT; i++ ) {
					this.bitmaps[i].dispose();
				}

			} //

		} //

	} // class

} // package