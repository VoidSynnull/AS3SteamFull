package game.scenes.lands.review {

	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import engine.ShellApi;
	import engine.group.Scene;
	
	import game.scenes.lands.review.ui.ReviewPane;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.world.LandRealmData;

	public class ReviewUI {

		private var _onLoad:Function;

		private var _parent:Scene;
		private var shellApi:ShellApi;

		private var uiClip:MovieClip;

		//private var btnLoadLocal:MovieClip;
		private var _reviewPane:ReviewPane;
		public function get reviewPane():ReviewPane { return this._reviewPane; }

		private var inputMgr:InputManager;

		/**
		 * no params.
		 */
		public var onLocalLoad:Function;

		public function ReviewUI( parent:Scene, inputManager:InputManager) {

			this._parent = parent;
			this.shellApi = parent.shellApi;

			this.inputMgr = inputManager;

		}

		public function lockInput():void {
			this.uiClip.mouseEnabled = this.uiClip.mouseChildren = false;
		} //

		public function unlockInput():void {
			this.uiClip.mouseEnabled = this.uiClip.mouseChildren = true;
		} //

		public function load( onLoaded:Function=null ):void {

			this._onLoad = onLoaded;

			this.shellApi.loadFile( this.shellApi.assetPrefix + this._parent.groupPrefix + "review_ui.swf", this.onSwfLoaded );

		} //

		private function onSwfLoaded( clip:MovieClip ):void {

			this.uiClip = clip;

			this.initUI();		
			this._parent.overlayContainer.addChildAt( clip, 0 );

			if ( this._onLoad ) {
				this._onLoad();
				this._onLoad = null;
			}

		} //

		public function showMessage( msg:String ):void {

			this.reviewPane.showMessage( msg );

		}

		public function setTotalPending( count:int ):void {
			this.reviewPane.setTotalPending( count );
		} //

		public function displayRealm( realm:LandRealmData ):void {

			this.reviewPane.displayRealm( realm );

		} //

		private function initUI():void {

			this._reviewPane = new ReviewPane( this.uiClip.realmPane, inputMgr );

			//this.btnLoadLocal = this.uiClip.btnLoadLocal;
			this.uiClip.removeChild( this.uiClip.btnLoadLocal );
			//this.inputMgr.addEventListener( this.btnLoadLocal, MouseEvent.CLICK, this.onLoadLocal );

		} //

		private function onLoadLocal( e:MouseEvent ):void {

			if ( this.onLocalLoad ) {
				this.onLocalLoad();
			}

		} //

	} // class
	
} // package