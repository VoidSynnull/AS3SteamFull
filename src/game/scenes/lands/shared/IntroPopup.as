package game.scenes.lands.shared {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.data.ui.ToolTipType;
	import game.scenes.map.map.Map;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.Popup;

	public class IntroPopup extends Popup {

		private var content:MovieClip;
		//private var inputMgr:InputManager;

		private var btnStart:Entity;
		private var btnTour:Entity;
		private var btnExit:Entity;
		private var isMember:Boolean;

		public function IntroPopup( container:DisplayObjectContainer=null ) {

			super(container);
		}

		override public function init( container:DisplayObjectContainer=null ):void {

			darkenBackground = true;
			groupPrefix = "scenes/lands/shared/";
			super.screenAsset = "introPopup.swf";
			super.init( container );
			load();
		}
		
		override public function loaded():void {

			super.preparePopup();
			
			this.content = this.screen.content;
			
			isMember = super.shellApi.profileManager.active.isMember;
			
			/*if (isMember) {
				this.content.nonmember.visible = false;
				this.btnStart = SimpleUtils.makeUIBtn( this.content.btnStart, this.onClickStart, this );
				super.shellApi.track("IntroPopup", "Impression", "Member", LandGroup.CAMPAIGN);
			}
			else {
				this.content.btnStart.visible = false;
				this.btnTour = SimpleUtils.makeUIBtn( this.content.nonmember.btnTour, this.onClickMembership, this );
				this.btnExit = SimpleUtils.makeUIBtn( this.content.nonmember.btnExit, this.onClickExit, this );
				super.shellApi.track("IntroPopup", "Impression", "NonMember", LandGroup.CAMPAIGN);
			}*/
			
			//changed to "technical difficulties" popup
			this.btnExit = SimpleUtils.makeUIBtn( this.content.btnExit, this.onClickExit, this );
			super.shellApi.track("IntroPopup", "Impression", "TechnicalDifficulties", LandGroup.CAMPAIGN);
			
			//loadCloseButton();
			super.groupReady();
		} //

		public function onClickStart( e:Entity ):void {

			super.shellApi.track("IntroPopup", "Started", null, LandGroup.CAMPAIGN);
			this.close(true);

		} //

		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		private function onClickExit( e:Entity ):void {
			//shellApi.siteProxy.getMemberStatus(onMembershipResult);
			
			shellApi.loadScene(Map);
		}
		
		private function onClickMembership( e:Entity ):void {
			super.shellApi.track("IntroPopup", "Clicked Membership", LandGroup.CAMPAIGN);
			HudPopBrowser.buyMembership(super.shellApi);
		}
		
		/*
		private function onMembershipResult(result:PopResponse):void {
			shellApi.siteProxy.onMemberStatus(result);
			
			isMember = super.shellApi.profileManager.active.isMember;
			if (isMember) {
				super.shellApi.track("IntroPopup", "Started", null, LandGroup.CAMPAIGN);
				this.close(true);
			}
			else {
				//exit to map
				shellApi.loadScene(Map);
			}
		}
		*/

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