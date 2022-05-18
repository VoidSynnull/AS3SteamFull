package game.scenes.custom
{
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.adparts.parts.AdVideo;
	import game.data.ads.AdTrackingConstants;
	import game.managers.ads.AdManager;
	import game.scenes.custom.AdBasePopup;
	
	public class BlimpVideoPopup extends AdBasePopup
	{
		public var adVideo:AdVideo;
		
		public function BlimpVideoPopup()
		{
			// name of swf to load
			_popupType = "blimpVideoPopup";
		}
		
		/**
		 * Setup popup buttons
		 */
		override protected function setupPopup():void
		{
			// use background to consume clicks
			setupButton(super.screen["background"], doNothing);
			
			// hide clickURL and replay buttons until video is done
			var button:Entity = super.getEntityById("clickURL");
			if (button != null)
				button.get(Display).visible = false;
			button = super.getEntityById("replayButton")
			if (button != null)
				button.get(Display).visible = false;
			// let ad video know
			adVideo.blimpVideoPopupLoaded();
		}
		
		/**
		 * Replay video
		 * @param button
		 */
		override protected function replayGame(button:Entity):void
		{
			adVideo.fnReplay();
		}
		
		/**
		 * Close popup
		 */
		override protected function closePopup(button:Entity):void
		{
			AdManager(super.shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLOSE_VIDEO_POPUP);
			// force stop video
			adVideo.fnStop(true);
			// close popup
			super.closePopup(button);
		}
		
		private function doNothing(entity:Entity):void
		{
		}
	}
}