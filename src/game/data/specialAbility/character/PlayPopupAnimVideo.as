// Used by:
// Card 2760 using item limited_zootopia_car

package game.data.specialAbility.character
{	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.adparts.parts.AdVideo;
	import game.components.timeline.Timeline;
	import game.scene.template.ads.AdVideoGroup;
	import game.util.TimelineUtils;
	
	/**
	 * Play popup animation with video
	 * 
	 * Required params:
	 * videoPath			String		Path to video
	 * 
	 * Optional params:
	 * videoWidth			Number		Video width
	 * VideoHeight			Number		video height
	 * 
	 * Optional parent params:
	 * lockInput			Boolean		Lock user input (default is true)
	 * alignToPlayer		Boolean 	Align popup to player location (default is false) - align swf content to offset from player position
	 * standingOnly			Boolean		Trigger popup only if player is standing (default is false)
	 * flipPopup			Boolean		Flip popup to align with player direction (default is false)
	 */
	public class PlayPopupAnimVideo extends PlayPopupAnim
	{
		/**
		 * when popup swf completes loading 
		 * @param clip
		 */
		override protected function loadPopupComplete(clip:MovieClip):void
		{
			super.loadPopupComplete(clip);
			
			// setup video
			// if video group exists, then don't create new one
			_videoGroup = AdVideoGroup(super.shellApi.sceneManager.currentScene.groupManager.getGroupById("AdVideoGroup"));
			if (_videoGroup == null)
				_videoGroup = new AdVideoGroup();
			var videoData:Object = {};
			videoData.width = _videoWidth;
			videoData.height = _videoHeight;
			// use video passed to popup
			videoData.videoFile = _videoPath;
			_videoEntity = _videoGroup.setupAutoCardVideo(this, _popupClip.content.popupVideo, _popupClip.content, videoData);
			
			// label for when video should start
			TimelineUtils.onLabel( _timeline, "startVideo", _videoEntity.get(AdVideo).fnClick );
		}
				
		/**
		 * When video is done playing, called automatically
		 */
		public function doneVideo():void
		{
			// resume timeline
			_timeline.get(Timeline).play();
			// dispose of video
			_videoEntity.get(AdVideo).fnDispose();
			_videoGroup.removeEntity(_videoEntity);
		}

		public var _videoPath:String;
		public var _videoWidth:Number = 960;
		public var _videoHeight:Number = 640;
		
		private var _videoGroup:AdVideoGroup;
		private var _videoEntity:Entity;
	}
}
