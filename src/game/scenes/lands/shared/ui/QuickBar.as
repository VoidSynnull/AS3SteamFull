package game.scenes.lands.shared.ui {

	/**
	 * controls the quickbar that holds all the selected tiles available in Lands.
	 *
	 * note: in all the icon draw commands, 0xFFFFFF is used for the player level,
	 * since any item in the quickbar should be usable anyway.
	 */

	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import engine.util.Command;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.components.SharedToolTip;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.lands.shared.ui.panes.LandPane;
	
	public class QuickBar extends LandPane {

		private const BUTTON_SIZE:int = 52;
		/**
		 * maximum number of items in the quickbar.
		 */
		public const MAX_ITEMS:int = 7;

		/**
		 * maps button sprites to type selectors so a mouseEvent can tell which type is associated
		 * with which button.
		 */
		//private var typeSelectors:Dictionary;

		/**
		 * startX of the quick bar before the button bar pulls out.
		 */
		private var startX:int;

		private var animating:Boolean;
		/**
		 * animation tick counter.
		 */
		private var curFrames:int;
		/**
		 * percent of the tween from previous frame. need this for next-position calculations.
		 */
		private var lastPercent:Number;
		/**
		 * animation time in frames. dont bother with real time because the tick rate isn't sent to this class.
		 */
		private var animateFrames:int = 50;

		/**
		 * tells whether the buttons are visible or not - only true in edit mode.
		 */
		private var buttonsVisible:Boolean;

		/**
		 * function called when a tile type is selected.
		 * onTypeSelected( selector:TypeSelector )
		 */
		//private var onTypeSelected:Function;

		/**
		 * the hilite for the currently selected whatever.
		 */
		private var hiliteClip:Shape;

		private var selectedBtn:TileTypeButton;

		public function QuickBar( pane:MovieClip, group:LandUIGroup, selectFunc:Function=null ) {

			// false means hide/show doesn't change quick bar pane visibility.
			super( pane, group, false );

			//this.onTypeSelected = selectFunc;

			this.startX = this.myPane.x;

			//this.typeSelectors = new Dictionary( true );

			this.hiliteClip = new Shape();
			this.hiliteClip.y = -this.BUTTON_SIZE/2;
			this.myPane.addChild( this.hiliteClip );

		} //

		/**
		 * awful function for caching the quickbar state to an object.
		 * this is because the quickbar dies when you exit to an ad-scene
		 * and has to be restored exactly.
		 */
		public function cacheQuickBarState( cacheObj:Object ):void {

			if ( this.buttons.length == 0 ) {
				return;
			}

			var myCache:Array = new Array( this.buttons.length );

			var btn:TileTypeButton;
			var type:TypeSelector;
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[ i ] as TileTypeButton;
				type = btn.typeSelector;

				myCache[i] = { tileSet:type.tileSet.name, tileType:type.tileType.type, flipped:( btn.scaleX < 0 ) };

			} // for-loop.

			if ( this.selectedBtn != null ) {
				cacheObj.quickSelectIndex = this.getSelectedIndex();
			} else {
				// something actually has to be selected and this will simplify the restore code.
				cacheObj.quickSelectIndex = 0;
			}

			cacheObj.quickBar = myCache;

		} //

		/**
		 * restore the quickbar from a cached object.
		 */
		public function restoreQuickBar( landGroup:LandGroup, cacheObj:Object ):void {

			var myCache:Array = cacheObj.quickBar;
			if ( myCache == null || myCache.length == 0 ) {
				return;
			}

			var info:Object;

			var tileSets:Dictionary = landGroup.gameData.tileSets;
			var tileSet:TileSet;

			for( var i:int = 0; i < myCache.length; i++ ) {

				info = myCache[i];

				tileSet = tileSets[ info.tileSet ];

				this.createNewSelector( new TypeSelector( tileSet.getTypeByCode( info.tileType ), tileSet ), null, info.flipped );

			} //

			// select the last button.
			// stupid work around for now. actually selecting the button with the selection function would trigger
			// a ui-mode change, and would make the hilite visible.
			this.selectedBtn = this.buttons[ cacheObj.quickSelectIndex ];
			this.hiliteSelected( this.selectedBtn, this.selectedBtn.typeSelector.tileSet );

			this.hide();

		} //

		/**
		 * returns the index of the currently selected tileType, or -1 if none selected.
		 */
		public function getSelectedIndex():int {

			if ( this.selectedBtn == null ) {
				return -1;
			}

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				if ( this.buttons[i] == this.selectedBtn ) {
					return i;
				} //

			} //

			// can't ever happen but the compiler insists.
			return -1;

		} //

		public function getCurrentSelection():TypeSelector {

			if ( this.selectedBtn == null ) {
				return null;
			}

			return this.selectedBtn.typeSelector;

		} //

		/**
		 * quick thing to get info on whether the current selection is flipped.
		 * messy but avoids putting extraneous tile flip information in EVERY tile selector.
		 */
		public function isFlipped():Boolean {

			if ( this.selectedBtn == null ) {
				return false;
			}
			return ( this.selectedBtn.scaleX < 0 );

		} //

		private function typeClicked( e:MouseEvent ):void {

			this.selectButton( e.target as TileTypeButton );

		} //

		public function selectButton( btn:TileTypeButton ):void {

			if ( btn == null ) {
				return;
			}
			this.selectedBtn = btn;
			var selector:TypeSelector = btn.typeSelector;

			if ( selector ) {
				
				// second variable indicates tile is flipped.
				this.myGroup.selectTileType( selector, (this.selectedBtn.scaleX < 0) );
				
				if ( selector.tileType != null ) {
					this.hiliteSelected( this.selectedBtn, selector.tileSet );
				} else {
					
					this.hiliteClip.visible = false;
				} //

			} else {
				//trace( "ERROR: NO SELECTOR FOR: " + this.selectedBtn );
			} //

		} //

		private function hiliteSelected( btn:Sprite, tileSet:TileSet ):void {

			var buttonSize:Number = this.BUTTON_SIZE;

			// move the select clip over the selected tile and redraw its outline to match - square for tiles, circle for terrain.
			var g:Graphics = this.hiliteClip.graphics;
			g.clear();
			g.lineStyle( 4, 0xFFFF00 );

			if ( tileSet.setType != "natural" ) {
				g.drawRect( 0, 0, buttonSize, buttonSize );
			} else {
				g.drawCircle( buttonSize/2, buttonSize/2, (buttonSize+1)/2 );
			} //

			this.hiliteClip.visible = true;
			this.hiliteClip.x = btn.x;
			if ( btn.scaleX < 0 ) {
				this.hiliteClip.x -= btn.width;
			}

		} //

		/**
		 * add a tile type (or template?) selection option to the quick bar.
		 * icons are used in several places. eventually need a consistent way to organize them.
		 */
		public function addTypeSelector( selector:TypeSelector, icon:BitmapData=null, flipped:Boolean=false ):void {

			var btn:TileTypeButton;

			// first check for DUPLICATE selector:
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i] as TileTypeButton;
				if ( (flipped && btn.scaleX > 0) || (!flipped && btn.scaleX < 0) ) {
					// same selector but the button in bar has a different flip-state --> so keep both in the bar.
					continue;
				} //

				if ( btn.typeSelector.tileType == selector.tileType ) {

					// SELECTOR ALREADY IN QUICK BAR.
					this.buttons.splice( i, 1 );
					this.buttons.push( btn );

					this.startAnimation();
					this.reassignSelector( btn, selector, icon, flipped );
					this.selectButton( btn );
					return;

				} //

			} //

			if ( this.buttons.length < this.MAX_ITEMS ) {

				// still room for more buttons. add a new one for this type selector.
				this.createNewSelector( selector, icon, flipped );

			} else {

				// all the available spaces are filled. shift the buttons and reuse the last button.
				this.cycleSelectors( selector, icon, flipped );

			} //

			this.startAnimation();

			this.selectButton( this.buttons[ this.buttons.length-1 ] as TileTypeButton );

		} //

		public function isEmpty():Boolean {
			return ( this.buttons.length == 0 );
		}

		/**
		 * remove all quickbar buttons.
		 */
		public function removeAll():void {

			var btn:DisplayObjectContainer;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[ i ];

				this.sharedToolTip.removeToolTip( btn );
				this.inputManager.removeListeners( btn );
				this.myPane.removeChild( btn );

			} //

			if ( this.animating ) {
				this.stopAnimation();
			}

			this.selectedBtn = null;
			this.hiliteClip.visible = false;

			this.myPane.x = this.startX;
			this.buttons.length = 0;

			this.setBarPosition();

		} //

		/**
		 * creates a new button for a tile type -- does not reuse existing buttons so this is only called
		 * if the max buttons haven't been reached yet.
		 * 
		 * a note on adding buttons: buttons are automatically PUSHED onto the superclass button list, so index 0 is
		 * the oldest button, and the top of the stack is the newest. when buttons get reused the oldest ( index 0 )
		 * is the one reused.
		 */
		private function createNewSelector( selector:TypeSelector, icon:BitmapData, flipped:Boolean ):void {

			var btn:TileTypeButton = new TileTypeButton( this.BUTTON_SIZE, selector );
			if ( icon != null ) {
				btn.useIcon( icon );
			} else {
				this.tryDrawButton( btn );
			}

			// add all new children at index 1 so the hilite stays above them.
			// index 0 is the background shape bar.
			this.myPane.addChildAt( btn, 1 );

			btn.x = (this.buttons.length)*( this.BUTTON_SIZE + 4 ) - this.BUTTON_SIZE/2;
			btn.y = -btn.height/2;
			if ( flipped ) {
				btn.x += btn.width;
				btn.scaleX = -1;
			}

			this.makeButton( btn, this.typeClicked );

		} //

		private function cycleSelectors( selector:TypeSelector, icon:BitmapData, flipped:Boolean ):void {

			// take the oldest button and move it back around to the front.
			var btn:TileTypeButton = this.buttons.shift() as TileTypeButton;
			this.buttons.push( btn );

			btn.x = ( this.buttons.length )*( this.BUTTON_SIZE + 4 );
			if ( flipped ) {
				btn.x += btn.width;
			} //
			this.reassignSelector( btn, selector, icon, flipped );

		} //

		/**
		 * moves the bar when a game mode changes. this happens instantly - no animation.
		 */
		public function setBarStart( x:int ):void {

			this.startX = x;
			this.setBarPosition();

		} //

		/**
		 * enter frame for animating the buttons and bar when they are moving.
		 */
		private function animateBar( e:Event ):void {

			if ( ++this.curFrames >= this.animateFrames ) {

				this.stopAnimation();

				this.setButtonPositions();
				this.setBarPosition();
				return;

			} //

			// t moves linearly from 0 to 1, and then ease performs the easing 0-1 func.
			var t:Number = ( (this.curFrames) / this.animateFrames );
			// pct performs a [ pct*Xf + (1-pct)*Xo ] easing calculation, but Xo is not known for these variables...
			var pct:Number = t*t*( 3 - 2*t );

			// i computed the factor below on paper to be the correct factor to multiply ( Xf - Xcur) by at every step.
			var factor:Number = ( (pct - this.lastPercent) / ( 1 - this.lastPercent ) );
			this.lastPercent = pct;		// save.

			// destination for button or bar.
			var destX:Number;
			var btn:DisplayObjectContainer;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {
	
				btn = this.buttons[i];
				destX = i*( this.BUTTON_SIZE + 4 ) - this.BUTTON_SIZE/2;
				if ( btn.scaleX < 0 ) {
					destX += btn.width;
				}

				btn.x += factor*( destX - btn.x );

			} //

			if ( this.selectedBtn != null ) {
				this.hiliteClip.x = this.selectedBtn.x;
				if ( this.selectedBtn.scaleX < 0 ) {
					this.hiliteClip.x -= this.selectedBtn.width;
				}
			}

			// Now animate the bar position itself.
			if ( this.buttonsVisible ) {
				destX = this.startX - this.buttons.length*( this.BUTTON_SIZE + 4 ) + this.BUTTON_SIZE/2;
			} else {
				destX = this.startX;
			} //
			this.myPane.x += factor*( destX - this.myPane.x );

		} //

		private function setButtonPositions():void {

			var btn:DisplayObjectContainer;
			var len:int = this.buttons.length;
			// move all the buttons to the correct positions: low index furthest left, high index at 0
			//techincally only need to do this when the buttons cylce
			for( var i:int = len-1; i >= 0; i-- ) {
				
				btn = this.buttons[i];
				btn.x = i*( this.BUTTON_SIZE + 4 ) - this.BUTTON_SIZE/2;
				if ( btn.scaleX < 0 ) {
					btn.x += btn.width;
				}
				
			} //

			if ( this.selectedBtn != null ) {
				this.hiliteClip.x = this.selectedBtn.x;
				if ( this.selectedBtn.scaleX < 0 ) {
					this.hiliteClip.x -= this.selectedBtn.width;
				}
			}

		} //

		private function setBarPosition():void {

			if ( this.buttonsVisible ) {
				this.myPane.x = this.startX - this.buttons.length*( this.BUTTON_SIZE + 4 ) + this.BUTTON_SIZE/2;
			} else {
				this.myPane.x = this.startX;
			} //

		} //

		private function reassignSelector( btn:TileTypeButton, selector:TypeSelector, icon:BitmapData=null, flipped:Boolean=false ):void {

			if ( flipped ) {
				btn.scaleX = -1;
			} else {
				btn.scaleX = 1;
			}

			btn.setTileType( selector );
			if ( icon != null ) {
				btn.useIcon( icon );
			} else {
				this.tryDrawButton( btn );
			}

		} //

		/**
		 * this function is identical to the one in TileButtonPane but without a level param
		 * (since anything in the quickbar is the right level)
		 * i'd like to organize those into a single function at some point..
		 */
		protected function tryDrawButton( btn:TileTypeButton ):void {

			if ( !btn.tryRedrawButton( 0xFFFFFF ) ) {

				btn.addLoadIcon( this.myGroup );

				// currently only clip tile types can late-load.
				var clipType:ClipTileType = btn.typeSelector.tileType as ClipTileType;

				if ( clipType ) {
					// button tileType resources not loaded.
					this.myGroup.assetLoader.loadSingleDecal( clipType,
						Command.create( this.tileTypeLoaded, btn ) );
				}

			} //

		} //

		/**
		 * redraw a button whose tileType finished loading resources.
		 */
		protected function tileTypeLoaded( btn:TileTypeButton ):void {

			btn.removeLoadIcon();
			btn.redrawButton( 0xFFFFFF );

		} //

		override public function hide():void {

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;
			var btn:DisplayObjectContainer;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i];

				input.pauseListeners( btn );
				tips.deactivate( btn );
				btn.visible = false;

			} //

			this.buttonsVisible = false;
			this.hiliteClip.visible = false;

		} //
		
		override public function show():void {

			var input:InputManager = this.myGroup.inputManager;
			var tips:SharedToolTip = this.myGroup.sharedTip;
			var btn:DisplayObjectContainer;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i];

				input.unpauseListeners( btn );
				tips.reactivate( btn );
				btn.visible = true;

			} //

			this.hiliteClip.visible = this.buttonsVisible = true;

		} //

		/**
		 * start animating all the buttons to their correct positions on the quick bar.
		 */
		public function startAnimation():void {

			this.curFrames = 0;
			this.lastPercent = 0;
			if ( !this.animating ) {
				this.animating = true;
				this.inputManager.addEventListener( this.myPane, Event.ENTER_FRAME, this.animateBar );
			}

		} //

		public function stopAnimation():void {

			if ( this.animating ) {
				this.animating = false;
				this.inputManager.removeEventListener( this.myPane, Event.ENTER_FRAME, this.animateBar );
			}

		} //

		override public function destroy():void {

			if ( this.inputManager ) {
				this.stopAnimation();
			} //

			super.destroy();

			/*if ( this.slideTween ) {
				this.slideTween.kill();
				this.slideTween = null;
			}*/
		}

	} // class

} // package