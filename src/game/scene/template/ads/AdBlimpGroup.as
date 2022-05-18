package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.adparts.parts.AdVideo;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManager;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBaseGroup;
	import game.scenes.map.map.Map;
	import game.utils.AdUtils;
		
	/**
	 * Blimp takeover ad group within scenes
	 * @author Rick Hocker
	 */
	public class AdBlimpGroup extends AdBaseGroup
	{
		private var adVideo:AdVideo;
		private var trackingData:Object;
		
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function AdBlimpGroup(container:DisplayObjectContainer=null, adManager:AdManager = null)
		{
			super(container, adManager);
			this.id = GROUP_ID;
		}
		
		/**
		 * Prepare blimp group and check if blimp can be loaded
		 * @param scene
		 * @return Boolean (true means ad group gets added to scene)
		 */
		override public function prepAdGroup(scene:PlatformerGameScene):Boolean
		{
			super.prepAdGroup(scene);
			
			// if scene doesn't already have ad blimp group
			if (_parentScene.getGroupById(GROUP_ID) == null)
			{
				// if data node has blimp.xml
				if (String(_parentScene.sceneData.data).indexOf("blimp.xml") != -1)
				{
					// ad inventory tracking (if scene supports vendor cart)
					_adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, _adManager.blimpType);
					
					// check if blimp takeover is on this island
					_adData = _adManager.getAdData(_adManager.blimpType, false, true);
					// if blimp found in CMS data, then load it
					if (_adData != null)
					{
						// load xml for blimp takeover on island scene
						shellApi.loadFile(shellApi.dataPrefix + _parentScene.groupPrefix + "blimp.xml", blimpXMLLoaded);
						return true;
					}
				}
			}
			// if blimp not found, then return false for no ad
			trace("AdBlimpGroup: no blimp takeover to display");
			return false;
		}

		/**
		 * When blimp xml is loaded 
		 * @param sceneXML
		 */
		private function blimpXMLLoaded(sceneXML:XML):Boolean
		{
			// if success
			if (super.sceneXMLLoaded(sceneXML))
			{
				// impression tracking		
				_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, _adData.campaign_type);
				
				// parse scene xml and get layer data
				var parser:SceneParser = new SceneParser();
				_sceneData = parser.parse(sceneXML, shellApi);
				
				// offsets within scene
				var layerData:CameraLayerData = _sceneData.layers["blimp"][GameEvent.DEFAULT];
				this._offsetX = layerData.offsetX; 
				this._offsetY = layerData.offsetY;
				
				// set final group prefix
				groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/" + _adData.campaign_name + "/";
				
				// load blimp foreground and interactive swfs
				super.loadFiles(["blimp.swf","interactive.swf","hotspots.xml","tracking.xml","npcs.xml","dialog.xml"], false, true, mergeSceneFiles);
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
		 * Merge scene files when blimp takeover swf loaded 
		 */
		private function mergeSceneFiles():void
		{
			var inInteractiveLayer:Boolean = false;
			
			// hide normal blimp in foreground, if found
			var originalFile:MovieClip = shellApi.getFile(shellApi.assetPrefix + _parentScene.groupPrefix + "foreground.swf");
			if (originalFile["blimp"] != null)
			{
				originalFile["blimp"].visible = false;
			}
			// if not found in foreground and in town hub scene
			else if (_parentScene.groupPrefix == "scenes/hub/town/")
			{
				inInteractiveLayer = true;
				// set original file to interactive layer for town hub scene
				originalFile = shellApi.getFile(shellApi.assetPrefix + _parentScene.groupPrefix + "interactive.swf");
				// hide balloon
				originalFile["blimp"]["balloon"].visible = false;
			}
			
			// list of files to merge
			var mergeList:Array = ["interactive.swf","npcs.xml","dialog.xml"];
			
			// add blimp to interactive layer
			if (inInteractiveLayer)
			{
				var blimp:MovieClip = shellApi.getFile(shellApi.assetPrefix + groupPrefix + "blimp.swf");
				blimp = MovieClip(originalFile["blimp"].addChild(blimp));
				blimp.x = 0;
				blimp.y = 60;
			}
			else
			{
				// else add blimp to merge list
				mergeList.push("blimp.swf");
			}

			// merge blimp files into foreground and interactive swfs
			_parentScene.sceneDataManager.mergeSceneFiles(mergeList, groupPrefix, _parentScene.groupPrefix, mergeProcessor);
			
			// attach listener for whenever a new scene is loaded
			shellApi.sceneManager.sceneLoaded.add(handleSceneLoaded);

			// trigger completion
			this.groupReady();
		}
		
		/**
		 * When scene loaded
		 */
		private function handleSceneLoaded(scene:Group):void
		{
			// remove listener
			shellApi.sceneManager.sceneLoaded.remove(handleSceneLoaded);
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			// get uiLayer swf
			var uiContainer:Sprite = GameScene(scene).uiLayer;
			var hitContainer:DisplayObjectContainer = PlatformerGameScene(scene).hitContainer;
			var overlayContainer:DisplayObjectContainer = Scene(scene).overlayContainer;
			
			// move NPC to blimpNPC y location in scene
			var npc:Entity = _parentScene.getEntityById("custom_blimp_npc");
			if (npc != null)
			{
				npc.get(Spatial).x = hitContainer["blimpNPC"].x;
				npc.get(Spatial).y = hitContainer["blimpNPC"].y - 36; // need offset from center of NPC to feet
				
				// sort any bitmapped NPCs by depth (includes npc friends or ad npcs)
				// will be redunant if there is a main street ad as well
				AdSceneGroup.sortBitmapNPCs(super.systemManager.getNodeList(NpcNode), shellApi.player);
				
				// set up interaction for clicking on NPC
				var npcInteraction:Interaction = npc.get(Interaction);
				if (npcInteraction)
					npcInteraction.click.add(npcClicked);
			}
			
			// get hotspots xml for ad
			var hotspotsXML:XML = getData("hotspots.xml", false);
			var trackingXML:XML = getData("tracking.xml", false);
			
			// parse tracking data
			trackingData = AdTrackingParser.parse(trackingXML);
			// part hotspot data
			var hotSpotsData:Object = AdHotSpotParser.parse(hotspotsXML);
			
			// look for blimp_video clip (publishes as interactive.swf) which is merged with interactive layer
			var videoClip:MovieClip = hitContainer["blimpVideoContainer"];
			if (videoClip != null)
			{
				// add blimp video to uiLayer clip and position
				videoClip = uiContainer.addChild(videoClip) as MovieClip;
				
				// setup video container
				var videoGroup:AdVideoGroup = new AdVideoGroup();
				adVideo = videoGroup.setupAdScene(Scene(scene), uiContainer, _adData, hotSpotsData, trackingData);
				// to force events for cards already awarded (doesn't work for dialog conversations/exchanges)
				// useful for dialog variations on statements
				adVideo.handleSceneLoaded();
			}
			
			// setup any poster hotspots
			var posterGroup:AdPosterGroup = new AdPosterGroup(null, shellApi);
			posterGroup.setupAdScene(_parentScene, hitContainer, _adData, hotSpotsData, trackingData);				

			// update exitToMap blimp hotspot to fit extents of balloon
			var hotSpot:MovieClip = hitContainer["exitToMap"];
			var balloonHotSpot:MovieClip = hitContainer["balloonHotSpot"];
			if (balloonHotSpot)
			{
				hotSpot.x = balloonHotSpot.x;
				hotSpot.y = balloonHotSpot.y;
				hotSpot.width = balloonHotSpot.width;
				hotSpot.height = balloonHotSpot.height;
			}

			// setup secondary hotspot, if found
			hotSpot = hitContainer["travelHotSpot"];
			if (hotSpot)
			{
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(hotSpot.x, hotSpot.y));
				buttonEntity.add(new Display(hotSpot));
				scene.addEntity(buttonEntity);
				ToolTipCreator.addToEntity(buttonEntity,ToolTipType.EXIT_UP,"TRAVEL");		
				// create interaction for clicking on button
				var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], hotSpot);
				interaction.click.add(goTravelMap);
			}
		}
				
		/**
		 * When blimp NPC clicked 
		 * @param charEntity
		 */
		private function npcClicked(charEntity:Entity):void
		{
			// get tracking node for character id
			var vNode:Object = trackingData[charEntity.get(Id).id];
			// if node found then track
			if (vNode != null)
			{
				_adManager.track(_adData.campaign_name, vNode.event, vNode.choice, vNode.subchoice);
			}
		}
		
		// capture dialog events
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event)
			{
				case "goTravelMap":
					goTravelMap();
					break;
				
				case "playBlimpVideo":
					// force click playButtonBlimp or replayButtonBlimp button to start video
					var buttonName:String = "playButtonBlimp";
					// if replay, then set to replayButtonBlimp
					if (adVideo.replay)
						buttonName = "re" + buttonName;
					adVideo.clickButton(_parentScene.getEntityById(buttonName));
					break;
			}
		}
		
		// go to travel map
		private function goTravelMap(entity:Entity = null):void
		{
			shellApi.loadScene(Map);
		}
		
		public static const GROUP_ID:String = "AdBlimpGroup";
	}
}