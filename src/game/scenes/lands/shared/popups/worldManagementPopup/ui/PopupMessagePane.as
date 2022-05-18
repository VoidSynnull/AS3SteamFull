package game.scenes.lands.shared.popups.worldManagementPopup.ui {

	/**
	 * used to display confirm/cancle/error messages in the Realms Popup.
	 */

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.ui.panes.LandPane;


	public class PopupMessagePane extends LandPane {

		private var fldTitle:TextField;
		private var fldDescription:TextField;
		private var fldCancel:TextField;
		private var fldConfirm:TextField;

		/**
		 * callback function for cancel button. No parameters.
		 */
		public var onCancel:Function;
		/**
		 * callback function for confirm button. No parameters.
		 */
		public var onConfirm:Function;

		private var btnConfirm:MovieClip;
		private var btnCancel:MovieClip;

		public function PopupMessagePane( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			this.initUI();

		} //

		private function initUI():void {

			this.fldTitle = pane["fldTitle"];
			this.fldTitle.mouseEnabled = false;
			this.fldDescription = pane["fldDescription"];
			this.fldDescription.mouseEnabled = false;

			this.fldCancel = pane["fldCancel"];
			this.fldCancel.mouseEnabled = false;
			this.fldConfirm = pane["fldConfirm"];
			this.fldConfirm.mouseEnabled = false;

			this.btnCancel = pane["btnCancel"];
			this.btnConfirm = this.myPane["btnConfirm"];

			this.makeButton( this.btnCancel, this.onCancelClicked );
			this.makeButton( this.btnConfirm, this.onConfirmClicked );

			this.fldConfirm.text = "Ok";
			this.fldCancel.text = "Cancel";

		} //

		public function showConfirm( title:String, msg:String, confirmFunc:Function=null, cancelFunc:Function=null ):void {

			this.btnConfirm.visible = true;

			this.fldTitle.text = title;
			this.fldDescription.text = msg;

			this.onConfirm = confirmFunc;
			this.onCancel = cancelFunc;

			this.show();

		} //

		public function showMessage( title:String, msg:String ):void {

			this.btnConfirm.visible = false;

			this.fldTitle.text = title;
			this.fldDescription.text = msg;

			this.show();

		} //

		private function onCancelClicked( e:MouseEvent ):void {

			if ( onCancel ) {
				onCancel();
			}
			this.hide();

		} //

		private function onConfirmClicked( e:MouseEvent ):void {

			if ( onConfirm ) {
				onConfirm();
			}
			this.hide();

		} //

	} // class
	
} // package