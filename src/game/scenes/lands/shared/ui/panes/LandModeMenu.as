package game.scenes.lands.shared.ui.panes {

	/**
	 * the pane that allows user to select one of three play modes - explore, mine, create.
	 */

	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.LandsEvents;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class LandModeMenu extends LandPane {

		/**
		 * last button selected. remember it because it needs to be hilited.
		 */
		private var selectedBtn:MovieClip;


		public function LandModeMenu( pane:MovieClip, group:LandUIGroup ) {

			super( pane, group );

			this.init();

		} //

		private function init():void {

			this.makeButton( this.clipPane.btnExplore, this.onClickMode, 2, "Explore" );

			this.makeButton( this.clipPane.btnMine, this.onClickMode, 2, "Mine" );

			this.makeButton( this.clipPane.btnCreate, this.onClickMode, 2, "Create" );

			this.makeButton( this.clipPane.btnRealms, this.onRealmsClicked, 2, "Realms" );

			this.selectedBtn = this.clipPane.btnExplore;
			this.selectedBtn.hilite.visible = true;

			this.myGroup.onUIModeChanged.add( this.onUIModeChanged );

		} //

		/**
		 * editModes are an OR-d combination of the basic LandEditModes
		 * which indicates which buttons should be available.
		 */
		/*public function setAllowedModes( editModes:int ):void {
		} //*/

		/**
		 * shared realms will not allow the use of create-mode.
		 */
		public function setPublicMode():void {

			this.lockButton( this.clipPane.btnCreate );
			this.lockButton( this.clipPane.btnMine );
			// PROBLEM: the rollOver tooltips will still come back after pane show()???
			//this.inputManager.removeListeners( btn );

		} //

		public function setPrivateMode():void {

			this.unlockButton( this.clipPane.btnCreate );
			this.unlockButton( this.clipPane.btnMine );
			//this.inputManager.addEventListener( btn, MouseEvent.CLICK, this.onClickMode );

		} //

		private function lockButton( btn:MovieClip ):void {

			btn.mouseEnabled = false;

			if ( btn.getChildByName( "lockIcon" ) == null ) {

				var bitmap:Bitmap = new Bitmap( this.myGroup.lockBitmap );
				bitmap.name = "lockIcon";
				// note: buttons are centered in their views here. apparently.
				bitmap.x = -bitmap.width/2;
				bitmap.y = -bitmap.height/2 - 4;
				btn.addChild( bitmap );

			} //

		} //

		private function unlockButton( btn:MovieClip ):void {

			var lock:DisplayObject = btn.getChildByName( "lockIcon" );
			if ( lock != null ) {
				btn.removeChild( lock );
			}
			btn.mouseEnabled = true;

		} //

		/**
		 * select the appropriate edit mode - for when the edit mode is changed by something outside the menu itself.
		 */
		public function onUIModeChanged( mode:uint ):void {

			this.selectedBtn.hilite.visible = false;

			if ( mode == LandEditMode.EDIT ) {
				this.selectedBtn = this.clipPane.btnCreate;
			} else if ( mode == LandEditMode.MINING ) {
				this.selectedBtn = this.clipPane.btnMine;
			} else if ( mode == LandEditMode.PLAY ) {
				this.selectedBtn = this.clipPane.btnExplore;
			} else {
				return;
			}

			this.selectedBtn.hilite.visible = true;

		} //

		/**
		 * quick patch for star wars.
		 */
		public function deselectCurMode():void {
			
			this.selectedBtn.hilite.visible = false;
			
		} //

		/**
		 * pointless thing just to get the hint arrow to appear.
		 */
		public function getEditButton():MovieClip {
			return this.clipPane.btnCreate;
		} //

		/**
		 * displays the world management screen.
		 */
		private function onRealmsClicked( e:MouseEvent ):void {		

			this.myGroup.shellApi.track( "Clicked", "RealmsMenu", null, LandGroup.CAMPAIGN );
			this.myGroup.landGroup.showWorldManagementScreen();
			this.myGroup.hideHintArrow();

			var evts:LandsEvents = this.myGroup.landGroup.curScene.events as LandsEvents;
			if (!this.myGroup.shellApi.checkEvent( evts.GOT_REALMS_HINT) ) {
				this.myGroup.shellApi.completeEvent( evts.GOT_REALMS_HINT );
			}

		} //

		private function onClickMode( e:MouseEvent ):void {

			// removed this because of star wars. see about what else can do.
			/*if ( this.selectedBtn == e.target ) {
				return;
			}*/

			if ( e.target == this.clipPane.btnExplore ) {
				this.myGroup.shellApi.track( "Clicked", "PlayMode", null, LandGroup.CAMPAIGN );
				this.myGroup.uiMode = LandEditMode.PLAY;
			} else if ( e.target == this.clipPane.btnMine ) {
				this.myGroup.shellApi.track( "Clicked", "MineMode", null, LandGroup.CAMPAIGN );
				this.myGroup.uiMode = LandEditMode.MINING;
			} else if ( e.target == this.clipPane.btnCreate ) {
				this.myGroup.shellApi.track( "Clicked", "EditMode", null, LandGroup.CAMPAIGN );
				this.myGroup.uiMode = LandEditMode.EDIT;
			} else {
				return;
			}

			/*this.selectedBtn.gotoAndStop( 1 );
			this.selectedBtn = e.target as MovieClip;
			this.selectedBtn.gotoAndStop( 2 );*/

		} //

	} // class
	
} // package