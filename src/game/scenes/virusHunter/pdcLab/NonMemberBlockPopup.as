package game.scenes.virusHunter.pdcLab {

import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.Security;

import game.data.comm.PopResponse;
import game.data.ui.ButtonSpec;
import game.data.ui.TransitionData;
import game.proxy.PopDataStoreRequest;
import game.proxy.browser.DataStoreProxyPopBrowser;
import game.ui.elements.MultiStateButton;
import game.ui.elements.PoptropicaYouTubePlayer;
import game.ui.hud.HudPopBrowser;
import game.ui.popup.Popup;
import game.util.PlatformUtils;

/**
 * NonMemberBlockPopup presents an interface urging nonmembers
 * to sign up and receive more privileges.
 * @author Rich Martin
 * 
 */
public class NonMemberBlockPopup extends Popup {
	
	private const VIDEO_ID:String = 'T8goxcMDkLw';
	private var membershipBtn:MultiStateButton;
	private var gCampaignName:String = "VirusHunterPromo";
	private var youTubePlayer:PoptropicaYouTubePlayer;

	public function NonMemberBlockPopup(container:DisplayObjectContainer=null) {
		super(container);
	}
	
	// pre load setup
	public override function init(container:DisplayObjectContainer=null):void {
		transitionIn = new TransitionData();
		transitionIn.duration = .625;
		transitionIn.startPos = new Point(0, -shellApi.viewportHeight);
		transitionOut = transitionIn.duplicateSwitch();	// this shortcut method flips the start and end position of the transitionIn
		
		darkenBackground = true;
		groupPrefix = "scenes/virusHunter/pdcLab/";
		super.init(container);
		load();
	}		

	// initiate asset load of scene specific assets.
	public override function load():void {
		shellApi.fileLoadComplete.addOnce(loaded);
		loadFiles(["nonMemberBlock.swf"]);
	}

	// all assets ready
	public override function loaded():void {
		super.shellApi.track("VideoImpressions", "End Sneak Peek", null, gCampaignName);
		
		screen = getAsset("nonMemberBlock.swf", true) as MovieClip;
		this.centerWithinDimensions(this.screen.content);
		
		membershipBtn = MultiStateButton.instanceFromButtonSpec(
			ButtonSpec.instanceFromInitializer(
				{
					displayObjectContainer:	screen.content.membershipBtn,
					pressAction:			super.playClick,
					clickHandler:			onMembershipBtn
				}
			)
		);
		
		screen.content.membershipBtn
		loadCloseButton();
	//	layout.centerUI(screen.content);
		if (PlatformUtils.inBrowser) {
			Security.allowDomain("youtube.com");
			youTubePlayer = new PoptropicaYouTubePlayer();
			screen.addChild(youTubePlayer);
			youTubePlayer.size = new Rectangle(282,254, 400,225);
			youTubePlayer.videoID = VIDEO_ID;
			youTubePlayer.playerReady.addOnce(onYouTubeReady);
		}
		
		super.loaded();
	}
	
	public override function destroy():void {
		super.destroy();
	}

	protected override function handleCloseClicked(...args):void 
	{
		shellApi.siteProxy.retrieve(PopDataStoreRequest.memberStatusRequest(), onMembershipResult);
	}

	private function onYouTubeReady():void {
		trace("yutoob", youTubePlayer.percentLoaded, "percent loaded");
	}

	private function onMembershipBtn(e:MouseEvent):void {
		if (youTubePlayer) {
			youTubePlayer.pausePlayer(true);
		}
		super.shellApi.track("ClickToSponsor", "End Sneak Peek", null, gCampaignName);
		HudPopBrowser.buyMembership(super.shellApi);
	}

	private function onMembershipResult():void 
	{
		if (youTubePlayer) {
			youTubePlayer.destroy();
		}
		super.handleCloseClicked();
	}

}

}

/*

gCampaignName = "BacklotPromo";

_root.trackCampaign(gCampaignName,"VideoImpressions","End Sneak Peek");

btnMembership.onRollOver = _root.useArrow;
btnMembership.onRelease = function() {
_root.trackCampaign(gCampaignName,"ClickToSponsor","End Sneak Peek");

//_root.openStoreMemRenewAgain = true;
//_root.popup("stats.swf", true);
//_root.closePopup();

getURL(gClickURL, "_blank");
videoHolder.pauseVideo();
}

//youtube video
System.security.allowDomain("youtube.com");
//System.security.allowInsecureDomain("youtube.com");

loadYouTubeVideo();

function loadYouTubeVideo() {
videoHolder._alpha = 0;
videoHolder.loadMovie("http://www.youtube.com/apiplayer");
createEmptyMovieClip("videoWait", getNextHighestDepth());
videoWait.onEnterFrame = function() {
if (videoHolder.isPlayerLoaded()) {
delete this.onEnterFrame;
//videoHolder.playVideo();

videoHolder.loadVideoByUrl("to-QheWGprk");
videoHolder.setSize(400, 225);
videoHolder.addEventListener("onStateChange", onPlayerStateChange);
}
}

videoHit.isPaused = false;
videoHit.onRollOver = _root.useArrow;
videoHit.onRelease = function() {
	
	if (this.isPaused) {
		videoHolder.playVideo();
	}
	else {
		videoHolder.pauseVideo();
	}
	this.isPaused = !this.isPaused;
	this.gotoAndStop(this.isPaused + 1);
}
}

function onPlayerStateChange(newState:Number) {
	// _root.trc("New player state: "+ newState);
	if (newState == 0) {
		if (!finishedVideo) {
			_root.trackCampaign(gCampaignName,"VideoComplete","End Sneak Peek");
			finishedVideo = true;
		}
		videoHit.isPaused = true;
		videoHit.gotoAndStop(2);
		this.seekTo(0);
	}
	videoHolder._alpha = 100;
}

//check for membership again on close
_root.popupBack.btnClose.onRelease = function() {
	this._visible = false;
	videoHolder.pauseVideo();
	checkMembership();
}

function checkMembership() {
	//trace("checkMembership() in travelMap");
	if (_root.avatar.isRegistred() && !_root.isActiveMember()) {
		var sender = new LoadVars();
		var receiver = new LoadVars();
		
		receiver.onLoad = function(success)
		{
			if (success)
			{
				if (this.status != "nologin" && this.status != "badpass" && this.status != "dberror")
				{
					_root.avatar.FunBrain_so.data.mem_status = this.memstatus;
				}
			}
			chooseFrame();
		}
		
		sender.login = _root.avatar.loadLogin();
		sender.pass_hash = _root.avatar.FunBrain_so.data.password;
		sender.dbid = _root.avatar.FunBrain_so.data.dbid;
		
		sender.sendAndLoad(_root.getPrefix()+"/get_mem_status.php", receiver, "POST");
	}
	else {
		chooseFrame();
	}
}

function chooseFrame() {
	if (_root.isActiveMember() || testMode) {
		_root.camera.scene.gScene.clearNonMemberBlock();
		
	}
	_root.popupBack.btnClose.onRelease = _root.closePopup;
	_root.popupBack.btnClose._visible = true;
	_root.takeClick._visible = false;
	_root.closePopup();
}

*/