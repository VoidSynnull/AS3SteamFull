package game.scenes.lands.shared.ui.panes {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	import game.data.ui.ToolTipType;
	import game.scenes.lands.shared.classes.SharedTipTarget;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.components.SharedToolTip;
	import game.scenes.lands.shared.groups.LandUIGroup;

	/**
	 * 
	 * super class for panes that use the land sharedToolTip and InputManagers.
	 * this helps ensure all the right events get added/removed.
	 * 
	 */

	public class LandPane {

		protected var myPane:DisplayObjectContainer;
		public function get pane():DisplayObjectContainer {
			return this.myPane;
		}

		/**
		 * this should only be used if myPane is a movieclip - not a sprite. sprites don't allow dynamic child references
		 * but movieclips do, so this simplifies things.
		 */
		protected function get clipPane():MovieClip {
			return this.myPane as MovieClip;
		}

		protected var myGroup:LandUIGroup;

		/**
		 * If true, the view pane hides and displays when the pane is shown.
		 * 
		 * use false for when the view pane is shared or controlled by other views.
		 * ( for instance if this LanePane just controls a few buttons on a larger view pane )
		 */
		protected var autoControlPane:Boolean;

		protected var buttons:Vector.<DisplayObjectContainer>;

		/**
		 * maybe use to group events/buttons/tooltips by pane name?
		 */
		//protected var paneName:String;

		public function get visible():Boolean {
			return this.myPane.visible;
		} //

		/**
		 * auto control pane indicates that this pane owns the clip it recieves and will hide it and show it automatically,
		 * as well as remove it from the display on destroy()
		 */
		public function LandPane( pane:DisplayObjectContainer, group:LandUIGroup, autoPane:Boolean=true ) {

			this.myPane = pane;
			this.myGroup = group;

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
		public function makeButton( btn:DisplayObjectContainer, func:Function, rollOver:int=0, rollOverText:String=null ):void {

			this.myGroup.inputManager.addEventListener( btn, MouseEvent.CLICK, func );
			var tipTarget:SharedTipTarget = this.myGroup.sharedTip.addClipTip( btn, ToolTipType.CLICK, rollOverText, this.myPane.visible );

			if ( btn is MovieClip ) {

				btn.mouseChildren = false;
				var mc:MovieClip = btn as MovieClip;
				mc.gotoAndStop( 1 );
				if ( mc.hilite ) {
					mc.hilite.mouseEnabled = false;
					mc.hilite.visible = false;
				}

			}

			if ( rollOver != 0 ) {
				tipTarget.rollOverFrame = rollOver;
			}

			this.buttons.push( btn );

		} //


		/**
		 * this creates a button that listens for both mouse up and mouse down events - not just clicks.
		 */
		public function makeUpDownButton( btn:DisplayObjectContainer, down:Function, up:Function, rollOver:int=0 ):void {
			
			this.myGroup.inputManager.addEventListener( btn, MouseEvent.MOUSE_DOWN, down );
			this.myGroup.inputManager.addEventListener( btn, MouseEvent.MOUSE_UP, up );
			this.myGroup.inputManager.addEventListener( btn, MouseEvent.RELEASE_OUTSIDE, up );
			
			var tipTarget:SharedTipTarget = this.myGroup.sharedTip.addClipTip( btn, ToolTipType.CLICK, null, this.myPane.visible );
			if ( rollOver != 0 ) {
				tipTarget.rollOverFrame = rollOver;
			}

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
				this.myGroup.inputManager.addEventListener( this.myPane.stage, KeyboardEvent.KEY_DOWN, keyDownFunc );
			}
			if ( keyUpFunc ) {
				this.myGroup.inputManager.addEventListener( this.myPane.stage, KeyboardEvent.KEY_UP, keyUpFunc );
			} //

		} //

		/**
		 * remove key listeners attached to this.myPane.stage
		 * Make sure the keyDownFunc, keyUpFuncs really refer to active key listeners.
		 */
		public function removeKeyListener( keyDownFunc:Function=null, keyUpFunc:Function=null ):void {
			
			if ( keyDownFunc ) {
				this.myGroup.inputManager.removeEventListener( this.myPane.stage, KeyboardEvent.KEY_DOWN, keyDownFunc );
			}
			if ( keyUpFunc ) {
				this.myGroup.inputManager.removeEventListener( this.myPane.stage, KeyboardEvent.KEY_UP, keyUpFunc );
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

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				input.pauseListeners( this.buttons[i] );
				tips.deactivate( this.buttons[i] );

			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = false;
				this.myPane.visible = false;
				this.myPane.mouseChildren = false;
			}

		} //

		public function show():void {

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				input.unpauseListeners( this.buttons[i] );
				tips.reactivate( this.buttons[i] );

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

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				input.pauseListeners( this.buttons[i] );
				tips.deactivate( this.buttons[i] );

			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = false;
				this.myPane.mouseChildren = false;
			}

		} //

		public function unpause():void {

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				input.unpauseListeners( this.buttons[i] );
				tips.reactivate( this.buttons[i] );

			} //

			if ( this.autoControlPane ) {
				this.myPane.mouseEnabled = true;
				this.myPane.mouseChildren = true;
			}

		} //

		public function destroy():void {

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;

			// depending on the order of things, the input and tips might have been destroyed already.
			if ( input ) {
	
				for( var i:int = this.buttons.length-1; i >= 0; i-- ) {
	
					input.removeListeners( this.buttons[i] );
	
				} //

			}

			if ( tips ) {

				for( i = this.buttons.length-1; i >= 0; i-- ) {

					tips.removeToolTip( this.buttons[i] );

				} //

			} //

			if ( this.autoControlPane && this.myPane && this.myPane.parent ) {
				this.myPane.parent.removeChild( this.myPane );
			}

			this.buttons.length = 0;
			this.myGroup = null;
			this.myPane = null;

		} //

		/**
		 * convenience function for sub-class accessing the input manager.
		 */
		protected function get inputManager():InputManager {
			return this.myGroup.inputManager;
		}

		protected function get sharedToolTip():SharedToolTip {
			return this.myGroup.sharedTip;
		}

	} // class
	
} // package