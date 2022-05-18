package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Id;
	import engine.group.DisplayGroup;
	
	import game.adparts.creators.AdPosterCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.specialAbility.SpecialAbilityData;
	import game.scene.template.ui.CardGroup;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.utils.AdUtils;
	
	public class AdPosterGroup extends DisplayGroup
	{
		// instance of AdPosterCreator
		private var _adPosterCreator:AdPosterCreator;
		// array of ad Poster entities in group
		private var _adPosterArray:Vector.<Entity> = new <Entity>[];
		
		/**
		 * Constructor 
		 * @param container
		 */
		public function AdPosterGroup(container:DisplayObjectContainer=null, shellApi:ShellApi = null)
		{
			super(container);
			this.id = "AdPosterGroup";
			super.shellApi = shellApi;
		}
		
		/**
		 * Destroy method 
		 */
		override public function destroy():void
		{
			//super.destroy(); // this caused a crash because container and group container are the same
			// clear creator object
			_adPosterCreator = null;
		}
		
		/**
		 * setup scene for ad Posters
		 * @param group Scene to add posters to
		 * @param interactiveClip
		 * @param adData	Campaign data object
		 * @param hotSpotsData	hotspots xml data object for scene
		 * @param trackingData	tracking xml data object for scene
		 */
		public function setupAdScene(group:DisplayGroup, interactiveClip:DisplayObjectContainer, adData:Object, hotSpotsData:Object, trackingData:Object):void
		{
			// this group should inherit properties of the group
			this.groupPrefix = group.groupPrefix;
			this.container = group.container;
			this.groupContainer = interactiveClip;
			
			// check if any poster clips by ID
			var vHasPoster:Boolean = false;
			// iterate through hot spots data
			for (var vID:String in hotSpotsData)
			{
				// get data object for ID
				var vData:Object = hotSpotsData[vID];
				
				// if date object type is poster, then process
				if (vData.type == "poster")
				{
					// get poster clip in interactive clip
					var vPosterClip:MovieClip = interactiveClip[vID];
					
					// if found poster
					if (vPosterClip)
					{
						// check if prize poster and suppress if card awarded
						if (checkPrizeAwarded(vID, vData) || DataUtils.getBoolean(vData.mobileOnly) && PlatformUtils.inBrowser)
						{
							// hide hot spot
							vPosterClip.visible = false;
							// hide prize clip in scene if exists
							if (interactiveClip[vID + "clip"] != null)
							{
								interactiveClip[vID + "clip"].visible = false;
							}
							// skip out and don't create entity
							continue;
						}
						
						// if first poster found, then add poster group to scene group
						if (!vHasPoster)
						{
							vHasPoster = true;
							// add it as a child group to give it access to systemManager.
							group.addChildGroup(this);
						}
						
						// if no poster creator, then create it
						if (_adPosterCreator == null)
							_adPosterCreator = new AdPosterCreator();
						
						// create poster data object and add properties
						var vPosterData:Object = {};
						vPosterData.campaign_name = adData.campaign_name;
						// if tracking data, then add those properties
						if (trackingData[vID])
						{
							var posterData:Object = trackingData[vID];
							vPosterData.event = posterData.event;
							vPosterData.choice = posterData.choice;
							vPosterData.subchoice = posterData.subchoice;

							// add poster impression if indicated in xml
							if (posterData.triggerImpression == "true")
							{
								super.shellApi.adManager.track(adData.campaign_name, AdTrackingConstants.TRACKING_POSTER_IMPRESSION, posterData.subchoice);
							}
						}
						else
						{
							trace("AdPosterGroup :: error: can't find tracking data for " + vID);
						}
						
						// if click URL provided
						if (vData.openUrlOnClick)
						{
							// if value is "clickURL" then pull from CMS data
							if (vData.openUrlOnClick == "clickURL")
							{
								vPosterData.clickURL = AdUtils.getCampaignValue(adData, "clickURL");
							}
							else{
								// else use the valid full URL from the hotspots xml file
								vPosterData.clickURL = vData.openUrlOnClick;
							}
						}
						
						// if impression URL is "impressionURL", then pull from CMS data
						if (vData.impressionOnClick == "impressionURL")
						{
							vPosterData.impressionURL = AdUtils.getCampaignValue(adData, "impressionURL");
						}
						else
						{
							// else use the valid full URL from the hotspots xml file
							vPosterData.impressionURL = vData.impressionOnClick;
						}
						
						// if enter quest, then set to true
						if (vData.enterQuest)
							vPosterData.enterQuest = vData.enterQuest;
						// if enter photo booth, then set to true
						if (vData.enterPhotoBooth)
						{
							vPosterData.enterPhotoBooth = vData.enterPhotoBooth;
							// allows a suffix to be appended so that a specific photobooth / ar experience can be loaded
							if(vData.suffix)
								vPosterData.campaign_name += vData.suffix;
						}
						
						// look for other nodes for poster
						vPosterData.giveItemMale = vData.giveItemMale;
						vPosterData.giveItemFemale = vData.giveItemFemale;
						vPosterData.popupSwf = vData.popup;
						vPosterData.className = vData.className;
						vPosterData.param1 = vData.param1;
						vPosterData.suppressSponsorClick = vData.suppressSponsorClick;
						vPosterData.autoOpenPopupClass = vData.autoOpenPopupClass;
						vPosterData.autoOpenPopupFile = vData.autoOpenPopupFile;
						vPosterData.autoOpenPopupSaveToggleButtons = vData.autoOpenPopupSaveToggleButtons;
						vPosterData.autoOpenPopupTrackToggleButtons = vData.autoOpenPopupTrackToggleButtons;
						vPosterData.autoOpenPopupClickURL = vData.autoOpenPopupClickURL;
						vPosterData.gotoAndPlay = vData.gotoAndPlay;
						vPosterData.gotoAndStop = vData.gotoAndStop;
						vPosterData.autoPlay = vData.autoPlay;
						vPosterData.gameClass = vData.gameClass;
						vPosterData.gameID = vData.gameID;
						vPosterData.posterID = vID;
						vPosterData.trigger = vData.trigger;
						
						// special ability data
						if (vData.specialAbilityClass != null)
						{
							var className:String = vData.specialAbilityClass;
							var array:Array = className.split(".");
							var myClass:Class = ClassUtils.getClassByName(className);
							var mySAData:SpecialAbilityData = new SpecialAbilityData(myClass);
							mySAData.id = array[array.length - 1];
							mySAData.triggerable = false;
							for (var i:int = 1; i != 8; i++)
							{
								var param:String = vData["specialAbilityParam" + i];
								if (param == null)
									break;
								else
								{
									array = param.split("=");
									mySAData.params.addParam(array[0], array[1]);
								}
									
							}
							vPosterData.specialAbility = mySAData;
						}
						
						// create poster entity
						var poster:Entity = _adPosterCreator.create(group, vPosterClip, vPosterData, interactiveClip);
						// add ID
						poster.add(new Id(vID));
					}
					else
					{
						trace("AdPosterGroup :: error: Can't find poster for id " + vID);
					}
				}
			}
		}
		
		// check if poster hotspot is a prize hot spot
		// only works if one prize per hotspot
		private function checkPrizeAwarded(vID:String, vData:Object):Boolean
		{
			// if id has prize in name
			if (vID.indexOf("prize") != -1)
			{
				// get prize cards for gender
				var prizes:Array;
				if (super.shellApi.profileManager.active.gender == SkinUtils.GENDER_MALE)
				{
					if (vData.giveItemMale != null)
						prizes = vData.giveItemMale.split(",");
				}
				else
				{
					if (vData.giveItemFemale != null)
						prizes = vData.giveItemFemale.split(",");
				}
				// if prizes supplied, then check if all awarded
				if ((prizes != null) && (prizes.length != 0))
				{
					var gotAllCards:Boolean = true;
					for each (var cardID:String in prizes)
					{
						// if not awarded
						if (!super.shellApi.checkHasItem(cardID, CardGroup.CUSTOM))
						{
							gotAllCards = false;
						}
					}
					return gotAllCards;
				}
			}
			return false;
		}
	}
}