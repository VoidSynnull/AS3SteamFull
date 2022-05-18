package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	import engine.group.Group;
	
	import game.adparts.parts.AdFullScreenVideo;
	import game.data.ads.AdTrackingConstants;
	import game.ui.popup.Popup;
	
	public class CardPlayMobileVideo extends Popup
	{
		public function CardPlayMobileVideo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = false;
			super.init(container);
			// don't need popup to play mobile video
			super.remove();
			
			_group = super.shellApi.sceneManager.currentScene;
			
			_videoFile = super.data.video;
			_fsVideo = new AdFullScreenVideo(_group, true, notifyFullScreen);
			_fsVideo.clickURL = super.data.clickURL;
			_fsVideo.campaignName = super.campaignData.campaignId;
			_fsVideo.videoURL = _videoFile;
			_fsVideo.play();
			
			// trim video file for tracking
			var videoArray:Array = _videoFile.split("/");
			var videoName:String = videoArray[videoArray.length-1];
			_videoFile = videoName.substr(0, videoName.indexOf("."));		
		}		
		
		private function notifyFullScreen(message:String):void
		{
			switch (message)
			{
				case AdFullScreenVideo.NOT_FOUND:
					disposeVideo();
					break;
				case AdFullScreenVideo.STARTED:
					_group.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_VIDEO_CLICKED, "Video", _videoFile);
					break;
				case AdFullScreenVideo.QUIT:
					disposeVideo();
					break;
				case AdFullScreenVideo.ENDED:
					disposeVideo();
					_group.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_VIDEO_COMPLETE, "Video", _videoFile);
					break;
			}
		}
		
		private function disposeVideo():void
		{
			_fsVideo.dispose();
		}
		
		private var _group:Group;
		private var _videoFile:String;
		private var _fsVideo:AdFullScreenVideo;	
	}
}