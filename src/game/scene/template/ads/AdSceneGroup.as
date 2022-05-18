package game.scene.template.ads
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.CharacterProximity;
	import game.components.motion.TargetEntity;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.data.scene.SceneParser;
	import game.managers.ads.AdManager;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.ThresholdSystem;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	/**
	 * Group for billboards or main street buildings
	 * @author Rick Hocker
	 */
	public class AdSceneGroup extends AdBaseGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function AdSceneGroup(container:DisplayObjectContainer=null, adManager:AdManager = null)
		{
			super(container, adManager);
			this.id = GROUP_ID;
		}
				
		/**
		 * prepare ad group and check if ad can be loaded
		 * @param scene
		 * @return Boolean (true means ad group gets added to scene)
		 */
		override public function prepAdGroup(scene:PlatformerGameScene):Boolean
		{
			super.prepAdGroup(scene);
						
			// if scene doesn't already have ad scene group
			if (_parentScene.getGroupById(this.id) == null)
			{
				// get custom xml for scene (add numbers if lego)
				// add sponsored islands here (lowercase)
				if ((_num == 1) && ((shellApi.island != "lego") || (shellApi.island != "americanGirl")))
					_customSceneXML = _parentScene.getData(CUSTOM_FILE_NAME);
				else
					_customSceneXML = _parentScene.getData("custom" + _num + ".xml");
				trace(shellApi.island + " custom" + _num + " found xml? " + (_customSceneXML != null));
				// if custom xml found then get island ad data
				if (_customSceneXML != null)
				{
					// inventory tracking call
					var choice:String;
					//if (_adManager.defaultOffMain)
					//	choice = _adManager.billboardType;
					//else
						choice = _adManager.mainStreetType;
					//if (_adManager.swappable)
					//	choice += " Swappable";
					_adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, choice);
					
					// get campaign street type: billboard or main street
					_campaignType = _adManager.campaignStreetType;
					
					// add suffix if 2 or 3
					if (_num != 1)
						_campaignType += (" " + _num);
					
					// get ad data for specific campaign type
					_adData = _adManager.getAdData(_campaignType, _adManager.offMain, true);
					
					// if ad data not found, then look for other ads
					if (_adData == null)
					{
						// get scene class string
						var vScene:String = ClassUtils.getNameByObject(_parentScene);
						// if ad mixed scene and no main street ad, then get main street billboard
						/*
						if ((!_adManager.hasMainStreetAd()) && (vScene.indexOf("::AdMixed") != -1))
						{
							trace("AdSceneGroup: Fetching main street billboard instead of main street ad");
							_campaignType = _adManager.billboardType;
							_adData = _adManager.getAdData(_campaignType, false, true);
						}
						else if (_adManager.offMain)		
						*/
						if (_adManager.offMain)
						{
							// if off-main street, then load main street billboard, if no off-main billboard found
							trace("AdSceneGroup: Fetching main street billboard for billboard scene");
							_adData = _adManager.getAdData(_campaignType, false, true);
						}
					}
					
					// if found ad data, then display ad
					if (_adData != null)
					{
						trace("AdSceneGroup: display ad: campaign: " + _adData.campaign_name + ", type: " +  _adData.campaign_type);
						
						// get street type directory
						var streetPath:String = "/";
						// if version 1, then set street path
						var campaignData:CampaignData = _adManager.getActiveCampaign(_adData.campaign_name)
						if ((campaignData != null) && (campaignData.version == 1))
						{
							switch (_adData.campaign_type)
							{
								case AdCampaignType.MAIN_STREET:
									streetPath = "/mainStreet/";
									break;
								//case AdCampaignType.BILLBOARD:
								//	streetPath = "/sideStreet/";
								//	break;
							}
						}
						
						// create group prefix
						groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/" + _adData.campaign_name + streetPath;
												
						// load scene xml for ad
						super.loadFile(GameScene.SCENE_FILE_NAME, sceneXMLLoaded);
						return true;
					}
					else
					{
						trace("AdSceneGroup error: AD data is null for type: " + _campaignType);
					}
				}
				else
				{
					trace("AdSceneGroup: No custom.xml to support ad");
				}
			}
			// if no ad found, then load scene without ad
			return false;
		}
				
		/**
		 * When scene xml for ad is loaded 
		 * @param sceneXML - scene xml for ad
		 * @return 
		 */
		override protected  function sceneXMLLoaded(sceneXML:XML):Boolean
		{
			// if success
			if (super.sceneXMLLoaded(sceneXML))
			{
				// impression tracking
				_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, _campaignType);
				
				// parse ad scene data
				var parser:SceneParser = new SceneParser();
				_sceneData = parser.parse(sceneXML, shellApi);
				 
				// load the ad scene files
				_parentScene.sceneDataManager.loadSceneConfiguration(GameScene.SCENE_FILE_NAME, groupPrefix, mergeSceneFiles);
				return true;
			}
			else
			{
				// if failure
				// trigger completion with no ad
				_adManager.track(AdTrackingConstants.AD_FAILURE, "Ad XML Failure", AdCampaignType.MAIN_STREET, _adData.campaign_name);
				this.groupReady();
				return false;
			}
		}
		
		/**
		 * Merge ad scene files with parent scene files once ad scene files have loaded 
		 * @param parentSceneFiles - Array of urls of loaded scene files
		 */
		private function mergeSceneFiles(files:Array):void
		{
			// set ad offsets
			setOffsets();
			
			// merge ad scene files into parent scene files
			_parentScene.sceneDataManager.mergeSceneFiles(files, groupPrefix, _parentScene.groupPrefix, mergeProcessor, ""+_num);
			
			// now that we have merged doors.xml, check for custom door
			var doorXML:XML = Scene(super.parent).getData(GameScene.DOORS_FILE_NAME);
			if(doorXML != null)
			{
				for each (var node:XML in doorXML.door)
				{
					// if customDoor found then ad building has door to interior
					if (DataUtils.getString(node.attribute("id")).indexOf("customDoor") != -1)
					{
						// add campaign name to door node so we can start timer when entering an AS2 quest
						// do this only if campaignName is already null (not in xml)
						if (DataUtils.getString(node.attribute("campaignName")) == null)
						{
							node.@campaignName = _adData.campaign_name;
						}
						trace("AdSceneGroup: has customDoor: " + node.@campaignName);
						//hasCustomDoor = true;
						break;
					}
				}
			}
			
			// rlh: start ad timer if ad building doesn't have door
			// rlh: changed this so timer starts when interacting with main street video
			//if (!hasCustomDoor)
			//	_adManager.startActivityTimer(_adData.campaign_name);
						
			this.groupReady();
		}
		
		/**
		 * Set ad offsets 
		 */
		private function setOffsets():void
		{
			// get offsets from custom.xml for scene
			var x_offset:int = DataUtils.getNumber(_customSceneXML.offset.x);
			var y_offset:int = DataUtils.getNumber(_customSceneXML.offset.y);

			// offsets for ad itself to bottom center
			// custom.xml for ad itself
			var vAdCustom:XML = getData(CUSTOM_FILE_NAME);
			if (vAdCustom != null)
			{
				_adOffsetX = DataUtils.getNumber(vAdCustom.offset.x);
				_adOffsetY = DataUtils.getNumber(vAdCustom.offset.y);
			}

			// if add is aligned upper left
			if (_adOffsetY > 0)
			{
				// NOTE: we don't use positive ad offsets anymore but some legacy ads still do
				_offsetX = x_offset - _adOffsetX;
				_offsetY = y_offset - _adOffsetY;
			}
			else
			{
				// if ad is aligned bottom center
				_offsetX = x_offset + _adOffsetX;
				_offsetY = y_offset + _adOffsetY;
			}
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
				// for intro animation when NPC first speaks
				case "introAnimation":
					trace("AdSceneGroup: has intro animation");
					_hasIntroAnimation = true;
					var entity:Entity = TimelineUtils.convertClip(addedChild, _parentScene);
					_introAnimTimeline = entity.get(Timeline);
					_introAnimTimeline.gotoAndStop(0);
					break;
			}
		}
		
		/**
		 * Process clips on interactive layer 
		 * @param adFile
		 */
		override protected function processInteractiveLayer(adFile:MovieClip, suffix:String):void
		{
			// remember interactive clip
			_interactiveClip = adFile;
			var depth:int = 0
			for(var i:int = 0; i < adFile.numChildren; i++) {
				var clip:MovieClip = MovieClip(adFile.getChildAt(i));
				if(clip != null && clip.name != "bitmapHits") {
					DisplayUtils.replaceClip(clip, suffix);
				}
			}
			
			// get tracking xml for ad
			var trackingXML:XML = getData("tracking.xml", false);
			
			// if null, then error
			if (trackingXML == null)
			{
				trace("AdSceneGroup error: Missing tracking.xml");
			}
			else
			{
				// if valid
				// get hotspots xml for ad
				var hotspotsXML:XML = getData("hotspots.xml", false);
				
				// parse tracking data
				_trackingData = AdTrackingParser.parse(trackingXML);
				// part hotspot data
				var vHotSpotsData:Object = AdHotSpotParser.parse(hotspotsXML);
				
				// setup any video containers
				var videoGroup:AdVideoGroup = new AdVideoGroup();
				videoGroup.setupAdScene(_parentScene, adFile, _adData, vHotSpotsData, _trackingData, suffix);
				
				// setup any poster hotspots
				var posterGroup:AdPosterGroup = new AdPosterGroup(null, shellApi);
				posterGroup.setupAdScene(_parentScene, adFile, _adData, vHotSpotsData, _trackingData);				
			}
			
			// if message changes, then setup
			AdUtils.setUpMessaging(shellApi, _adData, _interactiveClip, suffix);
		}

		// CHARACTER FUNCTIONS ////////////////////////////////////////////////////
		
		/**
		 * Process NPCs on scene when all characters are loaded
		 * @param group
		 */
		public function processNPCs(group:Group):void
		{
			// get NPC node list
			var npcNodes:NodeList = super.systemManager.getNodeList(NpcNode);
			
			// sort any bitmapped NPCs by depth (includes npc friends or ad npcs)
			sortBitmapNPCs(npcNodes, shellApi.player);
			
			// process any ad NPCs
			processAdNPC(npcNodes);
		}
		
		/**
		 * Sort npc depths so bitmapped NPCs are toward back
		 * @param npcNodes
		 */
		static public function sortBitmapNPCs(npcNodes:NodeList, player:Entity):void
		{
			if(player == null)
				return;
			// get player clip and get depth of clip as stating depth
			var playerClip:MovieClip = MovieClip(player.get(Display).displayObject);
			var lowestDepth:int = playerClip.parent.getChildIndex(playerClip);
			
			// move bitmap NPCs behind all NPCs (get lowest non-bitmap NPC depth)
			var npcList:Array = [];
						
			// for each NPC
			for( var node:NpcNode = npcNodes.head; node; node = node.next )
			{
				var charEntity:Entity = node.entity;
				
				// if not bitmapped NPC
				if (charEntity.get(BitmapCharacter) == null)
				{
					// get lowest depth if less than current depth
					var clip:MovieClip = MovieClip(charEntity.get(Display).displayObject);
					var depth:int = clip.parent.getChildIndex(clip)
					if (depth < lowestDepth)
						lowestDepth = depth;
				}
				else
				{
					// else add to list (if bitmapped)
					npcList.push(charEntity);
				}
			}
			
			// if found bitmapped NPCs and depth has changed, then move to lowest depth
			if (npcList.length != 0)
			{
				// for each bitmapped npc
				for each (var npc:Entity in npcList)
				{
					var npcClip:MovieClip = MovieClip(npc.get(Display).displayObject);
					npcClip.parent.setChildIndex(npcClip, lowestDepth);
				}
			}
		}
		
		/**
		 * Process all ad NPCs 
		 * @param npcNodes
		 */
		private function processAdNPC(npcNodes:NodeList):void
		{
			var interaction:Interaction;
			
			// if have tracking data, then add interations with NPCs
			if (_trackingData)
			{
				// for each NPC
				for ( var node:NpcNode = npcNodes.head; node; node = node.next )
				{
					var charEntity:Entity = node.entity;
					// set up interaction for clicking on NPC
					interaction = charEntity.get(Interaction);
					if (interaction)
					{
						interaction.click.add(npcClicked);
					}
					else
					{
						trace("AdSceneGroup Error: Bitmap NPC needs to have full path specified in npcs.xml: " + charEntity.get(Id).id);
					}
					
					// if advertising NPC, then track NPC impressions if indicated in xml
					var charID:String = charEntity.get(Id).id;
					var charData:Object = _trackingData[charID];
					if ((charData != null) && (charData.triggerImpression == "true"))
					{
						_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_NPC_IMPRESSION, charID); 
					}
					
					//check for proximity
					if (charEntity.has(CharacterProximity))
					{
						// get and set current npc dialog
						// (seems ridiculous but fixes the problem with the NPC not speaking when first clicked)
						// TODO :: This should really just be and event id for dialog, could be set with CharacterProximity. - bard
						// TODO :: Better yet this proximiy business could just be its own system
						_npcDefaultDialog = charEntity.get(Dialog).current;
						Dialog(charEntity.get(Dialog)).current = _npcDefaultDialog;
						
						// setup NPC for proximity trigger of dialog				
						// setup tresholds for entering and exiting
						var charProximity:CharacterProximity = charEntity.get(CharacterProximity);
						var threshold:Threshold = new Threshold( "x", "<>", charEntity, charProximity.proximity );
						threshold.entered.add( Command.create(triggerNpcProximity,charEntity) );
						threshold.exitted.add( Command.create(restoreNpcProximity,charEntity) );
						shellApi.player.add( threshold );
						
						// add threshold system is not added
						if (!_parentScene.getSystem(ThresholdSystem))
						{
							_parentScene.addSystem(new ThresholdSystem());
						}
					}
				}
			}
		}
		
		/**
		 * When NPC clicked 
		 * @param charEntity
		 */
		private function npcClicked(charEntity:Entity):void
		{
			// interact with campaign and check for branding
			AdUtils.interactWithCampaign(_parentScene, _adData.campaign_name);

			// get tracking node for character id
			var vNode:Object = _trackingData[charEntity.get(Id).id];
			// if node found then track
			if (vNode != null)
			{
				_adManager.track(_adData.campaign_name, vNode.event, vNode.choice, vNode.subchoice);
			}
			// reset dialog if npc with proximity
			if (charEntity.has(CharacterProximity))
			{
				charEntity.get(Dialog).current = _npcDefaultDialog;
			}
		}

		/**
		 * Trigger NPC dialog when when avatar walks by
		 * @param charEntity
		 */
		private function triggerNpcProximity(charEntity:Entity):void
		{
			// check if target entity
			var targetEntity:TargetEntity = shellApi.player.get(TargetEntity);
			// if no target entity or didn't click on NPC then can trigger
			if ((targetEntity == null) || (targetEntity.active))
			{
				// send event to framework
				shellApi.triggerEvent("npcProximity");
				// reset dialog to current
				charEntity.get(Dialog).current = _npcDefaultDialog;
				
				// if has intro animation and hasn't been triggered, then trigger once
				if ((_hasIntroAnimation) && (!_playedIntroAnimation))
				{
					_playedIntroAnimation = true;
					_introAnimTimeline.play();
				}
			}
		}
		
		/**
		 * Restore NPC dialog when when avatar walks away
		 * @param charEntity
		 */
		private function restoreNpcProximity(charEntity:Entity):void
		{
			if ((charEntity != null) && (_npcDefaultDialog != null))
			{
				charEntity.get(Dialog).current = _npcDefaultDialog;
			}
		}
		
		private var _campaignType:String;
		private var _customSceneXML:XML;
		private var _trackingData:Object;
		private var _npcDefaultDialog:Object;
		private var _interactiveClip:DisplayObjectContainer;
		private var _hasIntroAnimation:Boolean = false;
		private var _playedIntroAnimation:Boolean = false;
		private var _introAnimTimeline:Timeline;
		protected var _num:int = 1;
		
		/** flag determining if main street building has a custom door to interior */
		// no longer used
		//public var hasCustomDoor:Boolean = false;

		static public const CUSTOM_FILE_NAME:String = "custom.xml";
		
		public static const GROUP_ID:String = "AdSceneGroup1";
	}
}

