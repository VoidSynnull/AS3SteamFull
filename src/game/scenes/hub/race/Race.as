package game.scenes.hub.race
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Zone;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.FlameCreator;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.scene.template.ActionsGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.con1.roofRace.NavigationSmart.SmartNavUtils;
	import game.scenes.con1.roofRace.Timer.Timer;
	import game.scenes.con1.roofRace.Timer.TimerSystem;
	import game.scenes.hub.town.Town;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.survival1.cave.particles.CaveDrip;
	import game.scenes.survival1.cave.particles.CaveSplash;
	import game.systems.actionChain.ActionChain;
	import game.systems.entity.character.states.ClimbState;
	import game.systems.entity.character.states.FallState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.entity.character.states.touch.SkidState;
	import game.systems.entity.character.states.touch.StandState;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class Race extends PlatformerGameScene
	{
		private var path:Vector.<Point>;
		private var npc:Entity;
		
		private var finish:Entity;
		
		private var includeNpc:Boolean = true;
		
		private var playerFinished:Boolean = false;
		private var npcFinished:Boolean = false;
		
		private var finishLine:Zone;
		
		private const START_RACE:String = "start_race";
		private const VIEW_RACE:String = "view_race";
		
		private const RACE_ACTIONS:String = "_race_actions";
		
		private const ZONE:String = "Zone";
		private const FINISH_ZONE:String = "finishZone";// every race should have a finish zone and it performs a specific series of events for ending race
		
		private var actions:ActionsGroup;
		// if you are going to have an npc, you are going to need a safety valve so player doesn't wait forever for the npc to finish
		private var safetyValve:Point;
		
		private var flameCreator:FlameCreator;
		
		private var rewards:RaceRewardsData;
		
		private var bestTime:Number;
		
		private var targetTime:String;
		
		private var campaignName:String = "";
		
		private const LIMITED_PATH:String = "scenes/limited/";
		
		private var adData:AdData;
		
		private var ui:RaceUI;
		
		public function Race()
		{
			super();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// hopefully we can make a campaign for these races 
			var adType:String = AdCampaignType.WEB_MINI_GAME;
			
			adData = shellApi.adManager.getAdData(adType, true, false);
			
			// if ad data found, then use data from CMS
			if (adData)
			{
				campaignName = adData.campaign_name;
			}
			else if(!DataUtils.validString(campaignName))//for testing until cms works
			{
				var races:Array = 
					["RaceCon1RoofRace", 
						"RaceArab2Entrance", 
						"RaceGHDGhostShip", 
						"RaceMocktropicaMountain"];
				campaignName = races[int(Math.random() * races.length)];
			}
			
			groupPrefix = LIMITED_PATH + campaignName +"/";
			
			trace(campaignName);
			
			var obj:Object = shellApi.profileManager.active.scores[campaignName];
			if(obj)
			{
				bestTime = obj.score / 100.00;
				if(bestTime != 0)
					includeNpc = false;
			}
			
			addChildGroup(new RaceUI(overlayContainer, go, again)).ready.addOnce(uiReady);
		}
		
		private function uiReady(group:RaceUI):void
		{
			ui = group;
			super.load();
		}
		
		override public function destroy():void
		{
			var i:int = 1;
			var entity:Entity = getEntityById("drip"+i);
			while(entity)
			{
				CaveDrip(Emitter(entity.get(Emitter)).emitter).deadParticle.removeAll();
				++i;
				entity = getEntityById("drip"+i);
			}
			path = null;
			npc = null;
			finish = null;
			finishLine.entered.removeAll();
			finishLine = null;
			actions = null;
			flameCreator = null;
			rewards = null;
			super.destroy();
		}
		
		override protected function addBaseSystems():void
		{
			addSystem(new HitTheDeckSystem());
			addSystem(new TimerSystem());
			super.addBaseSystems();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			actions = getGroupById(ActionsGroup.GROUP_ID+RACE_ACTIONS) as ActionsGroup;
			
			shellApi.eventTriggered.add(handleEventTrigger);
			
			setUpNpc();
			
			var clip:MovieClip = new MovieClip();
			clip.graphics.beginFill(0xff0000);
			clip.graphics.drawCircle(0,0,25);
			clip.graphics.endFill();
			
			clip.x = 30;
			clip.y = shellApi.viewportHeight - 30;
			
			flameCreator = new FlameCreator();
			var template:MovieClip = _hitContainer["fire1"];
			if(template)
			{
				flameCreator.setup(this, template, null, setUpScene);
			}
			else
				setUpScene();
		}
		
		private function setUpScene():void
		{
			var entity:Entity;
			
			for each (var clip:MovieClip in _hitContainer)
			{
				if(clip.totalFrames >1)
				{
					entity = setUpTimeline(clip);
					if(clip.name.indexOf("popup") >= 0)
					{
						setUpPopUpAnimations(entity);
					}
					if(clip.name.indexOf("flag") >= 0)
					{
						var range:AudioRange = new AudioRange(1500, 0, 2, Quad.easeOut);
						entity.add(new Audio()).add(range);
						Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "flag_flapping_01.mp3", true, SoundModifier.POSITION);
					}
				}
				else
				{
					if(clip.name.indexOf("fly")>=0)
					{
						setUpFly(clip);
					}
					if(clip.name.indexOf("drip")>=0)
					{
						setUpDrips(clip);
					}
					if(clip.name.indexOf(ZONE) >= 0)
					{
						if(clip.name == FINISH_ZONE)
							setUpFinishLine();
						else
							setUpZone(clip.name);
					}
					if(clip.name.indexOf("fire") >=0)
					{
						flameCreator.createFlame(this, clip);
					}
				}
			}
			
			setUpTimer();
		}
		
		private function setUpTimer():void
		{
			rewards = new RaceRewardsData(getData("rewards.xml"));
			
			if(!npc)// racing yourself for world record
			{
				var goForReward:Boolean = false;
				for(var i:int = 0; i < rewards.rewards.length; ++i)
				{
					var reward:Reward = rewards.rewards[i];
					if(reward.threshold < bestTime && reward.id != "npc")
					{
						goForReward = true;
						ui.timeToBeat.setTime(reward.threshold);
						break;
					}
				}
				if(!goForReward)
					ui.timeToBeat.setTime(bestTime);
				
				performAction("start");
			}
			else
			{
				removeEntity(getEntityById("timeToBeat"));
				ui.timeToBeat = null;
				performAction("startNpc");
			}
		}
		
		private function setUpZone(name:String):void
		{
			var entity:Entity = getEntityById(name);
			if(actions)
			{
				var zone:Zone = entity.get(Zone);
				zone.entered.add(enterZone);
			}
		}
		
		private function enterZone(zoneId:String, entityId:String):void
		{
			var index:int = zoneId.indexOf(ZONE);
			var actionName:String = zoneId.substr(0, index);
			performAction(actionName);
		}
		
		private function setUpTimeline(clip:MovieClip):Entity
		{
			if(clip == null)
				return null;
			if(PlatformUtils.isMobileOS)
			{
				convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			}
			var entity:Entity= EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip, this, entity);
			entity.add(new Id(clip.name));
			return entity;
		}
		
		private function setUpPopUpAnimations(entity:Entity):void
		{
			var look:HitTheDeck = new HitTheDeck(player.get(Spatial), 300,false);
			look.duck.add(lookAtPlayer);
			entity.add(look);
		}
		
		private function lookAtPlayer(popup:Entity):void
		{
			Timeline(popup.get(Timeline)).play();
			shellApi.triggerEvent(popup.get(Id).id);
		}
		
		private static var drips:int = 1;
		
		private function setUpDrips(clip:MovieClip):void
		{
			var range:AudioRange = new AudioRange(1000, 0, 1, Quad.easeIn);
			if(clip)
			{
				var zone:Rectangle = clip.getBounds(_hitContainer);
				var rate:Number = Math.random() * .1 + .1;
				var particle:CaveDrip = new CaveDrip(zone, rate, drips);
				particle.deadParticle.add(playDripAudio);
				var entity:Entity = EmitterCreator.create(this, _hitContainer, particle,zone.x, zone.y, null, "drip"+drips);
				
				var splash:CaveSplash = new CaveSplash( new Point(zone.x, zone.bottom) );
				entity = EmitterCreator.create(this, this._hitContainer, splash,0,0, null, "splash"+drips, null, false);
				entity.add(new Audio()).add(range);
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = zone.x;
				spatial.y = zone.bottom;
				_hitContainer.removeChild(clip);
				++drips;
			}
		}		
		
		private function playDripAudio(caveDrip:CaveDrip):void
		{
			var entity:Entity = this.getEntityById("splash" + caveDrip.index);
			
			var emitter:Emitter = entity.get(Emitter);
			emitter.start = true;
			emitter.emitter.start();
			
			Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "drip_0" + Utils.randInRange(1, 3) + ".mp3", false,SoundModifier.POSITION);
		}
		
		private function setUpFly(basePosition:MovieClip):void
		{
			if( basePosition)
			{
				for(var i:int = 1; i <= 4; i++)
				{
					var clip:MovieClip = new MovieClip();
					clip.graphics.beginFill(0,1);
					clip.graphics.drawCircle(0,0,2);
					clip.graphics.endFill();
					
					var fly:Entity = EntityUtils.createSpatialEntity(this, BitmapUtils.createBitmapSprite(clip), _hitContainer);
					
					var flyPos:Spatial = fly.get(Spatial);
					flyPos.x = basePosition.x + Math.random() * basePosition.width;
					flyPos.y = basePosition.y + Math.random() * basePosition.height;
					
					fly.add(new SpatialAddition());
					fly.add(new WaveMotion());
					fly.add(new OriginPoint(flyPos.x, flyPos.y));
					fly.add(new Tween());
					
					moveFly(fly);
				}
				_hitContainer.removeChild(basePosition);
			}
		}
		
		private function moveFly(fly:Entity):void
		{
			var wave:WaveMotion = fly.get(WaveMotion);
			wave.data.length = 0;
			wave.data.push(new WaveMotionData("x", Math.random() * 10, Math.random() / 10));
			wave.data.push(new WaveMotionData("y", Math.random() * 10, Math.random() / 10));
			
			var origin:OriginPoint = fly.get(OriginPoint);
			var targetX:Number = (Math.random() - 0.5) * 250 + origin.x;
			var targetY:Number = (Math.random() - 0.5) * 100 + origin.y;
			
			var time:Number = Math.random() * .25 +.5;
			
			var tween:Tween = fly.get(Tween);
			tween.to(fly.get(Spatial), time, {x:targetX, y:targetY, ease:Linear.easeInOut, onComplete:moveFly, onCompleteParams:[fly]});
		}
		
		private function setUpFinishLine():void
		{
			finish = getEntityById("finishZone");
			finishLine = finish.get(Zone);
			finishLine.entered.add(crossedFinishLine);
			finishLine.pointHit = true;
			finish.remove(Sleep);
		}
		
		private function crossedFinishLine(finishID:String, hitID:String):void
		{
			if(hitID == "player")
			{
				if(ui.timer != null)
					ui.timer.stop();
				
				SceneUtil.lockInput(this);
				playerFinished = true;
				if(npcFinished)
					youWin(false);
				else if(npc)
				{
					var spatial:Spatial = npc.get(Spatial);
					if(spatial.y > safetyValve.y)
					{
						spatial.x = safetyValve.x;
						spatial.y = safetyValve.y;
						
						var endPoint:Point = path[path.length-1];
						CharUtils.moveToTarget(npc, endPoint.x, endPoint.y);
					}
				}
				else
					youWin(true);
			}
			else
			{
				npcFinished = true;
				if(playerFinished)
					youWin(true);
				else
					targetTime = ui.timer.toString();
			}
		}
		
		private function youWin(won:Boolean):void
		{
			// dialogId is in reference to the npc's perspective not the player's
			var dialogId:String = "win";
			
			var time:Number = ui.timer.time.toSeconds();
			
			var island:String = shellApi.island;
			if(adData)
			{
				var firstLetter:String = adData.island.substr(0,1).toLowerCase();
				island = firstLetter+adData.island.substr(1);
			}
			
			if(ui.timeToBeat)// racing self
			{
				targetTime = ui.timeToBeat.toString();
				if(time < ui.timeToBeat.time.toSeconds())
				{
					ui.timeToBeat.setTime(time);
					
					shellApi.completeEvent("record"+campaignName, island);
				}
				else
					won = false;
			}
			else if(won)
			{
				shellApi.completeEvent("npc"+campaignName, island);
				if(time <rewards.getRewardById("record").threshold)//incase you beat world record on first try
					shellApi.completeEvent("record"+campaignName, island);
			}
			
			if(won)
			{
				setBestTime(time);
				dialogId = "loose";
				includeNpc = false;
			}
			
			finishLine.entered.removeAll();
			if(npc == null)
			{
				var dialogData:DialogData = new DialogData();
				dialogData.id = dialogId;
				SceneUtil.delay(this, 1, Command.create(endRacePopup, dialogData));
				return;
			}
			
			SceneInteraction(npc.get(SceneInteraction)).activated = true;
			
			var dialog:Dialog = npc.get(Dialog);
			
			dialog.complete.addOnce(endRacePopup);
			
			dialog.sayById(dialogId);
		}
		
		private function setBestTime(time:Number):void
		{
			bestTime = time;
			var obj:Object = shellApi.profileManager.active.scores[campaignName];
			if(obj == null)
			{
				obj = new Object();
				obj.score = 0;
				obj.wins = 0;
				obj.losses = 0;
			}
			obj.score = String(int(time * 100));
			
			shellApi.profileManager.active.scores[campaignName] = obj;
			IDataStore2(shellApi.siteProxy).call(DataStoreRequest.highScoreStorageRequest(campaignName,obj.score ));
		}
		
		private function endRacePopup(dialogData:DialogData):void
		{
			var text:String = "Congrats! Your time was " + ui.timer.display.text + "!";
			
			if(dialogData.id == "win")
			{
				ui.displayMessage("Nice try! Try again?", ui.timer.display.text, "Your Time", targetTime, npc?"Speedy Sam":"World Record", false);
			}
			else
			{
				if(npc)
				{
					SceneUtil.delay(this, 1, Command.create(shellApi.loadScene, Town,1100,960,"left"));
					return;
				}
				var reward:Reward = rewards.getRewardById("record");
				ui.displayMessage("You beat the world record!", ui.timer.display.text, "New Time", targetTime, "Old Record",true);
			}
			
			SceneUtil.lockInput(this, false);
		}
		
		public function again():void
		{
			if(ui.timer)
				ui.timer.stop();
			SceneUtil.lockInput(this);
			SceneUtil.delay(this, 1, resetRace);
		}
		
		private function resetRace():void
		{
			screenEffects.fadeToBlack(1, reset);
		}
		
		private function reset():void
		{
			playerFinished = false;
			EntityUtils.position(player, sceneData.startPosition.x, sceneData.startPosition.y);
			MotionUtils.zeroMotion(player);
			var motionControl:MotionTarget = player.get(MotionTarget);
			motionControl.targetX = sceneData.startPosition.x;
			motionControl.targetY = sceneData.startPosition.y;
			CharUtils.setDirection(player, sceneData.startDirection == "right");
			if(npc)
			{
				if(!includeNpc)
				{
					removeEntity(npc);
					npc = null;
				}
				else
				{
					npcFinished = false;
					var offset:Number = sceneData.startDirection == "right"?100:-100;
					EntityUtils.position(npc, sceneData.startPosition.x + offset, sceneData.startPosition.y,0);
					MotionUtils.zeroMotion(npc);
					var nav:Navigation = npc.get(Navigation);
					nav.active = false;
					nav.index = NaN;
					nav.path = null;
					motionControl = npc.get(MotionTarget);
					motionControl.targetX = sceneData.startPosition.x + offset;
					motionControl.targetY = sceneData.startPosition.y;
					CharUtils.setDirection(npc, sceneData.startDirection == "left");
				}
			}
			finishLine.entered.add(crossedFinishLine);
			screenEffects.fadeFromBlack(2,getReady);
			
			for each( var clip:MovieClip in _hitContainer)
			{
				if(clip.totalFrames > 1)
				{
					Timeline(getEntityById(clip.name).get(Timeline)).gotoAndStop(0);
				}
			}
			
			performAction("reset");
		}
		
		private function setUpNpc():void
		{
			npc = getEntityById("npc");
			path = SmartNavUtils.createPath(_hitContainer);
			var clip:MovieClip = _hitContainer["safetyValve"];
			if(clip)
			{
				safetyValve = new Point(clip.x, clip.y);
				_hitContainer.removeChild(clip);
			}
			
			if(npc == null)
				return;
			if(!includeNpc)
			{
				removeEntity(npc);
				npc = null;
				return;
			}
			npc.add(new ZoneCollider()).add(new SpecialAbilityControl());
			SmartNavUtils.addSmartNavToChar(this, npc);
			EntityUtils.turnOffSleep(npc);
			
			var states:Vector.<Class> = new <Class>[ ClimbState, FallState, JumpState, LandState, RunState, SkidState, StandState, WalkState ]; 
			CharacterGroup(super.getGroupById( CharacterGroup.GROUP_ID )).addFSM( npc, true, states, "stand" );	
			
			SceneInteraction(npc.get(SceneInteraction)).reached.removeAll();
			
			var i:int = 1;;
			var climb:Entity = getEntityById("climb"+i);
			while(climb)
			{
				climb.remove(Sleep);
				++i;
				climb = getEntityById("climb"+i);
			}
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			performAction(event);
		}
		
		private function performAction(actionName:String):void
		{
			if(actions)
			{
				var chain:ActionChain = actions.getActionChain(actionName);
				if(chain)
					chain.execute();
			}
		}
		
		public function getReady():void
		{
			if(npc)
			{
				performAction("getReadyNpc");
			}
			else
			{
				performAction("getReady");
			}
		}
		
		public function startCountDown():void
		{
			SceneUtil.lockInput(this);
			ui.countDown.play();
		}
		
		public function go():void//start player
		{
			race();
			if(ui.timer != null)
			{
				ui.timer.setTime();
				ui.timer.start();
			}
			returnControls();
		}
		
		private function race(...args):void// start npc
		{
			if(npc == null)
				return;
			CharUtils.followPath(npc,path,null,true,false,new Point(50, 100), true);
			CharacterMotionControl(npc.get(CharacterMotionControl)).maxVelocityX = 600;
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
		}
	}
}