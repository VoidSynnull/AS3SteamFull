package game.scenes.mocktropica.mainStreet {
	
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
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.ui.elements.MultiStateButton;
	import game.ui.elements.PoptropicaYouTubePlayer;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.Popup;
	import game.util.PlatformUtils;
	
	/**
	 * NonMemberBlockPopup presents an interface urging nonmembers
	 * to sign up and receive more privileges.
	 * @author Jordan Leary
	 * 
	 */
	public class NonMemberBlockPopup extends Popup {
		
		private const VIDEO_ID:String = "fUyZyo3vvaU";
		private var membershipBtn:MultiStateButton;
		private var gCampaignName:String = "Mocktropica";
		private var youTubePlayer:PoptropicaYouTubePlayer;
		private var mocktropicaEvents:MocktropicaEvents;
		
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
			groupPrefix = "scenes/mocktropica/mainStreet/";
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
			mocktropicaEvents = new MocktropicaEvents();
			
			//remember that they have been blocked, so we'll know if they are converted later on
			//incorrectly had this set to blocked_from_bonus at first, so was doing tracking incorrectly during ea
			super.shellApi.completeEvent(mocktropicaEvents.BLOCKED_FROM_EA);
			
			super.shellApi.track("Demo", "DemoBlock", "Impressions", gCampaignName);
			
			screen = getAsset("nonMemberBlock.swf", true) as MovieClip;
			this.centerWithinDimensions(this.screen.content);
			
			membershipBtn = MultiStateButton.instanceFromButtonSpec(
				ButtonSpec.instanceFromInitializer(
					{
						displayObjectContainer:	screen.content.membershipBtn,
						pressAction: super.playClick,
						clickHandler: onMembershipBtn
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
				youTubePlayer.size = new Rectangle(283,256,400,225);
				youTubePlayer.videoID = VIDEO_ID;
				youTubePlayer.playerReady.addOnce(onYouTubeReady);
			}
			
			super.loaded();
		}
		
		public override function destroy():void {
			super.destroy();
		}
		
		protected override function handleCloseClicked(...args):void {
			shellApi.siteProxy.retrieve(PopDataStoreRequest.memberStatusRequest(), onMembershipResult);
		}
		
		private function onYouTubeReady():void {
			trace("yutoob", youTubePlayer.percentLoaded, "percent loaded");
		}
		
		private function onMembershipBtn(e:MouseEvent):void {
			if (youTubePlayer) {
				youTubePlayer.pausePlayer(true);
			}
			super.shellApi.track("Demo", "DemoBlock", "Clicks", gCampaignName);
			HudPopBrowser.buyMembership(super.shellApi);
		}
		
		private function onMembershipResult():void {
			if (youTubePlayer) {
				youTubePlayer.destroy();
			}
			super.handleCloseClicked();
		}
		
	}
	
}