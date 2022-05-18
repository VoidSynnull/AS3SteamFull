package game.scenes.lands.shared.ui.panes {
	
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
		
	public class DialogPane extends LandPane {
		
		public function DialogPane( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			this.makeButton( pane[ "btnClose" ], this.closePane, 2 );

		} //

		public function showMessage( txt:String ):void {

			this.myPane[ "fldDialog" ].text = txt;
			this.show();

		} //

		private function closePane( e:MouseEvent ):void {

			this.hide();

		} //

	} // class
	
} // package