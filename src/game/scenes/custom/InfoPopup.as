package game.scenes.custom
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.printing.PrintJob;
	import flash.printing.PrintJobOptions;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.ParamData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ScreenManager;
	import game.managers.ads.AdManager;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	import game.utils.AdUtils;
	
	public class InfoPopup extends Popup
	{
		public function InfoPopup()
		{
			
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			// assets will be found in campaign folder in custom/limited folder
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
			super.screen = super.getAsset(super.data.swfPath, true) as MovieClip;
			
			if (super.screen == null)
			{
				trace("Can't find popup: " + super.data.swfPath);
			}
			else
			{				
				// TotalTime tracking currently disabled
				//_timer = getTimer();
				
				// target proportions for device (assumes art is non-centered and within 960x640 clip)
				var targetProportions:Number = super.shellApi.viewportWidth/super.shellApi.viewportHeight;
				var destProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
				// if wider, then fit to width and center vertically
				if (destProportions >= targetProportions)
				{
					var scale:Number = super.shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
				}
				else
				{
					// else fit to height and center horizontally
					scale = super.shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
				}
				super.screen.x = super.shellApi.viewportWidth / 2 - ScreenManager.GAME_WIDTH * scale / 2;
				super.screen.y = super.shellApi.viewportHeight / 2 - ScreenManager.GAME_HEIGHT * scale/ 2;
				super.screen.scaleX = super.screen.scaleY = scale;
				
				if (super.screen["closeButton"] != null)
					super.screen.closeButton = null;
				
				// set up close button
				setupButton(super.screen.btnClose, closePopup, null);
				
				// set up click urls
				var urlParam:ParamData;
				for (var j:int = 0; j < super.campaignData.clickUrls.length; j++) 
				{
					urlParam = super.campaignData.clickUrls.getParamByIndex(j);
					// if matching button
					if (super.screen[urlParam.id] != null)
					{
						var button:MovieClip = super.screen[urlParam.id];
						setupButton(button, Command.create( visitSponsorSite, String(urlParam.value) ), null);
					}
				}
				
			}
			
			// unlock input (that was locked in AdPoster class)
			SceneUtil.lockInput(super.parent, false);
			
			super.loaded();
		}

	
		private function closePopup(button:Entity):void
		{
			super.close();
		}
		
		
		
		private function setupButton(button:MovieClip, action:Function, id:String):void
		{
			//create button entity
			var buttonEntity:Entity = new Entity();
			buttonEntity.add(new Spatial(button.x, button.y));
			buttonEntity.add(new Display(button));
			if ( id )
				buttonEntity.add(new Id(id));
			
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
			if (_sponsorURL)
				AdManager.visitSponsorSite(super.shellApi, super.campaignData.campaignId, triggerSponsorSite);
		}
		
		private function triggerSponsorSite():void
		{
			super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _subchoice);
			AdUtils.openSponsorURL(super.shellApi, super.campaignData.campaignId, _sponsorURL, _choice, _subchoice);
		}
		
		// TotalTime tracking currently disabled
		// private var _timer:uint;
		
		private var _sponsorURL:String;
		private var _choice:String = "Popup";
		private var _subchoice:String = "Info";
	}
}

