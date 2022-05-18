package game.scenes.photoBoothIsland.photoBoothScene
{
	import com.poptropica.AppConfig;
	
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import game.ar.ArPopup.ArPopup;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.SceneManager;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerBrowser;
	import game.photoBooth.PhotoBooth;
	import game.scene.template.GameScene;
	import game.scenes.hub.town.Town;
	import game.util.ClassUtils;
	
	public class PhotoBoothScene extends GameScene
	{
		public function PhotoBoothScene()
		{
			trace("PhotoBoothScene started");
			super();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// default folder name for testing
			var campaignName:String = "_ARInteriorTemplate";
			var adData:AdData;
			var wrapperCampaign:String;
			// get campaign data for main street campaign on PhotoBoothIsland (offmain is true)
			if(AppConfig.adsActive)
			{
				adData = shellApi.adManager.getAdData(AdCampaignType.PHOTO_BOOTH_INTERIOR, true, false, "PhotoBoothIsland");
				//var wrapperData:AdData = shellApi.adManager.getAdData(AdCampaignType.WRAPPER,false,false,this.shellApi.profileManager.active.previousIsland);
				
				// if web, then do wrapper stuff
				if (!AppConfig.mobile)
				{
					if(adData)
						wrapperCampaign = adData.campaign_name.substr(10) + "PBWrapper";
					
					var wrapperData:AdData = AdManager(shellApi.adManager).getAdDataByCampaign(wrapperCampaign);
					trace("PHOTOBOOTH:" + wrapperData);
					if(wrapperData)
					{
						
						// send tracking call
						AdManager(shellApi.adManager).track(wrapperData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, "Wrapper", "offMain");
						
						// if new wrapper from last, then send wrapper to page			
						// notify page to load wrapper
						if (ExternalInterface.available)
						{
							// tell Javascript to show wrapper
							if ((wrapperData.campaign_name) && (wrapperData.campaign_name != ""))
								ExternalInterface.call("showWrapper", wrapperData.campaign_name, wrapperData.clickURL, wrapperData.leftWrapper, wrapperData.rightWrapper);
						}
					}
					else
					{
						AdManagerBrowser(shellApi.adManager).wrapperManager.clearWrapper();
					}
				}
			}
			
			// if ad data found, then use data from CMS
			if (adData)
			{
				campaignName = adData.campaign_name;
				trace("PhotoBoothScene: found campaign: " + campaignName);
				var suffix:String = campaignName.indexOf("PhotoBooth") == -1?AR_SUFFIX:PHOTO_BOOTH_SUFFIX;
				// point to photobooth xml in campaign interior folder
				var path:String = shellApi.dataPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + campaignName + suffix;
				if(suffix == AR_SUFFIX)
					addChildGroup(new ArPopup(overlayContainer, path, campaignName)).removed.add(returnToPreviousScene);
				else
					addChildGroup(new PhotoBooth(overlayContainer, path, campaignName)).removed.add(returnToPreviousScene);
			}
			else
			{
				// else use default
				var tf:TextField = new TextField();
				tf.text = "Campaign Name:";
				tf.background = true;
				tf.backgroundColor = 0xff0000;
				tf.autoSize = TextFieldAutoSize.LEFT;
				tf.x = shellApi.viewportWidth / 2 -tf.width;
				tf.y = shellApi.viewportHeight / 2 - tf.height / 2;
				overlayContainer.addChild(tf);
				tf = new TextField();
				tf.text = campaignName;
				tf.autoSize = TextFieldAutoSize.LEFT;
				tf.background = true;
				tf.type = TextFieldType.INPUT;
				tf.x = shellApi.viewportWidth / 2;
				tf.y = shellApi.viewportHeight / 2 - tf.height / 2;
				overlayContainer.addChild(tf);
				tf.addEventListener(KeyboardEvent.KEY_UP, Command.create(enterText, tf));
				tf.stage.focus = tf;
			}
			
			super.loaded();
		}
		
		protected function enterText(event:KeyboardEvent, tf:TextField):void
		{
			if(event.charCode == 13)
			{
				var suffix:String = tf.text.indexOf("PhotoBooth") == -1?AR_SUFFIX:PHOTO_BOOTH_SUFFIX;
				var url:String = shellApi.dataPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + tf.text + suffix;
				trace(url);
				if(suffix == AR_SUFFIX)
					addChildGroup(new ArPopup(overlayContainer, url)).removed.add(returnToPreviousScene);
				else
					addChildGroup(new PhotoBooth(overlayContainer, url));
			}
		}
		
		// return to previous scene on click
		private function returnToPreviousScene(group:Group):void
		{
			var sceneManager:SceneManager = shellApi.sceneManager;
			var destScene:String = sceneManager.previousScene;
			var destX:Number = sceneManager.previousSceneX;
			var destY:Number = sceneManager.previousSceneY;
			
			if (destScene.indexOf('.') > -1) {
				shellApi.loadScene(ClassUtils.getClassByName(destScene), destX, destY, sceneManager.previousSceneDirection);
			} else {
				shellApi.loadScene(Town);
			}
		}
		
		private const PHOTO_BOOTH_SUFFIX:String = "Interior/photobooth.xml";
		private const AR_SUFFIX:String = "Interior/ar.xml";
	}
}