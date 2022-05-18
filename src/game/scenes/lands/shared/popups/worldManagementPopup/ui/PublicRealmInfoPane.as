package game.scenes.lands.shared.popups.worldManagementPopup.ui {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.world.LandRealmData;
	import game.scenes.lands.shared.world.PublicWorldSource;

	public class PublicRealmInfoPane extends RealmInfoPane {

		//private var btnFlag:MovieClip;
		private var btnLike:MovieClip;
		
		private var fldAvatarName:TextField;

		/**
		 * used to confirm displayed realm hasnt changed after avatar name has loaded.
		 */
		private var curRealm:LandRealmData;

		public function PublicRealmInfoPane( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

		} //

		override protected function initUI():void {
			
			super.initUI();

			//this.btnFlag = this.myPane["btnFlag"];
			this.btnLike = this.myPane["btnLike"];
			
			this.fldAvatarName = this.myPane["fldAvatarName"];
			
		}

		public function setPublicClicks( onVisit:Function, onLikeClick:Function, onFlagClick:Function ):void {

			this.setVisitFunction( onVisit );

			this.makeButton( this.btnLike, onLikeClick );
			//this.makeButton( this.btnFlag, onFlagClick );

		} //

		override public function displayRealm( realmData:LandRealmData ):void {

			super.displayRealm( realmData );

			this.curRealm = realmData;

			if ( realmData.avatar_name != null ) {

				this.fldAvatarName.text = realmData.avatar_name;

			} else {

				if ( realmData.creator_login != null ) {

					this.fldAvatarName.text = "";
					var source:PublicWorldSource = ( this.myGroup.landGroup.worldMgr.worldSource as PublicWorldSource );
					if ( source ) {
						source.loadAvatarName( realmData, this.avatarNameLoaded );
					} //

				} else {
					this.fldAvatarName.text = "Unknown";
				}

			} //

		} //

		private function avatarNameLoaded( avatar_name:String ):void {

			if ( !this.visible ) {
				return;
			} else if ( avatar_name == null ) {

				this.fldAvatarName.text = "Unknown";

			} else {

				if ( this.curRealm.avatar_name == avatar_name ) {
					this.fldAvatarName.text = avatar_name;
				} //

			}

		} //

	} // class
	
} // package