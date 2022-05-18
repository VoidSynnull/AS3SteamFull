package game.scenes.reality2.gameShow
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.DepthChecker;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Npc;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.DanceMoves01;
	import game.data.animation.entity.character.Proud;
	import game.data.character.LookData;
	import game.data.profile.ProfileData;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.ActionsGroup;
	import game.scene.template.SceneUIGroup;
	import game.scenes.reality2.Reality2Events;
	import game.scenes.reality2.mainStreet.MainStreet;
	import game.scenes.reality2.shared.Contestant;
	import game.scenes.reality2.shared.RealityScene;
	import game.systems.actionChain.ActionChain;
	import game.systems.motion.DestinationSystem;
	import game.ui.saveGame.SaveGamePopup;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.utils.AdUtils;
	
	import org.hamcrest.object.nullValue;
	
	public class GameShow extends RealityScene
	{
		private const CONTESTANTS_MAX:int   = 7;
		
		private var allContestants:Vector.<Contestant>;
		private var needStartingContestants:Boolean = false;
		
		private var contestantsXml:XML
		private var probably:Entity;
		private var sign:Entity;
		private var transition:Entity;
		
		private var candidates:int = 0;
		private var gamesPlayed:int = 0;
		
		private var credits:int;
		
		private var actionsGroup:ActionsGroup;
		
		public function GameShow()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/reality2/gameShow/";
			
			super.init(container);
		}
		
		override protected function addGroups():void
		{
			super.addChildGroup(new SceneUIGroup(super.overlayContainer, uiLayer)).ready.addOnce(hideHud);
			super.addGroups();
		}
		
		private function hideHud(group:Group):void
		{
			SceneUtil.showHud(this, false);
		}
		
		override protected function contestantDataLoaded(xml:XML):void
		{
			actionsGroup = getGroupById(ActionsGroup.GROUP_ID) as ActionsGroup;
			
			addSystem(new DestinationSystem());
			// reset competition if being replayed
			if(shellApi.checkEvent(reality.COMPETITION_FINISHED))
			{
				shellApi.setUserField(reality.CONTESTANTS_FIELD, "",shellApi.island,true);
				shellApi.setUserField(Reality2Events.GAMES_PLAYED_FIELD, "",shellApi.island,true);
				shellApi.removeEvent(reality.COMPETITION_FINISHED);
				shellApi.removeEvent(reality.GAMES_STARTED);
				contestants = null;
			}
			
			if(contestants == null)
			{
				needStartingContestants = true;
				contestants = new Vector.<Contestant>();
			}
			
			SceneUtil.setCameraPoint(this, sceneData.cameraLimits.width/2, sceneData.cameraLimits.height/2,true);
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			contestantsXml = xml;
			probably = getEntityById("probably");
			probably.get(Dialog).replaceKeyword("[Player Name]", shellApi.profileManager.active.avatarName);
			probably.remove(PlatformDepthCollider);
			CharUtils.lockControls(player);
			player.remove(DepthChecker);
			player.remove(PlatformDepthCollider);
			
			if(needStartingContestants)
			{
				prepareCandidates();		
			}
			else
			{
				setUpContestants();
			}
			
			setUpSelectors();
			setUpFire();
			setUpSign();
			setUpTransition();
			setUpCeremonyAnimations();
			getNumGamesPlayed(shellApi,numGames);
		}
		
		private function numGames(games:int):void
		{
			gamesPlayed = games;
		}
		
		private function setUpSign():void
		{
			var clip:MovieClip = _hitContainer["sign"];
			if(!needStartingContestants)
			{
				_hitContainer.removeChild(clip);
				return;
			}
			
			sign = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertAllClips(clip, sign, this);
		}
		
		private function setUpTransition():void
		{
			var clip:MovieClip = _hitContainer["tran"];
			if(needStartingContestants)
			{
				_hitContainer.removeChild(clip);
				return;
			}
			super.uiLayer.addChild(clip);
			convertContainer(clip);
			DisplayUtils.moveToTop(clip);
			transition = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertAllClips(clip,null, this,true, 32, transition);
			var timeline:Timeline = transition.get(Timeline);
			timeline.stop();
			transition.add(new Id("transition"));
		}
		
		private function setUpCeremonyAnimations():void
		{
			var clip:MovieClip = _hitContainer["awardCeremony"];
			if(needStartingContestants)
			{
				_hitContainer.removeChild(clip);
				return;
			}
			convertContainer(clip);
			TimelineUtils.convertAllClips(clip, null, this);

		}
		
		private function setUpFire():void
		{
			var clip:MovieClip = _hitContainer["fire"];
			convertContainer(clip);
			TimelineUtils.convertAllClips(clip, null, this);
		}
		
		private function setUpSelectors():void
		{
			var clip:MovieClip;
			var entity:Entity;
			
			for(var i:int = 1; i <= 3; i++)
			{
				clip = _hitContainer["s"+i];
				if(!needStartingContestants)
				{
					_hitContainer.removeChild(clip);
					clip = _hitContainer["coin"+i];
				}
				else
				{
					_hitContainer.removeChild(_hitContainer["coin"+i]);
				}
				convertContainer(clip);
				DisplayUtils.moveToTop(clip);
				entity = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertAllClips(clip,null,this,!needStartingContestants,32,entity);
				entity.add(new Id(clip.name));
				Sleep(entity.get(Sleep)).ignoreOffscreenSleep = true;
				EntityUtils.visible(entity, false);
			}
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			if(actionsGroup)
			{
				var actionChain:ActionChain = actionsGroup.getActionChain(event);
				
				if(actionChain)
				{
					actionChain.execute();
					return;
				}
			}
			
			var difficulty:Number = 0;
			switch(event)
			{
				case "repick":
				{
					shellApi.track("ResetContestants");
					resetContestants();
					break;
				}
				case "difficulty_easy":
				{
					shellApi.track("DifficultySetting", "Easy");
					difficulty = Contestant.EASY;
					break;
				}
				case "difficulty_normal":
				{
					shellApi.track("DifficultySetting", "Medium");
					difficulty = Contestant.NORMAL;
					break;
				}
				case "difficulty_hard":
				{
					shellApi.track("DifficultySetting", "Hard");
					difficulty = Contestant.HARD;
					break;
				}
				case "save_game":
				{
					addChildGroup(new SaveGamePopup(overlayContainer)).removed.addOnce(savePopupClosed);
					break;
				}
				case "continue_game":
				{
					var dialog:Dialog = probably.get(Dialog);
					dialog.sayById("final");
					dialog.complete.addOnce(endCeremony);
					break;
				}
			}
			if(difficulty > 0)
			{
				setDifficulty(difficulty);
			}
		}
		
		private function savePopupClosed(popup:SaveGamePopup):void
		{
			var dialog:Dialog = probably.get(Dialog);
			dialog.sayById(popup.savedGame?"splendid":"uhoh");
			if(popup.savedGame)
				dialog.complete.addOnce(creditsAwarded);
		}
		
		private function setDifficulty(difficulty:Number):void
		{
			for each(var contestant:Contestant in contestants)
			{
				contestant.difficulty = difficulty;
			}
			var dialog:Dialog = probably.get(Dialog);
			dialog.sayById("begin");
			dialog.complete.addOnce(chooseNextContest);
		}
		
		private function chooseNextContest(...args):void
		{
			SceneUtil.lockInput(this);
			getNextContest(shellApi);
		}
		
		private function resetContestants():void
		{
			for(var i:int = 1; i <= 3; i++)
			{
				EntityUtils.visible(getEntityById("s"+i),false);
			}
			contestants = new Vector.<Contestant>();
		}
		
		private function setUpContestants():void
		{
			var contestant:Contestant;
			var npc:XML;
			var child:XML;
			var index:int;
			var npcID:String;
			var look:LookData;
			var cpu:Entity;
			var spatial:Spatial;
			for(var i:int = 0; i <contestants.length-1; i++)
			{
				contestant = contestants[i];
				index = contestant.index;
				
				npc = contestantsXml.children()[index];
				
				child = npc.child("skin")[0];
				npcID = DataUtils.getString(child.attribute("id")[0]);
				
				look = new LookData(child);
				cpu = getEntityById("c"+(i+1));
				cpu.remove(SceneInteraction);
				SkinUtils.applyLook(cpu,look,true,candidateReady);
				// position contestants in order
				spatial = cpu.get(Spatial);
				spatial.x = 300 + 200 * i;
				spatial.y = 500;
				contestant.id = npcID;
			}
			spatial = player.get(Spatial);
			spatial.x = 900;
			spatial.y = 550;
			contestant = contestants[3];
			contestant.id = "player";
			player.add(contestant);
			
			determineParticipantPlaces(contestants);
		}
		
		private function prepareCandidates():void
		{
			var clip:MovieClip;
			var contestant:Contestant;
			allContestants = new Vector.<Contestant>();
			var npc:XML;
			var child:XML;
			var index:int;
			var npcID:String;
			var look:LookData;
			var cpu:Entity;
			var interaction:Interaction;
			
			for(var i:int = 0; i < contestantsXml.child("npc").length(); i++)
			{
				npc = contestantsXml.child("npc")[i];
				npcID = DataUtils.getString(npc.attribute("id")[0]);
				
				contestant = new Contestant(i);
				contestant.id = npcID;
				allContestants.push(contestant);
			}
			//widdle down to 10
			while(allContestants.length > CONTESTANTS_MAX)
			{
				index = int(Math.random() * allContestants.length);
				contestant = allContestants[index];
				allContestants.splice(index, 1);
			}
			for(i = 0; i <allContestants.length; i++)
			{
				index = allContestants[i].index;
				npcID = allContestants[i].id;
				
				npc = contestantsXml.children()[index];
				
				child = npc.child("skin")[0];
				
				look = new LookData(child);
				cpu = getEntityById("c"+(i+1));
				Npc(cpu.get(Npc)).ignoreDepth = true;
				cpu.remove(PlatformDepthCollider);
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(cpu));
				cpu.remove(SceneInteraction);
				InteractionCreator.addToEntity(cpu,[InteractionCreator.CLICK,InteractionCreator.OVER, InteractionCreator.OUT]);
				interaction = cpu.get(Interaction);
				interaction.click.add(Command.create(selectNPC, index, npcID));
				interaction.over.add(Command.create(overNPC, npcID));
				interaction.out.add(Command.create(outNPC));
				SkinUtils.applyLook(cpu,look,true,candidateReady);
			}
		}
		
		private function outNPC(entity:Entity):void
		{
			var ui:MovieClip = _hitContainer["cNameUI"];
			ui.visible = false;
		}
		
		private function overNPC(entity:Entity, id:String):void
		{
			var ui:MovieClip = _hitContainer["cNameUI"];
			ui.visible = true;
			ui.x = entity.get(Spatial).x - (ui.width / 2);
			ui.y = entity.get(Spatial).y + ui.height;
			var tf:TextField = ui["cName"];
			tf.text = formatId(id);
		}
		
		private function candidateReady(entity:Entity):void
		{
			candidates++;
			
			if(needStartingContestants)
			{
				if(candidates >= CONTESTANTS_MAX)
				{
					contestantsPrepared();
					TweenUtils.entityTo(sign, Spatial, .5,{y:255, ease:Quad.easeOut,onComplete:Command.create(jimJumpUp)});
				}
			}
			else
			{
				if(candidates >= NUM_AIS)
				{
					contestantsPrepared();
					shellApi.triggerEvent("ceremony");
				}
			}
		}
		
		private function jimJumpUp():void
		{
			var height:Number = probably.get(Spatial).x - 20;
			TweenUtils.entityTo(probably, Spatial, .25,{y:height, ease:Quad.easeOut,onComplete:Command.create(jimJumpDown)});
			shellApi.triggerEvent("intro");
		}
		
		private function jimJumpDown():void
		{
			var height:Number = probably.get(Spatial).x + 20;
			TweenUtils.entityTo(probably, Spatial, .25,{y:height, ease:Quad.easeOut});
		}
		
		public function awardCredits():void
		{
			var contestant:Contestant = player.get(Contestant);
			var place:int = contestant.place;
			contestant = contestants[0];
			var multiplier:int = 1;
			switch(contestant.difficulty)
			{
				case Contestant.NORMAL:
				{
					multiplier = 2;
					break;
				}
				case Contestant.HARD:
				{
					multiplier = 3;
					break;
				}
				default:
				{
					multiplier = 1;
					break;
				}
			}
			//1st = 4 * 5 : 4th = 1 * 5 multiplier is 1 to 3
			//totals range from 5 to 60 based on 4th on easy to 1st on hard
			credits = (5 - place) * 5 * multiplier;
			var dialog:Dialog = probably.get(Dialog);
			dialog.say(credits + " credits!");
			dialog.complete.addOnce(creditsAwarded);
		}
		
		private function creditsAwarded(...args):void
		{
			var dialog:Dialog = probably.get(Dialog);
			// need to ask players to save their game if they want their credits
			if(shellApi.profileManager.active.isGuest)
			{
				dialog.sayById("uhoh");
			}
			else
			{
				SceneUtil.showHud(this);
				SceneUtil.getCoins(this, credits);
				SceneUtil.delay(this, 2, Command.create(SceneUtil.showHud, this, false));
				
				dialog.sayById("final");
				dialog.complete.addOnce(endCeremony);
			}
		}
		
		public function endCeremony(...args):void
		{
			var profile:ProfileData = shellApi.profileManager.active;
			//actually award credits at the very end to prevent infinite rewards
			if(!profile.isGuest && gamesPlayed == NUM_AIS)// adding a speed hack check
			{
				var gameName:String = shellApi.island+"_";
				var difficulty:String = getDifficultyStringFromAI(contestants[0].difficulty);
				var place:int = Contestant(player.get(Contestant)).place;
				gameName += difficulty+"_"+place;
				gameName = gameName.toLowerCase();
				trace(gameName);
				AdUtils.setScore(shellApi, credits,gameName, onCreditsAwarded);
			}
			else
			{
				shellApi.loadScene(MainStreet);
			}
		}
		
		private function onCreditsAwarded():void
		{
			shellApi.profileManager.active.credits += shellApi.arcadePoints;
			shellApi.arcadePoints = 0;
			shellApi.profileManager.save();
			shellApi.loadScene(MainStreet);
		}
		
		public function awardPlace(place:int):void
		{
			var contestant:Contestant;
			var entity:Entity;
			var coin:Entity;
			for(var i:int = 0; i < contestants.length; i++)
			{
				contestant = contestants[i];
				if(contestant.place == place)
				{
					entity = i < NUM_AIS?getEntityById("c"+(i+1)):shellApi.player;
					break;
				}
			}
			if(place <= NUM_AIS)
			{
				coin = getEntityById("coin"+place);
				var npcSpatial:Spatial = entity.get(Spatial);
				var coinSpatial:Spatial = coin.get(Spatial);
				coinSpatial.x = sceneData.cameraLimits.width/2;
				coinSpatial.y = 100;
				EntityUtils.visible(coin, true, true);
				
				var final:Function = Command.create(TweenUtils.entityTo,coin, Spatial, 1, {y:npcSpatial.y - 150, ease:Quad.easeInOut, onComplete:Command.create(celebrate,entity,place)});
				var prepare:Function = Command.create(TweenUtils.entityTo,coin, Spatial, 1, {y:-500, x:npcSpatial.x, ease:Quad.easeInOut, onComplete:final});
				var pass:Function = Command.create(TweenUtils.entityTo,coin, Spatial, 1, {x:0, ease:Quad.easeInOut, onComplete:prepare});
				TweenUtils.entityTo(coin, Spatial, 1, {x:sceneData.cameraLimits.right, ease:Quad.easeInOut, onComplete:pass});
			}
			else
			{
				celebrate(entity, place);
			}
			
			trace(place + ": " + contestant.id + ": " + contestant.score);
		}
		
		private function celebrate(entity:Entity, place:int):void
		{
			var celebration:Class;
			switch(place)
			{
				case 1:
				{
					celebration = Celebrate;
					break;
				}
				case 2:
				{
					celebration = DanceMoves01;
					break;
				}
				case 3:
				{
					celebration = Proud;
					break;
				}
				default:
				{
					celebration = Cry;
					break;
				}
			}
			
			CharUtils.setAnim(entity, celebration);
		}
		
		private function selectNPC(entity:Entity, index:int, id:String):void
		{
			var contestant:Contestant
			for each(contestant in contestants)
			{
				if(contestant.index == index)
				{
					return;
				}
			}
			if(contestants.length < 3)
			{
				var dialog:Dialog = entity.get(Dialog);
				dialog.sayById(id);
				
				contestant = new Contestant(index);
				contestant.id = id;
				contestants.push(contestant);
				
				id = id.substr(0,1).toUpperCase()+id.substr(1);
				
				shellApi.track("ContestantSelected",id);
				
				dialog.complete.addOnce(Command.create(contestantEntered, contestants.length));
				
				var selector:Entity = getEntityById("s"+contestants.length);
				var spatial:Spatial = selector.get(Spatial);
				var target:Spatial = entity.get(Spatial);
				spatial.x = target.x;
				spatial.y = target.y + 50;
				EntityUtils.visible(selector);
				Timeline(selector.get(Timeline)).gotoAndPlay(0);
			}
		}
		
		private function contestantEntered(dialogData:DialogData, contestantNumber:int):void
		{
			if(contestants.length == contestantNumber && contestantNumber >= 3)
			{
				Dialog(probably.get(Dialog)).sayById("chosen");
				shellApi.completeEvent(Reality2Events.CONTESTANTS_CHOSEN);

			}
		}
	}
}