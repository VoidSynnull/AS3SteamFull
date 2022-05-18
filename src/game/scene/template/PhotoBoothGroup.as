package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.ShellApi;
	
	import game.components.entity.Sleep;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManager;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBaseGroup;
	import game.scenes.photoBoothIsland.photoBoothScene.PhotoBoothScene;
		
	/**
	 * photo booth group within scenes
	 * @author VHOCKRI
	 */
	public class PhotoBoothGroup extends AdBaseGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function PhotoBoothGroup(container:DisplayObjectContainer=null, adManager:AdManager = null)
		{
			super(container, adManager);
			this.id = GROUP_ID;
		}
		
		/**
		 * Prepare photo booth group and check if photo booth can be loaded
		 * @param scene
		 * @return Boolean (true means ad group gets added to scene)
		 */
		override public function prepAdGroup(scene:PlatformerGameScene):Boolean
		{
			super.prepAdGroup(scene);
			
			// if scene doesn't already have photo booth group
			if (_parentScene.getGroupById(GROUP_ID) == null)
			{
				// if data node has photo_booth.xml
				if (String(_parentScene.sceneData.data).indexOf("photo_booth.xml") != -1)
				{
					// ad inventory tracking (if scene supports photo booth)
					_adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, _adManager.photoBoothType);
					
					// if ad type is supported (browser or mobile photo booth)
					if (_adManager.adTypes.indexOf(_adManager.photoBoothType) != -1)
					{
						// check if photo booth is on this island
						_adData = _adManager.getAdData(_adManager.photoBoothType, false, true);
						// if photo booth found in CMS data, then load it
						if (_adData != null)
						{
							// load xml for photo booth on island scene
							shellApi.loadFile(shellApi.dataPrefix + _parentScene.groupPrefix + "photo_booth.xml", photoBoothXMLLoaded);
							return true;
						}
					}
				}
			}
			// if photo booth not found, then return false for no ad
			trace("PhotoBoothGroup :: no photo booth to display");
			return false;
		}

		/**
		 * When photo booth xml is loaded 
		 * @param sceneXML
		 */
		private function photoBoothXMLLoaded(sceneXML:XML):Boolean
		{
			// if success
			if (super.sceneXMLLoaded(sceneXML))
			{
				// impression tracking		
				_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_PHOTOBOOTH_IMPRESSION, _adData.campaign_type);

				// parse scene xml and get layer data
				var parser:SceneParser = new SceneParser();
				_sceneData = parser.parse(sceneXML, shellApi);
				
				// offsets within scene
				var layerData:CameraLayerData = _sceneData.layers["PhotoBooth"][GameEvent.DEFAULT];
				this._offsetX = layerData.offsetX; 
				this._offsetY = layerData.offsetY;
				
				// set final group prefix
				groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/" + _adData.campaign_name + "/";
				
				// load scene.xml for specific campaign
				_parentScene.sceneDataManager.loadSceneConfiguration("scene.xml", groupPrefix, mergeSceneFiles);
				
				return true;
			}
			else
			{
				// if failure
				// trigger completion with no ad
				this.ready.dispatch(this);
				return false;
			}
		}
		
		/**
		 * Merge scene files when files loaded 
		 */
		private function mergeSceneFiles(files:Array):void
		{
			// merge files into scene (swfs and xml files)
			_parentScene.sceneDataManager.mergeSceneFiles(files, groupPrefix, _parentScene.groupPrefix, mergeProcessor);

			// trigger completion
			this.ready.dispatch(this);
		}

		/**
		 * Process special clips by name 
		 * @param name
		 * @param addedChild
		 */
		override protected function processClipByName(name:String, addedChild:MovieClip):void
		{
			super.processClipByName(name, addedChild);
			
			switch(name)
			{
				// for door
				case "photoBoothDoor":
					
					//create hotspot entity
					var entity:Entity = new Entity();
					entity.add(new Spatial(addedChild.x, addedChild.y));
					var display:Display = new Display(addedChild);
					entity.add(display);
					entity.add(new Id(name));
					display.isStatic = true;
					entity.add(new Sleep());
					display.alpha = 0;
					
					// add enity to group
					this._parentScene.addEntity(entity);
					
					// add tooltip
					ToolTipCreator.addToEntity(entity, ToolTipType.CLICK, "Enter");
					
					// create interaction for clicking on vendor cart hotspot
					var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK], addedChild);
					interaction.click.add(doClick);
					break;
			}
		}
		
		/**
		 * When clicking on door 
		 * @param clickedEntity
		 */
		private function doClick(clickedEntity:Entity):void
		{
			enterPhotoBooth(_adData.campaign_name, super.shellApi);
		}
		
		/**
		 * Enter photo booth and load PhotoBoothScene
		 * @param adData
		 * @param shellApi
		 */
		static public function enterPhotoBooth(campaignName:String, shellApi:ShellApi):void
		{
			// tracking when clicked
			AdManager(shellApi.adManager).track(campaignName, AdTrackingConstants.TRACKING_PHOTO_BOOTH_CLICKED);
			
			// get ad data for campaign
			var oldAdData:AdData = AdManager(shellApi.adManager).getAdDataByCampaign(campaignName);
			
			// if found, then load photo booth
			if (oldAdData)
			{
				trace("PhotoBoothGroup: creating interior campaign for " + campaignName);
				// make new AdData copy for PhotoBoothIsland using off-main photo booth interior
				var newAdData:AdData = new AdData();
				newAdData.campaign_type = AdCampaignType.PHOTO_BOOTH_INTERIOR;
				newAdData.campaign_name = campaignName;
				newAdData.clickURL = oldAdData.clickURL;
				newAdData.offMain = true;
				newAdData.island = "PhotoBoothIsland";
				newAdData.suffix = oldAdData.suffix;
				
				// update ad data for photoBooth island
				AdManager(shellApi.adManager).makeAdDataCampaignsActive(newAdData);
				
				// go to photobooth scene
				shellApi.loadScene(PhotoBoothScene);
			}
			else
			{
				trace("PhotoBoothGroup: Can't find campaign data for " + campaignName);
			}
		}
		
		private var _layerData:CameraLayerData;
		
		public static const GROUP_ID:String = "PhotoBooth";
	}
}