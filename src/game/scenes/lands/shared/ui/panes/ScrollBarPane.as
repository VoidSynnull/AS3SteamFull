package game.scenes.lands.shared.ui.panes {

	/**
	 * a scrollbar controller that can be used for land menus.
	 * 
	 */

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class ScrollBarPane extends LandPane {

		private const MAX_SCROLL_SPEED:Number = 20;

		/**
		 * der scroll thumb.
		 */
		private var thumb:MovieClip;

		private var upArrow:MovieClip;
		private var downArrow:MovieClip;

		/**
		 * clip being scrolled by the scrollbar.
		 */
		private var scrollTarget:DisplayObjectContainer;

		/**
		 * the space available for the thumb to scroll up and down.
		 * this is computed as the scroll bar height, minus the size of the up and down arrows.
		 */
		private var scrollHeight:int;

		/**
		 * equal to the y-point just below the upArrow.
		 */
		//private var minThumbY:int;

		/**
		 * minThumbY + scrollHeight - thumb.height
		 * this value will change as the thumb size changes.
		 */
		//private var maxThumbY:int;

		/**
		 * bounding rectangle where the thumb can be dragged.
		 */
		private var thumbBounds:Rectangle;

		/**
		 * how long the arrow has been held down so the speed can be increased
		 * the longer it's held. these are actually counted in frames - because who cares?
		 */
		private var arrowTime:int;
		/**
		 * number of frames til holding the up/down arrows reaches maximum scroll speed.
		 */
		private var maxArrowTime:int = 60;

		/**
		 * scroll direction - whether scrolling up or down when holding the scroll arrows.
		 */
		private var scrollDir:int;

		/**
		 * the window visible in the scroll target.
		 */
		private var scrollWindow:Rectangle;

		/**
		 * notice fires when scroll view changes.
		 */
		private var onScrollChanged:Function;

		public function ScrollBarPane( pane:MovieClip, group:LandUIGroup, window:Rectangle ) {

			super( pane, group, false );

			this.scrollWindow = window;

			this.initScrollBar();

		} //

		private function initScrollBar():void {

			var clip:MovieClip = this.clipPane;

			var btn:MovieClip = this.upArrow = clip.upArrow;
			this.makeUpDownButton( btn, this.onArrowPress, this.onArrowRelease );

			btn = this.downArrow = clip.downArrow;
			this.makeUpDownButton( btn, this.onArrowPress, this.onArrowRelease );

			btn = this.thumb = clip.thumb;
			this.makeUpDownButton( btn, this.onThumbPress, this.onThumbRelease );

			this.inputManager.addEventListener( this.myPane, MouseEvent.MOUSE_DOWN, this.onPagePress );
			this.inputManager.addEventListener( this.myPane, MouseEvent.MOUSE_UP, this.onPageRelease );
			this.inputManager.addEventListener( this.myPane, MouseEvent.RELEASE_OUTSIDE, this.onPageRelease );

			var minThumbY:int = this.upArrow.y + this.upArrow.height + 2;
			var maxThumbY:int = this.downArrow.y - 2;
			this.scrollHeight =  (this.downArrow.y - 2) - minThumbY;

			this.thumbBounds = new Rectangle( this.thumb.x, minThumbY, 0, maxThumbY - minThumbY );

		} //

		override public function hide():void {

			super.hide();
			this.inputManager.removeEventListener( this.myPane.stage, MouseEvent.MOUSE_WHEEL, this.onScrollWheel );

		} //

		override public function show():void {

			super.show();
			this.inputManager.addEventListener( this.myPane.stage, MouseEvent.MOUSE_WHEEL, this.onScrollWheel );

		} //

		private function onPagePress( e:MouseEvent ):void {

			if ( (e.target as DisplayObject ) != this.myPane ) {
				return;
			}
			this.inputManager.addEventListener( this.myPane, Event.ENTER_FRAME, this.onPageScroll );

		} //

		private function onPageRelease( e:MouseEvent ):void {

			if ( (e.target as DisplayObject ) != this.myPane ) {
				return;
			}
			this.inputManager.removeEventListener( this.myPane, Event.ENTER_FRAME, this.onPageScroll );

		} //

		/**
		 * set the target scroll object.
		 * onScroll is an optional function that gets called when the scroll value changes.
		 */
		public function setScrollTarget( target:DisplayObjectContainer, onScroll:Function=null ):void {

			this.onScrollChanged = onScroll;
			this.scrollTarget = target;

			// match the thumb size ratio to the scroll window to total scroll clip size ratio.
			var windowRatio:Number = ( this.scrollWindow.height / target.height );
			if ( windowRatio > 1 ) {
				windowRatio = 1;
			}
			this.thumb.height = this.scrollHeight * ( windowRatio );

			this.thumbBounds.height = this.scrollHeight - this.thumb.height;

			// position the thumb at the location matching the target's current y within the scroll window.
			this.thumb.y = this.thumbBounds.y + this.thumbBounds.height * ( -target.y / (target.height-this.scrollWindow.height) );

			//trace( "thumb y: " +  this.thumb.y );

		} //

		/**
		 * a scroll arrow was pressed down.
		 */
		private function onArrowPress( e:MouseEvent ):void {

			this.arrowTime = 0;
			this.inputManager.addEventListener( this.myPane, Event.ENTER_FRAME, this.onArrowScroll );

			if ( e.target == this.upArrow ) {
				this.scrollDir = -1;
			} else {
				this.scrollDir = 1;
			} //

		} //

		/**
		 * a scroll arrow was released.
		 */
		private function onArrowRelease( e:MouseEvent ):void {

			this.inputManager.removeEventListener( this.myPane, Event.ENTER_FRAME, this.onArrowScroll );

		} //

		/**
		 * thumb was pressed down.
		 */
		private function onThumbPress( e:MouseEvent ):void {

			this.inputManager.addEventListener( this.myPane, Event.ENTER_FRAME, this.onDragThumb );

			this.thumb.startDrag( false, this.thumbBounds );

		} //
		
		/**
		 * thumb was released.
		 */
		private function onThumbRelease( e:MouseEvent ):void {

			this.thumb.stopDrag();

			this.inputManager.removeEventListener( this.myPane, Event.ENTER_FRAME, this.onDragThumb );

		} //

		/**
		 * enter_frame event that triggers as the scroll thumb is being dragged.
		 */
		private function onDragThumb( e:Event ):void {

			this.updateScrollRect();

		} //

		private function onScrollWheel( e:MouseEvent ):void {

			this.thumb.y -= 2*e.delta;
			this.updateScrollRect();

		} //

		/**
		 * enter_frame for scrolling by the scrollbar background.
		 */
		private function onPageScroll( e:Event ):void {

			var ytarget:Number = this.myPane.mouseY;

			if ( ytarget < this.thumb.y ) {

				this.thumb.y += ( ytarget - this.thumb.y ) / 6;
				this.updateScrollRect();

			} else if ( ytarget > this.thumb.y + this.thumb.height ) {

				this.thumb.y += ( ytarget - (this.thumb.y+this.thumb.height) ) / 6;
				this.updateScrollRect();

			}

		} //

		/**
		 * enter_frame event that occurs when one of the arrows is being held down.
		 */
		private function onArrowScroll( e:Event ):void {

			// speed increase timer.
			var speedPct:Number = ( ++this.arrowTime / this.maxArrowTime );
			if ( speedPct > 1 ) {
				speedPct = 1;
			}

			this.thumb.y += speedPct*this.scrollDir*this.MAX_SCROLL_SPEED;

			this.updateScrollRect();

		} //

		/**
		 * clamp the thumb to the thumb bounds and
		 * update the target scroll rect to match the thumb.
		 */
		private function updateScrollRect():void {

			if ( this.thumb.y < this.thumbBounds.y ) {

				this.thumb.y = this.thumbBounds.y;

			} else if ( this.thumb.y > this.thumbBounds.bottom ) {

				this.thumb.y = this.thumbBounds.bottom;

			} //

			this.scrollTarget.y = -( this.scrollTarget.height - this.scrollWindow.height )*( this.thumb.y - this.thumbBounds.y ) / this.thumbBounds.height;

			if ( this.onScrollChanged ) {
				this.onScrollChanged();
			}

		} //

	} // class

} // package