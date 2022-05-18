package game.scenes.custom
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.profile.ProfileData;
	import game.managers.ScreenManager;
	import game.managers.ads.AdManager;
	import game.proxy.Connection;
	import game.scenes.hub.starcade.Starcade;
	import game.ui.popup.Popup;
	import game.util.ClassUtils;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	public class AdBasePopup extends Popup
	{
		/**
		 * Init popup 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			/// all ad poups use the same ID
			this.id = "AdPopup";
			// add game ID to "Start", "Win", "Lose", "Info", or "" popup type
			_popupType += super.campaignData.gameID;
			// add game ID to "Game" or "Quest" tracking choice
			_trackingChoice = _gameType + super.campaignData.gameID;
			// quest name used for pulling files from campaign folder
			_questName = AdUtils.convertNameToQuest(super.campaignData.campaignId);
			// check if arcade game
			if (super.campaignData.campaignId.indexOf(shellApi.arcadeGame) != -1)
				_isArcadeGame = true;
			//check if the scene needs to be loaded
			_popupScene = super.campaignData.popupScene;
			// if info popup then use path in poster xml
			if (this is AdInfoPopup)
			{
				_swfName = "/" + this.data.swfPath;
			}
			else
			{
				// else get swf name based on popup type plus game ID, if any
				_swfName = "/" + _popupType + ".swf";
			}
			// darken background
			super.darkenBackground = true;
			// assets will be found in limited folder
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			super.init(container);
			load();
		}
		
		/**
		 * Load specific swf for popup (start, win or lose)
		 */
		override public function load():void
		{
			// load swf
			_swfPath = shellApi.assetPrefix + groupPrefix + _questName + _swfName;
			trace("load swf: " + _swfPath);
			shellApi.loadFile(_swfPath, gotSwf);
		}
		
		/**
		 * Set return position for avatar 
		 * @param returnX
		 * @param returnY
		 */
		public function setReturnPos(returnX:Number, returnY:Number):void
		{
			_returnX = returnX;
			_returnY = returnY;
		}
		
		private function gotSwf(clip:MovieClip = null):void
		{
			if (clip == null)
			{
				trace("AdBasePopup: Can't find popup: " + _swfPath);
				return;
			}
			trace("AdBasePopup: loaded popup: " + _swfPath);
			
			// get popup swf
			super.screen = clip;
			
			loaded();
		}
		
		/**
		 * When assets loaded 
		 */
		override public function loaded():void
		{
			// center screen
			super.centerPopupToDevice();
			
			// add blackout area around wishlist
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0);
			shape.graphics.drawRect(-ScreenManager.GAME_WIDTH, -ScreenManager.GAME_HEIGHT, 3 * ScreenManager.GAME_WIDTH, 3 * ScreenManager.GAME_HEIGHT);
			shape.graphics.drawRect(0, 0, ScreenManager.GAME_WIDTH, ScreenManager.GAME_HEIGHT);
			shape.graphics.endFill();
			shape = Shape(super.screen.addChild(shape));
			shape.x = -ScreenManager.GAME_WIDTH/2;
			shape.y = -ScreenManager.GAME_HEIGHT/2;
			
			for(var clipName:String in screen) 
			{
				if (clipName.indexOf("messag") == 0)
				{
					screen[clipName].visible = false;
				}
			}
			AdUtils.setUpMessaging(shellApi, campaignData, screen);
			
			// if close button, then clear
			// NOTE: if you get a crash here, it is likely that the popup has TLF text in it. Change it to classic text.
			if (super.screen["closeButton"] != null)
				super.screen.closeButton = null;
			
			// set up clickURL button
			setupButton(super.screen["clickURL"], visitSponsorSite);
			// banner impression
			AdManager(shellApi.adManager).track(super.campaignData.campaignId, _popupType + AdTrackingConstants.TRACKING_BANNER_IMPRESSION);
			
			// set up quit button
			setupButton(super.screen["quitButton"], closePopup);
			
			// set up replay button
			if(super.screen["replayButton"] != null)
				setupButton(super.screen["replayButton"], replayGame);
			
			if(super.screen["highscore"] != null)
			{
				_highscore = super.screen["highscore"];
				getHighScores(_highscore.currentFrameLabel);
			}
			
			// setup popup with popup specific buttons
			setupPopup();
		
			super.loaded();
			
			// if previous popup is ad popup then delete it
			var scene:Group = shellApi.sceneManager.currentScene;
			this.id = "CurrentAdPopup";
			var popup:Popup = Popup(scene.getGroupById("AdPopup"));
			if (popup)
			{
				trace("AdBaseGroup: remove " + popup);
				popup.remove();
				// pause parent again because popup.remove() will unpause parent
				super.parent.pause(false);
			}
			this.id = "AdPopup";
		}
		
		/**
		 * Setup popup buttons (to be overridden) 
		 */
		protected function setupPopup():void
		{
			// to be overridden by start and win popups
		}
		
		/**
		 * Update video game button by name
		 */
		protected function updateVideoGameButton(buttonName:String, status:String):void
		{
			// update game buttons on video unit
			var gameButton:Entity = shellApi.sceneManager.currentScene.getEntityById(buttonName);
			if (gameButton != null)
			{
				var timeline:Timeline = gameButton.get(Timeline);
				if (timeline != null)
				{
					switch(status)
					{
						case "win":
							timeline.gotoAndStop("replayGame");
							break;
						
						case "lose":
							// check if have cards (first one)
							var cards:Vector.<String> = AdUtils.getCardList(shellApi, super.campaignData.campaignId, super.campaignData.gameID);
							// if cards and player doesn't have first one, then set button to replay for prize
							if ((cards.length != 0) && (!shellApi.itemManager.checkHas(cards[0], "custom")))
								timeline.gotoAndStop("replayForPrize");
							else
								timeline.gotoAndStop("replayGame");
							break;
					}
				}
			}
		}
		
		
		/**
		 * Setup single button 
		 * @param button movieClip
		 * @param action function that triggers when interacting with button
		 * @param hide make button invisible
		 * @param interation type such as click or down
		 */
		protected function setupButton(button:MovieClip, action:Function, hide:Boolean = true, interactionType:String = InteractionCreator.CLICK):Entity
		{
			// if no button then error
			if (button == null)
				trace("null button");
			else
			{
				// if button found
				// force button to vanish (it flashes otherwise)
				if (hide)
					button.alpha = 0;
				
				//create button entity
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(button.x, button.y));
				buttonEntity.add(new Display(button));
				buttonEntity.add(new Id(button.name));
				if (hide)
					buttonEntity.get(Display).alpha = 0;
				
				// need this because showing the popup a second time will not have buttons
				if (button.parent != super.screen)
					super.screen.addChild(button);
				
				// add entity to group
				super.addEntity(buttonEntity);
				
				// add tooltip
				ToolTipCreator.addToEntity(buttonEntity);
				
				// add interaction
				var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [interactionType], button);
				if (interactionType == InteractionCreator.CLICK)
					interaction.click.add(action);
				else if (interactionType == InteractionCreator.DOWN)
					interaction.down.add(action);
				
				// if multiple frames
				if (button.totalFrames != 1)
				{
					button.gotoAndStop(1);
					TimelineUtils.convertClip(button, this, buttonEntity, null, false);
				}
			}
			return buttonEntity;
		}
		
		/**
		 * Replay popup or quest game
		 * @param button
		 */
		protected function replayGame(button:Entity):void
		{
			playGame(true);
		}
		
		/**
		 * Play popup or quest game
		 * @param replay flag (default is playing first time)
		 */
		protected function playGame(replay:Boolean = false):void
		{
			trace("AdBasePopup :: playGame");
			// trigger tracking
			if (_isArcadeGame)
			{
				if (replay)
					shellApi.track(Starcade.TRACK_ARCADE_GAME_REPLAY, shellApi.arcadeGame, null, "Starcade");
				else
				{
					// if start popup
					// if played game already (won or lost), then trigger replay tracking with TRACKING_START_POPUP subchoice
					if (shellApi.checkEvent(_questName + _trackingChoice + "Completed"))
					{
						shellApi.track(Starcade.TRACK_ARCADE_GAME_REPLAY, shellApi.arcadeGame, null, "Starcade");
					}
					else
					{
						// else trigger start tracking
						shellApi.track(Starcade.TRACK_ARCADE_GAME_START, shellApi.arcadeGame, null, "Starcade");
					}
				}
			}
			else
			{
				if (replay)
					AdManager(shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_REPLAY, _trackingChoice, AdTrackingConstants.TRACKING_REPLAY_BUTTON);
				else
				{
					// if start popup
					// if played game already (won or lost), then trigger replay tracking with TRACKING_START_POPUP subchoice
					if (shellApi.checkEvent(_questName + _trackingChoice + "Completed"))
					{
						AdManager(shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_REPLAY, _trackingChoice, AdTrackingConstants.TRACKING_START_POPUP);
					}
					else
					{
						// else trigger start tracking
						AdManager(shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_START, _trackingChoice);
					}
				}
			}
			//if(_popupScene)
				//_gameType= "Quest";
			// load game based on game type Quest or Popup (popup)
			// _gameType might be null in which case default to Quest
			if ((_gameType == "Quest") || (_gameType == null))
			{
				trace("ATTEMPTING TO LOAD QUEST GAME, GAMETYPE == QUEST");
				// load game
				var sceneClass:Class = ClassUtils.getClassByName("game.scenes.custom.questGame.QuestGame");
				shellApi.loadScene(sceneClass);
				
				// close popup
				super.close();
			}
			else
			{
				// load popup game ("Popup")
				if(_popupScene)
				{
					trace("ATTEMPTING TO LOAD QUEST GAME, POPUPSCENE VAR == TRUE");
					// load game
					var scene:Class = ClassUtils.getClassByName("game.scenes.custom.questGame.QuestGame");
					shellApi.loadScene(scene);
					
					// close popup
					super.close();
				}
				else
				{
					trace("ATTEMPTING TO LOAD POPUP GAME");
					var popupClass:Class = ClassUtils.getClassByName(super.campaignData.gameClass);
					if(!popupClass)
					{
						trace( "Error :: AdStartGamePopup : " + super.campaignData.gameClass + " is not a valid class name." );
						return;
					}
					var popup:Popup = shellApi.sceneManager.currentScene.addChildGroup(new popupClass()) as Popup;
					popup.campaignData = super.campaignData;
					popup.init( shellApi.sceneManager.currentScene.overlayContainer );
				}
			}
		}
		
		protected function loadGamePopup(className:String, suffix:String = null):Popup
		{
			var adManager:AdManager = AdManager(shellApi.adManager);
			if (suffix == null)
				suffix = adManager.questSuffix;
			else
			{
				// if suffix is true for single quests, then set to empty string
				if (suffix == "true")
					suffix = "";
				adManager.questSuffix = suffix;
			}
			trace("AdInterior: loadPopup suffix: " + suffix);
			
			// get popup class
			var popupClass:Class = ClassUtils.getClassByName("game.scenes.custom." + className);
			if(!popupClass)
			{
				trace( "Error :: AdStartGamePopup : " + "game.scenes.custom." + className + " is not a valid class name." );
				return null;
			}
			var popup:Popup = shellApi.sceneManager.currentScene.addChildGroup(new popupClass()) as Popup;
			popup.campaignData = super.campaignData;
			popup.init( shellApi.sceneManager.currentScene.overlayContainer );
			return popup;
		}
		
		/**
		 * Visit sponsor site and apply any delay 
		 * @param button
		 */
		private function visitSponsorSite(button:Entity):void
		{
			AdManager.visitSponsorSite(shellApi, super.campaignData.campaignId, triggerSponsorSite);
		}
		
		/**
		 * Visit sponsor site when delay ends 
		 * 
		 */
		private function triggerSponsorSite():void
		{
			// click to sponsor tracking
			AdManager(shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _popupType);
			// open sponsor URL from campaign.xml
			AdUtils.openSponsorURL(shellApi, AdvertisingConstants.CAMPAIGN_FILE, super.campaignData.campaignId, _choice, _popupType);
		}
		
		/**
		 * Return to ad interior scene 
		 */
		protected function returnToInterior():void
		{
			// if arcade game, then go back to arcade
			if (_isArcadeGame)
			{
				returnPreviousScene();
			}
			else
			{
				// go back to interior scene
				var sceneClass:Class = ClassUtils.getClassByName("game.scenes.custom.questInterior.QuestInterior");
				// tell adManager we are returning to interior
				AdManager(shellApi.adManager).returnToInterior = true;
				// determine if won quest by class name of popup
				var className:String = ClassUtils.getNameByObject(this);
				AdManager(shellApi.adManager).wonQuest = (className.indexOf("Win") != -1);
				// if no return Y value, then use default for scene
				if (_returnY == 0)
					shellApi.loadScene(sceneClass);
				else
					shellApi.loadScene(sceneClass, _returnX, _returnY);
			}
			// close popup
			super.close();
		}
		
		/**
		 * Close popup (default behavior, but is overriden by Quest popups)
		 * @param button
		 */
		protected function closePopup(button:Entity):void
		{
			// if start, win or lose game popup then stop any campaign music
			if ((this is AdStartGamePopup) || (this is AdWinGamePopup) || (this is AdLoseGamePopup))
			{
				AdManager(shellApi.adManager).stopCampaignMusic();
			}
			// if arcade game, then go back to arcade
			if (_isArcadeGame)
			{
				returnPreviousScene();
			}
			super.close();
		}
		
		/**
		 * Close popup when playing video next
		 * @param button
		 */
		protected function closePopupForVideo():void
		{
			// stop any campaign music and mute audio for video
			AdManager(shellApi.adManager).stopCampaignMusic(true);
			
			super.close();
		}
		
		private function returnPreviousScene():void
		{
			shellApi.arcadeGame = null;
			var destScene:String = shellApi.sceneManager.previousScene;
			var destSceneX:Number = shellApi.sceneManager.previousSceneX;
			var destSceneY:Number = shellApi.sceneManager.previousSceneY;
			var destSceneDirection:String = shellApi.sceneManager.previousSceneDirection;
			shellApi.loadScene(ClassUtils.getClassByName(destScene), destSceneX, destSceneY, destSceneDirection);
		}

		//highscores
		public function getHighScores(gameName:String):void
		{
			if (gameName == "kiosk")
				return;
			
			// clear fields
			//TextField(_highscore.getChildByName("score")).text = "0";
			
			// set params to send to server
			var vars:URLVariables = new URLVariables();
			
			// if not guest and is not mobile
			if ((!super.shellApi.profileManager.active.isGuest) && (!AppConfig.mobile))
			{
				var profile:ProfileData = super.shellApi.profileManager.active;
				vars.username = profile.login;
				vars.passhash = profile.pass_hash;
				vars.dbid = profile.dbid;
			}
			else
			{
				vars.username = "";
				vars.passhash = "";
				vars.dbid = "";
			}
			vars.count = 3;
			vars.gamename = _highscore.currentFrameLabel;
			super.shellApi.logWWW("getting high scores for " + vars.gamename);
			// make php call to server
			var connection:Connection = new Connection();
			connection.connect(super.shellApi.siteProxy.secureHost + "/games/interface/get_highscores.php", vars, URLRequestMethod.POST, Command.create(getScoresCallback, gameName), getScoresError);
			
			if (AppConfig.mobile)
			{
				var gm:String = gameName.toLowerCase();
				var so:SharedObject = SharedObject.getLocal("arcade", "/");
				so.objectEncoding = ObjectEncoding.AMF0;
				var score:String = "0";
				if (so.data[gm] != null)
					score = String(so.data[gm]);
				var tf:TextField = _highscore.getChildByName("score") as TextField;
				if(tf != null)
					tf.text = score;
			}
		}
		
		/**
		 * When win.php callback is received from server 
		 * @param e
		 */
		private function getScoresCallback(e:Event, gameName:String):void
		{
			// parse data
			var return_vars:URLVariables = new URLVariables(e.target.data);
			// check answer
			super.shellApi.logWWW("getscorescallback : " + return_vars.answer);
			switch (return_vars.answer)
			{
				case "ok": // if successful
					//answer=ok&high_scores_json={"personal_highscore":{"highscore":"0"},"weekly_highscore":{"highscore":0,"look":"string","name":"playerName"}}
					trace("getScoresCallback Success: " + gameName);
					super.shellApi.logWWW("getScoresCallback Success: " + gameName);
					// trim data to what follows equals sign
					var index:int = e.target.data.indexOf("json=");
					var data:String = unescape(e.target.data.substr(index+5));
					trace("getScoresCallback  Data: " + data);
					super.shellApi.logWWW("getScoresCallback Data: " + data);
					// convert to json object
					var json:Object = JSON.parse(data);
					super.shellApi.logWWW("getScoresCallback parsed Data: " + json);
					for (var sc:String in json) 
					{
						super.shellApi.logWWW(sc);
						if(sc == "all_time_highscore")
						{
							for (var i:Number=0; i<3; i++) 
							{
								if(json["all_time_highscore"][i] != null)
								{
									trace("setting score: " + json["all_time_highscore"][i].highscore);
									var score:String = json["all_time_highscore"][i].highscore;
									TextField(_highscore.getChildByName("score" + i.toString())).text = score.toLowerCase();
									
								}
							}
						}
					}
					
					// set personal high score on game console
					var personal:String = "0";
					if (data.indexOf("personal_highscore") != -1)
						personal = json.personal_highscore.highscore;
					
					// set weekly high score on game console
					var weekly:String = "370"; // default if errors or no one has played yet
					if (data.indexOf("weekly_highscore") != -1)
					{
						var wscore:String = json.weekly_highscore.highscore;
						super.shellApi.logWWW("wscore: " + wscore);
						// don't use zero
						if (wscore != "0")
							weekly = wscore;
					}
					
					// update text fields
					
					break;
				
				default: // if errors
					trace("getScoresCallback Error: " + return_vars.answer);
					break;
			}
		}
		private function getScoresError(e:IOErrorEvent):void
		{
			trace("getScores error: " + e.errorID)
		}
		protected var _gameType:String; // "Game" or "Quest"
		protected var _questName:String; // campaign name for quest
		protected var _isArcadeGame:Boolean = false;
		protected var _returnX:Number = 0;
		protected var _returnY:Number = 0;
		protected var _swfName:String;
		protected var _swfPath:String; // full path name for swf that includes quest name
		protected var _popupType:String; // "Start", "Win", "Lose" or "" followed by game ID
		protected var _trackingChoice:String; // "Game" or "Quest" followed by game ID (no longer used)
		private var _choice:String = "Popup";
		protected var _popupScene:Boolean=false; //for popup game that uses a quest game template (force a new scene load)
		protected var _highscore:MovieClip;

	}
}