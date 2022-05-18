package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneParser;
	import game.managers.ads.AdManager;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBaseGroup;
	import game.scene.template.ui.CardGroup;
	import game.ui.showItem.ShowItem;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.utils.AdUtils;
	
	/**
	 * Vendor cart group within scenes
	 * @author VHOCKRI
	 */
	public class AdVendorCartGroup extends AdBaseGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function AdVendorCartGroup(container:DisplayObjectContainer=null, adManager:AdManager = null)
		{
			super(container, adManager);
			this.id = GROUP_ID;
		}
		
		/**
		 * Prepare vendor cart group and check if vendor cart can be loaded
		 * @param scene
		 * @return Boolean (true means ad group gets added to scene)
		 */
		override public function prepAdGroup(scene:PlatformerGameScene):Boolean
		{
			super.prepAdGroup(scene);
			shellApi.sceneManager.sceneLoaded.add(handleSceneLoaded);
			
			// if scene doesn't already have vendor cart group
			if (_parentScene.getGroupById(GROUP_ID) == null)
			{
				// if data node has vendor_cart.xml
				if (String(_parentScene.sceneData.data).indexOf("vendor_cart.xml") != -1)
				{
					// ad inventory tracking (if scene supports vendor cart)
					_adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, _adManager.vendorCartType);
					
					// if ad type is supported (browser or mobile vendor cart)
					if (_adManager.adTypes.indexOf(_adManager.vendorCartType) != -1)
					{
						// check if vendor cart is on this island
						_adData = _adManager.getAdData(_adManager.vendorCartType, false, true);
						// if vendor cart found in CMS data, then load it
						if (_adData != null)
						{
							// load xml for vendor cart on island scene
							shellApi.loadFile(shellApi.dataPrefix + _parentScene.groupPrefix + "vendor_cart/" + GameScene.SCENE_FILE_NAME, sceneXMLLoaded);
							return true;
						}
					}
				}
			}
			// if vendor cart not found, then return false for no ad
			trace("AdVendorCart :: no vendor cart to display");
			return false;
		}

		/**
		 * When vendor cart scene xml is loaded 
		 * @param sceneXML
		 */
		override protected function sceneXMLLoaded(sceneXML:XML):Boolean
		{
			// if success
			if (super.sceneXMLLoaded(sceneXML))
			{
				// impression tracking		
				_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, _adData.campaign_type);

				// parse scene xml and get layer data
				var parser:SceneParser = new SceneParser();
				_sceneData = parser.parse(sceneXML, shellApi);
				_layerData = _sceneData.layers["vendorCart"][GameEvent.DEFAULT];
				
				// set final group prefix
				groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/" + _adData.campaign_name + "/";
				
				// load vendor cart swfs
				super.loadFiles(["interactive.swf", "background.swf"], false, true, mergeSceneFiles);
				return true;
			}
			else
			{
				// if failure
				// trigger completion with no ad
				this.groupReady();
				return false;
			}
		}

		/**
		 * Merge scene files when vendor cart swfs loaded 
		 */
		private function mergeSceneFiles():void
		{
			// offsets within scene
			this._offsetX = _layerData.offsetX;
			this._offsetY = _layerData.offsetY;
			
			// merge files into scene
			_parentScene.sceneDataManager.mergeSceneFiles(["interactive.swf", "background.swf"], groupPrefix, _parentScene.groupPrefix, mergeProcessor);
			
			// get cards
			var cardData:CampaignData = AdManager(shellApi.adManager).getActiveCampaign(_adData.campaign_name);
			// if card data found
			if (cardData)
			{
				// get girl/boy cards
				if (shellApi.profileManager.active.gender == SkinUtils.GENDER_MALE)
					_cards = cardData.boycards;
				else
					_cards = cardData.girlcards;
				
				// remove cards already awarded
				if (_cards != null)
				{
					for (var i:int = _cards.length-1; i!=-1; i--)
					{
						if (shellApi.checkHasItem(_cards[i], CardGroup.CUSTOM))
							_cards.splice(i,1);
					}
				}
			}

			// trigger completion
			this.groupReady();
		}
		
		private function handleSceneLoaded(scene:Group):void
		{
			// check for island door
			var door:Entity = _parentScene.getEntityById("islandDoor");
			if (door != null)
			{
				var doorInt:Interaction = door.get(Interaction);
				doorInt.click.add(islandDoorReached);
			}
		}
		
		private function islandDoorReached(door:Entity):void
		{			
			shellApi.adManager.track(door.get(Door).data.campaignName, AdTrackingConstants.TRACKING_DOOR_CLICKED);
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
				case "islandDoor":
					// now that we have merged doors.xml, check for custom door
					var doorXML:XML = Scene(super.parent).getData(GameScene.DOORS_FILE_NAME);	
					if(doorXML != null)
					{
						var campaignName:String = _adData.campaign_name;
						var index:int = campaignName.indexOf("Island");
						var scene:String = campaignName.substr(0,index).toLowerCase();
						var adData:AdData;
							adData = shellApi.adManager.getAdData(AdCampaignType.VENDOR_CART,false);
							if(adData != null)
							{
								if(adData.campaign_file2 != null)
									scene = _adData.campaign_file2;
							}
						var doorNode:XML = new XML('<door id="islandDoor" campaignName="' + campaignName + '"><scene>' + scene + '</scene><label><text>ENTER</text><type>exit3D</type><offset><x>0</x><y>0</y></offset></label></door>');
						doorXML.appendChild(doorNode);
					}
					break;
				case "questInteriorDoor":
					// now that we have merged doors.xml, check for custom door
					var questDoorXML:XML = Scene(super.parent).getData(GameScene.DOORS_FILE_NAME);	
					if(questDoorXML != null)
					{
						var questDoorNode:XML = new XML('<door id="questInteriorDoor"><scene>game.scenes.custom.questInterior.QuestInterior|campaignScene=' +_adData.campaign_file2 + '</scene><label><text>ENTER</text><type>exit3D</type><offset><x>0</x><y>0</y></offset></label></door>');
						questDoorXML.appendChild(questDoorNode);
					}
					break;
				// for hotspot clips
				case "poster":
				case "hotspot":
					
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
					ToolTipCreator.addToEntity(entity);
					
					// create interaction for clicking on vendor cart hotspot
					var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK], addedChild);
					interaction.click.add(doClick);
					break;
			}
		}

		/**
		 * When clicking on hotspot 
		 * @param clickedEntity
		 */
		private function doClick(clickedEntity:Entity):void
		{
			// tracking
			_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_VENDOR_CART_CLICKED);
			
			// if cards to award
			if ((_cards != null) && (_cards.length != 0))
			{
				trace(this," :: vendor cart awarding cards: " + _cards);
				// set card count
				_cardCount = _cards.length;
				// lock input
				SceneUtil.lockInput(_parentScene, true);
				// start awarding cards
				awardCards();
			}
			else
			{
				// if no cards to award, then go to sponsor URL
				trace(this," :: vendor cart clicked: " + _adData.clickURL);
				if(_adData.clickURL != null)
					navigateToURL(new URLRequest(_adData.clickURL), "_blank");
			}
		}
		
		/**
		 * Award cards (calls itself until done)
		 * @param e
		 */
		private function awardCards(e:Event = null):void
		{
			// do while there are cards
			if (_cards.length != 0)
			{
				// get card ID
				var cardID:String = _cards.shift();
				// remove initial space, if any
				if (cardID.substr(0,1) == " ")
					cardID = cardID.substr(1);
				// display card
				shellApi.getItem(cardID, CardGroup.CUSTOM, true);
				
				// setup timer for next card
				var timedEvent:TimedEvent = new TimedEvent(0.25, 1, awardCards);
				SceneUtil.addTimedEvent(_parentScene, timedEvent);
				
				// when card animation done
				ShowItem(_parentScene.getGroupById("showItemGroup")).transitionComplete.addOnce(gotCard);
			}
		}
		
		/**
		 * When card is awarded (when animation is done)
		 */
		private function gotCard():void
		{
			// decrement counter
			_cardCount--;
			// after last card awarded then unlock input and open URL
			if (_cardCount == 0)
			{
				SceneUtil.lockInput(_parentScene, false);
				if(_adData.clickURL != null)
					navigateToURL(new URLRequest(_adData.clickURL), "_blank");
			}
		}

		private var _fullPrefix:String;
		private var _layerData:CameraLayerData;
		private var _cards:Vector.<String>;
		private var _cardCount:int;
		
		public static const GROUP_ID:String = "VendorCartGroup";
	}
}