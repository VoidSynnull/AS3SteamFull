package game.scenes.lands.shared {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.data.ui.ToolTipType;
	import game.ui.popup.Popup;

	public class ContestFlyer extends Popup {

		private var content:MovieClip;
		//private var inputMgr:InputManager;
		private var campaignName:String = "LandPrototypeV2";

		public function ContestFlyer( container:DisplayObjectContainer=null ) {

			super(container);
		}

		override public function init( container:DisplayObjectContainer=null ):void {

			darkenBackground = true;
			groupPrefix = "scenes/lands/shared/";
			super.screenAsset = "contestFlyer.swf";
			super.init( container );
			load();
		}
		
		override public function loaded():void {

			super.preparePopup();
			
			this.content = this.screen.content;

			loadCloseButton();
			super.groupReady();
			
			super.shellApi.track("ContestFlyer", "Impression", null, campaignName);

		} //
		
		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}

	} // class

}
import game.ui.hud.HudPopBrowser;

/*
var campaignName:String = "LandPrototypeV2";

btnStart.onRollOver = _root.useArrow;
btnStart.onRollOut = function() {
_root.pointer.gotoAndStop("arrow");
}
btnStart.onRelease = function() {
_root.trackCampaign(campaignName, "IntroPopup", "Started");

var lso = _root.char.avatar.FunBrain_so.data;

if (_root.globalScene) {
lso.lastRoom = _root.islandMain;
lso.lastIsland = _root.island;
}
else {
lso.lastRoom = _root.desc;
lso.lastIsland = _root.island;
lso[lastRoom + "xPos"] = _root.char._x;
lso[lastRoom + "yPos"] = _root.char._y;
}

//_root.char.loadScene("LandPrototypeAS2", 1300, -200, "Demo");
_root.loadSceneAS3('game.scenes.lands.lab1.Lab1');
}

nonmember.btnTour.onRollOver = _root.useArrow;
nonmember.btnTour.onRollOut = function() {
_root.pointer.gotoAndStop("arrow");
}
nonmember.btnTour.onRelease = function() {
_root.trackCampaign(campaignName, "IntroPopup", "Clicked Membership");

HudPopBrowser.buyMembership();
}

// hide launch button if not member
if (_root.isActiveMember()) {
_root.trackCampaign(campaignName, "IntroPopup", "Impression", "Member");

nonmember._visible = false;
}
else {
_root.trackCampaign(campaignName, "IntroPopup", "Impression", "Non Member");

btnStart._visible = false;
}
*/