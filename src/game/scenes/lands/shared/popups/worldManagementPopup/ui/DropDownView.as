package game.scenes.lands.shared.popups.worldManagementPopup.ui {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.ui.panes.LandPane;
	import game.util.TweenUtils;

	public class DropDownView extends LandPane {

		/**
		 * whatever.
		 */
		protected var fldTitle:TextField;

		/**
		 * toggles the list view up and down.
		 */
		protected var btnToggle:MovieClip;

		/**
		 * clip that drops down and scrolls back up.
		 * NOTE TO JORDAN: need a mask?
		 */
		protected var listClip:MovieClip;
		protected var listStartY:Number;

		protected var listIsDisplayed:Boolean;

		/**
		 * onItemClicked( itemNum:int )
		 */
		public var onItemClicked:Function;

		public function DropDownView( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			this.initUI();

		} //

		private function initUI():void {

			this.fldTitle = this.myPane["fldTitle"];
			this.fldTitle.mouseEnabled = false;

			// unfortunately the listClip itself also has sub-buttons.
			this.listClip = this.myPane["list"];
			this.listStartY = this.listClip.y;

			this.listClip.y = this.listStartY - this.listClip.height/2;
			this.listClip.visible = false;
			this.listIsDisplayed = false;

			this.initListButtons();

			// not a very good name for a button.
			this.btnToggle = this.myPane["btnToggle"];

			this.makeButton( this.btnToggle, this.onToggleClicked );

		} //

		public function setItemNames( names:Array ):void {

			var btn:MovieClip;
			var fld:TextField;

			for( var i:int = 0; i < names.length; i++ ) {

				btn = this.listClip["btn"+i];
				if ( !btn ) {
					continue;
				}
				fld = btn.fldName;
				fld.mouseEnabled = false;

				btn.fldName.text = names[i];

			} //

		} //

		private function initListButtons():void {

			var i:int = 0;
			var btn:MovieClip = this.listClip[ "btn" + i ];

			while ( btn != null ) {

				btn.gotoAndStop( 1 );
				btn.index = i;		// need this info for dispatching events.
				this.makeButton( btn, this.onListItemClicked, 2 );

				i++;
				btn = this.listClip[ "btn" + i ];

			} //

		} //

		private function onListItemClicked( e:MouseEvent ):void {

			var btn:MovieClip = e.currentTarget as MovieClip;
			if ( !btn || btn.index == null ) {
				return;
			}

			/*if ( this.selectedBtn != null ) {
				this.selectedBtn.gotoAndStop( 1 );
			}*/

			this.fldTitle.text = btn.fldName.text;

			this.toggleList();

			if ( this.onItemClicked ) {
				this.onItemClicked( btn.index );
			}

		} //

		private function onToggleClicked( e:MouseEvent ):void {

			this.toggleList();

		} //

		public function toggleList():void {

			if ( this.listIsDisplayed ) {

				// hide the list.
				TweenUtils.globalTo( this.myGroup, this.listClip, 0.2, { y:(this.listStartY-this.listClip.height/2), alpha:0, onComplete:this.hideList } );

			} else {

				this.listClip.alpha = 0;
				this.listClip.visible = true;
				TweenUtils.globalTo( this.myGroup, this.listClip, 0.2, { y:(this.listStartY), alpha:1 } );

			} //
			this.listIsDisplayed = !this.listIsDisplayed;

		} //

		private function hideList():void {
			this.listClip.visible = false;
		} //

		public function selectItem( itemNum:int ):void {

			var btn:MovieClip = this.listClip["btn"+itemNum];

			if ( !btn ) {
				return;
			}
			/*if ( this.selectedBtn != null ) {
				this.selectedBtn.gotoAndStop( 1 );
			}
			btn.gotoAndStop( 2 );*/

			this.fldTitle.text = btn.fldName.text;
			if ( this.listIsDisplayed ) {
				this.toggleList();
			}

		} //

	} // class
	
} // package