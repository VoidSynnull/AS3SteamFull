package game.scenes.lands.shared.ui {

	/**
	 * controls scrolling over the scene when in editMode.
	 * this had to be a LandPane before because it had side-scroll buttons that appeared;
	 * 
	 * TO-DO: remove use of SimpleUpdater, replace with InputManager onEnterFrame
	 * 
	 */

	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.systems.CameraSystem;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.virusHunter.condoInterior.components.SimpleUpdater;
	import game.scenes.lands.shared.ui.panes.LandPane;

	public class ScrollControl extends LandPane {

		private var _allowScroll:Boolean = false;
		public function get allowScroll():Boolean {
			return this._allowScroll;
		}
		public function set allowScroll( b:Boolean ):void {
			this._allowScroll = b;
		}

		private var _maxScrollSpeed:int = 160;

		private var _isScrolling:Boolean = false;

		private var scrollEntity:Entity;
		/**
		 * current scrolling location that the camera pans to.
		 */
		private var scrollSpatial:Spatial;

		private var isOpen:Boolean = false;

		/**
		 * measures how long user has been scrolling. use scrollTime to slowly ramp up the scrolling speed.
		 */
		private var scrollTime:Number = 0;
		private var scroll_dx:int;
		private var scroll_dy:int;

		/*protected var btnUp:DisplayObjectContainer;
		protected var btnDown:DisplayObjectContainer;
		protected var btnLeft:DisplayObjectContainer;
		protected var btnRight:DisplayObjectContainer;*/

		private var scrollBounds:Rectangle;
		private var camera:CameraSystem;

		public function ScrollControl( pane:MovieClip, group:LandUIGroup ) {

			super( pane, group, false );

			this.camera = group.getSystem( CameraSystem ) as CameraSystem;

			this.scrollBounds = group.landGroup.sceneBounds;

			//this.initButtons();
			this.createScrollEntity();

		} //

		/*private function scrollBtnDown( e:MouseEvent ):void {

			var t:* = e.target;
			
			if ( t == this.btnLeft ) {
				
				this.scroll_dx = -1;
				this.scroll_dy = 0;
				
			} else if ( t == this.btnRight ) {
				
				this.scroll_dx = 1;
				this.scroll_dy = 0;
				
			} else if ( t == this.btnUp ) {
				
				this.scroll_dx = 0;
				this.scroll_dy = -1;
				
			} else {
				
				this.scroll_dx = 0;
				this.scroll_dy = 1;
				
			} //

			this.scrollTime = 0;			// used to slowly ramp up scrolling.
			this._isScrolling = true;

		} //*/

		private function onKeyDown( e:KeyboardEvent ):void {

			var key:int = e.keyCode;

			var new_dx:int;
			var new_dy:int;

			if ( key == Keyboard.LEFT ) {

				new_dx = -1;
				new_dy = 0;

			} else if ( key == Keyboard.RIGHT ) {

				new_dx = 1;
				new_dy = 0;

			} else if ( key == Keyboard.UP ) {

				new_dx = 0;
				new_dy = -1;

			} else if ( key == Keyboard.DOWN ) {

				new_dx = 0;
				new_dy = 1;

			} else {
				return;
			}

			if ( new_dx != this.scroll_dx || new_dy != this.scroll_dy ) {

				this.scroll_dx = new_dx;
				this.scroll_dy = new_dy;
				this.scrollTime = 0;
			}

			this._isScrolling = true;

		} //

		private function onKeyUp( e:KeyboardEvent ):void {

			var key:int = e.keyCode;

			// might make this check better in the future to allow holding down successive keys.
			if ( key == Keyboard.LEFT || key == Keyboard.RIGHT || key == Keyboard.DOWN || key == Keyboard.UP ) {
				this._isScrolling = false;
			} //

		} //

		private function doScroll( t:Number ):void {

			if ( !this._isScrolling ) {
				return;
			}

			this.scrollTime += t;
			if ( this.scrollTime > 3 ) {
				this.scrollTime = 3;
			}

			if ( this.scroll_dx != 0 ) {
				this.scrollSpatial.x += this.scroll_dx*(this.scrollTime/3)*this._maxScrollSpeed;

				if ( this.scrollSpatial.x < this.camera.viewportWidth/2 ) {
					this.scrollSpatial.x = this.camera.viewportWidth/2;
				} else if ( this.scrollSpatial.x > ( this.camera.areaWidth - this.camera.viewportWidth/2 ) ) {
					this.scrollSpatial.x = this.camera.areaWidth - this.camera.viewportWidth/2;
				} //

			} else {

				this.scrollSpatial.y += this.scroll_dy*(this.scrollTime/3)*this._maxScrollSpeed;
				if ( this.scrollSpatial.y < this.camera.viewportHeight/2 ) {
					this.scrollSpatial.y = this.camera.viewportHeight/2;
				} else if ( this.scrollSpatial.y > ( this.camera.areaHeight - this.camera.viewportHeight/2 ) ) {
					this.scrollSpatial.y = this.camera.areaHeight - this.camera.viewportHeight/2;
				} //

			} //

		} //

		private function scrollBtnUp( e:MouseEvent ):void {

			this._isScrolling = false;

		} //

		override public function hide():void {

			this._isScrolling = false;

			if ( this.isOpen == false ) {
				return;
			}
			this.isOpen = false;

			this.removeKeyListener( this.onKeyDown, this.onKeyUp );

			super.hide();

			( this.scrollEntity.get( SimpleUpdater ) as SimpleUpdater ).paused = true;

			/*this.btnLeft.visible = false;
			this.btnRight.visible = false;
			this.btnUp.visible = false;
			this.btnDown.visible = false;*/

		} //

		override public function show():void {

			if ( this.isOpen ) {
				return;
			}
			this.isOpen = true;

			super.show();

			this.addKeyListener( this.onKeyDown, this.onKeyUp );

			( this.scrollEntity.get( SimpleUpdater ) as SimpleUpdater ).paused = false;

			/*this.btnLeft.visible = true;
			this.btnRight.visible = true;
			this.btnUp.visible = true;
			this.btnDown.visible = true;*/

		} //

		public function getScrollSpatial():Spatial {
			return this.scrollSpatial;
		}
		
		public function getScrollEntity():Entity {
			return this.scrollEntity;
		}

		/*private function initButtons():void {

			var clip:MovieClip = this.myPane as MovieClip;

			this.btnLeft = clip.btnScrollLeft;
			this.btnLeft.visible = false;
			this.makeUpDownButton( this.btnLeft, this.scrollBtnDown, this.scrollBtnUp );
			
			this.btnRight = clip.btnScrollRight;
			this.btnRight.visible = false;
			this.makeUpDownButton( this.btnRight, this.scrollBtnDown, this.scrollBtnUp );
			
			this.btnUp = clip.btnScrollUp;
			this.btnUp.visible = false;
			this.makeUpDownButton( this.btnUp, this.scrollBtnDown, this.scrollBtnUp );
			
			this.btnDown = clip.btnScrollDown;
			this.btnDown.visible = false;
			this.makeUpDownButton( this.btnDown, this.scrollBtnDown, this.scrollBtnUp );
			
		} //*/

		private function createScrollEntity():void {
			
			this.scrollSpatial = new Spatial( 0, 0 );
			this.scrollEntity = new Entity()
				.add( this.scrollSpatial, Spatial );			// spatial is for camera panning
			
			var updater:SimpleUpdater = new SimpleUpdater( this.doScroll );
			updater.paused = true;
			
			this.scrollEntity.add( updater, SimpleUpdater );
			
			this.myGroup.addEntity( this.scrollEntity );
			
		} // createScrollEntity()

	} // class
	
} // package