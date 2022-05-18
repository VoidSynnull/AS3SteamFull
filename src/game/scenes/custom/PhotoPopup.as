package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.scene.template.PhotoGroup;
	import game.ui.popup.Popup;
	import game.utils.AdUtils;
	
	public class PhotoPopup extends Popup
	{
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		// all assets ready
		override public function loaded():void
		{
			// get photo ID (comes from hotspots.xml)
			photoID = super.data.param1;
			
			super.screen = super.getAsset(super.data.swfPath, true) as MovieClip;
			
			// set up quit button
			setupButton(super.screen["quitButton"], closePopup);
			
			// set up photo button
			setupButton(super.screen["photoButton"], takePhoto);
			
			// set up clickURL button
			_sponsorURL = super.campaignData.clickUrls.getParamByIndex(0).value;
			setupButton(super.screen["clickURL"], visitSponsorSite);
			
			// set up photo art
			// if have photo, then show different art
			if (super.shellApi.photoManager.checkIsTaken(photoID, "custom"))
			{
				tookPhoto = true;
				super.screen["photoInfo"].gotoAndStop(2);
			}
			else
			{
				super.screen["photoInfo"].gotoAndStop(1);
			}
			super.loaded();
		}
		
		private function setupButton(button:MovieClip, action:Function):void
		{
			if (button == null)
				trace("null button");
			else
			{
				// force button to vanish (it flashes otherwise)
				button.alpha = 0;
				
				//create button entity
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(button.x, button.y));
				buttonEntity.add(new Display(button));
				buttonEntity.get(Display).alpha = 0;
				
				// need this because showing the popup a second time will not have buttons
				if (button.parent != super.screen)
					super.screen.addChild(button);
				
				// add enity to group
				super.addEntity(buttonEntity);
				
				// add tooltip
				ToolTipCreator.addToEntity(buttonEntity);
				
				// add interaction
				var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], button);
				interaction.click.add(action);
			}
		}
		
		private function closePopup(button:Entity):void
		{
			super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_QUIT, _choice, _subchoice);
			super.close();
		}
		
		private function visitSponsorSite(button:Entity):void
		{
			if (_sponsorURL)
				AdManager.visitSponsorSite(super.shellApi, super.campaignData.campaignId, triggerSponsorSite);
		}
		
		private function triggerSponsorSite():void
		{
			super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _subchoice);
			AdUtils.openSponsorURL(super.shellApi, _sponsorURL, super.campaignData.campaignId, _choice, _subchoice);		
		}
		
		private function takePhoto(button:Entity):void
		{
			if (tookPhoto)
				closePopup(button);
			else
			{
				super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_TAKE_PICTURE, _choice, _subchoice);
				var photoGroup:PhotoGroup = PhotoGroup(super.shellApi.sceneManager.currentScene.getGroupById(PhotoGroup.GROUP_ID));
				photoGroup.takePhoto(photoID, "custom");
				super.screen["photoInfo"].gotoAndStop(2);
				tookPhoto = true;
			}
		}
		
		private var _sponsorURL:String;
		private var tookPhoto:Boolean = false;
		private var photoID:String;
		private var _choice:String = "Popup";
		private var _subchoice:String = "Photobooth";
	}
}