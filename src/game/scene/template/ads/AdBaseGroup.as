package game.scene.template.ads
{
	import com.adobe.utils.XMLUtil;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	
	import game.components.motion.FollowTarget;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneData;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerBrowser;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.util.DataUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	import org.hamcrest.object.nullValue;
		
	/**
	 * Base group for billboards, main street ads and house vendor carts 
	 * @author VHOCKRI
	 * 
	 */
	public class AdBaseGroup extends DisplayGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function AdBaseGroup(container:DisplayObjectContainer = null, adManager:AdManager = null)
		{
			super(container);
			// remember ad manager
			_adManager = adManager;
		}

		// FUNCTIONS TO BE OVERRIDEN ////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Prepare ad group and check if ad can be loaded
		 * @param scene
		 * @return Boolean (true means ad group gets added to scene)
		 */
		public function prepAdGroup(scene:PlatformerGameScene):Boolean
		{
			_parentScene = scene;
			shellApi = scene.shellApi;
			return true;
		}
		
		/**
		 * When scene xml for ad is loaded
		 */
		protected function sceneXMLLoaded(sceneXML:XML):Boolean
		{
			// if missing scene xml for ad
			if(sceneXML == null)
			{
				trace("Error :: AdBaseGroup :: No scene.xml for ad. No ad loaded for " + _adData.campaign_name);
				// track missing xml
				shellApi.track("MissingAd", "MissingXML", _adData.campaign_name);
				return false;
			}
			// check branding
			AdUtils.checkBranding(_parentScene, _adData.campaign_name);
			return true;
		}
		
		// PROCESSING FUNCTIONS ////////////////////////////////////////////////////////////////////////
		
		/**
		 * Process the merging of data files and assets
		 * If the mergeProcessor returns false, it means the function will handle the merge on its own
		 * Otherwise the default merge will be executed
		 * @param adFile File being added
		 * @param adURL URL of file being added
		 * @param originalFile File getting added to
		 * @param originalUrl URL of file getting added to
		 * @return Boolean
		 */
		
		private function findAttribute(xml:XML, attribute:String, callback:Function, recursive:Boolean = true):void {
			if(xml.attribute(attribute) != null) {
				callback(xml);
				return;
			}
			for (var i:int = 0; i < xml.elements().length(); i++) {
				var el:XML = xml.elements()[i];
				if (el.attribute(attribute) != null) {
					callback(el);
				} else {
					if (recursive) {
						findAttribute(el, attribute, callback);
					}
				}
			}
		}
		
		protected function mergeProcessor(adFile:*, adURL:String, originalFile:*, originalUrl:String, suffix:String ):Boolean
		{
			if(DataUtils.validString(suffix)) {
				if(adFile is XML) {
					var xml:XML = adFile;
					if(adURL.indexOf("campaign") == -1) {
						for each(var element:XML in xml.elements()) 
						{
							findAttribute(element, "id", function(node:XML):void{
								var id:String = node.@id;
								if(DataUtils.validString(id) && id != "player")
								{
									node.@id = id + suffix;
									trace(node.@id);
								}
							});
							findAttribute(element, "linkEntityId", function(node:XML):void{
								var id:String = node.@linkEntityId;
								if(DataUtils.validString(id) && id != "player")
								{
									node.@linkEntityId = id + suffix;
									trace(node.@linkEntityId);
								}
							});
						}
					}
				}
			}
			// if npcs xml file
			if(adURL.indexOf(GameScene.NPCS_FILE_NAME) != -1)
			{
				// apply offset for all NPC positions
				for each (var position_node:XML in adFile..position)
				{
					position_node.x = parseInt(position_node.x) + _offsetX;
					position_node.y = parseInt(position_node.y) + _offsetY;
				}
			}
			// if swf file
			else if(adURL.indexOf(".swf") != -1)
			{
				// set display offset for swf
				var displayOffsetX:Number = _offsetX;
				var displayOffsetY:Number = _offsetY;
				// if negative offset, then handle differently
				if(_adOffsetY < 0)
				{
					displayOffsetX = _offsetX - _adOffsetX;
					displayOffsetY = _offsetY - _adOffsetY;
				}
				
				// if hits or interactive layer
				if(adURL.indexOf("interactive.swf") != -1 || adURL.indexOf("hits.swf") != -1)
				{
					// if original file is null, then find it
					if(!originalFile)
					{
						if(adURL.indexOf("interactive.swf") > -1)
							originalUrl = originalUrl.replace("interactive.swf", "hits.swf");
						else if(adURL.indexOf("hits.swf") > -1)
							originalUrl = originalUrl.replace("hits.swf", "interactive.swf");
						originalFile = shellApi.getFile(originalUrl);
					}
					
					var nextChild:MovieClip;
					var addedChild:MovieClip;
					var vcHotSpot:MovieClip;
					var hasBranding:Boolean = false;
					var videoList:Array = [];
					
					// special handling for interactive layer
					// message change clips are handled here
					processInteractiveLayer(adFile, suffix);
					// for each child in interactive layer
					for (var i:int = adFile.numChildren-1; i != -1; i--)
					{
						// child clip in ad's interactive layer
						nextChild = adFile.getChildAt(i);
						
						// if bitmap hits, then add to bitmap hits clip
						if(nextChild.name == "bitmapHits")
						{
							// if scene doesn't have a bitmapHits layer, then create one
							if (originalFile.bitmapHits == null)
							{
								var bitmapHitsClip:MovieClip = new MovieClip();
								bitmapHitsClip = MovieClip(originalFile.addChild(bitmapHitsClip));
								originalFile.bitmapHits = bitmapHitsClip;
								bitmapHitsClip.name = "bitmapHits";
							}
							addedChild = originalFile.bitmapHits.addChild(adFile.bitmapHits);
						}
						else
						{
							// if not bitmap hits
							// if name has "branded" in it
							var isBranded:Boolean = (nextChild.name.toLowerCase().indexOf("branded") != -1);
							// if any branded item, then set branding flag
							if (isBranded)
								hasBranding = true;
							// if branding has expired and name has branding, then skip
							if ((_brandingRemoved) && (isBranded))
							{
								trace("Branding: expired clip: " + nextChild.name);
								continue;
							}
								
							// add children at lowest depth of interactive layer
							addedChild = originalFile.addChildAt(nextChild, 0);
							// create reference to added clip
							originalFile[addedChild.name] = addedChild;
							
							// if branded then add to array
							if (isBranded)
							{
								trace("Branding: branded clip: " + nextChild.name);
								if (brandedClips == null)
									brandedClips = [];
								brandedClips.push(addedChild);
							}
							// add videos to list
							if (nextChild.name.indexOf("videoContainer") != -1)
								videoList.push(addedChild);
						}
						// set added child alpha to original alpha
						addedChild.alpha = nextChild.alpha;
						// hide any clips that start with message
						if (nextChild.name.indexOf("messag") == 0)
							addedChild.visible = false;
						
						// offset added child
						addedChild.x += displayOffsetX;
						addedChild.y += displayOffsetY;
						
						// special processing by clip name
						processClipByName(nextChild.name, addedChild);
					}
					
					// if has branding, then add videos
					if (hasBranding)
					{
						// for each video
						for each (var video:MovieClip in videoList)
						{
							// if branding expired then remove
							if (_brandingRemoved)
							{
								originalFile.removeChild(video);
							}
							else
							{
								// else add to array
								brandedClips.push(video);
							}
						}
					}
					
					// if rollover text for vendor carts
					if (_rolloverText)
					{
						// if hot spot is found for rollover text, then set listeners
						if (_vcHotSpot)
						{
							_vcHotSpot.addEventListener(MouseEvent.ROLL_OVER, showRolloverText);
							_vcHotSpot.addEventListener(MouseEvent.ROLL_OUT, hideRolloverText);
						}
						else
						{
							trace("AdBaseGroup: error: missing hotspot for rollover text. It must be named 'poster' or 'hotspot'");
						}
					}
					return false;
				} else if (adURL.indexOf("bitmap_hits.swf") != -1) {
					if (originalFile == null) {
						trace("scene is missing bitmap_hits layer");
					} else {
						addedChild = originalFile.addChild(adFile);
						addedChild.x += displayOffsetX;
						addedChild.y += displayOffsetY;
					}

				} else {
					// if all other swfs, such as background
					// set offsets for ad clip
					adFile.x += displayOffsetX;
					adFile.y += displayOffsetY;
					
					// get layer data
					var layerId:String = getIdFromLayerUrl(adURL);
					var layerData:CameraLayerData = SceneUtil.getCameraLayerDataById(_sceneData, "custom_" + layerId+suffix);
					
					// if layer data found, then set merge values
					if(layerData != null)
					{
						// if merging or is background
						if(layerData.condition == "alwaysMerge" || layerData.id.indexOf("background") != -1)
						{
							// createad layer data for ad layer
							_parentScene.sceneData.layers[layerData.id+suffix] = new Dictionary();
							_parentScene.sceneData.layers[layerData.id+suffix][GameEvent.DEFAULT] = layerData;
							layerData.asset = adURL;
							layerData.absoluteFilePaths = true;
							layerData.condition = "alwaysMerge";
							layerData.conditionValue = ["background", "placeOver"];
							return false;
						}
					}
					else
					{
						// look for blimp layerdata
						layerData = SceneUtil.getCameraLayerDataById(_sceneData, "blimp");
						layerId = getIdFromLayerUrl(adURL);
						if((layerData != null) && (layerId == "blimp"))
						{
							// create layer data for ad layer to merge blimp into foreground
							_parentScene.sceneData.layers[layerData.id] = new Dictionary();
							_parentScene.sceneData.layers[layerData.id][GameEvent.DEFAULT] = layerData;
							layerData.asset = adURL;
							layerData.absoluteFilePaths = true;
							layerData.condition = "alwaysMerge";
							layerData.conditionValue = ["foreground", "placeOver"];
							return false;
						}
					}
					
					// add ad scene to layer
					if (addChildAdToLayer(adFile, adURL))
						return false;
				}
			}
			return true;
		}
		
		/**
		 * Process interactive layer (overriden by AdSceneGroup)
		 * @param adFile
		 */
		protected function processInteractiveLayer(adFile:MovieClip, suffix:String):void
		{
			// to be overriden
		}
		
		/**
		 * Special handling of added clips by name 
		 * @param name
		 * @param addedChild
		 */
		protected function processClipByName(name:String, addedChild:MovieClip):void
		{
			switch (name)
			{
				// names used for hotspot area for floating rollover text for vendor carts
				case "poster":
				case "hotspot":
					_vcHotSpot = addedChild;
					break;
				
				case "rolloverText": // add floating rollover text for vendor carts
					
					trace("AdBaseGroup: Create floating rollover text for vendor cart");
					//create entity
					_rolloverText = new Entity();
					_rolloverText.add(new Spatial(addedChild.x, addedChild.y));
					var display:Display = new Display(addedChild);
					display.visible = false;
					_rolloverText.add(display);
					addedChild.mouseEnabled = false;
					addedChild.mouseChildren = false;
					
					// add enity to group
					_parentScene.addEntity(_rolloverText);
					
					// set mouse follow
					var followTarget:FollowTarget = new FollowTarget();
					// the Spatial that will be followed, in this case the main input
					followTarget.target = _parentScene.shellApi.inputEntity.get( Spatial );
					// rate of target following, 1 is highest causing 1:1 following
					followTarget.rate = 1;
					// this needs be true with scenes using the camera
					followTarget.applyCameraOffset = true;
					_rolloverText.add( followTarget );
					break;
				
				case "animation": // create timeline from any animation named "animation"
					TimelineUtils.convertClip(addedChild, _parentScene);
					break;
			}
		}

		/**
		 * Add ad clip to layer scene clip as child (is overriden by ad groups)
		 * IMPORTANT NOTE: backgrounds need to have an ID that starts with background if there are multiple backgrounds
		 * @param adFile
		 * @param adURL
		 * @return Boolean
		 */
		private function addChildAdToLayer(adFile:MovieClip, adURL:String):Boolean
		{
			var layer:String = "background";
			if (adURL.indexOf(layer) != -1)
			{
				// hide/show embedded clips named boy or girl depending on gender
				// NOTE: this won't work if the layer id contains "background"
				// suggest "custom_back_nomerge" as the layer id
				var clip:MovieClip = adFile["bgVector"];
				if (clip != null)
				{
					var gender:String = shellApi.profileManager.active.gender;
					if (gender == null)
						gender = SkinUtils.GENDER_MALE;
					// look for boy and girl layers and hide them based on gender
					if ((clip["boy"] != null) && (gender == SkinUtils.GENDER_FEMALE))
						clip["boy"].visible = false;
					if ((clip["girl"] != null) && (gender == SkinUtils.GENDER_MALE))
						clip["girl"].visible = false;
				}
			}
			else if (adURL.indexOf("foreground") != -1)
			{
				layer = "foreground";
			}

			// get copy of events
			var events:Vector.<String> = shellApi.getEvents().slice();
			// add default to beginning of event list
			events.unshift(GameEvent.DEFAULT);
			
			var layerData:CameraLayerData;
			var allLayerData:Dictionary;
			
			// search scene layers for layer data for the most recent event
			for each (allLayerData in _parentScene.sceneData.layers)
			{
				// iterate through events in order
				for (var n:uint = 0; n < events.length; n++)
				{
					var tempLayerData:CameraLayerData = allLayerData[events[n]];
					
					// if found match for event
					if (tempLayerData)
					{
						// if layer data is background layer data, then set layer data
						if ((tempLayerData.id == layer) || ((layerData == null) && (tempLayerData.id.indexOf(layer) != -1)))
						{
							layerData = tempLayerData;
						}
					}
				}
			}
			// if layer data found, then add ad file to scene layer clip
			if (layerData)
			{
				clip = shellApi.getFile(shellApi.assetPrefix + _parentScene.groupPrefix + layerData.asset);
				clip.addChild(adFile);
				return true;
			}
			else
			{
				// if can't find then load default background swf
				clip = shellApi.getFile(shellApi.assetPrefix + _parentScene.groupPrefix + layer + ".swf");
				if (clip)
				{
					clip.addChild(adFile);
					return true;
				}
			}
			return false;
		}
				
		/**
		 * Get layer ID from layer URL 
		 * @param url
		 * @return String
		 */
		private function getIdFromLayerUrl(url:String):String
		{
			var parts:Array = url.split("/");
			var filePath:String = parts[parts.length - 1];
			var layerId:String = filePath.substring(0, filePath.length - 4);
			return(layerId);
		}
		
		/**
		 * Remove branding from campaign
		 */
		public function removeBranding():void
		{
			// if branding not removed, then remove it once
			if (!_brandingRemoved)
			{
				// set expired flag to true
				_brandingRemoved = true;
				// set unbranded flag to be used for tracking
				_adData.unbranded = true;
				// hide branded clips
				for each (var clip:MovieClip in brandedClips)
				{
					trace("Branding: remove branding: " + clip.name);
					clip.visible = false;
					// need to move offscreen for any poster clips
					clip.y += 99999;
				}
				// remove all videos (this stops any videos that are currently playing also)
				var adVideoGroup:DisplayGroup = shellApi.groupManager.getGroupById('AdVideoGroup') as DisplayGroup;
				if (adVideoGroup)
				{
					if (adVideoGroup.hasOwnProperty('removeAll'))
						adVideoGroup['removeAll']();
				}
				// if wrapper active on main street, then remove it
				if ((_adManager.campaignStreetType == AdCampaignType.MAIN_STREET) && (_adManager.getAdData(AdCampaignType.WRAPPER, false)))
					AdManagerBrowser(_adManager).wrapperManager.expireMainStreetWrapper();
			}
		}

		// UTILITY FUNCTIONS /////////////////////////////////////////////////////////////
		
		/**
		 * Show rollover text 
		 * @param aEvent
		 */
		private function showRolloverText(aEvent:MouseEvent):void
		{
			Display(_rolloverText.get(Display)).visible = true;
		}
		
		/**
		 * Hide rollover text 
		 * @param aEvent
		 */
		private function hideRolloverText(aEvent:MouseEvent):void
		{
			if ((_rolloverText) && (_rolloverText.get(Display)))
				Display(_rolloverText.get(Display)).visible = false;
		}
		
		public var brandedClips:Array;
		
		private var _vcHotSpot:MovieClip;
		private var _brandingRemoved:Boolean = false;
		
		protected var _parentScene:PlatformerGameScene;
		protected var _adManager:AdManager;
		protected var _adData:AdData;
		protected var _sceneData:SceneData;
		protected var _adOffsetY:int = 0;
		protected var _adOffsetX:int = 0;
		protected var _offsetX:int = 0;
		protected var _offsetY:int = 0;
		protected var _rolloverText:Entity;
	}
}