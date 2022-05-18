package game.scenes.custom.partyRoom
{
	import com.greensock.easing.Bounce;
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
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
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.HitTest;
	import game.components.motion.WaveMotion;
	import game.components.scene.RainRandomClips;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdTrackingConstants;
	import game.data.animation.entity.character.Grief;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.profile.ProfileData;
	import game.data.scene.characterDialog.DialogData;
	import game.managers.ads.AdManager;
	import game.nodes.entity.character.NpcNode;
	import game.proxy.Connection;
	import game.scene.template.SFSceneGroup;
	import game.scene.template.ads.AdInteriorScene;
	import game.scenes.hub.arcadeGame.ArcadeGame;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.scenes.hub.town.Town;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.ShowOverlayAnimAction;
	import game.systems.actionChain.actions.StopFollowAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.hit.HitTestSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.scene.RainRandomClipsSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class PartyRoom extends AdInteriorScene
	{
		public function PartyRoom()
		{
			super();
		}
		
		/**
		 * All assets loaded 
		 */
		override public function loaded():void
		{
			super.shellApi.logWWW("PartyRoom :: loaded");
			//set up multiplayer
			var sfSceneGroup:SFSceneGroup = new SFSceneGroup();
			this.addChildGroup(sfSceneGroup); 
			// listen for objects recieved
			sfSceneGroup.objectRecieved.add(onObjectRecieved); 
			shellApi.smartFoxManager.disconnected.addOnce(onDisconnect);
			//shellApi.smartFoxManager.disconnected.addOnce(removeTrigger);
			// setup earthquake button
			if(_hitContainer["triggerButton"])
			{
				super.shellApi.loadFile("data/scenes/limited/"+super.adData.campaign_name+"_Interior/trigger.xml", setupTrigger);
			}
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
			
			// trigger any initial dialog for any NPCs
			super.shellApi.triggerEvent("initScene",false, false);
			
			//tracking
			_campaignName = AdManager(super.shellApi.adManager).getAdData(AdCampaignType.ARCADE_TAKEOVER).campaign_name;
			shellApi.track(TRACK_ARCADE_ENTER, null, null, _campaignName);

			// get return to interior flag
			_returnToInterior = AdManager(super.shellApi.adManager).returnToInterior;
			
			// get ad manager
			_adManager = AdManager(super.shellApi.adManager);
			
			
			
			//starcade stuff
			// when adding new games, they have to be added to the database by Dan Franklin (along with new highscore rows)
			// Game Name: 		ID (IDs are lowercase in database)
			// Crash N Bash: 	CrashDerby
			// Poptastic: 		Poptastic
			// Blaster Attack: 	Blasteroids
			// Vampire Blitz:	VampireBlitz
			var games:Array = ["kiosk", "CrashDerby", "Poptastic", "Blasteroids"];
			for each (var game:String in games)
			{
				var entity:Entity = ButtonCreator.createButtonEntity(_hitContainer[game], this, Command.create(gotoGame, game));
				entity.get(Display).alpha = 0;
				getHighScores(game);
			}
			
			setupBouncyAnimations();
			
			// attach listener for whenever a new scene is loaded
			shellApi.sceneManager.sceneLoaded.add(checkCoins);
			
			
			super.loaded();	
		}
		private function checkCoins(scene:Group):void
		{
			// if have point, then set delay
			if (shellApi.arcadePoints != 0)
			{
				SceneUtil.delay(this, 0.25, getCoins);
			}
		}
		
		private function getCoins():void
		{
			// apply arcade points to credits
			shellApi.profileManager.active.credits += shellApi.arcadePoints;
			shellApi.profileManager.save();
			// show coins
			SceneUtil.getCoins(this, Math.round(shellApi.arcadePoints/5));
			// clear arcade points
			shellApi.arcadePoints = 0;
		}
		private function setupBouncyAnimations():void
		{
			var bounceContainer:MovieClip = _hitContainer["bouncies"];
			if(bounceContainer)
			{
				addSystem(new HitTestSystem());
				var clip:MovieClip;
				for(var i:int = 0; i < bounceContainer.numChildren; i++)
				{
					clip = bounceContainer.getChildAt(i) as MovieClip;
					if (clip == null)
						continue;
					var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
					entity.add(new Id(clip.name));
					var hit:Entity = getEntityById(clip.name+"_hit");
					//trace(clip.name);
					if(hit)
					{
						//trace("add hit test to " + clip.name);
						hit.add(new HitTest(onBouncyHit));
					}
				}
			}
		}
		private function onBouncyHit(entity:Entity, id:String):void
		{
			var hitId:String = entity.get(Id).id;
			var anim:Entity = getEntityById(hitId.substr(0,hitId.length-4));
			//trace(hitId);
			TweenUtils.entityFromTo(anim, Spatial, .5, {scaleY:.7},{scaleY:1, ease:Bounce.easeInOut});
		}

		// select single-player arcade game and play
		private function selectArcadeGame():void
		{
			shellApi.track(TRACK_ARCADE_GAME_SELECT, _currentGame, null, _campaignName);
			shellApi.arcadeGame = _currentGame;
			shellApi.loadScene(ArcadeGame);
		}
		
		// go to choose game screen
		private function chooseGames():void
		{
			_holdConnection = true;
			shellApi.loadScene(ChooseGame);
		}
		
		private function confirmGame($entity:Entity):void
		{
			if (_currentGame == "kiosk")
			{
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(2, "Leave the arcade to play other players?", chooseGames)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= false;
				dialogBox.init(this.overlayContainer);
			}
			else
			{
				// if guest, then show dialog
				if (super.shellApi.profileManager.active.isGuest)
				{
					dialogBox = this.addChildGroup(new ConfirmationDialogBox(2, "Your high score won't be saved unless you register first.", selectArcadeGame)) as ConfirmationDialogBox;
					dialogBox.darkenBackground 	= true;
					dialogBox.pauseParent 		= false;
					dialogBox.init(this.overlayContainer);
				}
				else
				{
					selectArcadeGame();
				}
			}
		}
		private function gotoGame(buttonEntity:Entity, game:String):void
		{
			_currentGame = game;
			var spatial:Spatial = buttonEntity.get(Spatial);
			CharUtils.followPath( player, new <Point>[new Point(spatial.x, spatial.y)], confirmGame, false, false, new Point(100,100), true  );
		}
		/**
		 * Get high scores per game
		 * @param score
		 */
		public override function getHighScores(gameName:String):void
		{
			if (gameName == "kiosk")
				return;
			
			// clear fields
			_hitContainer[gameName + "_yours"].text = "0";
			_hitContainer[gameName + "_weekly"].text = "0";
			
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
		 * If error when calling win.php
		 * @param e
		 */
		private function getScoresError(e:IOErrorEvent):void
		{
			trace("getScores error: " + e.errorID)
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
			switch (return_vars.answer)
			{
				case "ok": // if successful
					//answer=ok&high_scores_json={"personal_highscore":{"highscore":"0"},"weekly_highscore":{"highscore":0,"look":"string","name":"playerName"}}
					trace("getScoresCallback Success: " + gameName);
					// trim data to what follows equals sign
					var index:int = e.target.data.indexOf("json=");
					var data:String = unescape(e.target.data.substr(index+5));
					trace("getScoresCallback Data: " + data);
					// convert to json object
					var json:Object = JSON.parse(data);
					
					// set personal high score on game console
					var personal:String = "0";
					if (data.indexOf("personal_highscore") != -1)
						personal = json.personal_highscore.highscore;
					
					// set weekly high score on game console
					var weekly:String = "370"; // default if errors or no one has played yet
					if (data.indexOf("weekly_highscore") != -1)
					{
						var wscore:String = json.weekly_highscore.highscore;
						// don't use zero
						if (wscore != "0")
							weekly = wscore;
					}
					
					// update text fields
					if (!AppConfig.mobile)
						_hitContainer[gameName + "_yours"].text = personal;
					_hitContainer[gameName + "_weekly"].text = weekly;
					break;
				
				default: // if errors
					trace("getScoresCallback Error: " + return_vars.answer);
					break;
			}
		}
		
		private function setupTrigger(triggerXML:XML):void
		{
			// if xml object, then setup
			if (triggerXML!= null)
			{
				_triggerXML = triggerXML;
				if(triggerXML.sceneFunction)
				{
					_sceneFunction = triggerXML.sceneFunction;
				}
				if(triggerXML.broadcast)
				{
					if(triggerXML.broadcast == "false")
						_broadcast = false;
				}
				if(triggerXML.popupSWF)
				{
					_popupSWF = triggerXML.popupSWF;
				}
				if(triggerXML.transformLookString)
				{
					_transformLookString = triggerXML.transformLookString;
				}
				if(triggerXML.triggerParam1)
				{
					_triggerParams = new Array();
					_triggerParams.push(triggerXML.triggerParam1);
				}
				if(triggerXML.triggerParam2)
				{
					_triggerParams.push(triggerXML.triggerParam2);
				}
				if(triggerXML.triggerParam3)
				{
					_triggerParams.push(triggerXML.triggerParam3);
				}
				if(triggerXML.triggerParam4)
				{
					_triggerParams.push(triggerXML.triggerParam4);
				}
				
				try{
					if(this[_sceneFunction] != null)
						_triggerButton = ButtonCreator.createButtonEntity(_hitContainer["triggerButton"], this, sendTrigger, _hitContainer); 
				}
				catch(error:Error){
					trace(this,"Not a valid trigger function "+ error.message);
				}
			}
					
		}
		
		private function onObjectRecieved(obj:Object, whoSentIt:Entity):void{
			trace(" <--- Recieved an object from server");
			if(obj.hasOwnProperty("sceneFunction")){
				this[obj.sceneFunction](whoSentIt);
			}
		}
		private function sendTrigger(...p):void{
			trace(" ---> Sending an object to the server");
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			sfSceneGroup.shareObject({sceneFunction:_sceneFunction});
			_adManager.track(super.adData.campaign_name, AdTrackingConstants.TRACKING_CLICK_ROOM_TRIGGER);
		}
		
		private function earthquake(whoSentIt:Entity):void{
			Dialog(whoSentIt.get(Dialog)).say("EARTHQUAKE!"); // have player who sent the object yell, "EARTHQUAKE!"
			cameraShake(); // shake scene
			
			// have all other players react
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			for each(var player:Entity in sfSceneGroup.allSFPlayers()){
				if(player != whoSentIt)
					CharUtils.setAnim(player, Grief);
			}
		}
		
		private function playPopup(whoSentIt:Entity):void{
			loadPopup(_popupSWF);
		}
		
		private function globalAction(whoSentIt:Entity):void
		{
			var action:Class;
			try
			{
				action = ClassUtils.getClassByName(_triggerParams[0]) as Class;
				
				
			} 
			catch(error:Error) 
			{
				trace( "Error :: PlayPopupAnim : given animation class was not found: " + _triggerParams[0] );
			}
			if(action != null)
			{
				var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
				CharUtils.setAnim(whoSentIt, Grief);
				for each(var player:Entity in sfSceneGroup.allSFPlayers()){
					CharUtils.setAnim(player, Grief);
				}			
			}
		}
		
		private function applyLook(whoSentIt:Entity):void
		{
			
				var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
				buildLook();
				SkinUtils.applyLook( whoSentIt, _transformData, false );
				for each(var player:Entity in sfSceneGroup.allSFPlayers()){
					SkinUtils.applyLook( player, _transformData, false );
					}
		}
		
		private function buildLook():void
		{
			_transformData = new LookData();
			
			for ( var i:int = 0; i < _LOOK_ATTRIBUTES.length; i ++ )
			{
				var param:String = _LOOK_PARAMS[i];
				if ( _triggerXML.child(param) != null  )
					_transformData.applyAspect( new LookAspectData( _LOOK_ATTRIBUTES[i], String( _triggerXML.child(param) ) ) );
				
			}
			trace("");
		}
		
		private function cameraShake():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion= cameraEntity.get(WaveMotion);
			
			if(waveMotion != null)
			{
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
			} else {
				waveMotion = new WaveMotion();
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 3;
			waveMotionData.rate = 0.5;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			TweenUtils.globalTo(this, waveMotionData, 3, {magnitude:0});
			
			if(!super.hasSystem(WaveMotionSystem)){
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
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
						if (animClip)
						{
							// convert clip to timeline
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
			// look for any triggered event in events object
			var eventList:Array = questInteriorEvents["triggered_" + event];
			
			// if returned to interior get any return events (event name followed by "Return" in xml)
			if (_returnToInterior)
				var eventListReturn:Array = questInteriorEvents["triggered_" + event + "Return"];
			
			// if found in event list, then process
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
				funct();
			}
		}
		
		/**
		 * Process the event list and activate events
		 * TODO: change this to use ActionChains instead
		 * @param eventList Array of events, each with their own params
		 */
		private function processEvent(eventList:Array):void
		{
			var callback:Function = null;
			var targetX:Number;
			var targetY:Number;
			var actChain:ActionChain = new ActionChain(this);
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
							actChain = null;
						}
						else
						{
							// else assumes action chain
							actChain.lockInput = true;
						}
						break;
					
					case "wait": // ["setPart", partID, partValue] set player part
						
						// get part id and value
						var delay:Number = Number(event[1]);
						
						// set part on player action and don't save
						actChain.addAction( new WaitAction(delay) );
						break;
					
					case "talk": // ["talk", charID, sayID] make entity (npc or player) talk by calling dialog ID
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						// get dialog ID
						var sayID:String = String(event[2]);
						
						// add talk action
						actChain.addAction( new TalkAction(charEntity, sayID) );
						break;
					
					case "setPart": // ["setPart", partID, partValue] set player part
						
						// get part id and value
						var partID:String = String(event[1]);
						var partValue:String = String(event[2]);
						
						// set part on player action and don't save
						actChain.addAction( new SetSkinAction(super.shellApi.player, partID, partValue, false, true) );
						break;
					
					case "setSpatial": // ["setSpatial", npcID, coords] sets spatial for npc
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						// get coordinates
						var arr:Array = event[2].split(",");
						targetX = Number(arr[0]);
						targetY = Number(arr[1]);
						
						// set coordinates of npc
						actChain.addAction( new SetSpatialAction(charEntity, new Point(targetX, targetY)) );
						// this prevents any current moveToTarget setting to resume
						var isPlayer:Boolean = (charEntity == super.shellApi.player);
						actChain.addAction( new StopFollowAction(charEntity, isPlayer, isPlayer) );
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
						var actionCommand:MoveAction = new MoveAction(charEntity, {x:targetX, y:targetY});
						actionCommand.noWait = !wait;
						actChain.addAction(actionCommand);
						
						var test:CallFunctionAction = new CallFunctionAction(reachedTarget);
						test.args[0] = event[4];
						actChain.addAction(test);
						
						
						break;
					
					case "stopFollow": // ["stopFollow", npcID] stop following target
						
						// get NPC entity or player
						charEntity = getEntityByID(String(event[1]));
						
						isPlayer = (charEntity == super.shellApi.player);
						actChain.addAction( new StopFollowAction(charEntity, isPlayer, isPlayer) );
						break;
					
					case "showOverlayAnim": // ["showOverlayAnim", swfPath] // load and show overlay animation voer scene
						
						// get swf path
						var swfPath:String = String(event[1]);
						// add overlay animation action
						actChain.addAction( new ShowOverlayAnimAction(swfPath) );
						break;
					
					case "startRain": // ["startRain", frequency, speed]
						var frequency:int = -1;
						var speed:int = -1;
						if (event.length > 1)
							frequency = int(event[1]);
						if (event.length > 2)
							speed = int(event[2]);
						super.shellApi.player.add(new RainRandomClips());
						this.addSystem( new RainRandomClipsSystem(this, frequency, speed), SystemPriorities.updateAnim );
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
							actChain.addAction( new TimelineAction(entity, startLabelName, endLabelName) );
						break;
					
					case "callFunction": // ["callFunction", functionName] call function in this class or superclass
						
						// get function name
						var functName:Function = this[String(event[1])];						
						switch(event.length)
						{
							case 1:
								trace("QuestInterior: Missing function name for callFunction action!");
							case 2:
								actChain.addAction( new CallFunctionAction(functName) );
								break;
							case 3:
								actChain.addAction( new CallFunctionAction(functName, String(event[2])) );
								break;
							case 4:
								actChain.addAction( new CallFunctionAction(functName, String(event[2]), String(event[3])) );
								break;
							case 5:
								actChain.addAction( new CallFunctionAction(functName, String(event[2]), String(event[3]), String(event[4])) );
								break;
							default:
								trace("QuestInterior: callFunction can't handle " + event.length + " number of arguments!");
								break;
						}
						break;
				}
			}
			if (actChain)
				actChain.execute();
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
		
		// Functions called by callFunction in action chain ///////////////////////////////////////////////////////////
		
		/**
		 * Rain random clips
		 * @param frequency
		 * @param speed
		 */
		private function startRain(frequency:String = "10", speed:String = "900"):void
		{
			if(this.hasSystem(RainRandomClipsSystem))
				return;
				
			if(_triggerParams[0] != null)
				frequency = _triggerParams[0];
			if(_triggerParams[1] != null)
				frequency = _triggerParams[1];
			super.shellApi.player.add(new RainRandomClips());
			this.addSystem( new RainRandomClipsSystem(this, int(frequency), int(speed), false ), SystemPriorities.updateAnim );
			if(_triggerParams[2] != null)
				SceneUtil.addTimedEvent( this, new TimedEvent( _triggerParams[2], 1, removeRainSystem ));

		}
		
		/**
		 * Remove Rain System 
		 */
		private function removeRainSystem():void
		{
			this.removeSystemByClass(RainRandomClipsSystem);
		}
		/**
		 * Load start popup 
		 */
		private function loadStartPopup():void
		{
			super.loadGamePopup("AdStartQuestPopup", "");
		}
		
		/**
		 * Trigger event when move to target reaches target 
		 * @param entity
		 * @param eventName
		 */
		private function reachedTarget(entity:Entity, eventName:String):void
		{
			super.shellApi.triggerEvent(eventName);
		}
		
		/**
		 * Trigger event when popup is closed 
		 * @param eventName
		 */
		private function popupDone(eventName:String):void
		{
			super.shellApi.triggerEvent(eventName);
		}
		
		/**
		 * Trigger event when time animation reaches end label
		 * @param eventName
		 */
		private function animDone(eventName:String):void
		{
			super.shellApi.triggerEvent(eventName);
		}
		private function onDisconnect():void
		{	
			
			shellApi.track(TRACK_ARCADE_DISCONNECT, null, null, _campaignName);
			
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", leaveArcade)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		private function leaveArcade():void
		{
			shellApi.loadScene(Town, 4720, 880);
		}
		override public function destroy():void
		{
			// remove sceneLoaded listener
			shellApi.sceneManager.sceneLoaded.remove(checkCoins);
			
			shellApi.track(TRACK_ARCADE_EXIT, null, null, _campaignName);
			
			// leave room
			shellApi.smartFoxManager.leaveRoom();
			
			shellApi.smartFoxManager.disconnected.remove(onDisconnect);
			shellApi.smartFoxManager.loginError.removeAll();
			shellApi.smartFoxManager.loggedIn.removeAll();
			if(!_holdConnection)
			{
				shellApi.smartFox.disconnect();
			}
			super.destroy();
		}
		
		private var questInteriorEvents:Object;
		private var _triggerButton:Entity;
		private var _sceneFunction:String;
		private var _numOfTriggers:Number
		private var _popupSWF:String;
		private var _broadcast:Boolean = true;
		private var _returnToInterior:Boolean;
		private var _triggerParams:Array;
		private var _adManager:AdManager;
		private const _LOOK_ATTRIBUTES:Array = new Array(SkinUtils.SKIN_COLOR, SkinUtils.HAIR_COLOR, SkinUtils.EYE_STATE, SkinUtils.EYES, SkinUtils.MARKS, SkinUtils.MOUTH, SkinUtils.FACIAL, SkinUtils.HAIR, SkinUtils.PANTS, SkinUtils.SHIRT, SkinUtils.OVERPANTS, SkinUtils.OVERSHIRT, SkinUtils.ITEM, SkinUtils.ITEM2, SkinUtils.PACK);
		private const _LOOK_PARAMS:Array = new Array("skinColor", "hairColor", "eyeState", "eyes", "marks", "mouth", "facial", "hair", "pants", "shirt", "overpants", "overshirt", "item", "item2", "pack");
		private var _transformData:LookData;
		private var _transformLookString:String;
		private var _triggerXML:XML;
		private var _currentGame:String;
		private var _holdConnection:Boolean;
		private var _campaignName:String;
		
		public static const TRACK_ARCADE_ENTER:String 		= "StarcadeEnter";
		public static const TRACK_ARCADE_EXIT:String 		= "StarcadeExit";
		public static const TRACK_ARCADE_DISCONNECT:String 	= "StarcadeDisconnected";
		
		public static const TRACK_ARCADE_GAME_SELECT:String = "ArcadeGameSelect";
		public static const TRACK_ARCADE_GAME_START:String 	= "ArcadeGameStart";
		public static const TRACK_ARCADE_GAME_REPLAY:String = "ArcadeGameReplay";
		public static const TRACK_ARCADE_GAME_WIN:String 	= "Win";
		public static const TRACK_ARCADE_GAME_LOSE:String 	= "Lose";
	}
}


