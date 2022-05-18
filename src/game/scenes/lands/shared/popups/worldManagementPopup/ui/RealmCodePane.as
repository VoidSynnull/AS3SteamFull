package game.scenes.lands.shared.popups.worldManagementPopup.ui {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.FocusEvent;
	import flash.text.TextField;
	import flash.utils.setTimeout;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.ui.panes.LandPane;
	
	/**
	 * pane for displaying and dispatching realm codes.
	 * 
	 * btnRealmCode --> GO
	 * fldRealmCode --> textField
	 */

	public class RealmCodePane extends LandPane {

		private var fldRealmCode:TextField;
		private var btnRealmCode:MovieClip;

		public function RealmCodePane(pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			this.initUI();

		} //

		private function initUI():void {

			this.fldRealmCode = this.myPane["fldRealmCode"];

			//this.inputManager.addEventListener( this.fldRealmCode, FocusEvent.FOCUS_IN, this.onTextFocus );

			// try to STEAL the event.
			this.fldRealmCode.addEventListener( FocusEvent.FOCUS_IN, this.onTextFocus );

			this.btnRealmCode = this.myPane["btnRealmCode"];

		} //

		private function onTextFocus( e:FocusEvent ):void {

			setTimeout( this.selectAllText, 100 );

		} //

		private function selectAllText():void {

			if ( this.fldRealmCode == null ) {
				// theoretically possible for the popup to close before text select.
				return;
			}
			this.fldRealmCode.setSelection( 0, this.fldRealmCode.text.length );

		} //

		public function addRealmCodeClick( func:Function ):void {

			this.makeButton( this.btnRealmCode, func );

		} //

		public function getCurrentCode():String {
			return this.fldRealmCode.text;
		} //

		override public function destroy():void {

			this.fldRealmCode.removeEventListener( FocusEvent.FOCUS_IN, this.onTextFocus );
			super.destroy();
			this.fldRealmCode = null;

		} //

	} // class
	
} // package