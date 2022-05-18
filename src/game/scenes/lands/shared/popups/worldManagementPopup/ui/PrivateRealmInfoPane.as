package game.scenes.lands.shared.popups.worldManagementPopup.ui {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.world.LandRealmData;

	public class PrivateRealmInfoPane extends RealmInfoPane {

		protected var btnDelete:MovieClip;
		protected var btnShare:MovieClip;

		protected var fldSharedStatus:TextField;

		protected const REJECT_LINK:String = "https://www.poptropica.com/Poptropica-FAQ.html#realms.4";

		/**
		 * this is a box surrounding the shared status stuff
		 * and is hidden when the realm is not shared.
		 */
		protected var sharedBox:MovieClip;

		public function PrivateRealmInfoPane( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			initUI();

		} //

		override protected function initUI():void {

			super.initUI();

			this.btnDelete = this.myPane["btnDelete"];
			this.btnShare = this.myPane["btnShare"];

			this.fldSharedStatus = this.myPane["fldSharedStatus"];

			this.sharedBox = this.myPane["sharedStatusBox"];
			this.sharedBox.mouseEnabled = false;
			this.sharedBox.visible = false;

		} //
		
		public function setPrivateClicks( onVisit:Function, onDeleteWorld:Function, onShareWorld:Function ):void {

			this.setVisitFunction( onVisit );

			this.makeButton( this.btnDelete, onDeleteWorld );
			//this.makeButton( this.btnShare, onShareWorld );
			this.btnShare.visible = false;

		} //

		override public function displayRealm( realmData:LandRealmData ):void {
			
			super.displayRealm( realmData );

			if ( realmData.hasSavedScenes() ) {

				if ( !this.btnShare.mouseEnabled ) {
					this.btnShare.alpha = 1;
					this.btnShare.mouseEnabled = true;
					this.sharedToolTip.reactivate( this.btnShare );
				}


			} else {

				if ( this.btnShare.mouseEnabled ) {
					this.sharedToolTip.deactivate( this.btnShare );
					this.btnShare.alpha = 0.5;
					this.btnShare.mouseEnabled = false;
				}

			} //

			if ( realmData.approveStatus == LandRealmData.REALM_STATUS_REJECTED ) {

				// REALM WAS PREVIOUSLY REJECTED.
				this.showRejectedRealm( realmData );

			} else if ( realmData.shareStatus == LandRealmData.REALM_STATUS_SHARED ) {

				// REALM WAS SHARED, but possibly not yet approved.

				if ( realmData.approveStatus == LandRealmData.REALM_STATUS_APPROVED ) {

					// REALM PREVIOUSLY APPROVED.
					this.showApprovedRealm( realmData );

				} else {

					this.showPendingRealm( realmData );

				} // end-if.

			} else {

				// REALM NOT SHARED.
				this.fldSharedStatus.visible = false;
				this.btnShare.gotoAndStop( 1 );
				this.fldLikes.visible = false;
				this.fldRealmCode.visible = false;
				this.sharedBox.visible = false;
				this.sharedBox.gotoAndStop( 2 );

				//this.fldSharedStatus.text = "Realm is not currently shared.";
			} //
			
		} // displayRealm()

		private function showRejectedRealm( realm:LandRealmData ):void {

			this.fldLikes.visible = false;
			this.fldRealmCode.visible = false;
			this.btnShare.gotoAndStop( 2 );
			this.sharedBox.visible = true;
			this.sharedBox.gotoAndStop( 2 );
			
			var shareMsg:String = this.getSharedString( realm );

			this.fldSharedStatus.htmlText = shareMsg + " but disapproved. <a href=\"" + this.REJECT_LINK +
				"\" target=\"_blank\"><u>Click here</u></a> to find out why.";

			this.fldSharedStatus.visible = true;

		} //

		private function showApprovedRealm( realm:LandRealmData ):void {

			var sharedMsg:String = this.getSharedString( realm );

			this.btnShare.gotoAndStop( 2 );
			this.sharedBox.visible = true;
			this.fldSharedStatus.visible = true;

			this.fldLikes.visible = true;
			this.fldRealmCode.visible = true;
			this.sharedBox.gotoAndStop( 1 );

			this.fldSharedStatus.text = sharedMsg + " and approved.";

		} //

		private function showPendingRealm( realm:LandRealmData ):void {

			var sharedMsg:String = this.getSharedString( realm );

			this.btnShare.gotoAndStop( 2 );
			this.sharedBox.visible = true;
			this.fldSharedStatus.visible = true;

			this.fldLikes.visible = false;
			this.fldRealmCode.visible = false;
			this.sharedBox.gotoAndStop( 2 );

			this.fldSharedStatus.text = sharedMsg + " and waiting for approval.";

		} //

		/**
		 * gets the string of the date when the realm was shared.
		 */
		private function getSharedString( realm:LandRealmData ):String {

			if ( realm.sharedDate <= 0 ) {
				return "Shared";
			}

			return "Shared on " + new Date( Number( 1000*realm.sharedDate ) ).toLocaleString();

		} //

	} // class
	
} // package