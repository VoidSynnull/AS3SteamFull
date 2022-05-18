package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.external.ExternalInterface;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.adparts.parts.AdVideo;
	import game.creators.ui.ToolTipCreator;
	import game.data.ParamData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.scene.template.ads.AdVideoGroup;
	import game.ui.popup.Popup;
	import game.utils.AdUtils;
	
	/**
	 * Plays a video popup from a card 
	 * Refer to the PeanutsMovieVideoIC campaign and card 2738
	 */
	public class AutoCardVideo extends Popup
	{
		public function AutoCardVideo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			
			// if missing limited, then add
			if (super.data.swfPath.substr(0,7) != AdvertisingConstants.AD_PATH_KEYWORD)
				super.data.swfPath = AdvertisingConstants.AD_PATH_KEYWORD + "/" + super.data.swfPath;
			
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.screen = super.getAsset(super.data.swfPath, true) as MovieClip;
			
			if (super.screen == null)
			{
				trace("Can't find popup: " + super.data.swfPath);
				//super.loaded();
				super.close();
				return;
			}
			else
			{
				//center popup
				super.centerPopupToDevice();
				
				_adManager = super.shellApi.adManager as AdManager;
				
				if( !super.campaignData )
				{
					trace( "Error :: AutoCardVideo : campaignData has not been defined, is required to proceed.");
					//super.loaded();
					super.close();
					return;
				}
				else
				{
					_adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_VIDEO_POPUP_IMPRESSION, _choice, _subchoice);
					
					_timer = getTimer();
					
					if (ExternalInterface.available)
						ExternalInterface.call("hideWrapper");
					
					if (super.screen["closeButton"] != null)
						super.screen.closeButton = null;
					
					// set up close button
					setupButton(super.screen.btnClose, closePopup);
					
					// for each click url
					var urlParam:ParamData;
					for (var j:int = 0; j < super.campaignData.clickUrls.length; j++) 
					{
						urlParam = super.campaignData.clickUrls.getParamByIndex(j);
						// if matching button
						if (super.screen[urlParam.id] != null)
						{
							var button:MovieClip = super.screen[urlParam.id];
							setupButton(button, Command.create( visitSponsorSite, String(urlParam.value) ));
						}
					}
	
					// if video group exists, then don't create new one
					_videoGroup = AdVideoGroup(super.shellApi.sceneManager.currentScene.groupManager.getGroupById("AdVideoGroup"));
					if (_videoGroup == null)
						_videoGroup = new AdVideoGroup();
					var videoData:Object = {};
					videoData.campaign_name = super.campaignData.campaignId;
					videoData.width = super.screen.videoContainer.width/super.screen.videoContainer.scaleX;
					videoData.height = super.screen.videoContainer.height/super.screen.videoContainer.scaleY;
					videoData.choice = "Video";
					videoData.subchoice = "";
					videoData.videoFile = super.campaignData.video;
					// use first URL for video click to sponsor
					videoData.clickURL = super.campaignData.clickUrls.byIndex(0);
					_videoEntity = _videoGroup.setupAutoCardVideo(this, super.screen.videoContainer, super.screen, videoData);
				}
			}
			
			super.loaded();
			
			if ( super.data.autoPlay )
			{
				var autoVid:AdVideo = _videoEntity.get(AdVideo);
				autoVid.fnClick();
			}
		}
		
		private function closePopup(button:Entity):void
		{
			var elapsedTime:uint = Math.round((getTimer() - _timer)/1000);
			
			_adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_TOTAL_TIME, _choice, _subchoice, "TimeSpent", elapsedTime);
			
			_videoGroup.removeVideo(_videoEntity);
			
			if (ExternalInterface.available)
				ExternalInterface.call("unhideWrapper");
			
			super.close();
		}
		
		private function setupButton(button:MovieClip, action:Function):void
		{
			//create button entity
			var buttonEntity:Entity = new Entity();
			buttonEntity.add(new Spatial(button.x, button.y));
			buttonEntity.add(new Display(button));
			
			// add enity to group
			super.addEntity(buttonEntity);
			
			// add tooltip
			ToolTipCreator.addToEntity(buttonEntity);
			
			// add interaction
			var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], button);
			interaction.click.add(action);
		}
		
		private function visitSponsorSite(button:Entity, url:String):void
		{
			_sponsorURL = url;
			//_subchoice = button.get(Display).displayObject.getChildAt(0).name;
			//if (_subchoice.substr(0,8) == "instance")
				//_subchoice = "";
			if (_sponsorURL)
				AdManager.visitSponsorSite(super.shellApi, super.campaignData.campaignId, triggerSponsorSite);
		}
		
		private function triggerSponsorSite():void
		{
			_adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _subchoice);
			AdUtils.openSponsorURL(super.shellApi, _sponsorURL, super.campaignData.campaignId, _choice, _subchoice);			
		}
		
		private var _videoGroup:AdVideoGroup;
		private var _videoEntity:Entity;
		private var _timer:uint;
		private var _choice:String = "Popup";
		private var _subchoice:String = "Video";
		private var _sponsorURL:String;
		private var _adManager:AdManager;
	}
}

