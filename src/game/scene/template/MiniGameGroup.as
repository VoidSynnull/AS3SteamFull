package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneParser;
	import game.managers.ads.AdManager;
	import game.scene.template.ads.AdBaseGroup;
		
	/**
	 * photo booth group within scenes
	 * @author VHOCKRI
	 */
	public class MiniGameGroup extends AdBaseGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function MiniGameGroup(container:DisplayObjectContainer=null, adManager:AdManager = null)
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
				// if data node has mini_game.xml
				if (String(_parentScene.sceneData.data).indexOf("mini_game.xml") != -1)
				{
					// ad inventory tracking (if scene supports mini game)
					_adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, _adManager.miniGameType);
					
					// if ad type is supported (browser or mobile photo booth)
					if (_adManager.adTypes.indexOf(_adManager.miniGameType) != -1)
					{
						// check if mini game is on this island
						_adData = _adManager.getAdData(_adManager.miniGameType, true, true);
						// if mini game found in CMS data, then load it
						if (_adData != null)
						{
							// load xml for photo booth on island scene
							shellApi.loadFile(shellApi.dataPrefix + _parentScene.groupPrefix + "mini_game.xml", miniGameXMLLoaded);
							return true;
						}
					}
				}
			}
			// if photo booth not found, then return false for no ad
			trace("MiniGameGroup :: no mini game to display");
			return false;
		}

		/**
		 * When photo booth xml is loaded 
		 * @param sceneXML
		 */
		private function miniGameXMLLoaded(sceneXML:XML):Boolean
		{
			// if success
			if (super.sceneXMLLoaded(sceneXML))
			{
				// impression tracking		
				_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_MINIGAME_IMPRESSION, _adData.campaign_type);

				// parse scene xml and get layer data
				var parser:SceneParser = new SceneParser();
				_sceneData = parser.parse(sceneXML, shellApi);
				
				// offsets within scene
				var layerData:CameraLayerData = _sceneData.layers["MiniGame"][GameEvent.DEFAULT];
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
		}
		
		public static const GROUP_ID:String = "MiniGame";
	}
}