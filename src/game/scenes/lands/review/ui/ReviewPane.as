package game.scenes.lands.review.ui {

	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.world.LandRealmData;

	public class ReviewPane extends InputPane {

		private var btnApprove:MovieClip;
		private var btnReject:MovieClip;

		private var btnNext:MovieClip;

		public var onApprove:Function;
		public var onReject:Function;
		public var onNext:Function;

		public var onRefreshPending:Function;

		/**
		 * click to try to get more pending realms.
		 */
		public var btnRefresh:MovieClip;

		public var onPopularize:Function;

		private var fldId:TextField;

		/**
		 * realm name, not user name - need to clear this up.
		 */
		private var fldName:TextField;
		private var fldUsername:TextField;
		/**
		 * displays number of realms still pending to be approved.
		 */
		private var fldPending:TextField;
		private var fldMessage:TextField;

		private var btnPopularize:MovieClip;

		public function ReviewPane( pane:MovieClip, input:InputManager ) {

			super( pane, input );

			this.init();

			this.show();

		} //

		public function init():void {

			this.btnApprove = this.pane.btnApprove;
			this.btnReject = this.pane.btnReject;
			this.btnNext = this.pane.btnNext;
			this.btnRefresh = this.pane.btnRefresh;

			this.fldId = this.pane.fldId;
			this.fldName = this.pane.fldName;
			this.fldMessage = this.pane.fldMessage;
			this.fldMessage.selectable = true;

			this.fldPending = this.pane.fldPending;
			this.fldUsername = this.pane.fldUsername;

			this.makeButton( this.btnApprove, this.onApproveClicked );
			this.makeButton( this.btnReject, this.onRejectClicked );
			this.makeButton( this.btnNext, this.onNextClicked );

			this.makeButton( this.btnRefresh, this.onRefreshClicked );

			this.btnPopularize = this.pane.btnPopularize;
			this.makeButton( this.btnPopularize, this.onPopularClicked );

		} //

		public function displayRealm( realm:LandRealmData ):void {

			this.fldId.text = realm.id.toString(10);
			if ( realm.name != null ) {
				this.fldName.text = realm.name;
			}
			this.fldUsername.text = realm.creator_login;

			//this.fldMessage.text = "";

		} //

		public function setTotalPending( count:int ):void {

			this.fldPending.text = count.toString();

		} //

		public function showMessage( msg:String ):void {

			this.fldMessage.text += ( "\n" + msg );
			this.fldMessage.scrollV = this.fldMessage.maxScrollV;

		} //

		private function onRefreshClicked( e:MouseEvent ):void {

			if ( this.onRefreshPending ) {
				this.onRefreshPending();
			}

		} //

		private function onPopularClicked( e:MouseEvent ):void {

			if ( this.onPopularize ) {
				this.onPopularize();
			}

		} //

		private function onApproveClicked( e:MouseEvent ):void {

			if ( this.onApprove ) {
				this.onApprove();
			}

		} //

		private function onRejectClicked( e:MouseEvent ):void {

			if ( this.onReject ) {
				this.onReject();
			}

		} //

		private function onNextClicked( e:MouseEvent ):void {

			if ( this.onNext ) {
				this.onNext();
			}

		} //

	} // class

} // package