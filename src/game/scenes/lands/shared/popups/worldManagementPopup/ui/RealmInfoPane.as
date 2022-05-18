package game.scenes.lands.shared.popups.worldManagementPopup.ui {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.ui.panes.LandPane;
	import game.scenes.lands.shared.world.LandRealmData;

	public class RealmInfoPane extends LandPane {

		protected var btnVisit:MovieClip;

		protected var fldLikes:TextField;
		protected var fldRealmCode:TextField;

		public function RealmInfoPane( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			this.initUI();

		}

		protected function initUI():void {

			this.btnVisit = this.myPane["btnVisit"];

			this.fldRealmCode = this.myPane["fldRealmCode"];
			this.fldLikes = this.myPane["fldLikes"];

		} //

		public function setVisitFunction( onVisitWorld:Function ):void {

			//this.btnVisit.x += this.btnVisit.width/2;
			this.makeButton( this.btnVisit, onVisitWorld );

		} //

		/**
		 * display the information associated with a given realm.
		 */
		public function displayRealm( realmData:LandRealmData ):void {

			if ( realmData.name != null ) {
				this.myPane["fldName"].text = realmData.name;
			} else {
				this.myPane["fldName"].text = "Unknown Realm";
			}

			// NO LONGER BEING USED:
			/*var visitString:String;
			if ( realmData.last_visit_time > 0 ) {
				visitString = "Last visited " + new Date( Number( 1000*realmData.last_visit_time ) ).toLocaleString();
			} else {
				visitString = "Unexplored";
			}
			this.myPane["fldInfo"].text =
				"Type: " + realmData.biome +
				"\nSize: " + realmData.realmSize + "\n" + visitString;*/

			this.fldLikes.text = realmData.rating.toString();
			this.fldRealmCode.text = realmData.getRealmCode();

			if ( !this.visible ) {
				this.show();
			}

		} //

	} // class

} // package