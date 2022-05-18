package game.adparts.parts
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.AudioSystem;
	
	import game.adparts.parts.vpaid.VPAIDEvent;
	import game.adparts.parts.vpaid.VPAIDWrapper;
	import game.components.timeline.Timeline;
	import game.data.ParamData;
	import game.data.ParamList;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.CampaignData;
	import game.managers.ads.AdManager;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.AdSceneGroup;
	import game.scene.template.ui.CardGroup;
	import game.scenes.custom.AdStartGamePopup;
	import game.scenes.custom.BlimpVideoPopup;
	import game.ui.popup.Popup;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.utils.AdUtils;
	
	public class AdVideo extends Component
	{
		// status string can be: "start", "playing", "done", "paused", "end", "replay"... and also "disposed" (used in VPAID ads only)
		public var pStatus:String = "";
		//reference to group so that we can call shellApi functions
		private var _group:Group;
		// video container movieclip and timeline
		private var _container:MovieClip;
		private var _timeline:Timeline;
		private var _fsVideo:AdFullScreenVideo;
		// streaming variables
		private var _connection:NetConnection;
		private var _stream:NetStream;
		private var _videoPlayer:Video;
		private var _videoClip:DisplayObject;
		private var _videoUI:MovieClip;
		// video variables
		private var _videoWidth:int = 300;
		private var _videoHeight:int = 170;
		private var _videoFile:String; // path to video file string
		private var _videoFiles:Array; // array video files
		private var _videoDuration:int; // length of video, currently only used by VAST tracking
		private var _giveItemMale:Array;
		private var _giveItemFemale:Array;
		private var _videoNumber:int;
		// tracking variables
		private var _campaignName:String = "No Campaign";
		private var _choice:String = "Video";
		private var _clickURL:String = "";
		// third-party tracking (use "impressionOnClick" in xml)
		private var _impressionURL:String;
		
		private var _audioSystem:AudioSystem;
		
		private var _hasSequentialVideos:Boolean = false;
		private var _replay:Boolean = false;
		private var _hasSeenVideo:Boolean = false;
		private var _locked:Boolean = true;
		private var _controls:Boolean = false;
		private var _progressBar:MovieClip;
		private var _firstGameButton:Entity;
		private var _fullscreen:Boolean = false;
		private var _miniGameMVU:Boolean = false;
		private var _gameData:String;
		private var _gameID:String;
		private var _gameClass:String;
		private var _cardList:Vector.<String>;
		private var _popupScene:Boolean;

		// vast variables
		
		// set when VAST is detected in the file2 parameter (represented by starting with "VAST=")
		private var _vastEnabled:Boolean;
		// set when VAST tag has been loaded and parsed; prevents video from being set up until media location is pulled from VAST tag
		private var _vastReady:Boolean;
		// set when VAST-enabled video is being replayed; forces re-load and re-parse of VAST tag
		private var _vastReset:Boolean;
		// set when VAST-enabled video has already been viewed (used to fire the correct tracking event on replay)
		private var _vastReplay:Boolean;
		// VAST tag URL
		private var _vastTagURL:String;
		// used to keep track of progress during video for progress reporting events
		private var _vastNextProgressEvent:int;
		// set when video should immediately pay after VAST load
		private var _vastAutoPlay:Boolean;
		// entity that will be clicked once autoplay occurs
		private var _vastAutoPlayClickEntity:Entity;
		
		// current VAST XML data
		private var _vastXML:XML;
		// VAST XML loader
		private var _vastXMLLoader:URLLoader;
		
		// VAST tracking links
		private var _vastVideoImpressionURLs:Array;
		private var _vastTrackVideoStartURLs:Array;
		private var _vastTrackVideoFirstQuartileURLs:Array;
		private var _vastTrackVideoMidpointURLs:Array;
		private var _vastTrackVideoThirdQuartileURLs:Array;
		private var _vastTrackVideoCompleteURLs:Array;
		private var _vastVideoClickTrackingURLs:Array;
		
		// VAST click-through URL
		private var _vastVideoClickThroughURL:String;
		
		// VPAID variables
		
		// set when VPAID is detected in the file2 parameter (represented by starting with "VPAID=")
		private var _VPAIDEnabled:Boolean;
		// VPAID tag URL
		private var _VPAIDTagURL:String;
		// VPAID tag URL after replacing timestamp for cache-busting
		private var _VPAIDFilteredTagURL:String;
		// container for VPAID ad
		private var _VPAIDContainer:MovieClip;
		// XML from VPAID tag
		private var _VPAIDTagXML:XML;
		// VPAID tag URLRequest of location
		private var _VPAIDTagURLRequest:URLRequest;
		// loader for VPAID tag url
		private var _VPAIDTagLoader:URLLoader;
		// url of VPAID ad, extracted from tag
		private var _VPAIDAdUrl:String;
		// loads VPAID ad swf
		private var _VPAIDLoader:Loader;
		// URLRequest for VPAID ad swf URL
		private var _VPAIDUrl:URLRequest;
		// wrapper class that holds VPAID ad
		private var _VPAIDAdWrapper:VPAIDWrapper;
		// clip used to indicate to the user that the VPAID ad is loading
		private var _VPAIDLoadingClip:MovieClip;
		// flag to signal when video needs to be paused on play
		private var _VPAIDPauseOnPlay:Boolean;
		
		// blimp video popup
		private var _isBlimpPopup:Boolean = false;
		private var _blimpPopup:BlimpVideoPopup;
		
		private var _isCarouselVideo:Boolean = false;
		
		private const CARD_PREFIX:String = "hasAdItem_";
		private var _card:String;
		private var _card2:String;
		private var singleContainer:Boolean = true;
		
		//awarding credits
		private var _awardCredits:Number = 0;
		
		/**
		 * Contstructor
		 * @param	entity	 		video timeline entity
		 * @param	container		video container
		 * @param	videoData		Object that contains all video data
		 * @param	scene
		 */
		public function AdVideo(entity:Entity, container:MovieClip, videoData:Object, group:Group):void
		{
			// video container and timeline and scene
			_container = container;
			// if container is named "videoContainer" or "blimpVideoContainer" then assume a single container
			if (container.name == "videoContainer")
			{
				singleContainer = true;
			}
			else if (container.name == "carouselVideoContainer")
			{
				singleContainer = true;
				_isCarouselVideo = true;
			}
			else if (container.name == "blimpVideoContainer")
			{
				singleContainer = true;
				_isBlimpPopup = true;
			}
			// get timeline (errors if only one frame)
			if (entity)
				_timeline = entity.get(Timeline);
			
			_group = group;
			_vastEnabled = _VPAIDEnabled = false;
			
			// setup progress bar
			_progressBar = container.progressBar;
			if (_progressBar != null)
			{
				_progressBar.visible = false;
				_progressBar.bar.width = 0;
			}
			
			// get variables
			_locked = videoData.locked;
			_controls = videoData.controls;
			if (videoData.width != null)
				_videoWidth = int(videoData.width);
			if (videoData.height != null)
				_videoHeight = int(videoData.height);
			if (videoData.videoFile != null)
			{
				// use VAST
				if ( videoData.videoFile.indexOf("VAST=") == 0 )
				{
					// set up VAST-related variables
					_vastEnabled = true;
					_vastReady = false;
					_vastReset = false;
					_vastReplay = false;
					_vastAutoPlay = false;
					
					// parse out VAST tag location
					_vastTagURL = videoData.videoFile.substr(5);
					
					// continue with VAST setup
					setupVAST();
				}
				if ( videoData.videoFile.indexOf("VPAID=") == 0 )
				{
					// mark that ad is a VPAID ad; extract the actual VPAID tag URL
					_VPAIDEnabled = true;
					_VPAIDPauseOnPlay = false;
					_VPAIDTagURL = videoData.videoFile.substr(6);
				}
				else
				{
					// just a standard video
					_videoFiles = videoData.videoFile.split(",");
				}
			}
			if (videoData.campaign_name != null)
				_campaignName = videoData.campaign_name;
			if (videoData.clickURL != null)
				_clickURL = videoData.clickURL;
			if (videoData.awardCredits != null) {
				trace(videoData.awardCredits);
				_awardCredits = int(videoData.awardCredits);
			}
			if (videoData.impressionURL != null)
				_impressionURL = videoData.impressionURL;
			
			// setup end screen text for sequential videos
			if (videoData.endScreensText)
			{
				var list:Array = videoData.endScreensText.split(",");
				for (var k:int = 0; k!= list.length; k++)
				{
					var screen:MovieClip = _container["endScreen" + (k+1)];
					if (screen)
					{
						screen.videoText.htmlText = list[k] + "<br />will play<br />next";
					}
				}
			}
			//if (videoData.choice != null)
			//_choice = videoData.choice;
			//if (videoData.subchoice != null)
			//_subChoice = videoData.subchoice;
			if (videoData.giveItemMale != null)
				_giveItemMale = videoData.giveItemMale.split(",");
			if (videoData.giveItemFemale != null)
				_giveItemFemale = videoData.giveItemFemale.split(",");
			
			// get game data, if any
			_gameData = videoData.game;
			if (_gameData != null)
			{
				// game data has form "gameID|gameClass"
				// framework will look for popup with name "[GameID]Start.swf"
				// gameClass is the class to load for the popup mini-game named [gameID].swf which loads [gameID.xml]
				var gameData:Array = _gameData.split("|");
				_gameID = gameData[0];
				_gameClass = gameData[1];
				_popupScene = gameData[2];
			}
					
			// if fullscreen is designated in hotspots.xml then it is a mini-game MVU
			_miniGameMVU = videoData.fullscreen;
			// always play fullscreen now
			//if ((PlatformUtils.isMobileOS) || (_miniGameMVU))
			{
				_fullscreen = true;
				_fsVideo = new AdFullScreenVideo(group, AppConfig.mobile, notifyFullScreen);
				_fsVideo.clickURL = _clickURL;
				_fsVideo.campaignName = _campaignName;
				_fsVideo.showLikeButton = videoData.showLikeButton;
				_fsVideo.suppressSponsorButton = videoData.suppressSponsorButton;
				trace("Video is locked: " + videoData.locked);
				_fsVideo.locked = videoData.locked;
				trace("Video has controls: " + videoData.controls);
				_fsVideo.controls = videoData.controls;
				_fsVideo.containerName = _container.name;
			}
			
			// call fnDoneFade when reaching end label
			if (_timeline)
				TimelineUtils.onLabel(entity, "end", fnDoneFade, false);
			
			// trigger awarded card events after scene is loaded
			// doing this before was causing the events to get lost
			_group.shellApi.sceneManager.sceneLoaded.add(handleSceneLoaded);
		}
		
		/**
		 * trigger awarded card events for cards already awarded 
		 * @param group
		 */
		public function handleSceneLoaded(group:Scene = null):void
		{
			if (_giveItemMale)
				triggerEarnedCards(_giveItemMale);
			if (_giveItemFemale)
				triggerEarnedCards(_giveItemFemale);
		}
		
		/**
		 * Call trigger event for any cards already awarded in card array 
		 * @param cardArray
		 * 
		 */
		private function triggerEarnedCards(cardArray:Array):void
		{
			for each (var card:String in cardArray)
			{
				if (_group.shellApi.checkHasItem(card, CardGroup.CUSTOM))
				{
					_group.shellApi.triggerEvent(CARD_PREFIX + card);
				}
			}
		}
		
		/**
		 * Click Video (for old video containers)
		 */
		public function fnClick():void
		{
			// interact with campaign and check for branding
			AdUtils.interactWithCampaign(_group, _campaignName);

			// if mobile and no network then skip
			if ((PlatformUtils.isMobileOS) && (!_group.shellApi.networkAvailable()))
			{
				var sceneUIGroup:SceneUIGroup = _group.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CONNECT_TO_INTERNET, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				return;
			}
			
			trace("Ad Video Click: old video container.");
			
			if (_audioSystem == null)
				_audioSystem = AudioSystem(_group.getSystem(AudioSystem));
			
			// don't allow if game is paused
			if (pStatus != "paused")
			{
				_videoNumber = 0;
				_videoFile = convertVideoURL(_videoFiles[_videoNumber]);
				if (_fsVideo)
					_fsVideo.videoURL = _videoFile;
				trace("Ad Video Player: playing video file: " + _videoFile);
				
				switch(pStatus)
				{
					case "":
						// first time click, make start request to system
						pStatus = "start";
						break;
					case "end":
						// when on video end screen
						// assumes invisible button clip on top of replay button, named replayButton
						// invisible button clip has width and height equal to zero, so can't use hitTestPoint
						var vReplayBtn:DisplayObject = _container.replayButton;
						var vURLBtn:DisplayObject = _container.clickURLButton;
						var vBtnRect:Rectangle;
						// if replay button exists (clicking outside of button will go to sponsor url)
						if (vReplayBtn != null)
						{
							// bounds of replay button
							vBtnRect = new Rectangle(vReplayBtn.x, vReplayBtn.y, vReplayBtn.scaleX * 10, vReplayBtn.scaleY * 10);
							// if clicking inside replay button, then replay request to system
							if (vBtnRect.contains(_container.mouseX, _container.mouseY))
							{
								pStatus = "replay";
							}
							else
							{
								if (_clickURL)
									AdManager.visitSponsorSite(_group.shellApi, _campaignName, triggerSponsorSite);
							}
						}
						else if (vURLBtn != null)
						{
							// if click URL button exists (clicking outside of button will replay video)
							// bounds of replay button
							vBtnRect = new Rectangle(vURLBtn.x, vURLBtn.y, vURLBtn.scaleX * 10, vURLBtn.scaleY * 10);
							// if clicking inside replay button, then replay request to system
							if (vBtnRect.contains(_container.mouseX, _container.mouseY))
							{
								if (_clickURL)
									AdManager.visitSponsorSite(_group.shellApi, _campaignName, triggerSponsorSite);
							}
							else
							{
								pStatus = "replay";
							}
						}
						else
						{
							if (_clickURL)
								AdManager.visitSponsorSite(_group.shellApi, _campaignName, triggerSponsorSite);
						}
						break;
					case "playing":
						break;
				}
			}
		}
		
		/**
		 * Click Video - newer
		 */
		public function clickButton(entity:Entity):void
		{
			// interact with campaign and check for branding (not if blimp)
			if (!_isBlimpPopup)
			{
				AdUtils.interactWithCampaign(_group, _campaignName);
			}
			
			// if game is paused, then skip
			if (pStatus == "paused")
				return;
			
			// if game button
			var id:String = entity.get(Id).id;
			if (id.indexOf("GameButton") != -1)
			{
				openPopup();
				return;
			}
			
			// if mobile and no network then skip
			if ((PlatformUtils.isMobileOS) && (!_group.shellApi.networkAvailable()))
			{
				var sceneUIGroup:SceneUIGroup = _group.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CONNECT_TO_INTERNET, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				return;
			}
			
			// handle sponsor buttons first, then proceed to attempt video play / replay
			if (id.indexOf("clickURLButton") != -1)
			{
				if (_clickURL)
					AdManager.visitSponsorSite(_group.shellApi, _campaignName, triggerSponsorSite);
				return;
			}
			
			// if VPAID ad, abort normal sequence and use custom-loading process
			if ( _VPAIDEnabled )
			{
				setupVpaid(entity);
				return;
			}
			
			// if VAST enabled and not yet loaded, skip
			if ( _vastEnabled && !_vastReady )
				return;
			
			// if VAST tag needs to be pulled again, do so now and abort current click
			if ( _vastReset )
			{
				_vastReady = false;
				_vastReset = false;
				_vastAutoPlayClickEntity = entity;
				_vastAutoPlay = true;
				setupVAST();
				return;
			}
			// otherwise, it should happen on the next click and we can keep going
			else if ( _vastEnabled )
			{
				_vastReset = true;
				_vastNextProgressEvent = 25;
			}
			
			if (_audioSystem == null)
				_audioSystem = AudioSystem(_group.getSystem(AudioSystem));
			
			// figure out which video from id
			_videoNumber = int(id.substr(id.length - 1));
			
			// if buttons have numbers, then decrement
			if (_videoNumber != 0)
				_videoNumber--;
			
			// limit to number of files
			if (_videoNumber > _videoFiles.length-1)
				_videoNumber = _videoFiles.length-1;
			
			_videoFile = convertVideoURL(_videoFiles[_videoNumber]);
			trace("Ad Video Player: playing video " + (_videoNumber+1) + " of " + _videoFiles.length + " : " + _videoFile);
			
			if (_fsVideo)
				_fsVideo.videoURL = _videoFile;
			
			if (id.indexOf("replayButton") != -1)
				pStatus = "replay";
			else
			{
				pStatus = "start";
				// remove play button
				_group.removeEntity(entity);
				// remove first game button
				if (_firstGameButton != null)
					_group.removeEntity(_firstGameButton);
			}
			
			// if blimp popup
			if (_isBlimpPopup)
			{
				// prepend status
				pStatus = "blimp" + pStatus;
				// show blimp video popup
				if (_blimpPopup == null)
					showBlimpVideoPopup();
			}
				
			// hide all other buttons
			// don't hide buttons if fullscreen
			//showButtons(false);
		}
		
		/**
		 * Update all buttons on video container
		 * NOTE: multiple video containers in one scene cannot have the same button names since they are referenced by button name
		 * @param state
		 * @param fade
		 */
		private function showButtons(state:Boolean, fade:Boolean = true):void
		{
			// no need for fades if fullscreen
			fade = false;
			
			var delay:Number = 0.5;
			var entity:Entity;
			
			// don't fade if hiding buttons
			if (!state)
				fade = false;
			
			// play and replay buttons (handles generic and 4 multi videos)
			for (var i:int = 0; i!=10; i++)					
			{
				// if multiple containers, then only update that container only
				if ((!singleContainer) && (i != _videoNumber + 1))
					continue;
				
				// suffix after name, use none if i==0 (for generic)
				var suffix:String = String(i);
				if (i == 0)
				{
					// if blimp popup then add blimp suffix
					// this prevents conflicts with other video units on main street
					if (_isBlimpPopup)
						suffix = "Blimp";
					else if (_isCarouselVideo)
						suffix = "CV";
					else
						suffix = "";
				}
				var suffix2:String = _container.name.substr(_container.name.length-1,1);
				if(!isNaN(Number(suffix2)))
					suffix = suffix2;
				
				
				// click URL button
				entity = _group.getEntityById("clickURLButton" + suffix);
				
				if (entity)
				{
					entity.get(Display).visible = state;
					if (fade)
						TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "clickURLButton" + suffix);
				}
				
				// if play button then hide/show
				// note that play button is removed after video has started
				if (!_hasSeenVideo)
				{
					entity = _group.getEntityById("playButton" + suffix);
					if (entity != null)
					{
						entity.get(Display).visible = state;
						if (fade)
							TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "playButton" + suffix);
					}
				}
				// always hide/show replay button (assumes it is behind play button)
				entity = _group.getEntityById("replayButton" + suffix);
				if (entity)
				{
					entity.get(Display).visible = state;
					if (fade)
						TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "replayButton" + suffix);
				}
				
				// game buttons
				if (_gameData != null)
				{
					// get card list if not already have it
					if (_cardList == null)
						_cardList = AdUtils.getCardList(_group.shellApi, _campaignName, _gameID);
					// if cards and doesn't have first one
					var cardsNotAwarded:Boolean = ((_cardList.length != 0) && (!_group.shellApi.itemManager.checkHas(_cardList[0], "custom")));
					// note that the first game button is removed after video has started
					if (!_hasSeenVideo)
					{
						entity = _group.getEntityById("firstGameButton" + suffix);
						if (entity != null)
						{
							_firstGameButton = entity;
							updateGameButton(entity, cardsNotAwarded);
							entity.get(Display).visible = state;
							if (fade)
								TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "firstGameButton" + suffix);
						}
					}
					else
					{
						// else hide/show second game button
						entity = _group.getEntityById("secondGameButton" + suffix);
						if (entity)
						{
							entity.get(Display).visible = state;
							updateGameButton(entity, cardsNotAwarded);
							if (fade)
								TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "secondGameButton" + suffix);
						}
					}
				}
			}
			
			// if sequential videos
			if (_hasSequentialVideos)
			{
				// next button
				entity = _group.getEntityById("nextButton");
				if (entity)
				{
					// if showing and last video then force hide
					if ((state) && (_videoNumber == _videoFiles.length - 1))
						state = false;
					entity.get(Display).visible = state;
					if (fade)
						TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "nextButton");
				}
				// for multiple end screens
				var hasCurrentEndScreen:Boolean = false;
				for (i = 1; i!=5; i++)
				{
					entity = _group.getEntityById("endScreen" + i);
					if (entity)
					{
						// if not clicking play button then normal display
						if (i == _videoNumber + 1)
						{
							hasCurrentEndScreen = true;
							entity.get(Display).displayObject.visible = state;
							entity.get(Display).visible = state;
							if (fade)
								TweenUtils.globalFromTo(_group, entity.get(Display), delay, {alpha:0}, {alpha:1}, "endScreen" + i);
						}
						else
						{
							// otherwise suppress
							entity.get(Display).displayObject.visible = false;
							entity.get(Display).visible = false;
						}
					}
				}
				// if turning on and end screen found then hide replay button
				if ((state) && (hasCurrentEndScreen))
				{
					entity = _group.getEntityById("replayButton");
					if (entity)
					{
						entity.get(Display).visible = false;
					}
				}
			}
		}
		
		/**
		 * Update game button based on cards not awarded
		 */
		private function updateGameButton(entity:Entity, cardsNotAwarded:Boolean):void
		{
			var timeline:Timeline = entity.get(Timeline);
			if (timeline != null)
			{
				if (cardsNotAwarded)
					timeline.gotoAndStop("playForPrize");
				else
					timeline.gotoAndStop("playGame");
			}
		}
		
		/**
		 * When done fading and reach end screen
		 */
		private function fnDoneFade():void
		{
			pStatus = "end";
		}
		
		/**
		 * Play Video (called from system in response to "start")
		 * or called by clicking next button when sequential videos
		 */
		public function fnPlay(entity:Entity = null):void
		{
			var adManager:AdManager = AdManager(_group.shellApi.adManager);
			// check if main street unit
			var ad:AdData = adManager.getAdDataByCampaign(_campaignName);
			if (ad != null)
			{
				// if main street or mobile main street or billboard or mobile billboard
				//if ((ad.campaign_type == AdCampaignType.MAIN_STREET) || (ad.campaign_type == AdCampaignType.BILLBOARD))
				if (ad.campaign_type == AdCampaignType.MAIN_STREET || ad.campaign_type == AdCampaignType.MAIN_STREET2)
				{
					// need to filter out interior scenes
					if (!adManager.isInterior)
					{
						adManager.startActivityTimer(_campaignName);
					}
				}
			}
			
			// lock video if requested and not fullscreen
			if ((!_fullscreen) && (_locked))
				SceneUtil.lockInput(_group, true);
			
			trace("AdVideo :: fnPlay : play called");
			// if this is a VPAID ad, ignore the call to play
			if ( _VPAIDEnabled )
				return;
			// if no video then fade to end screen
			if (_videoFiles == null)
			{
				pStatus = "done";
				if (_timeline)
					_timeline.gotoAndPlay("fade");
				else
					showButtons(true);
			}
			else
			{
				showButtons(false);
				pStatus = "playing";
				
				// go to video frame
				if (_timeline)
					_timeline.gotoAndStop("video");
				
				// send tracking pixel (multiple for VAST)
				if ( _vastEnabled )
					AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, buildMultipleParameterString(_vastVideoImpressionURLs));
				else
					AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, _impressionURL);
				
				// if full screen, then play fullscreen
				if (_fsVideo)
				{
					_fsVideo.play();
				}
				else
				{
					// setup connection
					_connection = new NetConnection();
					_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
					_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnSecurityError);
					_connection.connect(null);
				}
			}
		}
		
		/**
		 * Replay video (called from system in response to "replay")
		 */
		public function fnReplay(entity:Entity = null):void
		{
			// lock video if requested and not fullscreen
			if ((!_fullscreen) && (_locked))
				SceneUtil.lockInput(_group, true);
			
			// if this is a VPAID ad, ignore the call to replay
			if ( _VPAIDEnabled )
				return;
			
			// if vast or has sequential videos, then force play
			if (( _vastEnabled ) || (_hasSequentialVideos))
			{
				fnPlay();
				return;
			}
			
			// if no video then fade to end screen
			if (_videoFiles == null)
			{
				pStatus = "done";
				if (_timeline)
					_timeline.gotoAndPlay("fade");
			}
			else
			{
				if (_timeline)
					_timeline.gotoAndStop("video");
				pStatus = "playing";
				
				// trigger event
				_group.shellApi.triggerEvent("videoPlaying");
				
				// show full screen again
				if (_fsVideo)
				{
					_fsVideo.replay();
					fnTrack(AdTrackingConstants.TRACKING_VIDEO_REPLAYED);
					AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, _impressionURL);
				}
				else
				{
					// setup connection again (needed if there are multiple videos in one MVU)
					_connection = new NetConnection();
					_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
					_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnSecurityError);
					_connection.connect(null);
					
					// mute sounds
					_audioSystem.muteSounds();
				}
			}
		}
		
		private function openPopup():void
		{
			// first make sure that game data is available
			if (_gameData == null)
			{
				trace("Error: Missing game data to load popup!");
			}
			else
			{
				trace("AdVideo :: openPopup - game data not null");
				// create popup and add to scene
				var popup:Popup = _group.shellApi.sceneManager.currentScene.addChildGroup(new AdStartGamePopup()) as Popup;
				trace("AdVideo :: openPopup - create AdStartGamePopup");
				// pass campaign data along to popup in case it's needed
				trace("AdVideo :: openPopup - get ad data for: " + _campaignName);
				trace("AdVideo :: openPopup - " +popup); 
				var campaignData:CampaignData = _group.shellApi.adManager.getActiveCampaign(_campaignName);
				trace("AdVideo :: openPopup - getting campaign data " + campaignData.campaignId);

				popup.campaignData = _group.shellApi.adManager.getActiveCampaign(_campaignName);
				popup.campaignData.gameID = _gameID;
				popup.campaignData.gameClass = _gameClass;
				popup.campaignData.popupScene = _popupScene;
				trace("AdVideo :: openPopup - assign vars");
				// add click URL to param list
				var paramList:ParamList = new ParamList();
				var paramData:ParamData = new ParamData();
				paramData.id = "clickURL";
				paramData.value = _clickURL;
				paramList.push(paramData);
				
				// initialize popup
				popup.init( _group.shellApi.sceneManager.currentScene.overlayContainer );
				trace("AdVideo :: openPopup - init popup");
				// play campaign music, if any
				if (popup.campaignData.musicFile != null)
					AdManager(_group.shellApi.adManager).playCampaignMusic(popup.campaignData.musicFile);
			}
		}
		
		/**
		 * Get status of stream or connection
		 * @param	aEvent
		 */
		private function fnStatus(aEvent:NetStatusEvent):void
		{
			//trace(aEvent.info.code);
			switch (aEvent.info.code) {
				case "NetConnection.Connect.Success":
					// successful connection, now connect stream
					fnConnectStream();
					break;
				case "NetStream.Play.StreamNotFound":
					// video not found
					trace("Ad Video Player: Unable to locate video: " + _videoFile);
					// clear video file and fade to end screen
					_videoFile = null;
					pStatus = "done";
					if (_timeline)
						_timeline.gotoAndPlay("fade");
					else
						showButtons(true);
					break;
				case "NetStream.Play.Stop":
					// video reaches end
					fnVideoDone();
					break;
				case "NetStream.Seek.Complete":
					_videoPlayer.visible = true;
					break;
			}
		}
		
		/**
		 * Connect stream after connection is made
		 */
		private function fnConnectStream():void
		{
			// set up stream
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, fnAsyncError);
			
			// set buffer to 0.1 seconds
			_stream.bufferTime = 0.1;
			
			// metadata
			var vMetaData:Object=new Object();
			vMetaData.onMetaData = fnMetaData;
			_stream.client = vMetaData;
			
			_videoPlayer = new Video(_videoWidth, _videoHeight);
			// if blimp video, then center video on screen
			if (_isBlimpPopup)
			{
				_videoClip = Scene(_group).overlayContainer.addChild(_videoPlayer);
				_videoClip.x = (960 - _videoWidth)/2;
				_videoClip.y = (640 - _videoHeight)/2;
			}
			else
			{
				_videoClip = _container.addChild(_videoPlayer);
				// swap progress bar with video player
				if (_progressBar != null)
				{
					_progressBar.visible = true;
					_container.swapChildren(_videoClip, _progressBar);
				}
			}		
			_videoPlayer.attachNetStream(_stream);
			
			// if video URL doesn't have http
			if ( _videoFile.toLowerCase().indexOf("https") == -1 )
			{
				var videoURL:String = "https://" + _group.shellApi.siteProxy.fileHost + "/" + _videoFile;
				trace("Ad Video Player: Playing video url: " + videoURL);
				_stream.play(videoURL);
			}
			else
			{
				trace("Ad Video Player: Playing video url: " + _videoFile);
				_stream.play(_videoFile);
			}
			
			// mute sounds
			_audioSystem.muteSounds();
			
			// trigger event
			_group.shellApi.triggerEvent("videoPlaying");
			if ( _vastReplay || _replay)
			{
				if ( _vastEnabled || _replay)
				{	
					fnTrack(AdTrackingConstants.TRACKING_VIDEO_REPLAYED);
					AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, _impressionURL);
				}				
			}
			else
			{
				fnTrack(AdTrackingConstants.TRACKING_VIDEO_CLICKED);
				if ( _vastEnabled )
					_vastReplay = true;
				_replay = true;
			}
		}
		
		private function notifyFullScreen(message:String):void
		{
			switch (message)
			{
				case AdFullScreenVideo.NOT_FOUND:
					pStatus = "done";
					if (_timeline)
						_timeline.gotoAndPlay("fade");
					else
						showButtons(true);
					break;
				
				case AdFullScreenVideo.STARTED:
					_group.shellApi.triggerEvent("videoPlaying");
					fnTrack(AdTrackingConstants.TRACKING_VIDEO_CLICKED);
					// don't break but include code below
				
				case AdFullScreenVideo.REPLAYED:					
					// if blimp video, then center popup on screen behind fullscreen video
					if (_isBlimpPopup)
					{
						// show blimp video popup
						if (_blimpPopup == null)
							showBlimpVideoPopup();
					}
					break;
				
				case AdFullScreenVideo.QUIT:
					pStatus = "done";
					if (_timeline)
						_timeline.gotoAndPlay("fade");
					else
						showButtons(true);
					
					// if sequential videos
					if (_hasSequentialVideos)
						updateSequentialVideos();
					
					if (_isBlimpPopup)
					{
						// show replay and clickURL buttons when video ends
						showBlimpVideoPopupButtons();
					}
					break;
				
				case AdFullScreenVideo.ENDED:
					fnVideoDone();
					break;			
				
				case AdFullScreenVideo.FAILED:
					fnVideoDone(true);
					break;			
			}
		}
		
		/**
		 * Video is done
		 */
		private function fnVideoDone(failed:Boolean = false):void
		{
			if (pStatus != "done")
			{
				if (_progressBar != null)
				{
					_progressBar.visible = false;
					_progressBar.bar.width = 0;
				}
	
				// unlock video if locked and not fullscreen
				if ((!_fullscreen) && (_locked))
					SceneUtil.lockInput(_group, false);
				
				if ( _vastEnabled )
					AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, buildMultipleParameterString(_vastTrackVideoCompleteURLs));
				
				// if card video power then notify popup class
				if (_group.hasOwnProperty('doneVideo')) {
					_group['doneVideo']();
				}
				
				_hasSeenVideo = true;
				pStatus = "done";
				
				// fade video
				if (_timeline)
				{
					_timeline.gotoAndPlay("fade");
				}
				else
				{
					// show all buttons
					showButtons(true);
				}
				
				// award cards if not blimp popup
				if (!_isBlimpPopup)
					awardCards();
				trace("AdVideo :: fnVideoDone - awardCredits: " + _awardCredits);
				if(_awardCredits != 0) {
					awardCredits();
				}
				
				if (_fsVideo == null)
				{
					_videoPlayer.visible = false;
					// restore sounds
					_audioSystem.unMuteSounds();
				}
				
				// trigger event
				if (!failed)
				{
					_group.shellApi.triggerEvent("videoDone");
					fnTrack(AdTrackingConstants.TRACKING_VIDEO_COMPLETE);
				}
	
				// if sequential videos
				if (_hasSequentialVideos)
					updateSequentialVideos();
				
				// if blimp popup, show replay and clickURL buttons
				if (_isBlimpPopup)
				{
					showBlimpVideoPopupButtons();
				}
				
				// if mini-game MVU, then open start popup
				if (_miniGameMVU)
					openPopup();
			}
		}
		// award credits
		private function awardCredits():void {
			_group.shellApi.profileManager.active.credits += _awardCredits;
			_group.shellApi.profileManager.save();
			// show coins
			SceneUtil.getCoins(_group.shellApi.currentScene, _awardCredits);
			// save to database
			AdUtils.setScore(_group.shellApi, _awardCredits, "housevideo");
		}
		// award cards
		private function awardCards():void
		{
			// award item cards
			switch(_group.shellApi.profileManager.active.gender)
			{
				case SkinUtils.GENDER_MALE:
				case null:
					if(_giveItemMale)
						_card = _giveItemMale[_videoNumber];
					break;
				case SkinUtils.GENDER_FEMALE:
					if(_giveItemFemale)
						_card = _giveItemFemale[_videoNumber];
					break;
			}
			
			// if card exists and not yet awarded
			if ( _card != null )
			{
				switch(_group.shellApi.profileManager.active.gender)
				{
					case SkinUtils.GENDER_MALE:
					case null:
						if(_giveItemMale)
							_card2 = _giveItemMale[_videoNumber+1];
						break;
					case SkinUtils.GENDER_FEMALE:
						if(_giveItemFemale)
							_card2 = _giveItemFemale[_videoNumber+1];
						break;
				}
				if(_card2 != null)
					_group.shellApi.getItem(_card, CardGroup.CUSTOM, true , awardNextCard);
				else
					_group.shellApi.getItem(_card, CardGroup.CUSTOM, true );
			}			
		}
		
		private function awardNextCard():void
		{
			_group.shellApi.getItem(_card2, CardGroup.CUSTOM, true );
		}
		
		private function updateSequentialVideos():void
		{
			// increment video number
			_videoNumber++;
			// if reached total videos, then reset
			if (_videoNumber == _videoFiles.length)
			{
				_videoNumber = 0;
			}
			_videoFile = convertVideoURL(_videoFiles[_videoNumber]);
			trace("AdVideo: next video will be " + _videoFile);
			
			// tell fullscreen video which next video to play
			if (_fsVideo)
				_fsVideo.videoURL = _videoFile;
		}
		
		private function triggerSponsorSite():void
		{
			fnTrack(AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR);
			if ( _vastEnabled )
			{
				AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, buildMultipleParameterString(_vastVideoClickTrackingURLs));
				AdUtils.openSponsorURL(_group.shellApi,_vastVideoClickThroughURL, _campaignName, _choice, _container.name );
			}
			else
			{
				AdUtils.openSponsorURL(_group.shellApi,_clickURL, _campaignName, _choice, _container.name);
			}
		}
		
		/**
		 * Stop video (called from system when another video is playing)
		 * @param	force (only used for blimp video when clicking close button)
		 */
		public function fnStop(force:Boolean = false):void
		{
			if (_progressBar != null)
			{
				_progressBar.visible = false;
				_progressBar.bar.width = 0;
			}

			if (_fsVideo)
				_fsVideo.stop();
			else
			{
				if (_timeline)
					_timeline.gotoAndStop("end");
				else
					showButtons(true, false);
				if (_stream != null)
				{
					pStatus = "end";
					_stream.pause();
					_videoPlayer.visible = false;
				}
			}
			if (_isBlimpPopup)
			{
				// if forcing stop, then remove popup reference
				if (force)
				{
					_blimpPopup = null;
					trace("Clearing blimp video popup");
					// award cards only if video has been watched to end
					if (_hasSeenVideo)
						awardCards();
				}
				else
				{
					// show replay and clickURL buttons when video ends
					showBlimpVideoPopupButtons();
				}
			}
		}
		
		/**
		 * when blimp video popup loaded
		 */
		public function blimpVideoPopupLoaded():void
		{
			// remove prefix to trigger play
			pStatus = pStatus.substr(5);
		}
		
		/**
		 * Hide show blimp video popup
		 */
		private function showBlimpVideoPopup():void
		{
			// add blimp video popup to scene
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(_group.groupManager.getGroupById("ui"));
			_blimpPopup = BlimpVideoPopup(sceneUIGroup.addChildGroup(new BlimpVideoPopup()));
			// pass ad data and game suffix as game ID to popup
			_blimpPopup.campaignData =  AdManager(_group.shellApi.adManager).getActiveCampaign(_campaignName);
			_blimpPopup.campaignData.gameID = "";
			_blimpPopup.adVideo = this;
			// don't pause popup, otherwise video won't play
			_blimpPopup.pauseParent = false;
			// initialize popup
			_blimpPopup.init(sceneUIGroup.groupContainer);
		}
		
		/**
		 * Hide show blimp video popup buttons
		 */
		private function showBlimpVideoPopupButtons():void
		{
			if (_blimpPopup != null)
			{
				var button:Entity = _blimpPopup.getEntityById("clickURL");
				if (button != null)
				{
					button.get(Display).visible = true;
					button.get(Display).alpha = 1;
				}
				button = _blimpPopup.getEntityById("replayButton")
				if (button != null)
				{
					button.get(Display).visible = true;
					button.get(Display).alpha = 1;
				}
			}
		}
		
		/**
		 * Pause video (called from game)
		 * @param	aEvent
		 */
		public function fnPause():void
		{
			if (_fsVideo)
				_fsVideo.pause();
			else
			{
				if ((_stream != null) && (pStatus == "playing"))
				{
					pStatus = "paused";
					_stream.pause();
				}
				else if ( _VPAIDEnabled && pStatus == "playing" )
				{
					pStatus = "paused";
					_VPAIDAdWrapper.pauseAd();
				}
				else if ( _VPAIDEnabled && (pStatus == "start" || pStatus == "replay") )
					_VPAIDPauseOnPlay = true;
					
			}
		}
		
		/**
		 * Unpause video (called from game)
		 * @param	aEvent
		 */
		public function fnUnpause():void
		{
			if (_fsVideo)
				_fsVideo.unpause();
			else
			{
				if ((_stream != null) && (pStatus == "paused"))
				{
					pStatus = "playing";
					_stream.resume();
				}
				else if ( _VPAIDEnabled && pStatus == "paused" )
				{
					pStatus = "playing";
					_VPAIDAdWrapper.resumeAd();
				}
			}
		}
		
		/**
		 * dispose video
		 * @param	aEvent
		 */
		public function fnDispose():void
		{
			if (_fsVideo)
				_fsVideo.dispose();
			else
			{
				if (_stream != null)
				{
					_stream.close();
					_videoPlayer.visible = false;
				}
				
				if (_connection != null)
					_connection.close();
				
				if ((_videoClip) && (_videoClip.parent))
				{
					_videoClip.parent.removeChild(_videoClip);
				}
				
				// restore sounds if playing
				if (pStatus == "playing")
				{
					_audioSystem.unMuteSounds();
				}
				
				// if a VPAID ad, send the message to shut it down
				if ( _VPAIDEnabled )
					VPAIDDispose();
			}
		}
		
		/**
		 * Set sequential files in video player (needs next button and extra end screens) 
		 */
		public function setSequentialVideos():void
		{
			// set sequential files to true if there is more than one video
			if (_videoFiles.length != 0)
				_hasSequentialVideos = true;
		}
		
		public function updateProgress():void
		{
			if (_fsVideo)
				_fsVideo.updateProgress();
			else
			{
				var videoProgress:Number = _stream.time / _videoDuration;
				if (videoProgress > 1.0)
					videoProgress = 1.0;
				if (_progressBar != null)
					_progressBar.bar.width = videoProgress * _videoWidth;
			}
		}
		
		// VAST-RELATED FUNCTIONS ///////////////////////////////////////////////////////////////////////
		
		/**
		 * called to make request for VAST tag
		 */
		private function setupVAST():void
		{			
			// if using [RANDOM] or [timestamp] for cache-busting, replace it now
			var vastFetchURL:String = _vastTagURL;
			if ( vastFetchURL.indexOf("[RANDOM]") != -1 )
				vastFetchURL = stringReplace(vastFetchURL, "[RANDOM]", String( Math.round(Math.random() * 10000) ) );
			if ( vastFetchURL.indexOf("[timestamp]") != -1 )
				vastFetchURL = stringReplace(vastFetchURL, "[timestamp]", String( Math.round(Math.random() * 10000) ) );
			if ( vastFetchURL.indexOf("[TIMESTAMP]") != -1 )
				vastFetchURL = stringReplace(vastFetchURL, "[TIMESTAMP]", String( Math.round(Math.random() * 10000) ) );
			
			// load XML
			_vastXMLLoader = new URLLoader();
			_vastXMLLoader.load(new URLRequest(vastFetchURL));
			_vastXMLLoader.addEventListener(Event.COMPLETE, loadedVAST);
		}
		
		/**
		 * once VAST tag is loaded, parse its XML
		 */
		private function loadedVAST(completeEvent:Event):void
		{
			// store retrieved XML
			_vastXML = new XML(completeEvent.target.data);
			
			// clear variables
			_vastVideoImpressionURLs = new Array();
			_vastTrackVideoStartURLs = new Array();
			_vastTrackVideoFirstQuartileURLs = new Array();
			_vastTrackVideoMidpointURLs = new Array();
			_vastTrackVideoThirdQuartileURLs = new Array();
			_vastTrackVideoCompleteURLs = new Array();
			_vastVideoClickTrackingURLs = new Array();
			
			// retrieve and store tracking url's from XML; store in the appropriate arrays
			var i:int;
			for ( i = 0; i < _vastXML.Ad.InLine.Impression.length(); i ++ )
				_vastVideoImpressionURLs.push(_vastXML.Ad.InLine.Impression[i]);
			for ( i = 0; i < _vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="start").length(); i ++ )
				_vastTrackVideoStartURLs.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="start")[i]);
			for ( i = 0; i < _vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="firstQuartile").length(); i ++ )
				_vastTrackVideoFirstQuartileURLs.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="firstQuartile")[i]);
			for ( i = 0; i < _vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="midpoint").length(); i ++ )
				_vastTrackVideoMidpointURLs.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="midpoint")[i]);
			for ( i = 0; i < _vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="thirdQuartile").length(); i ++ )
				_vastTrackVideoThirdQuartileURLs.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="thirdQuartile")[i]);
			for ( i = 0; i < _vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="complete").length(); i ++ )
				_vastTrackVideoCompleteURLs.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking.(@event=="complete")[i]);
			for ( i = 0; i < _vastXML.Ad.InLine.Creatives.Creative.Linear.VideoClicks.ClickTracking.length(); i ++ )
				_vastVideoClickTrackingURLs.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.VideoClicks.ClickTracking[i]);
			
			// video impression URL setup
			// add start URL's (they'll be sent at the same time as the impression URL)
			for ( i = 0; i < _vastTrackVideoStartURLs.length; i ++ )
				_vastVideoImpressionURLs.push(_vastTrackVideoStartURLs[i]);
			// if an impression URL is specified in the CMS, add that too (so they can all be sent at once)
			if ( _impressionURL != null )
				_vastVideoImpressionURLs.push(_impressionURL);
			
			// only support for one click-through URL
			_vastVideoClickThroughURL = _vastXML.Ad.InLine.Creatives.Creative.Linear.VideoClicks.ClickThrough;
			
			// store location of video; while VAST allows multiple videos, we currently only support using a single one
			_videoFiles = new Array();
			_videoFiles.push(_vastXML.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile[0]);
			
			// allow clicking the video to happen
			_vastReady = true;
			
			// autoplay if VAST is being refreshed
			if ( _vastAutoPlay )
			{
				_vastAutoPlay = false;
				clickButton(_vastAutoPlayClickEntity);
			}
		}
		
		public function checkProgressForVAST():void
		{
			if ( !_vastEnabled || _vastNextProgressEvent == 100 )
				return;
			
			var videoPercentagePlayed:Number = _stream.time / _videoDuration * 100;
			
			if ( videoPercentagePlayed > _vastNextProgressEvent )
			{
				switch ( _vastNextProgressEvent )
				{
					case 25:
						AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, buildMultipleParameterString(_vastTrackVideoFirstQuartileURLs));
						break;
					case 50:
						AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, buildMultipleParameterString(_vastTrackVideoMidpointURLs));
						break;
					case 75:
						AdUtils.sendTrackingPixels(_group.shellApi, _campaignName, buildMultipleParameterString(_vastTrackVideoThirdQuartileURLs));
						break;
				}
				_vastNextProgressEvent += 25;
			}
		}
		
		// VPAID FUNCTIONS ///////////////////////////////////////////////////////////////////////
		
		// function that begins the process of setting up and fetching the VPAID ad (called on every request to play or replay)
		private function setupVpaid(entity:Entity):void
		{					
			// standard video setup code
			if (_audioSystem == null)
				_audioSystem = AudioSystem(_group.getSystem(AudioSystem));
			
			var id:String = entity.get(Id).id;
			if (id.indexOf("replayButton") != -1)
				pStatus = "replay";
			else
			{
				pStatus = "start";
				// remove play button
				_group.removeEntity(entity);
				// remove first game button
				if (_firstGameButton != null)
					_group.removeEntity(_firstGameButton);
			}
			// hide all other buttons
			showButtons(false);
			
			// indicate the proper tracking call
			if ( pStatus == "start" )
				fnTrack(AdTrackingConstants.TRACKING_VIDEO_CLICKED);
			else
				fnTrack(AdTrackingConstants.TRACKING_VIDEO_REPLAYED);
			_group.shellApi.triggerEvent("videoPlaying");
			
			// setup a container for the VPAID ad if it does not exist
			if ( !_VPAIDContainer )
			{
				_VPAIDContainer = new MovieClip();
				_container.addChild(_VPAIDContainer);
			}
			
			// check to see if loading cilp exists in video
			if ( !_VPAIDLoadingClip )
			{
				// if not, create and load it before moving on
				var swfPath:String = _group.shellApi.assetPrefix + "limited/Shared/VpaidLoadingClip.swf";
				_group.shellApi.loadFile(swfPath, VPAIDLoadingClipLoaded);
			}
			else
			{
				// otherwise show the loading message and start the process of loading the VPAID ad
				_VPAIDLoadingClip.visible = true;
				VPAIDLoadTag();
			}
		}
			
		// loading clip has been loaded; set it up before proceeding with loading the ad
		private function VPAIDLoadingClipLoaded(clip:MovieClip):void
		{
			// initialize the clip (store reference, position, hide error messages, and add to container)
			_VPAIDLoadingClip = clip;
			_VPAIDLoadingClip.x = _videoWidth / 2;
			_VPAIDLoadingClip.y = _videoHeight / 2;
			_VPAIDLoadingClip.tagLoadingErrorMessage.visible = false;
			_VPAIDLoadingClip.adLoadingErrorMessage.visible = false;
			_container.addChild(_VPAIDLoadingClip);	
			
			// prepare to load the tag
			VPAIDLoadTag();
		}
		
		// setup info needed to load the VPAID tag
		private function VPAIDLoadTag():void	
		{
			// setup tag url and filter it if needed (replace timestamp for cache-busting)
			_VPAIDFilteredTagURL = _VPAIDTagURL;
			if ( _VPAIDFilteredTagURL.indexOf("[RANDOM]") != -1 )
				_VPAIDFilteredTagURL = _VPAIDFilteredTagURL.replace("[RANDOM]", Math.round(Math.random() * 10000).toString());
			if ( _VPAIDFilteredTagURL.indexOf("[timestamp]") != -1 )
				_VPAIDFilteredTagURL = _VPAIDFilteredTagURL.replace("[timestamp]", Math.round(Math.random() * 10000).toString());			
			if ( _VPAIDFilteredTagURL.indexOf("[TIMESTAMP]") != -1 )
				_VPAIDFilteredTagURL = _VPAIDFilteredTagURL.replace("[TIMESTAMP]", Math.round(Math.random() * 10000).toString());			
			
			// load the VPAID XML
			_VPAIDTagURLRequest = new URLRequest(_VPAIDFilteredTagURL);
			_VPAIDTagLoader = new URLLoader();
			_VPAIDTagLoader.addEventListener(Event.COMPLETE, VPAIDTagLoaded, false, 0, true);
			_VPAIDTagLoader.addEventListener(ErrorEvent.ERROR, VPAIDTagLoadError, false, 0, true);
			_VPAIDTagLoader.load(_VPAIDTagURLRequest);
		}
		
		// VPAID URL (XML) loaded, pull the URL of the VPAID ad out of it and load the ad
		private function VPAIDTagLoaded(e:Event):void
		{	
			// get the VPAID ad URL
			_VPAIDTagLoader.removeEventListener(Event.COMPLETE, VPAIDTagLoaded);
			_VPAIDTagLoader.removeEventListener(ErrorEvent.ERROR, VPAIDTagLoadError);
			_VPAIDTagXML = new XML(e.target.data);
			_VPAIDAdUrl = _VPAIDTagXML.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile.toString();
			
			// prepare the VPAID loader for action
			_VPAIDLoader = new Loader();
			_VPAIDUrl = new URLRequest(_VPAIDAdUrl);
			_VPAIDLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, VPAIDAdLoaded, false, 0, true);
			_VPAIDLoader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, VPAIDAdLoadError, false, 0, true);
			
			// add the ad
			_container.addChild(_VPAIDLoader);
			
			// load the ad
			_VPAIDLoader.load(_VPAIDUrl);
		}
		
		// the VPAID ad is loaded, communicate with ad to get it ready
		private function VPAIDAdLoaded(e:Event):void
		{
			// cleanup
			_VPAIDLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, VPAIDAdLoaded);
			_VPAIDLoader.contentLoaderInfo.removeEventListener(ErrorEvent.ERROR, VPAIDAdLoadError);
			
			// setup new wrapper class instance for ad (with appropriate listeners)
			_VPAIDAdWrapper = new VPAIDWrapper(_VPAIDLoader.content);
			_VPAIDAdWrapper.addEventListener(VPAIDEvent.AdImpression, VPAIDTrackAdImpression, false, 0, true);
			_VPAIDAdWrapper.addEventListener(VPAIDEvent.AdVideoComplete, VPAIDTrackAdVideoComplete, false, 0, true);
			_VPAIDAdWrapper.addEventListener(VPAIDEvent.AdLoaded, VPAIDAdReady, false, 0, true);
			_VPAIDAdWrapper.addEventListener(VPAIDEvent.AdStopped, endVPAIDAd, false, 0, true);
			
			// prepare ad
			_VPAIDAdWrapper.handshakeVersion("1.0");
			_VPAIDAdWrapper.initAd(_videoWidth, _videoHeight, "normal", 192, null, null);
		}
		
		// VPAID ad has indicated that it is ready to proceed, so get ready to start it
		private function VPAIDAdReady(e:*):void
		{
			// cleanup
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdLoaded, VPAIDAdLoaded);
			_VPAIDLoadingClip.visible = false;
			
			// if the ad was disposed during the loading process, abort playback
			if ( pStatus == "disposed" )
				return;
			
			// start the video
			_audioSystem.muteSounds();
			
			// let's go
			_VPAIDAdWrapper.startAd();
			
			if ( _VPAIDPauseOnPlay )
			{
				_VPAIDPauseOnPlay = false;
				_VPAIDAdWrapper.pauseAd();
				pStatus = "paused";
			}
			else
				pStatus = "playing";
		}
		
		// ad completed, close it up, show video end screen, and awards cards if needed
		private function endVPAIDAd(e:*):void
		{
			// cleanup
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdStopped, endVPAIDAd);
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdImpression, VPAIDTrackAdImpression);
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdVideoComplete, VPAIDTrackAdVideoComplete);
			_container.removeChild(_VPAIDLoader);
			
			// tracking
			_group.shellApi.triggerEvent("videoDone");
			fnTrack(AdTrackingConstants.TRACKING_VIDEO_COMPLETE);
			
			// close it
			pStatus = "done";
			showButtons(true);
			_audioSystem.unMuteSounds();
			
			// award item cards
			switch(_group.shellApi.profileManager.active.gender)
			{
				case SkinUtils.GENDER_MALE:
				case null:
					if(_giveItemMale)
						_card = _giveItemMale[_videoNumber];
					break;
				case SkinUtils.GENDER_FEMALE:
					if(_giveItemFemale)
						_card = _giveItemFemale[_videoNumber];
					break;
			}
			
			// if card exists and not yet awarded
			if ( _card != null )
			{
				_group.shellApi.getItem(_card, CardGroup.CUSTOM, true );
			}
		}
		
		// if the supplied tag is bad, display an error message
		private function VPAIDTagLoadError(e:ErrorEvent):void
		{
			_VPAIDTagLoader.removeEventListener(Event.COMPLETE, VPAIDTagLoaded);
			_VPAIDTagLoader.removeEventListener(ErrorEvent.ERROR, VPAIDTagLoadError);
			
			// notify user
			_VPAIDLoadingClip.tagLoadingErrorMessage.visible = true;
		}
		
		// if the act of loading the VPAID ad causes an issue, display an error message
		private function VPAIDAdLoadError(e:ErrorEvent):void
		{
			_VPAIDLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, VPAIDAdLoaded);
			_VPAIDLoader.contentLoaderInfo.removeEventListener(ErrorEvent.ERROR, VPAIDAdLoadError);
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdImpression, VPAIDTrackAdImpression);
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdVideoComplete, VPAIDTrackAdVideoComplete);
			
			// notify user
			_VPAIDLoadingClip.adLoadingErrorMessage.visible = true;
		}
		
		// used to confirm when the VPAID ad fired an "AdImpression" event on its end
		public function VPAIDTrackAdImpression(e:*):void
		{
			fnTrack("VpaidAdImpression"); // move event name into the core eventually
		}
		
		// used to confirm when the VPAID ad fired an "AdVideoComplete" event on its end
		public function VPAIDTrackAdVideoComplete(e:*):void
		{
			fnTrack("VpaidAdVideoComplete"); // move event name into the core eventually
		}
		
		// use to get rid of a VPAID ad that is running
		private function VPAIDDispose():void
		{
			// if ad isn't playing, no need to stop it
			if ( pStatus != "playing" )
			{
				// if ad is in the process of being set up, prevent it from starting
				if ( pStatus == "start" || pStatus == "replay" )
					pStatus = "disposed";
				return;
			}
			
			// cleanup
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdStopped, endVPAIDAd);
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdImpression, VPAIDTrackAdImpression);
			_VPAIDAdWrapper.removeEventListener(VPAIDEvent.AdVideoComplete, VPAIDTrackAdVideoComplete);
			_container.removeChild(_VPAIDLoader);
			
			// stop the ad
			_VPAIDAdWrapper.stopAd();
		}
		
		// UTILITY FUNCTIONS ///////////////////////////////////////////////////////////////////////
		
		/**
		 * Get Meta Data
		 * @param	aMetaData
		 */
		private function fnMetaData(aMetaData:Object):void
		{
			trace("Ad Video Player: Dimensions: " + aMetaData.width + " x " + aMetaData.height);
			_videoDuration = int(aMetaData.duration);
		}
		
		/**
		 * Security Errors
		 * @param	aEvent
		 */
		private function fnSecurityError(aEvent:SecurityErrorEvent):void
		{
			trace("Ad Video Player: Security Error: " + aEvent);
		}
		
		/**
		 * Asynchronous Errors
		 * @param	aEvent
		 */
		private function fnAsyncError(aEvent:AsyncErrorEvent):void
		{
			trace("Ad Video Player: Async Error: " + aEvent);
		}
		
		/**
		 * Send tracking call
		 * @param	aEvent	Name of event to track
		 */
		private function fnTrack(aEvent:String):void
		{
			if ((_campaignName != "No Campaign") && (_videoFile != null))
			{
				//var videoArray:Array = _videoFile.split("/");
				//var videoName:String = videoArray[videoArray.length-1];
				//videoName = videoName.substr(0, videoName.indexOf("."));
				// used to pass video name, now pass container name
				AdManager(_group.shellApi.adManager).track(_campaignName, aEvent, _choice, _container.name);
			}
			else if ( _VPAIDEnabled )
				AdManager(_group.shellApi.adManager).track(_campaignName, aEvent, _choice, _container.name);
		}
		
		/*
		* given a String block, replace the String find with the String replace 
		*/
		private function stringReplace(block:String, find:String, replace:String):String
		{
			return( block.split(find).join(replace) );
		}
		
		/*
		* given an array of tracking pixels, build a string with the syntax "var1=URL&var2=URL&var3=..."
		*/
		private function buildMultipleParameterString(parameters:Array):String
		{
			if ( parameters.length == 1 )
				return parameters[0];
			
			var parameterString:String = "";
			for ( var i:int = 0; i < parameters.length; i ++ )
			{
				if ( i > 0 )
					parameterString = parameterString.concat("&");
				parameterString = parameterString.concat("var", String ( i+1 ), "=", parameters[i]);
			}
			return parameterString;
		}
		
		/**
		 * Convert video URL for mobile phones 
		 * @param videoURL
		 * @return String
		 */
		private function convertVideoURL(videoURL:String):String
		{
			// video can be FLV or M4V (must be FLV if video plays in AS2 scenes such as MVUs or multiplayer rooms)
			var dpi:Number = Capabilities.screenDPI;
			// get widest device dimenion in inches (note that in FlashBuilder, the resolution is that of the monitor)
			var maxDimension:Number = Math.max(Capabilities.screenResolutionX/dpi, Capabilities.screenResolutionY/dpi);
			// if max dimension is 4 inches or less (phone size)
			if (maxDimension < 4.0)
			{
				trace("AdVideo: Use phone-size video for width " + maxDimension);
				// add _phone suffix to url
				var dotPos:int = videoURL.lastIndexOf(".");
				videoURL = videoURL.substr(0,dotPos) + "_phone" + videoURL.substr(dotPos);
			}
			else
			{
				trace("AdVideo: Use tablet-size video for width " + maxDimension);
			}
			return videoURL;
		}
		
		// get replay flag
		public function get replay():Boolean { return _replay; }
	}
}