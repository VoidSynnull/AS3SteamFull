package game.scene.template.ads
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterProximity;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.TargetEntity;
	import game.components.motion.Threshold;
	import game.components.scene.RainRandomClips;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.data.profile.ProfileData;
	import game.data.scene.characterDialog.DialogData;
	import game.managers.ads.AdManager;
	import game.nodes.entity.character.NpcNode;
	import game.proxy.Connection;
	import game.proxy.browser.AdProxyUtils;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ui.CardGroup;
	import game.scenes.carnival.shared.ferrisWheel.FerrisWheelGroup;
	import game.scenes.custom.AdAnimPopup;
	import game.scenes.custom.AdPopup;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.hub.arcadeGame.ArcadeGame;
	import game.scenes.hub.avatarShop.Colorizer;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.SetVisibleAction;
	import game.systems.actionChain.actions.ShowOverlayAnimAction;
	import game.systems.actionChain.actions.StopFollowAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.scene.DoorSystem;
	import game.systems.scene.RainRandomClipsSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	import org.hamcrest.object.nullValue;
	
	public class AdInteriorScene extends PlatformerGameScene
	{
		public function AdInteriorScene()
		{
			super();
		}
		
		/**
		 * Initialize scene before loading assets 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.shellApi.logWWW("AdInteriorScene :: init");
			// get ad manager
			_adManager = AdManager(super.shellApi.adManager);
			var _adDataTemp:AdData = _adManager.getAdData(_adManager.mainStreetType, false, false);
			
			var campaignData:CampaignData;
			if (_adDataTemp != null)
				campaignData = _adManager.getActiveCampaign(_adDataTemp.campaign_name);
			if ((campaignData != null) && (campaignData.popupScene == true))
			{
				_adData = _adManager.getAdData(_adManager.mainStreetType, false, false);
				super.shellApi.logWWW(_adData);
			}
			else
			{
				super.shellApi.logWWW("AdIntriorScene - get int ad");
				// get ad data from door entered
				_adData = _adManager.interiorAd;
				
			}
			// if ad data and campaign type is mobile map ad (can be MMQ)
			/*
			if ((_adData) && (_adData.campaign_type.indexOf(AdCampaignType.MOBILE_MAP_AD_BASE) != -1))
			{
				// set MMQ flag
				trace("AdInteriorScene :: is MMQ interior");
				_isMMQ = true;
			}
			*/
			if (_adData == null && shellApi.forcedAdData == null)
			{
				trace("AdInteriorScene :: no campaign data, pulling from LSO");
				super.shellApi.logWWW("AdInteriorScene :: no campaign data, pulling from LSO");
				// get ad data from custom island
				AdProxyUtils.getCampaignFromCustomIsland(_adManager);
				// pull data again for main street ad on custom island (off-main is expected to be true)
				_adData = _adManager.getAdData(_adManager.mainStreetType, true, false, AdvertisingConstants.AD_ISLAND);
				
			}
			if(shellApi.forcedAdData != null && _adData == null)
			{
				trace("AdInteriorScene :: forced ad found");
				_adData = shellApi.forcedAdData;
			}
			// if data missing then pull from LSO for custom island (used when coming from AS2)
			
			
			// if ad data found
			if (_adData != null)
			{
				super.shellApi.logWWW("AdInteriorScene :: ad Data not null");
				// get campaign name
				_campaignName = _adData.campaign_name;
				// get video file (need this when coming from AS2)
				_adData.videoFile = _adData.campaign_file2;
				
				// get name for base interior, usually ends in "Quest"
				_interiorBaseName = AdUtils.convertNameToQuest(_campaignName);
				
				// determine scene name based on interior base name
				// if quest game and not coming from AS2 (add suffix for multi-quests)
				if (this is QuestGame)
					_sceneName = _interiorBaseName + "_Game" + _adManager.questSuffix;
				else 
				{
					// if interior scene
					if(_adManager.interiorSuffix != "")
						_sceneName = _adManager.interiorSuffix;
					else
						_sceneName = _interiorBaseName + "_Interior";
				}
				
				trace("AdInteriorScene :: scene name: " + _sceneName);
				super.shellApi.logWWW("AdInteriorScene :: scene name: " + _sceneName);
				// get group prefix for files
				super.groupPrefix = "scenes/" + AdvertisingConstants.AD_PATH_KEYWORD + "/" + _sceneName + "/";
				super.init(container);
			}
			else
			{
				trace("AdInteriorScene :: error: no data for ad interior street: " + _campaignName);
				super.shellApi.logWWW("AdInteriorScene :: error: no data for ad interior street: " + _campaignName);
			}
		}
		
		/**
		 * Add groups to scene 
		 */
		override protected function addGroups():void
		{
			super.addGroups();
			super.shellApi.logWWW("AdIntriorScene :: addGroups");
			var hasBranding:Boolean = false;
			var videoList:Array = [];
			
			var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			var hasPrize:Boolean = false;
			
			// start branding timer if branded (if no branding inside, tne create an invisible clip that has "branded" in name)
			for (var i:int = this.hitContainer.numChildren - 1; i != -1; i--)
			{
				var clip:DisplayObject = this.hitContainer.getChildAt(i);
				// if clip has branded in name
				if(clip.name.toLowerCase().indexOf("branded") != -1)
				{
					hasBranding = true;
					if (brandedClips == null)
						brandedClips = [];
					brandedClips.push(clip);
				}
				else if (clip.name.indexOf("videoContainer") != -1)
				{
					videoList.push(clip);
				}
				else if (clip.name.indexOf("messag") == 0)
				{
					clip.visible = false;
				}
				else if(clip.name.indexOf("item")== 0)
				{
					if(shellApi.checkHasItem(clip.name.substr(4)))
					{
						clip.visible = false;
					}
					else
					{
						itemGroup.addSceneItemFromDisplay(clip as DisplayObjectContainer, clip.name);
						hasPrize = true;
					}
				}
				else if(clip.name.indexOf("all_time")!= -1)
				{
					getHighScores(clip.name.substring(0,clip.name.length-9));
				}
			}
			clip = this.hitContainer.getChildByName("ferrisAxle");
			if(clip)
			{
				var grp:FerrisWheelGroup = new FerrisWheelGroup();
				addChildGroup( grp );
				
				grp.beginCreate( hitContainer as MovieClip, clip as MovieClip, 20 );
				grp.addArms( "arm" );
				grp.addSwings( "seat", true, "ferrisPlat" );
				
				grp.start();
			}
			if(hasPrize)
			{
				itemGroup.addItemHitSystem();
			}
			// 
			if (hasBranding)
			{
				// add videos
				for each (var video:MovieClip in videoList)
				{
					brandedClips.push(video);
				}
				// update scene based on branding
				AdUtils.interactWithCampaign(this, _campaignName);
			}
			
			// track entered scene
			_adManager.track(_campaignName, AdTrackingConstants.TRACKING_ENTERED_SCENE, _sceneName);
			
			// if first time in interior, then call EnteredAdIsland or EnteredFromIsland
			if ((_adManager.isInterior) && (!_adManager.wasInterior))
			{
				// clear return to interior flag
				_adManager.returnToInterior = false;
				trace("AdInteriorScene: first time in interior");
				
				// if MMQ
				if (_isMMQ)
					_adManager.track(_campaignName, AdTrackingConstants.TRACKING_ENTERED_AD_ISLAND, _sceneName);
				else
					_adManager.track(_campaignName, AdTrackingConstants.TRACKING_ENTERED_FROM_ISLAND, _sceneName);
				// start ad timer
				_adManager.startActivityTimer(_campaignName, true);
			}
			
			// get tracking xml
			var vXML:XML = super.getData("tracking.xml", false);
			if (vXML == null)
				trace("AdInteriorScene :: error: missing tracking.xml");
			else
			{
				// if tracking xml found
				// parse xml
				trackingData = AdTrackingParser.parse(vXML);
				
				// get hotspots xml and parse
				vXML = super.getData("hotspots.xml", false);
				var vHotSpotsData:Object = AdHotSpotParser.parse(vXML);
				
				// add any video
				var videoGroup:AdVideoGroup = new AdVideoGroup();
				videoGroup.setupAdScene(this, _hitContainer, _adData, vHotSpotsData, trackingData);
				
				// ad any posters
				var posterGroup:AdPosterGroup = new AdPosterGroup(null, shellApi);
				posterGroup.setupAdScene(this, _hitContainer, _adData, vHotSpotsData, trackingData);
			}
			
			AdUtils.setUpMessaging(shellApi, _adData, _hitContainer);
		}
		
		//highscores
		public function getHighScores(gameName:String):void
		{
			if (gameName == "kiosk")
				return;
			
			// clear fields
			//_hitContainer[gameName + "_yours"].text = "0";
			_hitContainer[gameName + "_all_time"].text = "0";
			
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
			vars.gamename = gameName.toLowerCase();
			
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
				var tf:TextField = _hitContainer[gameName + "_yours"];
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
							//for (var i:Number=0; i<3; i++) 
							///{
								if(json["all_time_highscore"] != null)
								{
									trace("setting score: " + json["all_time_highscore"].highscore);
									var score:String = json["all_time_highscore"].highscore;
									_hitContainer[gameName + "_all_time"].text = score.toLowerCase();
									
								}
							//}
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
		
		/**
		 * If error when calling win.php
		 * @param e
		 */
		private function getScoresError(e:IOErrorEvent):void
		{
			trace("getScores error: " + e.errorID)
		}
		/**
		 * when all characters loaded 
		 */
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
					
					if (npcEntity.has(CharacterProximity))
					{
						// get and set current npc dialog
						// (seems ridiculous but fixes the problem with the NPC not speaking when first clicked)
						// TODO :: This should really just be and event id for dialog, could be set with CharacterProximity. - bard
						// TODO :: Better yet this proximiy business could just be its own system
						var charProximity:CharacterProximity = npcEntity.get(CharacterProximity);
						charProximity.defaultDialog = npcEntity.get(Dialog).current;
						Dialog(npcEntity.get(Dialog)).current = charProximity.defaultDialog;
						
						// setup NPC for proximity trigger of dialog				
						// setup tresholds for entering and exiting
						var threshold:Threshold = new Threshold( "x", "<>", npcEntity, charProximity.proximity );
						threshold.entered.add( Command.create(triggerNpcProximity,npcEntity) );
						threshold.exitted.add( Command.create(restoreNpcProximity,npcEntity) );
						var proxy:Entity = EntityUtils.createSpatialEntity(this, new Sprite(), EntityUtils.getDisplayObject(shellApi.player).parent);
						proxy.add(new FollowTarget(shellApi.player.get(Spatial))).add(threshold);
						//shellApi.player.add( threshold );
						
						// add threshold system is not added
						if (!shellApi.currentScene.getSystem(ThresholdSystem))
						{
							!shellApi.currentScene.addSystem(new ThresholdSystem());
						}
					}
					
					// impression tracking if setup in xml
					var id:String  = npcEntity.get(Id).id;
					var vNode:Object = trackingData[id];
					// if node found then track
					if (vNode != null)
					{
						if (vNode.triggerImpression == "true")
						{
							_adManager.track(_campaignName, AdTrackingConstants.TRACKING_NPC_IMPRESSION, npcEntity.get(Id).id);
						}
					}
				}
			}
			
			super.allCharactersLoaded();
			
			// sort bitmapped npcs so they are placed behind player
			AdSceneGroup.sortBitmapNPCs(super.systemManager.getNodeList(NpcNode), super.shellApi.player);
		}
		
		private function triggerNpcProximity(charEntity:Entity):void
		{
			// check if target entity
			var targetEntity:TargetEntity = shellApi.player.get(TargetEntity);
			// if no target entity or didn't click on NPC then can trigger
			if ((targetEntity == null) || (targetEntity.active))
			{
				// send event to framework
				shellApi.triggerEvent("npcProximity_"+charEntity.get(Id).id);
				// reset dialog to current
				var proximity:CharacterProximity = charEntity.get(CharacterProximity);
				charEntity.get(Dialog).current = proximity.defaultDialog;
			}
		}
		
		/**
		 * Restore NPC dialog when when avatar walks away
		 * @param charEntity
		 */
		private function restoreNpcProximity(charEntity:Entity):void
		{
			var proximity:CharacterProximity = charEntity.get(CharacterProximity);
			if ((charEntity != null) && (proximity.defaultDialog != null))
			{
				charEntity.get(Dialog).current = proximity.defaultDialog;
			}
		}
		
		override public function loaded():void
		{
			// set up events from xml
			questInteriorEvents = {};
			var eventsXML:XML = super.getData("events.xml");
			if (eventsXML)
				parseEvents(eventsXML);
			
			// catch events that get triggered
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			// catch dialog starts for NPCs
			var npcNodes:NodeList = super.systemManager.getNodeList(NpcNode);
			for( var node:NpcNode = npcNodes.head; node; node = node.next )
			{
				Dialog(node.entity.get(Dialog)).start.add(Command.create(handleDialogStart,node.entity.get(Id).id));
			}
			
			// if initializing player parts, then process
			if (questInteriorEvents["init_player"])
				processEvent(questInteriorEvents["init_player"]);
			
			// trigger any initial dialog for any NPCs or other initialization events
			super.shellApi.triggerEvent("initScene", false, false);
			
			// this must happen last because AdManager will set returnToInterior to false in handleSceneLoaded()
			super.loaded();
		}		
		
		/**
		 * when npc clicked 
		 * @param clickedEntity
		 */
		private function npcClicked(clickedEntity:Entity):void
		{
			// if scene has tracking data
			if (trackingData != null)
			{
				var id:String = clickedEntity.get(Id).id;
				var vNode:Object = trackingData[id];
				// if node found then track
				if (vNode != null)
					_adManager.track(_campaignName, vNode.event, vNode.choice, vNode.subchoice);
			}
		}
		
		/**
		 * Parse events xml 
		 * @param eventsXML
		 */
		private function parseEvents(eventsXML:XML):void
		{
			// get xml list
			var groups:XMLList = eventsXML.children();
			// for each group in xml
			for (var i:int = groups.length() - 1; i != -1; i--)
			{
				// get group
				var groupArray:Array = [];
				var groupXML:XML = groups[i];
				
				// set object in events based on type and id (type_id)
				questInteriorEvents[groupXML.attribute("type") + "_" + groupXML.attribute("id")] = groupArray;
				
				// get events in group
				var groupEvents:XMLList = groupXML.children();
				// for each group event
				for (var j:int = groupEvents.length() - 1; j != -1; j--)
				{
					var eventArray:Array = [];
					var groupEventXML:XML = groupEvents[j];
					
					// get params in event
					var params:XMLList = groupEventXML.children();
					for (var k:int = params.length() - 1; k != -1; k--)
					{
						// add param to array of params
						eventArray.unshift(String(params[k].valueOf()));
					}
					
					// convert any animations to timelines ["playAnim", animClipName, endlabelName, callback]
					if (eventArray[0] == "playAnim")
					{
						// get name of animation clip
						var animName:String = eventArray[1];
						// get clip in scene in hit container
						var animClip:MovieClip = this._hitContainer[animName];
						// convert clip to timeline if not already created
						if ((animClip) && (this.getEntityById(animName) == null))
						{
							var vTimeline:Entity = TimelineUtils.convertClip(animClip, this);
							// stop on first frame
							if (vTimeline)
								vTimeline.get(Timeline).gotoAndStop(0);
						}
					}
					// add event array to group array
					groupArray.unshift(eventArray);
				}
			}
		}
		
		/**
		 * To capture any dialog starts
		 * @param dialogData
		 * @param id ID of npc
		 */
		private function handleDialogStart(dialogData:DialogData, id:String):void
		{
			// look for any dialog start event in events object
			var eventList:Array = questInteriorEvents["dialogStart_" + id];
			// if found, then process
			if (eventList)
				processEvent(eventList);
		}
		
		/**
		 * To capture any game triggers 
		 * @param event
		 * @param makeCurrent
		 * @param init
		 * @param removeEvent
		 */
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			trace("QuestInterior: handleEvent: " + event);
			// event can be a pipe-delimited string
			var arr:Array = event.split("|");
			// get event as first item in array
			event = arr.shift();
			
			// look for any triggered event in events object
			var eventList:Array = questInteriorEvents["triggered_" + event];
			
			// if returned to interior get any return events (event name followed by "Return" or "Win" in xml)
			if (_returnToInterior)
			{
				trace("QuestInterior: returning to interior");
				
				// if won quest, then look for win event list
				if (AdManager(super.shellApi.adManager).wonQuest)
				{
					var eventListReturn:Array = questInteriorEvents["triggered_" + event + "Win"];
				}
				
				// use standard return event list if no win event list
				if (eventListReturn == null)
				{
					eventListReturn = questInteriorEvents["triggered_" + event + "Return"];
					if (eventListReturn != null)
					{
						trace("QuestInterior: found Return events");
					}
				}
				else
				{
					trace("QuestInterior: found Win events");
				}
			}
			
			// if found in event list, then process
			// order of priority: win list, return list, event list
			if (eventListReturn)
				processEvent(eventListReturn);
			else if (eventList)
				processEvent(eventList);
			else
			{
				// if not found in event list (xml) then try to call function by name
				var funct:Object;
				// check if game class has public function that matches event name
				try
				{
					funct = this[event];
				}
				catch(e:Error)
				{
					trace("QuestInterior: no matching function to " + event);
					return;
				}
				// call function
				switch (arr.length)
				{
					case 0:
						funct();
						break;
					case 1:
						funct(arr[0]);
						break;
					case 2:
						funct(arr[0], arr[1]);
						break;
					default:
						trace("too many arguments for function: " + arr.length);
						break;
				}
			}
		}
		
		/**
		 * Process the event list and activate events
		 * @param eventList Array of events, each with their own params
		 */
		private function processEvent(eventList:Array):void
		{
			var callback:Function = null;
			var targetX:Number;
			var targetY:Number;
			
			// clear previous action chain, if any
			if (_actionChain)
			{
				_actionChain.clearActions();
			}
			
			// create new action chain
			_actionChain = new ActionChain(this);
			
			var charEntity:Entity;
			
			for each (var event:Array in eventList)
			{
				// get first value, which is name of event
				switch(event[0])
				{
					case "lockInput": // ["lockInput"] // lock player input as event or for action chain
						
						// if this is the only event, then lock input now
						if (eventList.length == 1)
						{
							SceneUtil.lockInput(this, true);
							_actionChain = null;
						}
						else
						{
							// else assumes action chain
							_actionChain.lockInput = true;
						}
						break;
					
					case "wait": // ["wait", delay] wait
						
						// get part id and value
						var delay:Number = Number(event[1]);
						
						// set part on player action and don't save
						_actionChain.addAction( new WaitAction(delay) );
						break;
					
					case "talk": // ["talk", charID, sayID] make entity (npc or player) talk by calling dialog ID
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						// get dialog ID
						var sayID:String = String(event[2]);
						
						// add talk action
						_actionChain.addAction( new TalkAction(charEntity, sayID) );
						break;
					
					case "hide": // ["hide", charID] hide entity
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						
						// add hide action
						_actionChain.addAction( new SetVisibleAction(charEntity, false) );
						break;
					
					case "show": // ["show", charID] hide entity
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						
						// add hide action
						_actionChain.addAction( new SetVisibleAction(charEntity, true) );
						break;
					case "triggerEvent":
						_actionChain.addAction(new TriggerEventAction(event[1]));
					case "setPart": // ["setPart", partID, partValue, npcID] set player part
						
						// get part id and value
						var partID:String = String(event[1]);
						var partValue:String = String(event[2]);
						if (event.length > 3)
							charEntity = getEntityByID(String(event[3]));
						else
							charEntity = super.shellApi.player;
						
						// set part on char entity action and don't save
						_actionChain.addAction( new SetSkinAction(charEntity, partID, partValue, false, true) );
						break;
					
					case "setSpatial": // ["setSpatial", npcID, coords] sets spatial for npc
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						// get coordinates
						var arr:Array = event[2].split(",");
						targetX = Number(arr[0]);
						targetY = Number(arr[1]);
						
						// set coordinates of npc
						_actionChain.addAction( new SetSpatialAction(charEntity, new Point(targetX, targetY)) );
						// this prevents any current moveToTarget setting to resume
						var isPlayer:Boolean = (charEntity == super.shellApi.player);
						_actionChain.addAction( new StopFollowAction(charEntity, isPlayer, isPlayer) );
						break;
					
					case "moveToTarget": // ["moveToTarget", npcID, target, wait] move npc to target
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						// get coordinates
						arr = event[2].split(",");
						targetX = Number(arr[0]);
						targetY = Number(arr[1]);
						// get wait flag
						var wait:Boolean = false;
						if (event.length > 3)
							wait = (event[3] == "true");
						// other values that can come from xml
						var minDist:Point;
						var directionTargetX:Number;
						var ignorePlatformTarget:Boolean = false;
						
						// move to target
						var actionCommand:MoveAction = new MoveAction(charEntity, {x:targetX, y:targetY},null, NaN, true);
						actionCommand.noWait = !wait;
						_actionChain.addAction(actionCommand);
						break;
					
					case "followPlayer": // ["followPlayer", npcID] follow player around
						
						// get NPC entity
						charEntity = getEntityByID(String(event[1]));
						CharUtils.followEntity(charEntity, super.shellApi.player, new Point(120,120));
						break;
					
					case "stopFollow": // ["stopFollow", npcID] stop following target
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						
						isPlayer = (charEntity == super.shellApi.player);
						_actionChain.addAction( new StopFollowAction(charEntity, isPlayer, isPlayer) );
						break;
					
					case "showOverlayAnim": // ["showOverlayAnim", swfPath, scaleMode] // load and show overlay animation over scene
						
						// get swf path
						var swfPath:String = String(event[1]);
						var scaleMode:String;
						// scale mode: scaleToFill
						if (event.length > 2)
							scaleMode = event[2];
						// add overlay animation action
						_actionChain.addAction( new ShowOverlayAnimAction(swfPath, scaleMode) );
						break;
					
					case "playAnim": //["playAnim", animClipName, startLabelName, endlabelName] play animation in interactive layer
						
						// get clip name
						var clipName:String = String(event[1]);
						// get start label name
						var startLabelName:String;
						if (event.length > 2)
							startLabelName = event[2];
						// get end label name
						var endLabelName:String;
						if (event.length > 3)
							endLabelName = event[3];
						
						// get entity by name
						var entity:Entity = this.getEntityById(clipName);
						// if entity found, add timeline action
						if (entity)
							_actionChain.addAction( new TimelineAction(entity, startLabelName, endLabelName) );
						break;
					
					case "setZoneTrigger": // ["setZoneTrigger", clipName, event] set zone to trigger event
						
						// get clip name (NOTE: name must contain "zone" for this to work)
						clipName = String(event[1]);
						// get event name
						var eventName:String = event[2];
						var listenOnceString:String = event[3];
						var exitEventName:String = event[4];
						var listenOnce:Boolean;
						if(listenOnceString == "false")
							listenOnce = false;
						else
							listenOnce = true;
						this.addSystem( new ZoneHitSystem(), SystemPriorities.checkCollisions);
						
						entity = getEntityById(clipName);
						if (entity != null)
						{
							var zone:Zone = new Zone();
							zone.entered.add(Command.create(enteredZone, eventName, listenOnce));
							if(exitEventName != null)
								zone.exitted.add(Command.create(enteredZone, exitEventName, listenOnce));
							entity.add(zone);
						}
						else
						{
							trace("zone not found with id " + clipName);
						}
						break;
					
					case "makeInactive": // ["makeInactive", npcNames] make NPCs inactive
						
						// get NPC names (comma-delimited list)
						var NPCs:Array = String(event[1]).split(",");
						
						for each (var npcID:String in NPCs)
						{
							entity = getEntityById(npcID);
							if (entity != null)
							{						
								entity.remove(Interaction);
								ToolTipCreator.removeFromEntity(entity);
							}
						}
						break;
					
					case "setCameraTarget": // ["setCameraTarget", entityID] set camera to look at target
						entity = getEntityById(event[1]);
						_actionChain.addAction( new PanAction(entity) );
						break;
					
					case "awardCard":  // ["awardCard", cardNumber] award a card to the player (not part of action chain)
						var card:String = String(event[1]);
						if (!super.shellApi.checkHasItem(card, CardGroup.CUSTOM))
						{
							// get card and animate
							super.shellApi.getItem(card, CardGroup.CUSTOM, true);
						}
						break;
					
					case "multiPlayer":
						// start multiplayer
						_isMultiPlayer = true;
						shellApi.smartFoxManager.disconnected.addOnce(onDisconnect);
						shellApi.sceneManager.enableMultiplayer(false, true, false);
						break;
					
					case "callFunction": // ["callFunction", functionName] call function in this class or superclass
						
						// get function name
						var functName:Function = this[String(event[1])];						
						switch(event.length)
						{
							case 1:
								trace("QuestInterior: Missing function name for callFunction action!");
							case 2:
								_actionChain.addAction( new CallFunctionAction(functName) );
								break;
							case 3:
								_actionChain.addAction( new CallFunctionAction(functName, String(event[2])) );
								break;
							case 4:
								_actionChain.addAction( new CallFunctionAction(functName, String(event[2]), String(event[3])) );
								break;
							case 5:
								_actionChain.addAction( new CallFunctionAction(functName, String(event[2]), String(event[3]), String(event[4])) );
								break;
							default:
								trace("QuestInterior: callFunction can't handle " + event.length + " number of arguments!");
								break;
						}
						break;
					case "openColorizer":
						this.addChildGroup(new Colorizer(this.overlayContainer));
						break;
				}
			}
			if (_actionChain)
			{
				_actionChain.execute();
			}
		}
		
		/**
		 * When enter zone
		 * @param zoneId
		 * @param characterId
		 * @param event
		 */
		public function enteredZone(zoneId:String, characterId:String, event:String, listenOnce:Boolean=true):void
		{
			if (characterId == "player")
			{
				if(listenOnce)
					this.getEntityById(zoneId).remove(Zone);
				super.shellApi.triggerEvent(event);
			}
		}
		
		/**
		 * Get entity by ID 
		 * @param npcID
		 * @return entity
		 */
		private function getEntityByID(npcID:String):Entity
		{
			var charEntity:Entity;
			if (npcID == "player")
				charEntity = super.shellApi.player;
			else
				charEntity = super.getEntityById(npcID);
			return charEntity;
		}
		
		// common room stuff /////////////////////////////////////////////////////////////////////////////////////////
		
		private function onDisconnect():void
		{	
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", leaveMPRoom)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}

		private function leaveMPRoom():void
		{
			shellApi.loadScene(DoorSystem.PREVIOUS_SCENE);
		}

		// Functions called by callFunction in action chain ///////////////////////////////////////////////////////////
		
		/**
		 * Load scene
		 */
		private function loadScene(suffix:String = "", noFades:String = "false"):void
		{
			AdManager(super.shellApi.adManager).interiorSuffix = suffix;
			var sceneClass:Class = ClassUtils.getClassByName("game.scenes.custom.questInterior.QuestInterior");
			// RLH: was using shellApi.loadScene() but that didn't pass fade times
			if (noFades == "true")
				super.shellApi.loadScene(sceneClass, NaN, NaN, null, 0, 0);
			else
				super.shellApi.loadScene(sceneClass);
		}
		
		/**
		 * Play Audio
		 */
		private function playAudio(path:String):void
		{
			trace("QuestInterior: play audio: path = " + path);
			AudioUtils.play(this,path);
		}
		
		/**
		 * Rain random clips from scene whose name starts with "rain"
		 * @param frequency
		 * @param speed
		 */
		private function startRain(frequency:String = "10", speed:String = "900"):void
		{
			super.shellApi.player.add(new RainRandomClips());
			this.addSystem( new RainRandomClipsSystem(this, int(frequency), int(speed) ), SystemPriorities.updateAnim );
		}
		
		// popups /////////////////////////////////////////////
		
		/**
		 * Load start popup
		 */
		private function loadStartPopup(suffix:String = "",folderName:String=""):void
		{
			SceneUtil.lockInput(this, false);
			trace("QuestInterior: load start popup: suffix = " + suffix);
			loadGamePopup("AdStartQuestPopup", suffix, 0,0,null,0,folderName);
		}
		
		private function loadStartGamePopup(suffix:String, gameClass:String,folderName:String=""):void
		{
			SceneUtil.lockInput(this, false);
			trace("QuestInterior: load start game popup: suffix = " + suffix + ", gameClass = " + gameClass);
			loadGamePopup("AdStartGamePopup", suffix, 0, 0, gameClass, 0, folderName);
		}
		
		/**
		 * Load win popup (and reset interior suffix)
		 */
		private function loadWinPopup(returnX:String, returnY:String, suffix:String = ""):void
		{
			// reset interior suffix
			AdManager(super.shellApi.adManager).interiorSuffix = "";
			SceneUtil.lockInput(this, false);
			trace("QuestInterior: load win popup: suffix = " + suffix);
			loadGamePopup("AdWinQuestPopup", suffix, Number(returnX), Number(returnY));          
		}
		
		/**
		 * load game popup (Start, Win or Lose) 
		 * @param className
		 * @param returnX
		 * @param returnY
		 */
		public function loadGamePopup(className:String, suffix:String = "", returnX:Number = 0, returnY:Number = 0, gameClass:String = null, score:Number = 0, folderName:String="", returnToLastScene:Boolean=false):Popup
		{
			// if no suffix passed, then get from ad manager
			if (suffix == null)
				suffix = _adManager.questSuffix;
			else
			{
				// if suffix is true for single quests, then set to empty string
				if (suffix == "true")
					suffix = "";
				_adManager.questSuffix = suffix;
			}
			trace("AdInterior: loadPopup suffix: " + suffix);
			
			// get popup class
			var popupClass:Class = ClassUtils.getClassByName("game.scenes.custom." + className);
			// add popup to scene
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(super.groupManager.getGroupById("ui"));
			var popup:Object = Popup(popupClass(sceneUIGroup.addChildGroup(new popupClass())));
			// pass ad data and game suffix as game ID to popup
			var data:CampaignData = _adManager.getActiveCampaign(_adData.campaign_name);
			if (data == null)
			{
				data = new CampaignData();
				data.campaignId = _adData.campaign_name;
			}
			popup.campaignData = data;
			popup.campaignData.gameID = suffix;
			popup.campaignData.gameClass = gameClass;
			// initialize popup
			if(folderName != "")
				popup.groupPrefix = folderName;
			popup.init(sceneUIGroup.groupContainer);
			// if have return pos then pass to popup
			if (returnY != 0)
				popup.setReturnPos(returnX, returnY);
			
			// pass score to win popup
			if (className.indexOf("AdWin") == 0 || className.indexOf("AdLose") == 0)
				popup.setScore(score);
			if(returnToLastScene)
				popup.campaignData.popupScene = true;
			return popup as Popup;
		}
		
		public function selectArcadeGame(game:String, scene:String = null):void
		{
			var sceneClass:Class = null;
			if(DataUtils.validString(scene))
			{
				sceneClass = ClassUtils.getClassByName(scene);
			}
			var isMultiplayer:Boolean = true;
			if(sceneClass == null)
			{
				sceneClass = ArcadeGame;
				isMultiplayer = false;
			}
			shellApi.track("ArcadeGameSelect", game, null, _campaignName);
			shellApi.arcadeGame = game;
			var spatial:Spatial = player.get(Spatial);
			var overrideReturnScene:String = "game.scenes.custom.questInterior.QuestInterior," + spatial.x + ","+spatial.y;
			if(isMultiplayer)
				shellApi.sceneManager.gotoMultiplayerScene(sceneClass, overrideReturnScene);
			else
			{
				shellApi.sceneManager.loadScene(sceneClass);
				shellApi.overrideReturnScene = overrideReturnScene;
			}
		}
		
		/**
		 * Load ad popup this is not start, win or lose (used in PartyRoom.as)
		 * @param swfPath (swf path is not passed to class. Something is wrong here. Use next function)
		 * @param callback
		 */
		public function loadPopup(swfPath:String, callback:Function = null):void
		{
			// get ad popup class
			var popupClass:Class = ClassUtils.getClassByName("game.scenes.custom.AdPopup");
			// add popup to scene
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(super.groupManager.getGroupById("ui"));
			var popup:AdPopup = AdPopup(sceneUIGroup.addChildGroup(new popupClass(sceneUIGroup.groupContainer, _adData)));
			// initialize popup
			popup.init(sceneUIGroup.groupContainer);
			// if callback, then add listener
			if (callback)
				popup.popupRemoved.addOnce(callback);
		}
		
		/**
		 * Load ad popup this is not start, win or lose 
		 * @param swf
		 * @param callback
		 */
		public function loadAnimPopup(swfPath:String, callback:Function = null):void
		{
			// get ad popup class
			var popupClass:Class = ClassUtils.getClassByName("game.scenes.custom.AdAnimPopup");
			// add popup to scene
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(super.groupManager.getGroupById("ui"));
			var popup:AdAnimPopup = AdAnimPopup(sceneUIGroup.addChildGroup(new popupClass(sceneUIGroup.groupContainer, swfPath)));
			// initialize popup
			popup.init(sceneUIGroup.groupContainer);
			// if callback, then add listener
			if (callback)
				popup.popupRemoved.addOnce(callback);
		}
		
		/**
		 * Remove branding from campaign
		 */
		public function removeBranding():void
		{
			// if branding not removed, then remove it once
			if (!_brandingRemoved)
			{
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
			}
		}
		
		override public function destroy():void
		{
			if (_isMultiPlayer)
			{
				// leave room
				shellApi.smartFoxManager.leaveRoom();
				
				shellApi.smartFoxManager.disconnected.remove(onDisconnect);
				shellApi.smartFoxManager.loginError.removeAll();
				shellApi.smartFoxManager.loggedIn.removeAll();
				shellApi.smartFox.disconnect();
			}
			//shellApi.forcedAdData = null;
			super.destroy();
		}
		
		// get ad data for scene
		public function get adData():AdData { return(_adData); }
		public function get questName():String { return _interiorBaseName; }
		
		public var trackingData:Object;
		public var brandedClips:Array;
		
		protected var _returnToInterior:Boolean;
		
		private var questInteriorEvents:Object;
		private var _adData:AdData;
		private var _campaignName:String;
		private var _isMMQ:Boolean = false;
		private var _adManager:AdManager;
		private var _sceneName:String;
		private var _interiorBaseName:String;
		private var _brandingRemoved:Boolean = false;
		private var _actionChain:ActionChain;
		private var _isMultiPlayer:Boolean = false;
	}
}

