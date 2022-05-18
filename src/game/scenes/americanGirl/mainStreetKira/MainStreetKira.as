package game.scenes.americanGirl.mainStreetKira
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterProximity;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManager;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scene.template.ads.AdHotSpotParser;
	import game.scene.template.ads.AdPosterGroup;
	import game.scene.template.ads.AdSceneGroup;
	import game.scene.template.ads.AdTrackingParser;
	import game.scene.template.ads.AdVideoGroup;
	import game.scenes.americanGirl.AmericanGirlEvents;
	import game.scenes.carrot.processing.components.Dial;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class MainStreetKira extends PlatformerGameScene
	{
		public function MainStreetKira()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/americanGirl/mainStreetKira/";
			//allow pulling from server to avoid having to do a mobile release just for art/data changes.
			super.fetchFromServer = true;
			//AdManager(shellApi.adManager).interiorAd = shellApi.adManager.getAdData(shellApi.adManager.mainStreetType,true,false);
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			var vXML:XML = super.getData("tracking.xml", false);
			
			trackingData = AdTrackingParser.parse(vXML);
		}
		private function npcClicked(clickedEntity:Entity):void
		{
			// if scene has tracking data
			if (trackingData != null)
			{
				var id:String = clickedEntity.get(Id).id;
				var vNode:Object = trackingData[id];
				// if node found then track
				if (vNode != null)
					shellApi.adManager.track("AmericanGirlQuest", vNode.event, vNode.choice, vNode.subchoice);
			}
		}
		
		override protected function allCharactersLoaded():void
		{
			// get all NPCs
			var npcNodes:NodeList = super.systemManager.getNodeList(NpcNode);
			// if scene has tracking data
			if (trackingData != null)
			{
				// for each npc
				for( var node:NpcNode = npcNodes.head; node; node = node.next )
				{
					var npcEntity:Entity = node.entity;
					// add click action
					npcEntity.get(Interaction).click.add(npcClicked);
					
					
					
					// impression tracking if setup in xml
					var id:String  = npcEntity.get(Id).id;
					var vNode:Object = trackingData[id];
					// if node found then track
					if (vNode != null)
					{
						if (vNode.triggerImpression == "true")
						{
							shellApi.adManager.track("AmericanGirlQuest", AdTrackingConstants.TRACKING_NPC_IMPRESSION, npcEntity.get(Id).id);
						}
					}
				}
			}
			
			super.allCharactersLoaded();
			
			// sort bitmapped npcs so they are placed behind player
			AdSceneGroup.sortBitmapNPCs(super.systemManager.getNodeList(NpcNode), super.shellApi.player);
		}
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = super.events as AmericanGirlEvents;
			
			shellApi.adManager.track("AmericanGirlIsland", "AmericanGirlMainStreetLoaded");
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			var vXML:XML = super.getData("tracking.xml", false);
			
			trackingData = AdTrackingParser.parse(vXML);
			vXML = super.getData("hotspots.xml", false);
			var vHotSpotsData:Object = AdHotSpotParser.parse(vXML);
			
			
			// ad any poster
			var adData:Object = new Object();
			adData.campaign_name = "AmericanGirlQuest";
			
			var posterGroup:AdPosterGroup = new AdPosterGroup(null, shellApi);
			posterGroup.setupAdScene(this, _hitContainer, adData, vHotSpotsData, trackingData);
			
			if(shellApi.forcedAdData != null)
			{
				if(shellApi.forcedAdData.campaign_name == "AmericanGirlQuest")
				{
					trace("MainStreet (AG) : loaded - have AG forced data");
					adData = shellApi.forcedAdData;
					
				}
			}
			else
			{
				trace("MainStreet (AG) : loaded - getting ad data for AmericanGirl island");
				var temp:AdData = shellApi.adManager.getAdData(shellApi.adManager.mainStreetType,false,false,"AmericanGirl");
				adData = temp;
				shellApi.forcedAdData = temp;
			}
			
			if(adData != null)
			{
				trace("MainStreet (AG) : loaded - got ad data for AmericanGirl island");
				//shellApi.forcedAdData = shellApi.adManager.getAdData(shellApi.adManager.mainStreetType,false,false,"AmericanGirl");
				var videoGroup:AdVideoGroup = new AdVideoGroup();
				videoGroup.setupAdScene(this, _hitContainer, adData, vHotSpotsData, trackingData);
				
			}
			
			
			// sort bitmapped npcs so they are placed behind player
			AdSceneGroup.sortBitmapNPCs(super.systemManager.getNodeList(NpcNode), super.shellApi.player);
		}
		
		override protected function addGroups():void
		{
			super.addGroups();
			var vXML:XML = super.getData("tracking.xml", false);
			
			trackingData = AdTrackingParser.parse(vXML);
		}
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private var _events:AmericanGirlEvents;
		private var trackingData:Object;
	}
}

