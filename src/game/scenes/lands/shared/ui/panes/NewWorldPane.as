package game.scenes.lands.shared.ui.panes {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class NewWorldPane extends LandPane {

		/**
		 * onConfirm()
		 */
		public var onConfirm:Function;

		//private var fldSeed:TextField;

		public function NewWorldPane( pane:MovieClip, group:LandUIGroup ) {

			super( pane, group );

			//this.fldSeed = pane.fldSeed;

			this.makeButton( pane["btnConfirm"], this.confirmClicked, 2, "Accept" );
			this.makeButton( pane["btnClose"], this.closeClick, 2, "Close" );

		} //

		public function confirmClicked( e:MouseEvent ):void {

			this.hide();
			if ( this.onConfirm ) {
				this.onConfirm();
			}

		} //

	} // class
	
} // package