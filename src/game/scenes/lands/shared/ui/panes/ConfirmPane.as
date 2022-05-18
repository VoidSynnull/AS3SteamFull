package game.scenes.lands.shared.ui.panes {

	/**
	 * this confirm pane servers as the confirmation dialog for both creating a new world (frame 1)
	 * and shairng the current world with poptropica server. ( frame 2 )
	 */
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class ConfirmPane extends LandPane {

		/**
		 * onConfirm()
		 */
		private var onConfirm:Function;

		//private var fldSeed:TextField;

		public function ConfirmPane( pane:MovieClip, group:LandUIGroup ) {

			super( pane, group );
			pane.gotoAndStop( 1 );

			//this.fldSeed = pane.fldSeed;

			this.makeButton( pane.btnConfirm, this.confirmClicked, 2, "Accept" );
			this.makeButton( pane.btnClose, this.closeClick, 2, "Close" );

		} //

		public function showNewWorldConfirm( confirmFunc:Function ):void {

			this.onConfirm = confirmFunc;
			( this.myPane as MovieClip ).gotoAndStop( 1 );

			super.show();

		} //

		public function showShareConfirm( confirmFunc:Function ):void {

			this.onConfirm = confirmFunc;
			( this.myPane as MovieClip ).gotoAndStop( 2 );

			super.show();

		} //

		public function confirmClicked( e:MouseEvent ):void {

			this.hide();
			if ( this.onConfirm ) {
				this.onConfirm();
			}

		} //

	} // class
	
} // package