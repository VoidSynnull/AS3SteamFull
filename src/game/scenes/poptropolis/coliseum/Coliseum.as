package game.scenes.poptropolis.coliseum
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.MotionControl;
	import game.components.motion.RotateToVelocity;
	import game.components.motion.Threshold;
	import game.components.particles.Flame;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.FrontAimFire;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.Storm;
	import game.particles.emitter.specialAbility.Fire;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.scenes.poptropolis.coliseum.popups.BonusQuestPopup;
	import game.scenes.poptropolis.coliseum.popups.EventPopup;
	import game.scenes.poptropolis.coliseum.popups.GameOverPopup;
	import game.scenes.poptropolis.mainStreet.components.ScreenShake;
	import game.scenes.poptropolis.mainStreet.systems.ScreenShakeSystem;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.TribeRanksPopup;
	import game.scenes.poptropolis.shared.data.Competitor;
	import game.scenes.poptropolis.shared.data.Opponent;
	import game.scenes.poptropolis.wrestling.Wrestling;
	import game.systems.SystemPriorities;
	import game.systems.motion.RotateToVelocitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.particles.FlameSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Coliseum extends PlatformerGameScene
	{
		private const OPPONENT:String = "opponent";
		
		private var _isMember:Boolean = false;
		private var _events:PoptropolisEvents;
		
		private var _master:Entity;
		private var _warrior:Entity;
		private var _scorekeeper:Entity;
		private var arrow:Entity;
		private var oldArrow:Spatial;
		
		private var _winnerSteps:Array = [new Point(1041.25, 1133.5 - 36), new Point(958.25, 1156.5 - 36), new Point(1129.25, 1177.5 - 36)];

		/**
		 * Poptropolis controller.
		 */
		private var _poptropolis:Poptropolis;
		
		public function Coliseum()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/coliseum/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			_events = super.events as PoptropolisEvents;
			_isMember = true
			
			/**
			 * Potropolis doesn't seem to be loading fast enough for the podium to disappear before people can see it.
			 * So to counter this, the podium and flag should be set to invisible when the scene starts, then taken
			 * care of when Poptropolis finally loads.
			 */
			this._hitContainer["podium"].visible = false;
			this._hitContainer["tribalFlag"].visible = false;
			
			_master = this.getEntityById("master");
			_warrior = this.getEntityById("warrior");
			_scorekeeper = this.getEntityById("scorekeeper");
			
			//Testing only
			var allEvents:Array = [_events.ARCHERY_COMPLETED, _events.DIVING_COMPLETED, _events.HURDLES_COMPLETED, _events.JAVELIN_COMPLETED, _events.LONG_JUMP_COMPLETED, _events.POLE_VAULT_COMPLETED, _events.WEIGHT_LIFTING_COMPLETED, _events.SHOTPUT_COMPLETED, _events.TRIPLE_JUMP_COMPLETED, _events.SKIING_COMPLETED, _events.VOLLEYBALL_COMPLETED];
			if(false)
			{
				for(var i:int = 0; i < allEvents.length; i++)
				{
					this.shellApi.completeEvent(allEvents[i]);
				}
			}
			
			//Basic Scene Setup
			this.setupScoreboard();
			this.setupArrow();
			this.setupRain();
			this.setupCrowdFar();
			this.setupCrowdNear();
			this.setupFlames();
			
			//Event-Driven Scene Setup
			this.setupCeremony();
			this.setupFinale();
			this.setupBonus();
			
			_poptropolis = new Poptropolis( this.shellApi, this.poptropolisLoaded );
			_poptropolis.setup();
		}
		
		private function poptropolisLoaded( gameInfo:Poptropolis ):void
		{
			this.setupRankedCompetitors(gameInfo);
		}
		
		/**
		 * This function is an attempt to place NPCs on the podium correctly based on their rank in the previous
		 * game that was played AND give them their correct Tribe look.
		 */
		private function setupRankedCompetitors(poptropolis:Poptropolis):void
		{
			var i:int;
			var opponent:Opponent;
			var npcCount:int = 0;
			var npc:Entity;
			
			/**
			 * If a game was previously completed, then getRankings() should return a Vector of all Competitors. If any NPCs
			 * place in the top 3, those NPCs should ONLY be OPPONENT 1-3, since those are the only ones that have dialog when
			 * all games have been completed. The NPCs on the podium should be saying the "earthquake" dialog.
			 * 
			 * If no game was completed, then just give all NPCs arbitrary Opponent looks.
			 */
			if(this.shellApi.checkEvent(_events.EVENT_COMPLETED) && !this.shellApi.checkEvent(_events.WRESTLING_COMPLETED))
			{
				this.shellApi.removeEvent(_events.EVENT_COMPLETED);
				
				var competitors:Vector.<Competitor>;
				
				/**
				 * If all events aren't completed, then place the winners for the last event.
				 * If all events ARE completed, then place the overall winners.
				 */
				if(!this.shellApi.checkEvent(this._events.ALL_EVENTS_COMPLETED))
				{
					//Should return ordered Vector of Competitors based on score in previous game.
					competitors = poptropolis.getRankings();
					this.setupCompetitors(competitors, poptropolis);
					
					this.setupPodium(true, competitors.slice(0, 3));
					this.setupMasterDialog(poptropolis, competitors[0]);
					
					SceneUtil.lockInput(this);
					
					var dialog:Dialog = _master.get(Dialog);
					dialog.sayById("congratulations");
					dialog.complete.addOnce(finshedCongrats);
				}
				else
				{
					//Should return ordered Vector of leaders based on overall score.
					competitors = poptropolis.getLeaders();
					this.setupCompetitors(competitors, poptropolis);
					
					this.setupPodium(true, competitors.slice(0, 3));
					this.setupMasterDialog(poptropolis, competitors[0]);
				}
			}
			else
			{
				//No game was previously completed. Just give every NPC a look.
				for(i = 0; i < poptropolis.opponents.length; i++) 
				{
					npc = this.getEntityById(OPPONENT + (i + 1));
					opponent = poptropolis.opponents[i];
					
					opponent.applyLook(npc);
					this.replaceTribeDialog(npc, opponent.tribe.name);
				}
				
				//Remove the podium from the scene.
				this.setupPodium(false);
				this.setupMasterDialog(poptropolis);
			}
		}
		
		private function setupCompetitors(competitors:Vector.<Competitor>, poptropolis:Poptropolis):void
		{
			var npcCount:int = 0;
			
			for each(var competitor:Competitor in competitors)
			{
				//If the competitor is an NPC, then increment the current NPC index so the next check will update the next NPC.
				if(competitor.isNpc())
				{
					npcCount++;
					var npc:Entity = getEntityById(OPPONENT + npcCount);
					
					/**
					 * A Competitor has no applyLook() functionality, so I'm currently trying to iterate through
					 * all Opponents to find the Tribe that matches the Competitor's and then applying the look.
					 * 
					 * Not the best way to do things...
					 */
					for(var j:int = 0; j < poptropolis.opponents.length; j++)
					{
						var opponent:Opponent = poptropolis.opponents[j];
						
						if(competitor.tribe.name == opponent.tribe.name)
						{
							opponent.applyLook(npc);
							this.replaceTribeDialog(npc, opponent.tribe.name);
						}
					}
				}
			}
		}
		
		/**
		 * This get a Vector of the top 3 NPC and player competitors. If a game was previously completed, it should've fired
		 * an EVENT_COMPLETE event.
		 * 
		 * If the event is there, position all winners on the podium. If not, remove the podium from the scene.
		 */
		private function setupPodium(eventCompleted:Boolean, winners:Vector.<Competitor> = null):void
		{
			var podium:MovieClip = this._hitContainer["podium"];
			var tribeFlag:MovieClip = this._hitContainer["tribalFlag"];
			
			if(!eventCompleted)
			{
				this._hitContainer.removeChild(podium);
				this._hitContainer.removeChild(tribeFlag);
				this.removeEntity(this.getEntityById("podiumSteps"));
			}
			else
			{
				podium.visible 			= true;
				podium.mouseEnabled 	= false;
				podium.mouseChildren 	= false;
				tribeFlag.visible		= true;
				tribeFlag.mouseEnabled 	= false;
				tribeFlag.mouseChildren = false;
				
				var winner:Competitor;
				var spatial:Spatial;
				var npcCount:int = 0;
				var placePlayer:Boolean = true;
				
				for(var i:int = 0; i < winners.length; i++)
				{
					var step:Point = _winnerSteps[i];
					
					winner = winners[i];
					var entity:Entity;
					
					if(!winner.isNpc())
					{
						placePlayer = false;
						entity = this.player;
					}
					else
					{
						npcCount++;
						entity = this.getEntityById(OPPONENT + npcCount);
					}
					
					spatial = entity.get(Spatial);
					spatial.x = step.x;
					spatial.y = step.y;
					
					CharUtils.setDirection(entity, false);
					if(i == 0) CharUtils.setAnim(entity, Score);
					else CharUtils.setAnim(entity, Cry);
				}
				
				if(placePlayer)
				{
					CharUtils.setDirection(this.player, false);
					spatial = this.player.get(Spatial);
					spatial.x = 1185;
					spatial.y = 1288;
				}
				
				winner = winners[0];
				
				var flag:Entity = TimelineUtils.convertClip(tribeFlag, this);
				Timeline(flag.get(Timeline)).gotoAndStop(winner.tribe.id);
			}
		}
		
		private function setupMasterDialog(poptropolis:Poptropolis, winner:Competitor = null):void
		{
			if(!this._master) return;
			
			if(winner) this.replaceTribeDialog(this._master, winner.tribe.name);
			this.replaceTribeDialog(this._master, this.shellApi.profileManager.active.avatarName, "[player name]");
		}
		
		/**
		 * Replace [Tribe] markers in npc dialog with their corresponding tribe names.
		 */
		private function replaceTribeDialog( npc:Entity, tribeName:String, replaceMarker:String="[tribe]" ):void
		{
			//Also need to replace "[player name]" with the player's avatar name.
			var playerName:String = this.shellApi.profileManager.active.avatarName;

			var dict:Dictionary = ( npc.get( Dialog ) as Dialog ).allDialog;	// dialog dictionary.
			var dialogObj:Object;
			for( var s:String in dict ) {

				dialogObj = dict[s];
				if ( dialogObj is DialogData ) {

					(dialogObj as DialogData ).dialog = ( dialogObj as DialogData ).dialog.replace( replaceMarker, tribeName );

				} else if ( dialogObj is String ) {

					dict[ s ] = ( dialogObj as String ).replace( replaceMarker, tribeName );

				}
			}
		}
		
		/**
		 * Sort of stupid to have such a little thing in its own function, but it might change...
		 */
		private function displayRanksPopup():TribeRanksPopup 
		{
			return _poptropolis.displayRanksPopup();
		}
		
		private function setupScoreboard():void
		{
			var scoreboard:Entity = this.getEntityById("scoreboardInteraction");
			
			var interaction:SceneInteraction = scoreboard.get(SceneInteraction);
			interaction.approach = false;
			interaction.triggered.add(this.openScoreboard);
		}
		
		private function openScoreboard(...args):void
		{
			this.displayRanksPopup();
		}
		
		private function setupArrow():void
		{
			var clip:MovieClip = this._hitContainer["arrow"];
			
			if(this.shellApi.checkEvent(_events.STARTED_GAMES))
			{
				clip.parent.removeChild(clip);
				return;
			}
			
			this.oldArrow = new Spatial(clip.x, clip.y);
			this.oldArrow.rotation = clip.rotation;
			this.oldArrow.scale = clip.scaleX;
			
			clip.x = clip.y = 0;
			clip.scaleX = clip.scaleY = 3;
			
			var item:Entity = CharUtils.getPart(_scorekeeper, CharUtils.ITEM);
			var display:Display = item.get(Display);
			
			this.arrow = EntityUtils.createMovingEntity(this, clip, display.displayObject);
			
			var spatial:Spatial = this.arrow.get(Spatial);
			spatial.rotation += 75;
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			sprite.x = 24;
			sprite.y = 0;
			sprite.scaleX = sprite.scaleY = 0.3;
			sprite.rotation = -90;
			
			this.arrow.get(Display).displayObject.addChild(sprite);
			this.arrow.add(new Audio());
			this.arrow.add(new AudioRange(400));
			
			/**
			 * The arrow actually needs to have the audio, but currently the arrow is inside the scorekeeper's item part.
			 * So to counter this problem, the scorekeeper will have the positional audio until the arrow gets fired,
			 * then the arrow will start playing the audio.
			 */
			var audio:Audio = new Audio();
			_scorekeeper.add(audio);
			audio.play(SoundManager.EFFECTS_PATH + "fire_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			_scorekeeper.add(new AudioRange(400));
			
			var fire:Fire = new Fire();
			fire.init();
			var entity:Entity = EmitterCreator.create(this, sprite, fire, 0, 0, this.arrow);
		}
		
		private function setupCeremony():void
		{
			if(this.shellApi.checkEvent(_events.STARTED_GAMES)) return;

			SceneUtil.lockInput(this);
			
			player.get(Spatial).x = 50;
			var numOpps:int = Poptropolis.NUM_OPPONENTS;
			for(var i:uint = 1; i <= numOpps; i++) 
			{
				this.getEntityById(OPPONENT + i).get(Spatial).x = 2420 + Math.random() * 100;
			}
			
			_master.get(Spatial).x = 200;
			SceneUtil.setCameraTarget(this, _master);
			
			CharUtils.followPath(_master, new <Point> [new Point(1230, 1288), new Point(1230, 1136)], reachedChar1Target);
			SceneUtil.setCameraTarget(this, _master);
		}
		
		private function finshedCongrats(data:DialogData):void
		{
			SceneUtil.lockInput(this, false);
			CharUtils.stateDrivenOn(this.player);
		}
		
		private function setupFinale():void
		{
			if(!this.shellApi.checkEvent(_events.ALL_EVENTS_COMPLETED)) return;
			if(!this.shellApi.checkEvent(_events.EVENT_COMPLETED)) return;
			if(this.shellApi.checkEvent(_events.BONUS_STARTED) || this.shellApi.checkEvent(_events.BLOCKED_FROM_BONUS)) return;
			
			player.get(Spatial).x = _master.get(Spatial).x + 300;
			player.get(Spatial).y = 1288;
			CharUtils.setDirection(player, false);
			SceneUtil.lockInput(this);
			
			_master.get(Spatial).x = 817;
			_master.get(Spatial).y = 705 - 40;
			CharUtils.setDirection(_master, true);
			
			SceneUtil.setCameraTarget(this, _master);
			this.moveMic();
			Dialog(_master.get(Dialog)).sayById("finale1");
		}
		
		private function setupBonus():void
		{
			if(this.shellApi.checkEvent(this._events.BONUS_COMPLETED))
			{
				this.removeEntity(this._warrior);
			}
			else
			{
				if(this.shellApi.checkEvent(this._events.BONUS_STARTED) &&
					this.shellApi.checkEvent(this._events.WRESTLING_COMPLETED))
				{
					this.shellApi.triggerEvent(this._events.BONUS_COMPLETED, true);
					var dialog:Dialog = this._warrior.get(Dialog);
					dialog.sayById("strength");
					dialog.complete.addOnce(this.fadeWarrior);
				}
			}
		}
		
		private function fadeWarrior(data:DialogData):void
		{
			var tween:Tween = new Tween();
			this._warrior.add(tween);
			tween.to(this._warrior.get(Display), 2, {alpha:0, onComplete:this.removeEntity, onCompleteParams:[this._warrior]});
		}
		
		private function setupRain():void
		{
			var sprite:Sprite = new Sprite();
			
			sprite.mouseEnabled = false;
			sprite.mouseChildren = false;
			sprite.x = -this.shellApi.viewportWidth * 0.5;
			sprite.y = -this.shellApi.viewportHeight * 0.5;
			this.groupContainer.addChild(sprite);
			
			var colors:Array = [0xC8FAFF];
			var random:Random = new Random(1, 5);
			var box:RectangleZone = new RectangleZone(0, 0, this.shellApi.viewportWidth * 2, this.shellApi.viewportHeight);
			
			var rain:Storm = new Storm();
			rain.init(random, Droplet, [3], box, new RectangleZone(0, 0, 0, 200), new Point(0, 650), new Point(100, 0), colors, 0.5, true);
			
			var entity:Entity = EmitterCreator.create(this, sprite, rain, -box.right/2, -box.bottom/2, null, "rain");
		}
		
		private function setupFlames(start:Boolean = false):void
		{
			var clip:MovieClip = this._hitContainer["flame"];

			if(this.shellApi.checkEvent(_events.STARTED_GAMES) || start)
			{
				clip.visible = true;
				
				var sound:Entity = new Entity();
				this.addEntity(sound);
				
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "torch_fire_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				sound.add(audio);
				
				sound.add(new Spatial(1463, 1020));
				sound.add(new AudioRange(1000));
				
				this.addSystem(new FlameSystem(), SystemPriorities.lowest);
				
				var flames:Array = [clip["flame1"], clip["flame2"]];

				for(var i:int = 0; i < flames.length; i++)
				{
					var entity:Entity = new Entity();

					if(i == 0) entity.add(new Flame(flames[i], true));
					else entity.add(new Flame(flames[i], false));

					this.addEntity(entity);
				}
			} 
			else 
			{
				clip.visible = false;
			}
		}
		
		private function setupCrowdFar():void
		{
			var entity:Entity = this.getEntityById("backdrop2");
			var display:DisplayObjectContainer = entity.get(Display).displayObject;
			
			for(var i:int = 1; i <= 4; i++)
			{
				var clip:MovieClip = display["crowdFar" + i];
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				TimelineUtils.convertClip(clip, this);
			}
		}
		
		private function setupCrowdNear():void
		{
			var emotions:Array = ["cheer", "ooh", "angry", "sad", "clap"];
			
			for(var i:int = 1; i <= 4; i++)
			{
				var clip:MovieClip = this._hitContainer["crowd" + i];
				clip.gotoAndStop(1);
				
				var skin:int = Utils.randInRange(1, 3);
				var integer:int = Utils.randInRange(0, emotions.length - 1);
				var emotion:String = emotions[integer];
				
				clip["head"]["expression"].gotoAndStop(integer + 1);
				clip["body"]["shirt"].gotoAndStop(Utils.randInRange(1, 5));
				clip["hair"].gotoAndStop(Utils.randInRange(1, 5));
				
				//Skin Color
				clip["feet"].gotoAndStop(skin);
				clip["hand1"].gotoAndStop(skin);
				clip["hand2"].gotoAndStop(skin);
				clip["head"]["head"].gotoAndStop(skin);
				clip["head"]["expression"]["eyeLids"].gotoAndStop(skin);
				
				var spectator:Entity = TimelineUtils.convertClip(clip, this);
				changeExpression(spectator, emotions, skin);
			}
		}
		
		private function changeExpression(spectator:Entity, emotions:Array, skin:int):void
		{
			var integer:int = Utils.randInRange(0, emotions.length - 1);
			var emotion:String = emotions[integer];
			
			var timeline:Timeline = spectator.get(Timeline);
			timeline.gotoAndPlay(emotion);
			
			var clip:MovieClip = TimelineClip(spectator.get(TimelineClip)).mc;
			clip["head"]["expression"].gotoAndStop(integer + 1);
			clip["head"]["expression"]["eyeLids"].gotoAndStop(skin);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(Utils.randInRange(4, 6), 1, Command.create(changeExpression, spectator, emotions, skin)));
		}
		
		private function reachedChar1Target(entity:Entity):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1, -1, waitForLanding));
		}
		
		private function waitForLanding():void
		{
			CharUtils.setDirection(_master, true);
			this.moveMic();
			Dialog(_master.get(Dialog)).sayById("ceremony1");
		}

		private function cameraToMaster():void
		{
			SceneUtil.setCameraTarget(this, _master);
			_master.get(Dialog).sayById("ceremony2");
		}
		
		private function reachedLineTarget(entity:Entity):void
		{
			SceneUtil.setCameraTarget(this, this.getEntityById( String(OPPONENT + 2) ));
			
			var wait:uint = 10;
			var numOpps:int = Poptropolis.NUM_OPPONENTS;
			var npc:Entity;
			for(var i:uint = 1; i <= numOpps; i++) 
			{
				npc = this.getEntityById(OPPONENT + i);
				CharUtils.followPath(npc, new <Point> [new Point(1400 + 80 * wait / 10, npc.get(Spatial).y)], null, true);
				wait += 10;
				
				var motion:CharacterMotionControl = npc.get(CharacterMotionControl);
				motion.baseAcceleration = Utils.randNumInRange(10, 20);
				motion.maxVelocityX = Utils.randNumInRange(200, 400);
			}
			CharUtils.setDirection(player, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(5, -1, cameraToLineTarget3));
		}
		
		private function cameraToLineTarget3():void
		{
			this.shellApi.camera.target = new Spatial(1489, 1288);
			_master.get(Dialog).sayById("ceremony3");
		}
		
		private function shootArrow():void
		{
			this.addSystem(new RotateToVelocitySystem());
			this.addSystem(new ThresholdSystem());
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "snap_band_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var spatial:Spatial = this.arrow.get(Spatial);
			var display:Display = this.arrow.get(Display);
			var motion:Motion = this.arrow.get(Motion);
			
			this.arrow.add(new RotateToVelocity());
			
			spatial.x = oldArrow.x;
			spatial.y = oldArrow.y;
			spatial.scale = oldArrow.scale;
			spatial.rotation = 0;
			
			display.setContainer( this._hitContainer );
			
			_scorekeeper.remove(Audio);
			var audio:Audio = this.arrow.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "fire_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			
			motion.velocity.x = 170;
			motion.velocity.y = -1200;
			motion.acceleration.y = 600;
			
			CharUtils.eyesFollowTarget( _scorekeeper, this.arrow );
			
			/**
			 * The arrow's Threshold needs to be added after it fires because it already starts below
			 * its given Threshold value. Wiggity-wack!
			 */
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, addArrowThreshold));
			SceneUtil.setCameraTarget(this, this.arrow);
		}
		
		private function addArrowThreshold():void
		{
			var threshold:Threshold = new Threshold("y", ">=");
			threshold.threshold = 900;
			threshold.entered.addOnce(finishedFlame);
			this.arrow.add(threshold);
		}
		
		private function finishedFlame():void
		{
			CharUtils.setAnim(_scorekeeper, Stand);
			CharUtils.eyesFollowMouse( _scorekeeper );
			
			this.removeEntity(this.arrow);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_02.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			this.setupFlames(true);
			
			var animations:Array = [Score, Proud, Celebrate];
	
			var numOpps:int = Poptropolis.NUM_OPPONENTS;
			for(var i:uint = 1; i <= numOpps; i++) 
			{
				CharUtils.setAnim( super.getEntityById(OPPONENT + i), animations[ Math.floor(Math.random() * animations.length ) ]);
			}
			CharUtils.setAnim(player, Score);
			
			SceneUtil.setCameraTarget(this, _master);
			CharUtils.setDirection(_master, true);
			_master.get(Dialog).sayById("ceremony4");
		}
		
		private function reachedChar1StartTarget(entity:Entity):void
		{
			CharUtils.setDirection(_master, true);
			_master.get(Dialog).sayById("ceremony5");
		}
		
		private function reachedChar1StartTargetFinale(entity:Entity):void
		{
			/**
			 * Add check for winners here.
			 */
			
			Dialog(_master.get(Dialog)).sayById("finale4");
		}
		
		private function warriorVanished():void
		{
			_warrior.get(Display).alpha -= 0.15;
			if(_warrior.get(Display).alpha <= 0)
			{
				this.removeEntity(_warrior);
				CharUtils.setDirection(player, false);
				_master.get(Dialog).sayById("bonus_completed2");
			}
		}
		
		private function reachedChar10Target(entity:Entity):void
		{
			this.removeSystemByClass(ScreenShakeSystem);
			this.shellApi.camera.target = this.player.get(Spatial);
			
			_warrior.get(Dialog).sayById("bonus4");
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "popup_game_over")
			{
				if(!this.shellApi.checkHasItem(_events.MEDAL_POPTROPOLIS))
					this.addChildGroup(new GameOverPopup(this.overlayContainer));
			}
			else if(event == "popup_events")
			{
				this.addChildGroup(new EventPopup(this.overlayContainer));
			}
			else if(event == "popup_score") {

				if ( _poptropolis.loaded ) {
					this.displayRanksPopup();
				}

			}
			else if(event == "popup_blocker")
			{
				//For testing
				if (_isMember || false)
				{
					var dialog:Dialog = this._warrior.get(Dialog);
					dialog.complete.addOnce(this.loadWrestling);
				}
				else
				{
					this.shellApi.completeEvent(_events.BLOCKED_FROM_BONUS);
					var blocker:BonusQuestPopup = this.addChildGroup(new BonusQuestPopup(this.overlayContainer)) as BonusQuestPopup;
					blocker.id = "bounsQuestPopup";
					blocker.popupRemoved.addOnce(this.loadColiseum);
				}
			}
			else if(event == "ceremony1")
			{
				CharUtils.setDirection(_master, true);
				
				this.shellApi.camera.target = new Spatial(1463, 951);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, -1, cameraToMaster));
			}
			else if(event == "ceremony2")
			{
				CharUtils.setDirection(_master, true);
				CharUtils.followPath(player, new <Point> [new Point(1400, 1288)], reachedLineTarget, true);
				SceneUtil.setCameraTarget( this, _master );
			}
			else if(event == "ceremony3")
			{
				CharUtils.setDirection(_master, false);
				CharUtils.setDirection(_scorekeeper, true);
				SceneUtil.setCameraTarget(this, _scorekeeper);
				
				CharUtils.setAnim(_scorekeeper, FrontAimFire);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, shootArrow)); //moveParts
			}
			else if(event == "ceremony4")
			{
				this.moveMic(false);
				CharUtils.followPath(_master, new <Point> [new Point(863, 1288)], reachedChar1StartTarget, true);
				SceneUtil.setCameraTarget( this, _master );
			}
			else if(event == "ceremony5")
			{
				CharUtils.removeCollisions(_master);
				this.shellApi.completeEvent(_events.STARTED_GAMES);
				SceneUtil.setCameraTarget(this, player);
				SceneUtil.lockInput(this, false);
				
				//Remove collisions from entities after the ceremony is done. They're unneeded.
				var numOpps:int = Poptropolis.NUM_OPPONENTS;
				for(var i:uint = 1; i <= numOpps; i++) 
				{
					CharUtils.removeCollisions(this.getEntityById(OPPONENT + i));
				}

				this.moveMic(false);
				
				MotionControl(this.player.get(MotionControl)).lockInput = false;
				
				var interaction:SceneInteraction = _master.get(SceneInteraction);
				interaction.reached.removeAll();
				function firstEvent(player:Entity, master:Entity):void 
				{ 
					Dialog(master.get(Dialog)).sayById("first"); 
				};
				interaction.reached.add(firstEvent);
				
				interaction = _scorekeeper.get(SceneInteraction);
				interaction.reached.removeAll();
				function scorekeeper(player:Entity, scorekeeper:Entity):void 
				{ 
					Dialog(scorekeeper.get(Dialog)).sayById("scorekeeper"); 
				};
				interaction.reached.add(scorekeeper);
			}
			else if(event == "finale1")
			{
				/**
				 * Uncomment when it doesn't crash.
				 */
				SceneUtil.lockInput(this, false);
				if ( _poptropolis.loaded )
				{
					var popup:TribeRanksPopup = this.displayRanksPopup();
					popup.removed.addOnce(this.lockInput);
				}
				
				Dialog(_master.get(Dialog)).sayById("finale2");
			}
			else if(event == "finale3")
			{
				this.moveMic(false);
				
				CharUtils.followPath(_master, new <Point> [new Point(1050, 810), new Point(1200, 1190), new Point(863, 1288)], reachedChar1StartTargetFinale, true);
				SceneUtil.setCameraTarget( this, _master );
			}
			else if(event == "finale4")
			{
				if(this._poptropolis.loaded)
				{
					if(this._poptropolis.getLeaders()[0].isNpc())
						CharUtils.setAnim(this.getEntityById(OPPONENT + 1), Proud);
					else
					{
						//shellApi.completedIsland();
						CharUtils.setAnim(this.player, Proud);
						
						if(!this.shellApi.checkHasItem(this._events.MEDAL_POPTROPOLIS))
						{
							this.shellApi.getItem(this._events.MEDAL_POPTROPOLIS, null, true, medallionReceived);
						}
						else
						{
							medallionReceived();
						}
					}
				}
			}
			else if(event == "finale5")
			{
				//Can't get the master to say ANY other dialog once this part happens. It's weird. He just says his "supreme" dialog.
				var action:SceneInteraction = this._master.get(SceneInteraction);
				action.reached.removeAll();
				action.reached.add(sayAllEvents);
				
				if(this.shellApi.checkHasItem(this._events.MEDAL_POPTROPOLIS) || false)
				{
					Dialog(this.player.get(Dialog)).sayById("bonus_started1");
					
					this.addSystem(new ScreenShakeSystem());
					
					var target:Spatial = new Spatial();
					this.shellApi.camera.target = target;
					
					var shake:ScreenShake = new ScreenShake(target);
					shake.pauseTime = 100;
					this.player.add(shake);
				}
				else
				{
					SceneUtil.setCameraTarget(this, player);
					SceneUtil.lockInput(this, false);
					
					this.addChildGroup(new GameOverPopup(this.overlayContainer));
				}
			}
			else if(event == "bonus3")
			{
				SceneUtil.setCameraTarget(this, _warrior);
				CharUtils.followPath(_warrior, new <Point> [new Point(733, 1288)], reachedChar10Target, true);
				
				var control:CharacterMotionControl = _warrior.get(CharacterMotionControl);
				control.maxVelocityX = 200;
			}
			else if(event == "bonus4")
			{
				SceneUtil.setCameraTarget(this, player);
				CharUtils.followPath(this.player, new <Point> [new Point(1295, 1160), new Point(1065, 1288)]);
			}
			else if(event == "bonus5") SceneUtil.setCameraTarget(this, _warrior);
			else if(event == "bonus_started")
			{
				SceneUtil.setCameraTarget(this, player);
				SceneUtil.lockInput(this, false);
				
				CharUtils.lockControls(this.player);
			}
			else if(event == "coward")
			{
				CharUtils.lockControls(this.player, false, false);
			}
		}

		private function medallionReceived():void
		{
			shellApi.completedIsland('', showEndingPopup);
		}
		
		private function showEndingPopup(...args):void
		{
			SceneUtil.lockInput(this, false);
			
			var islandEndingPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer);
			islandEndingPopup.hasBonusQuestButton = true;
			islandEndingPopup.removed.addOnce(lockInput);
			this.addChildGroup(islandEndingPopup);
		}
		
		private function lockInput(group:Group):void
		{
			SceneUtil.lockInput(this);
		}
		
		public function sayAllEvents(player:Entity, master:Entity):void
		{
			Dialog(this._master.get(Dialog)).sayById(this._events.ALL_EVENTS_COMPLETED);
		}
		
		/**
		 * Helper function for the MC raising/lowering his mic.
		 */
		private function moveMic(up:Boolean = true):void
		{
			if(up)
			{
				CharUtils.setAnim(_master, PointItem);
				var timeline:Timeline = _master.get(Timeline);
				
				function stopPoint(timeline:Timeline):void { timeline.stop(); };
				timeline.handleLabel("pointing", Command.create(stopPoint, timeline));
			}
			else
			{
				CharUtils.setAnim( _master, Stand);
				CharUtils.stateDrivenOn( _master);
			}
			
		}
		
		private function loadWrestling(data:DialogData = null):void
		{
			this.shellApi.loadScene(Wrestling);
		}
		
		private function loadColiseum(popup:Popup = null):void
		{
			this.shellApi.loadScene(Coliseum);
		}
	}
}