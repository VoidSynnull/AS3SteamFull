package game.scene.template
{
	import com.poptropica.AppConfig;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.data.ads.AdCampaignType;
	import game.data.scene.DoorData;
	import game.managers.ads.AdManager;
	import game.nodes.scene.DoorNode;
	import game.systems.SystemPriorities;
	import game.systems.scene.DoorSystemPop;
	import game.systems.scene.browser.DoorSystemBrowser;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	
	public class DoorGroupPop extends DoorGroup
	{
		override protected function addSystems( scene:Scene ):void
		{
			// Doors have to handle movement to AS2, would like to move this into a proxy class though. - bard
			if( PlatformUtils.inBrowser )
			{
				scene.addSystem(new DoorSystemBrowser(), SystemPriorities.lowest);	
			}
			else
			{
				scene.addSystem(new DoorSystemPop(), SystemPriorities.lowest);	
			}
		}
		
		/**
		 * Removes the connecting scenes if we want to connect directly to the next island scene.  This is needed when no billboards are available so we don't load an empty billboard ad scene.
		 */
		override public function removeConnectingSceneDoors():void
		{
			// disable skipping of scenes
			return;
			/*
			var nodes:NodeList = systemManager.getNodeList(DoorNode);
			var node:DoorNode;
			var doorData:DoorData;
			var connectingDoorData:DoorData;
			
			var hasBillboard:Boolean = false;
			var hasMainStreetBillboard:Boolean = false;
			var hasMainStreetAd:Boolean = false;
			
			// if ads active and not interior
			var adManager:AdManager = super.shellApi.adManager as AdManager;
			if ( AppConfig.adsActive )
			{
				if( !adManager.isInterior )
				{
					//hasBillboard = adManager.hasBillboard();
					//hasMainStreetBillboard = adManager.hasMainStreetBillboard();
					hasMainStreetAd = adManager.hasMainStreetAd();
					trace("DoorGroupPop :: check connecting doors: hasBillboard: " + hasBillboard + ", hasMainStreetBillboard: " + hasMainStreetBillboard + ", hasMainStreetAd: " + hasMainStreetAd);
					// if no billboard and dead end billboard, then move door off screen
					var deadEndDoor:Entity = super.shellApi.sceneManager.currentScene.getEntityById("doorDeadEnd");
					//if((!hasBillboard) && (deadEndDoor))
					if((!hasMainStreetAd) && (deadEndDoor))
					{
						trace("DoorGroupPop :: remove dead end billboard door");
						deadEndDoor.get(Spatial).y += 10000;
					}
				}
			}
			
			for(node = nodes.head; node; node = node.next)
			{
				doorData = node.hit.data;
				
				if(doorData.connectingSceneDoors)
				{
					for each(connectingDoorData in doorData.connectingSceneDoors)
					{
						// if we don't have any ads, link the scene exit to the next island scene that is not equal to the current scene rather than the ad scene.
						if(connectingDoorData.destinationScene != ProxyUtils.convertSceneToStorageFormat(super.parent))
						{
							var skipScene:Boolean = true;
							
							// AD SPECIFIC
							if( AppConfig.adsActive )
							{
								// if forcing main street add on billboard scene
								if (adManager.forceMainStreetAdInBillboardScene)
								{
									trace("DoorGroupPop :: force main street ad on billboard");
									if (hasMainStreetAd)
										skipScene = false;
								}
								// if destination scene has AdMixed
								else if (doorData.destinationScene.indexOf(".AdMixed") != -1)
								{
									if ((hasMainStreetAd) || (hasMainStreetBillboard))
										skipScene = false;
								}
								// if standard ad
								else if (doorData.destinationScene.indexOf(".Ad") != -1)
								{
									if (hasBillboard)
										skipScene = false;
								}
							}
							
							if (skipScene)
							{
								trace("DoorGroupPop :: Skip Ad Scene: " + doorData.destinationScene);
								
								var adType:String;
								// if mixed scene, then default is main street
								if (doorData.destinationScene.indexOf(".AdMixed") != -1)
								{
									adType = AdCampaignType.MAIN_STREET;
								}
								else
								{
									// if billboard
									adType = AdCampaignType.BILLBOARD;
								}
								// all skippable scenes are swappable (both AdMixed and all billboards)
								doorData.skipAdType = adType + " Swappable";
								
								// if current scene doesn't have ad building then set destinationSceneOld
								// destinationSceneOld triggers interstitials
								if (!adManager.hasAdBuilding)
									doorData.destinationSceneOld = doorData.destinationScene;
								//doorData.destinationSceneXOld = doorData.destinationSceneX;
								//doorData.destinationSceneYOld = doorData.destinationSceneY;
								//doorData.destinationSceneDirectionOld = doorData.destinationSceneDirection;
								
								doorData.destinationScene = connectingDoorData.destinationScene;
								doorData.destinationSceneX = connectingDoorData.destinationSceneX;
								doorData.destinationSceneY = connectingDoorData.destinationSceneY;
								doorData.destinationSceneDirection = connectingDoorData.destinationSceneDirection;
							}
						}
					}
				}
				// if not connecting scene doors and not custom ad scene and current scene doesn't have an ad building
				else if ((doorData.destinationScene.indexOf(".custom.") == -1) && (!adManager.hasAdBuilding))
				{
					// set destinationSceneOld which triggers interstitials
					doorData.destinationSceneOld = doorData.destinationScene;
				}
			}
			*/
		}
	}
}