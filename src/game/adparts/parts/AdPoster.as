package game.adparts.parts
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.ar.ArPopup.ArPopup;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.ParamData;
	import game.data.ParamList;
	import game.data.TimedEvent;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.specialAbility.SpecialAbilityData;
	import game.managers.HouseVideos;
	import game.managers.ads.AdManager;
	import game.photoBooth.PhotoBooth;
	import game.scene.template.ui.CardGroup;
	import game.ui.popup.Popup;
	import game.ui.showItem.ShowItem;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	public class AdPoster extends Component
	{
		private var _posterID:String;
		// reference to scene so that we can call shellApi functions
		private var _group:DisplayGroup;
		private var _adManager:AdManager;
		private var _hitContainer:DisplayObjectContainer;
		// tracking variables
		private var _campaignName:String = "No Campaign";
		private var _event:String = "";
		private var _choice:String = "Poster";
		private var _subChoice:String = "";
		private var _clickURL:String;
		private var _impressionURL:String;
		// card variables
		private var _giveItemMale:String;
		private var _giveItemFemale:String;
		private var _cards:Array;
		private var _cardCount:int;
		// quest and photobooth variables
		private var _enterQuest:String;
		private var _enterPhotoBooth:Boolean = false;
		private var _trigger:String;
		// popup variables
		private var _popupSwf:String;
		private var _className:String;
		private var _param1:String;
		private var _suppressSponsorClick:Boolean;
		private var _autoOpenPopup:Boolean = false;
		private var _autoOpenPopupSaveToggleButtons:Boolean;
		private var _autoOpenPopupTrackToggleButtons:Boolean;
		// timeline variables
		private var _gotoAndPlayTimeline:Timeline;
		private var _gotoAndPlayFrame:String;
		private var _gotoAndStopTimeline:Timeline;
		private var _gotoAndStopFrame:String;
		private var _autoPlay:Boolean;
		// game vars
		private var _gameClass:String;
		private var _gameID:String;
		// special ability
		private var _specialAbility:SpecialAbilityData;
		
		private const CARD_PREFIX:String = "hasAdItem_";
		
		private const PHOTO_BOOTH_SUFFIX:String = "Interior/photobooth.xml";
		private const AR_SUFFIX:String = "Interior/ar.xml";
		
		/**
		 * Constructor 
		 * @param posterData
		 * @param group
		 * @param hitContainer
		 */
		public function AdPoster(posterData:Object, group:DisplayGroup, hitContainer:DisplayObjectContainer):void
		{
			_group = group;
			_hitContainer = hitContainer;
			
			// get variables
			_posterID = posterData.posterID;
			if (posterData.campaign_name)
				_campaignName = posterData.campaign_name;
			if (posterData.event)
				_event = posterData.event;
			// force choice to "Posters"
			//if (posterData.choice)
			//_choice = posterData.choice;
			if (posterData.subchoice)
				_subChoice = posterData.subchoice;
			if (posterData.clickURL)
				_clickURL = posterData.clickURL;
			// third-party tracking (use "impressionOnClick" in xml)
			if (posterData.impressionURL)
				_impressionURL = posterData.impressionURL;
			if (posterData.giveItemMale)
				_giveItemMale = posterData.giveItemMale;
			if (posterData.giveItemFemale)
				_giveItemFemale = posterData.giveItemFemale;
			if (posterData.enterQuest)
				_enterQuest = posterData.enterQuest;
			if (posterData.enterPhotoBooth)
				_enterPhotoBooth = posterData.enterPhotoBooth;
			if (posterData.popupSwf)
				_popupSwf = posterData.popupSwf;
			if (posterData.trigger)
				_trigger = posterData.trigger;
			if (posterData.className)
				_className = posterData.className;
			if (posterData.param1)
				_param1 = posterData.param1;
			if (posterData.suppressSponsorClick )
				_suppressSponsorClick = posterData.suppressSponsorClick;
			if (posterData.autoOpenPopupSaveToggleButtons )
				_autoOpenPopupSaveToggleButtons = posterData.autoOpenPopupSaveToggleButtons;
			if (posterData.autoOpenPopupTrackToggleButtons )
				_autoOpenPopupTrackToggleButtons = posterData.autoOpenPopupTrackToggleButtons;
			if (posterData.specialAbility)
				_specialAbility = posterData.specialAbility;
			_gameClass = posterData.gameClass;
			_gameID = posterData.gameID;
			
			_adManager = AdManager(_group.shellApi.adManager);
			trace("AdPoster: campaign: " + _campaignName);
			// animation that plays frame when clicked: clipName, frameName (don't use numbers but names)
			if (posterData.gotoAndPlay)
			{
				// get clip name and frame name
				var arr:Array = posterData.gotoAndPlay.split(",");
				_gotoAndPlayFrame = arr[1];
				// get clip and convert to timeline and stop on frame 1 if found
				var clip:MovieClip = hitContainer[arr[0]];
				if (clip)
				{
					_gotoAndPlayTimeline = TimelineUtils.convertClip(clip, group).get(Timeline);
					_gotoAndPlayTimeline.gotoAndStop(0);
					_gotoAndPlayTimeline.labelReached.add(_group.shellApi.triggerEvent);
				}
			}
			if (posterData.autoPlay)
			{
				
				// get clip and convert to timeline and stop on frame 1 if found
				var clip2:MovieClip = hitContainer[posterData.autoPlay];
				if (clip2)
				{
					var playTimeline:Timeline = TimelineUtils.convertClip(clip2, group).get(Timeline);
					playTimeline.gotoAndPlay(0);
				}
			}
			
			// animation that jumps to frame when clicked: clipName, frameName (don't use numbers but names)
			if (posterData.gotoAndStop)
			{
				// get clip name and frame name
				arr = posterData.gotoAndStop.split(",");
				_gotoAndStopFrame = arr[1];
				// get clip and convert to timeline and stop on frame 1 if found
				clip = hitContainer[arr[0]];
				if (clip)
				{
					_gotoAndStopTimeline = TimelineUtils.convertClip(clip, group).get(Timeline);
					_gotoAndStopTimeline.gotoAndStop(0);
				}
			}
			
			// only store popup class and file names for auto-open after awarding cards if both are present
			if ((posterData.autoOpenPopupClass) && (posterData.autoOpenPopupFile)) 
			{
				_autoOpenPopup = true;
				_className = posterData.autoOpenPopupClass;
				_popupSwf = posterData.autoOpenPopupFile;
				// if different URL for popup, then use that
				if ( posterData.autoOpenPopupClickURL )
					_clickURL = posterData.autoOpenPopupClickURL;	
			}
			
			// determine item cards, if any
			// if female
			if (_group.shellApi.profileManager.active.gender == SkinUtils.GENDER_FEMALE)
			{
				if (_giveItemFemale)
					_cards = _giveItemFemale.split(",");
			}
			else 
			{
				// if male or anything else
				if (_giveItemMale)
					_cards = _giveItemMale.split(",");
			}
			trace("AdPoster: cards to be awarded: " + _cards);
			
			// sandbox survey stuff
			/*
			if (posterData.param1 == "SandboxSurvey")
			{
			var bits:Number = 0;
			// get membership status
			var status:uint = _group.shellApi.profileManager.active.memberStatus.statusCode;
			if (status == MembershipStatus.MEMBERSHIP_ACTIVE || status == MembershipStatus.MEMBERSHIP_EXTENDED)
			bits = 2;
			// get gender
			var gender:String = _group.shellApi.profileManager.active.gender;
			if (gender == "male")
			bits++;
			_clickURL += String(bits);
			}
			*/
			
			// check if cards already awarded on scene load
			_group.shellApi.sceneManager.sceneLoaded.add(checkCards);
			trace("AdPoster: end");
		}
		
		/**
		 * Check if any cards have been awarded already
		 * This needs to happen when scene loaded or else the events get cleared
		 * @param scene
		 */
		private function checkCards(scene:Group):void
		{
			trace("AdPoster: checkCards : start");
			if (_cards)
			{
				trace("AdPoster: checkCards : cards found");
				// for each card
				for (var i:int = _cards.length-1; i != -1; i--)
				{
					// get card ID
					var cardID:String = _cards[i];
					// remove initial space, if any
					if (cardID.substr(0,1) == " ")
						cardID = cardID.substr(1);
					
					// if has card, then trigger event and remove from array
					if (_group.shellApi.checkHasItem(cardID, CardGroup.CUSTOM))
					{
						trace("AdPoster: has card " + cardID);
						_group.shellApi.triggerEvent(CARD_PREFIX + cardID);
						_cards.splice(i,1);
					}
				}
			}
			trace("AdPoster: checkCards : end");
		}
		
		/**
		 * Click poster
		 * @param id ID of button clicked
		 */
		public function clickPoster(id:String):void
		{
			// if houseVideos
			if (id == "houseVideos")
			{
				var videos:HouseVideos = new HouseVideos(_group.shellApi.sceneManager.currentScene, "PlaywireMSVideos");
				videos.playVideos();
				return;
			}
			
			// interact with campaign and check for branding
			AdUtils.interactWithCampaign(_group, _campaignName);
			
			// trigger special ability
			if (_specialAbility != null)
				CharUtils.addSpecialAbility(_group.shellApi.player, _specialAbility, true);
			
			// if entering quest, then load start popup (useful for interiors only)
			if (_enterQuest) {
				if (_group.hasOwnProperty('loadGamePopup')) {
					_group['loadGamePopup']("AdStartQuestPopup", _enterQuest);
				}
			}
			
			if (_trigger)
				_group.shellApi.triggerEvent(_trigger);
			
			// if cards to award
			var awardCard:Boolean = false;
			if ((_cards) && (_cards.length != 0))
			{
				trace("AdPoster: awarding cards: " + _cards);
				awardCard = true;
				// set card count
				_cardCount = _cards.length;
				// lock input
				SceneUtil.lockInput(_group, true);
				
				// hide if prize ID used
				if (_posterID.indexOf("prize") != -1)
				{
					var posterEntity:Entity = _group.getEntityById(_posterID);
					// hide hotspot
					posterEntity.get(Display).visible = false;
					// hide tooltip
					ToolTipCreator.removeFromEntity(posterEntity);
					// hide prize clip in scene if exists
					if (_hitContainer[_posterID + "clip"] != null)
						_hitContainer[_posterID + "clip"].visible = false;
				}
				
				// start awarding cards
				awardCards();
			}
			
			// if opening popup event, then open popup
			if (_event == AdTrackingConstants.TRACKING_OPENED_POPUP)
				openPopup();
			
			// if playing timeline, then play frame
			if ((_gotoAndPlayTimeline) && (_gotoAndPlayFrame))
				_gotoAndPlayTimeline.gotoAndPlay(_gotoAndPlayFrame);
			
			// if stopping on timeline, then jump frame
			if ((_gotoAndStopTimeline) && (_gotoAndStopFrame))
				_gotoAndStopTimeline.gotoAndStop(_gotoAndStopFrame);
			
			// if not awarding cards, then trigger URL and/or auto-open popup
			if (!awardCard)
				postCardAwarding();
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
				trace("AdPoster: awarding card " + cardID);
				_group.shellApi.getItem(cardID, CardGroup.CUSTOM, true);
				_group.shellApi.triggerEvent(CARD_PREFIX + cardID);
				
				// setup timer for next card
				var timedEvent:TimedEvent = new TimedEvent(0.25, 1, awardCards);
				SceneUtil.addTimedEvent(_group, timedEvent);
				
				// when card animation done
				ShowItem(_group.getGroupById("showItemGroup")).transitionComplete.addOnce(gotCard);
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
				// go to sponsor site and/or open popup
				postCardAwarding();
			}
		}
		
		/**
		 * When card awarding is done or if there are no cards to award 
		 */
		private function postCardAwarding():void
		{
			if (_enterPhotoBooth)
			{
				trace("PhotoBoothScene: found campaign: " + _campaignName);
				var suffix:String = _campaignName.indexOf("PhotoBooth") == -1?AR_SUFFIX:PHOTO_BOOTH_SUFFIX;
				// point to photobooth xml in campaign interior folder
				var path:String = _group.shellApi.dataPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + _campaignName + suffix;
				if(suffix == AR_SUFFIX)
					_group.addChildGroup(new ArPopup(Scene(_group).overlayContainer, path, _campaignName));
				else
					_group.addChildGroup(new PhotoBooth(Scene(_group).overlayContainer, path, _campaignName));
				
				//PhotoBoothGroup.enterPhotoBooth(_campaignName, _group.shellApi);
			}
				// if click url provided and not suppressing, then go to sponsor site
			else if ((_clickURL) && (!_suppressSponsorClick ))
				AdManager.visitSponsorSite(_group.shellApi, _campaignName, triggerSponsorSite,null,null,_clickURL);
			
			// if auto-opening popup, then open popup
			if (_autoOpenPopup)
			{
				openPopup();
			}
			else if (_trigger != null)
			{	
				if(_trigger.indexOf("selectArcadeGame") == -1)
				{
					//else restore input if not going to arcade game
					SceneUtil.lockInput(_group, false);
				}
			}
			else
				SceneUtil.lockInput(_group, false);
		}
		
		/**
		 * Open sponsor site (called after delay on mobile) 
		 */
		private function triggerSponsorSite():void
		{
			// tracking (choice is "Posters")
			_adManager.track(_campaignName, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _subChoice);
			// open sponsor URL
			AdUtils.openSponsorURL(_group.shellApi, _clickURL, _campaignName, _choice, _subChoice);
			// send tracking pixels
			AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, _impressionURL);
		}
		
		/**
		 * Open popup 
		 */
		private function openPopup():void
		{
			// if this is a wishlist popup, immediately lock input and pause game
			if ( _className == "game.scenes.custom.WishlistPopup" )
			{
				SceneUtil.lockInput(_group, true);
				_group.pause(false);
			}
			else 
			{
				// else restore input
				SceneUtil.lockInput(_group, false);
			}
			
			// tracking calls
			// if event is TRACKING_OPENED_POPUP
			if (_event == AdTrackingConstants.TRACKING_OPENED_POPUP)
			{
				_adManager.track(_campaignName, _event, _choice, _subChoice);
			}
			else
			{
				// if event is ClickToSponsor, then use this tracking
				_adManager.track(_campaignName, AdTrackingConstants.TRACKING_OPENED_POPUP_FROM_MAINSTREET);
			}
			
			// try to get class, if found
			var popupClass:Class = ClassUtils.getClassByName(_className);
			if(!popupClass)
			{
				trace( "Error :: AdPoster : " + _className + " is not a valid class name." );
				return;
			}
			
			// create popup and add to scene
			var popup:Popup = _group.shellApi.sceneManager.currentScene.addChildGroup(new popupClass()) as Popup;
			
			// pass params (just have one for now)
			var paramList:ParamList = new ParamList();
			if (_param1 != null)
			{
				var paramData:ParamData = new ParamData();
				paramData.id = "param1";
				paramData.value = _param1;
				paramList.push(paramData);
			}
			popup.setParams(paramList);
			
			// pass campaign data along to popup in case it's needed
			popup.campaignData = _group.shellApi.adManager.getActiveCampaign(_campaignName);
			if (popup.campaignData != null)
			{
				trace("AdPoster: game class: " + _gameClass);
				trace("AdPoster: game ID: " + _gameID);
				popup.campaignData.gameClass = _gameClass;
				popup.campaignData.gameID = _gameID;
			}
			else
			{
				trace("AdPoster: campaign data not found");
			}
			
			// RLH: doesn't seem to be used
			/*
			if (_clickURL != null)
			{
			// add click URL to param list
			paramList = new ParamList();
			paramData = new ParamData();
			paramData.id = "clickURL";
			paramData.value = _clickURL;
			paramList.push(paramData);
			
			// if auto open popup, add click URL with url1 ID to param list
			if ( _autoOpenPopup )
			{
			paramData.id = "url1";
			paramData.value = _clickURL;
			paramList.push(paramData);
			}
			}
			*/
			
			// add swf path to popup
			popup.data.swfPath = _popupSwf;
			
			// add other data to popup
			if ( _autoOpenPopupSaveToggleButtons )
				popup.data.saveToggleButtons = true;
			if ( _autoOpenPopupTrackToggleButtons )
				popup.data.trackToggleButtons = true;
			
			// initialize popup
			popup.init( _group.shellApi.sceneManager.currentScene.overlayContainer );
		}
	}
}