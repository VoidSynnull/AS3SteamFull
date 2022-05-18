package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.adparts.creators.AdVideoCreator;
	import game.adparts.parts.AdVideo;
	import game.adparts.systems.AdVideoSystem;
	import game.data.ads.CampaignData;
	import game.systems.SystemPriorities;
	import game.utils.AdUtils;
	
	public class AdVideoGroup extends DisplayGroup
	{
		// instance of AdVideoCreator
		private var _adVideoCreator:AdVideoCreator;
		private var _group:Group;
		// array of ad video entities
		public var adVideoArray:Vector.<Entity> = new <Entity>[];
		
		public function AdVideoGroup(container:DisplayObjectContainer=null)
		{
			super(container);
			this.id = "AdVideoGroup";
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{			
		}
		
		override public function destroy():void
		{			
			super.groupContainer = null;
			super.destroy();
			_adVideoCreator = null;
			adVideoArray = null;
		}
		
		/**
		 * setup scene for ad videos
		 * @param scene
		 * @param hitContainer
		 * @param adData	Campaign data object
		 * @param hotSpotsData	hotspots xml data object for scene
		 * @param trackingData	tracking xml data object for scene
		 */
		public function setupAdScene(group:Scene, hitContainer:DisplayObjectContainer, adData:Object, hotSpotsData:Object, trackingData:Object, suffix:String=""):AdVideo
		{
			_group = group;
			
			// this group should inherit properties of the scene.
			this.groupPrefix = group.groupPrefix;
			this.container = group.container;
			this.groupContainer = hitContainer;
			
			// check if any video containers
			var vHasVideo:Boolean = false;
			for (var vID:String in hotSpotsData)
			{
				// create data object to pass to video
				var vData:Object = hotSpotsData[vID];
				
				if (vData.type == "video")
				{
					var videoAsset:MovieClip;
					if (vID == "blimpVideoContainer")
						videoAsset = MovieClip(hitContainer.getChildByName(vID));
					else
						videoAsset = MovieClip(hitContainer[vID]);
					if (videoAsset != null)
					{
						if (!vHasVideo)
						{
							// add it as a child group to give it access to systemManager.
							group.addChildGroup(this);
							// add AdVideoSystem to engine
							group.addSystem(new AdVideoSystem(), SystemPriorities.lowest);
							vHasVideo = true;
						}
						if (_adVideoCreator == null)
							_adVideoCreator = new AdVideoCreator();
						
						var vVideoData:Object = {};
						vVideoData.campaign_name = adData.campaign_name;
						vVideoData.width = vData.width;
						vVideoData.height = vData.height;
						trace("video is locked: from hotspots data: " + vData.locked);
						vVideoData.locked = vData.locked;
						vVideoData.controls = vData.controls;
						vVideoData.suppressSponsorButton = vData.suppressSponsorButton;
						vVideoData.game = vData.game;
						vVideoData.fullscreen = vData.fullscreen;
						vVideoData.showLikeButton = vData.showLikeButton;
						vVideoData.endScreensText = vData.endScreensText;
						if(trackingData[vID])
						{
							vVideoData.choice = trackingData[vID].choice;
							vVideoData.subchoice = trackingData[vID].subchoice;
						}
						
						if (vData.play)
						{
							trace("AdVideoGroup :: vData.play: " + vData.play);
							vVideoData.videoFile = AdUtils.getCampaignValue(adData, vData.play);
						}
							
						if (vData.awardCredits) {
							trace("AdVideoGroup :: setupAdScene - award credits : " + vData.awardCredits);
							vVideoData.awardCredits = vData.awardCredits;
						}
						if (vData.openUrlOnClick)
						{
							// if value is "clickURL" then pull from CMS data
							if (vData.openUrlOnClick == "clickURL")
							{
								vVideoData.clickURL = AdUtils.getCampaignValue(adData, vData.openUrlOnClick);
							}
							else
							{
								// else use the valid full URL from the hotspots xml file
								vVideoData.clickURL = vData.openUrlOnClick;
							}
						}
						if (vData.impressionOnClick)
						{
							// if value is "impressionURL" then pull from CMS data
							if (vData.impressionOnClick == "impressionURL")
							{
								vVideoData.impressionURL = AdUtils.getCampaignValue(adData, vData.impressionOnClick);
							}
							else
							{
								// else use the valid full URL from the hotspots xml file
								vVideoData.impressionURL = vData.impressionOnClick;
							}
						}
						vVideoData.giveItemMale = vData.giveItemMale;
						vVideoData.giveItemFemale = vData.giveItemFemale;
						
						// get lockedVideo from campaign data
						var campaignData:CampaignData = group.shellApi.adManager.getActiveCampaign(adData.campaign_name);
						if ((campaignData != null) && (campaignData.lockVideo != null))
						{
							vVideoData.locked = campaignData.lockVideo;
							trace("video is locked: from campaign " + campaignData.campaignId + ": " + campaignData.lockVideo);
						}
						
						// create AdVideo entity
						var vAdVideo:Entity = _adVideoCreator.create(group, videoAsset, vVideoData, suffix);
						adVideoArray.push(vAdVideo);
					}
					else
					{
						trace("Error :: AdVideoGroup :: can't find video with id " + vID);
					}
				}
			}
			if (vAdVideo != null)
			{
				// this is only required for blimp videos
				return vAdVideo.get(AdVideo);
			}
			else
			{
				return null;
			}
		}
		
		public function setupAutoCardVideo(group:Group, video:MovieClip, container:DisplayObjectContainer, videoData:Object):Entity
		{			
			_group = group;
			
			// this group should inherit properties of the scene.
			this.groupContainer = container;
			
			// add it as a child group to give it access to systemManager.
			group.addChildGroup(this);
			// add AdVideoSystem to engine
			group.addSystem(new AdVideoSystem(), SystemPriorities.lowest);
			
			if (_adVideoCreator == null)
				_adVideoCreator = new AdVideoCreator();
			
			// create AdVideo entity
			var vAdVideo:Entity = _adVideoCreator.create(group, video, videoData);
			adVideoArray.push(vAdVideo);
			return vAdVideo;
		}
		
		public function setupTownCarouselVideo(group:Scene, video:MovieClip, hitContainer:DisplayObjectContainer, videoData:Object):Entity
		{			
			_group = group;
			
			// this group should inherit properties of the scene.
			this.groupPrefix = group.groupPrefix;
			this.container = group.container;
			this.groupContainer = hitContainer;
			
			// add it as a child group to give it access to systemManager.
			group.addChildGroup(this);
			// add AdVideoSystem to engine
			group.addSystem(new AdVideoSystem(), SystemPriorities.lowest);
			
			if (_adVideoCreator == null)
				_adVideoCreator = new AdVideoCreator();
			
			// create AdVideo entity
			var vAdVideo:Entity = _adVideoCreator.create(group, video, videoData);
			adVideoArray.push(vAdVideo);
			return vAdVideo;
		}

		/**
		 * Pause all videos
		 */
		override public function pause(pauseChildGroups:Boolean = false, waitForUpdateComplete:Boolean = true):void
		{
			for each(var vVideo:Entity in adVideoArray)
			{
				if (vVideo.get(AdVideo))
					vVideo.get(AdVideo).fnPause();
			}
		}
		
		/**
		 * Unpause all videos
		 */
		override public function unpause(unpauseChildGroups:Boolean = false, waitForUpdateComplete:Boolean = true):void
		{
			for each(var vVideo:Entity in adVideoArray)
			{
				if (vVideo.get(AdVideo))
					vVideo.get(AdVideo).fnUnpause();
			}
		}
		
		/**
		 * Remove all videos
		 */
		public function removeAll():void
		{
			for each(var vVideo:Entity in adVideoArray)
			{
				_group.removeEntity(vVideo);
			}
			new <Entity>[];
		}
		
		/**
		 * Remove video entity
		 */
		public function removeVideo(vEntity:Entity):void
		{
			var pos:int = adVideoArray.indexOf(vEntity);
			if (pos != -1)
			{
				_group.removeEntity(vEntity);
				adVideoArray.splice(pos,1);
				return;
			}
		}
	}
}