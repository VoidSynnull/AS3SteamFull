package game.scenes.lands.shared.ui.panes {

	/**
	 *
	 * THIS WAS THE OLD FILE MENU USED BY THE OLD VERSION OF LANDS/REALMS.
	 * this is probably no reason to keep it any more, but it's here just in case.
	 * marked for future deletion.
	 *
	 * contains the menu with the Save, Load, New World, and Share options,
	 * along with confirm dialog boxes for save and share.
	 */
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class LandFileMenu extends LandPane {

		// confirm new world pane, and share confirm pane.
		private var confirmPane:ConfirmPane;

		/**
		 * just an annoying temp thing right now. when the file menu closes after a menu is selected,
		 * the landMenu needs to know so it can un-hilite everything. another way to do this would
		 * be to have the landMenu have all the menu selection functions.
		 */
		public var onMenuPicked:Function;

		public function LandFileMenu(pane:MovieClip, group:LandUIGroup, onMenu:Function ) {

			super( pane, group );

			this.onMenuPicked = onMenu;

			this.init();

		} //

		private function init():void {

			var pane:MovieClip = this.myPane as MovieClip;
			
			this.confirmPane = new ConfirmPane( pane.confirmPane, this.myGroup );

			this.makeButton( pane.btnSave, this.saveClicked, 2 );
			this.makeButton( pane.btnLoad, this.loadClicked, 2 );
			this.makeButton( pane.btnNewWorld, this.newWorldClicked, 2 );
			this.makeButton( pane.btnShare, this.shareWorldClicked, 2 );

		} //

		private function newWorldClicked( e:MouseEvent ):void {
			
			this.confirmPane.showNewWorldConfirm( this.makeNewWorld );
			
		} //

		private function shareWorldClicked( e:MouseEvent ):void {

			this.confirmPane.showShareConfirm( this.shareWorld );
			
		} //

		/**
		 * share world was confirmed - share the world.
		 */
		private function shareWorld():void {

			this.onMenuPicked();
			this.myGroup.landGroup.shareWorld();

		} //

		private function saveClicked( e:MouseEvent ):void {

			this.onMenuPicked();
			this.myGroup.shellApi.track( "Clicked", "Save", null, LandGroup.CAMPAIGN );
			this.myGroup.landGroup.saveDataToDisk();

		} //

		private function loadClicked( e:MouseEvent ):void {

			this.myGroup.shellApi.track( "Clicked", "Load", null, LandGroup.CAMPAIGN );
			this.myGroup.landGroup.loadWorldFromDisk();

		} //

		/**
		 * called when the newWorldPane.confirm is clicked.
		 */
		private function makeNewWorld():void {

			this.onMenuPicked();
			this.myGroup.shellApi.track( "Clicked", "NewWorld", null, LandGroup.CAMPAIGN );
			//( this.myGroup.landGroup ).createNewLocalGalaxy();

		} //

	} // class
	
} // package