package game.scenes.lands.review.ui {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.components.InputManager;

	/**
	 * An input pane is any pane that uses an InputManager component to handle its input.
	 * there is also support for a collection of buttons, pausing/unpausing the pane, and destroying the pane.
	 */

	public class InputPane {

		protected var inputManager:InputManager;

		protected var myPane:MovieClip;
		public function get pane():MovieClip {
			return this.myPane;
		}

		protected var buttons:Vector.<DisplayObjectContainer>;

		public function get visible():Boolean {
			return this.myPane.visible;
		} //

		/**
		 * If true, the view pane hides and displays when the pane is shown.
		 * 
		 * use false for when the view pane is shared or controlled by other views.
		 * ( for instance if this LanePane just controls a few buttons on a larger view pane )
		 */
		protected var autoControlPane:Boolean;

		/**
		 * auto control pane indicates that this pane owns the clip it recieves and will hide it and show it automatically,
		 * as well as remove it from the display on destroy()
		 */
		public function InputPane( pane:MovieClip, input:InputManager, autoPane:Boolean=true ) {

			this.myPane = pane;

			this.inputManager = input;
			this.autoControlPane = autoPane;

			if ( autoPane ) {
				this.myPane.mouseEnabled = false;
				this.myPane.mouseChildren = false;
				this.myPane.visible = false;
			}

			this.buttons = new Vector.<DisplayObjectContainer>();
			
		} //
		
		/**
		 * turns a display object into a button with a MouseEvent.CLICK event handler.
		 */
		public function makeButton( btn:DisplayObjectContainer, func:Function ):void {
			
			this.inputManager.addEventListener( btn, MouseEvent.CLICK, func );

			if ( btn is MovieClip ) {
				
				btn.mouseChildren = false;
				var mc:MovieClip = btn as MovieClip;
				mc.gotoAndStop( 1 );
				if ( mc.hilite ) {
					mc.hilite.mouseEnabled = false;
					mc.hilite.visible = false;
				}

			}

			this.buttons.push( btn );

		} //
		
		/**
		 * this creates a button that listens for both mouse up and mouse down events - not just clicks.
		 */
		public function makeUpDownButton( btn:DisplayObjectContainer, down:Function, up:Function ):void {
			
			this.inputManager.addEventListener( btn, MouseEvent.MOUSE_DOWN, down );
			this.inputManager.addEventListener( btn, MouseEvent.MOUSE_UP, up );
			this.inputManager.addEventListener( btn, MouseEvent.RELEASE_OUTSIDE, up );
			
			if ( btn is MovieClip ) {
				( btn as MovieClip ).gotoAndStop( 1 );
			}
			
			this.buttons.push( btn );
			
		} //
		
		/**
		 * add key listeners attached to this.myPane.stage
		 */
		public function addKeyListener( keyDownFunc:Function=null, keyUpFunc:Function=null ):void {
			
			if ( keyDownFunc ) {
				this.inputManager.addEventListener( this.myPane.stage, KeyboardEvent.KEY_DOWN, keyDownFunc );
			}
			if ( keyUpFunc ) {
				this.inputManager.addEventListener( this.myPane.stage, KeyboardEvent.KEY_UP, keyUpFunc );
			} //
			
		} //
		
		/**
		 * remove key listeners attached to this.myPane.stage
		 * Make sure the keyDownFunc, keyUpFuncs really refer to active key listeners.
		 */
		public function removeKeyListener( keyDownFunc:Function=null, keyUpFunc:Function=null ):void {
			
			if ( keyDownFunc ) {
				this.inputManager.removeEventListener( this.myPane.stage, KeyboardEvent.KEY_DOWN, keyDownFunc );
			}
			if ( keyUpFunc ) {
				this.inputManager.removeEventListener( this.myPane.stage, KeyboardEvent.KEY_UP, keyUpFunc );
			} //
			
		} //
		
		/**
		 * reusable close click function that subclasses can set as the mouseDown event
		 * in order to make a close button that does nothing extra.
		 */
		public function closeClick( e:MouseEvent ):void {
			this.hide();
		} //
		
		public function hide():void {
			
			var input:InputManager = this.inputManager;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {
				
				input.pauseListeners( this.buttons[i] );

			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = false;
				this.myPane.visible = false;
				this.myPane.mouseChildren = false;
			}

		} //
		
		public function show():void {
			
			var input:InputManager = this.inputManager;
			
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {
				
				input.unpauseListeners( this.buttons[i] );
				
			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = true;
				this.myPane.visible = true;
				this.myPane.mouseChildren = true;
			}
			
		} //
		
		/**
		 * remove event listeners without closing.
		 */
		public function pause():void {
			
			var input:InputManager = this.inputManager;
			
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				input.pauseListeners( this.buttons[i] );

				
			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = false;
				this.myPane.mouseChildren = false;
			}
			
		} //
		
		public function unpause():void {
			
			var input:InputManager = this.inputManager;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {
				
				input.unpauseListeners( this.buttons[i] );
				
			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = true;
				this.myPane.mouseChildren = true;
			}

		} //
		
		public function destroy():void {
			
			var input:InputManager = this.inputManager;

			// depending on the order of things, the input and tips might have been destroyed already.
			if ( input ) {
				
				for( var i:int = this.buttons.length-1; i >= 0; i-- ) {
					
					input.removeListeners( this.buttons[i] );
					
				} //
				
			}

			if ( this.autoControlPane && this.myPane && this.myPane.parent ) {
				this.myPane.parent.removeChild( this.myPane );
			}

			this.buttons.length = 0;
			this.myPane = null;
			
		} //

	} // class
	
} // package