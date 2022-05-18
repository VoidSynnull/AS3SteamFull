package game.scenes.prison.yard
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Rig;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.hit.Item;
	import game.components.hit.Zone;
	import game.components.motion.Destination;
	import game.components.motion.MotionTarget;
	import game.components.motion.ShakeMotion;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.FightStance;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Hurl;
	import game.data.animation.entity.character.Magnify;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.PointPistol;
	import game.data.animation.entity.character.Pop;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Read;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Sword;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.Wave;
	import game.data.animation.entity.character.WeightLifting;
	import game.data.animation.entity.character.custom.Flex;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.cellBlock.CellBlock;
	import game.scenes.prison.metalShop.MetalShop;
	import game.scenes.prison.yard.components.Seagull;
	import game.scenes.prison.yard.states.SeagullBeginFlightState;
	import game.scenes.prison.yard.states.SeagullEatingState;
	import game.scenes.prison.yard.states.SeagullFlyState;
	import game.scenes.prison.yard.states.SeagullHopState;
	import game.scenes.prison.yard.states.SeagullIdleState;
	import game.scenes.prison.yard.states.SeagullLandState;
	import game.scenes.prison.yard.states.SeagullSittingAngryState;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class Yard extends PrisonScene
	{		
		public function Yard()
		{
			super();
			this.mergeFiles = true;
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			CharacterGroup( getGroupById( CharacterGroup.GROUP_ID )).preloadAnimations( new <Class>[ Cry, Flex, Hurl, Magnify, Proud, Read, Score
																									, Sit, Stomp, Sword, Think, WeightLifting ], this );
			_animationLoader = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/yard/";
			
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
			instantiateInmates();
			setupAssets();
			
			if(shellApi.checkEvent(_events.DRILLED_PLATE))
			{
				showLastDay();	
			}
			else
			{
				CharUtils.moveToTarget(player, 600, 1500, true);
			}
			
			if(currentDay + 1 == _events.DAYS_FOR_PATCHES)
			{
				shellApi.triggerEvent("patches_one_day");
			}
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var spatial:Spatial;		
			var actions:ActionChain;
			
			switch(event)
			{
				case "look_to_wall":
					spatial	=	_warden.get( Spatial );
					Dialog( _warden.get( Dialog )).faceSpeaker	=	false;
					
					actions	= new ActionChain( this );
					actions.addAction( new MoveAction( _warden, new Point( spatial.x - 100, spatial.y )));
					actions.addAction( new TalkAction( _warden, "dat_wall" ));
					actions.addAction( new AnimationAction( _warden, Wave ));
					actions.addAction( new MoveAction( _warden, new Point( spatial.x, spatial.y )));
					actions.addAction( new TalkAction( _warden, "assure" ));	
					actions.execute();
					break;
				
				case "triggerBigTuna":
					actions	= new ActionChain( this );
					actions.addAction( new PanAction( _bigTuna, .8 ));
					actions.addAction( new AnimationAction( _bigTuna, Stomp ));
					actions.addAction( new CallFunctionAction( bigTunaRushesPlayer ));
					actions.addAction( new TalkAction( _bigTuna, "set_me_up" ));
					actions.addAction( new CallFunctionAction( ratchetStopsBigTuna ));	
					actions.execute();
					break;
				
				case "busted": // warden busts nostrand of his art supplies
				case GameEvent.GET_ITEM + _events.PAINTED_DUMMY_HEAD:
					if(shellApi.checkItemEvent(_events.PAINTED_DUMMY_HEAD) && shellApi.checkItemEvent(_events.PAINTED_PASTA))
					{
						SceneUtil.lockInput(this, true);
						Display( _warden.get( Display )).visible = true;
						EntityUtils.position(_warden, 2435, 1200);					
						CharUtils.followPath(_warden, new <Point>[new Point(2350, 1200), new Point(2100, 1110), new Point(1840, 1110)], wardenBustsNostrand, false, false, new Point(40, 40));
					}
					break;
				
				case "leave_for_work":
					shellApi.removeEvent("give_tonight");
					shellApi.removeEvent("leave_for_work");
					openSchedule(this);
					break;
				
				case "already_fed":
					CharUtils.setDirection(_patches, true);
					CharUtils.setAnim(_patches, PointItem);
					_seedsAnim.get(Display).visible = true;
					var seedSpatial:Spatial = _seedsAnim.get(Spatial);			
					seedSpatial.x = 1060;
					seedSpatial.y = 1500;
					
					var seedTimeline:Timeline = _seedsAnim.get(Timeline);
					seedTimeline.gotoAndPlay("noSeeds");
					seedTimeline.handleLabel("hair", Command.create(AudioUtils.play, this, SoundManager.EFFECTS_PATH + "sand_hard_01.mp3"));
					
					var motionTarget:MotionTarget = _seagull.get(MotionTarget);
					motionTarget.targetX = SEED_LOCATION.x;
					motionTarget.targetY = SEED_LOCATION.y;
					if(!shellApi.checkItemEvent(_events.SUNFLOWER_SEEDS))
					{
						seedTimeline.handleLabel("ground", Command.create(SceneUtil.setCameraTarget, this, _currentNest));
						SceneUtil.delay(this, 3, Command.create(SceneUtil.setCameraTarget, this, player));
					}
					break;
				
				case "gum_marion":
					if(gumCount >= 3)
					{
						removePlayerGum(3, "marion");
						SceneUtil.lockInput(this);
						player.get(Dialog).sayById("correct_gum_marion");
						Dialog(getEntityById(MARION).get(Dialog)).complete.addOnce(unlockPlayer);
					}
					else
					{
						player.get(Dialog).sayById("wrong_gum_marion");
					}
					break;
				
				case "use_sunflower_seeds":
					spatial = player.get(Spatial);
					if(spatial.y > 1100 && spatial.x > 450 && spatial.x < 1500)
					{
						EntityUtils.removeAllWordBalloons(this);
						SceneUtil.lockInput(this, true);
						CharUtils.moveToTarget(player, 640, 1500, false, plantSeeds, new Point(20,50)).setDirectionOnReached("right");
						return;
					}
					break;
				
				case "use_water_cup":
					if(!shellApi.checkItemEvent(_events.SUNFLOWER) && shellApi.checkEvent(_events.PLANTED_SEEDS))
					{
						spatial = player.get(Spatial);
						if(spatial.x > 450 && spatial.x < 1200 && spatial.y > 1300)
						{
							EntityUtils.removeAllWordBalloons(this);
							CharUtils.moveToTarget(player, 720, 1500, false, waterPlants, new Point(20, 50)).setDirectionOnReached("left");
							return;
						}
					}
					break;
				
				case "use_sunflower":
					spatial = player.get(Spatial);
					spatial = player.get(Spatial);
					if(spatial.x > 1570 && spatial.x < 2090 && spatial.y < 1180)
					{
						EntityUtils.removeAllWordBalloons(this);
						if(spatial.x >= 1630 && spatial.x <= 1670) giveSunflower();
						else CharUtils.moveToTarget(player, 1650, 1125, false, giveSunflower, new Point(20, 50)).setDirectionOnReached("right");
						return;
					}
					break;
				
				case GameEvent.GET_ITEM + "painting":
					SceneUtil.lockInput(this, false);
					CharUtils.setAnim(_nostrand, Celebrate);
					break;
				
				case "use_dummy_head":
					if(shellApi.checkItemUsedUp(_events.SUNFLOWER))
					{
						if(shellApi.checkEvent("give_tonight"))
						{
							_nostrand.get(Dialog).sayById("already_painting");
							return;
						}
						
						spatial = player.get(Spatial);
						if(spatial.x > 1570 && spatial.x < 2090 && spatial.y < 1180)
						{
							EntityUtils.removeAllWordBalloons(this);
							if(spatial.x >= 1630 && spatial.x <= 1670) tryGiveDummyHead();
							else CharUtils.moveToTarget(player, 1650, 1125, false, tryGiveDummyHead, new Point(20, 50)).setDirectionOnReached("right");
							return;
						}
					}
					break;
				
				case "gum_paint_head": // after giving dummy head to Nostrand, need to check if enough gum
					if(gumCount >= 5)
					{
						removePlayerGum(5, "nostrand");
						_nostrand.get(Dialog).sayById("gum_for_head");
					}
					else
					{
						shellApi.getItem(_events.DUMMY_HEAD);
						player.get(Dialog).sayById("wrong_gum_head");
					}
					CharUtils.lockControls(player, false, false);
					break;
				
				case "use_uncooked_pasta":
					if(shellApi.checkItemUsedUp(_events.SUNFLOWER))
					{
						if(shellApi.checkEvent("give_tonight"))
						{
							_nostrand.get(Dialog).sayById("already_painting");
							return;
						}
						
						spatial = player.get(Spatial);
						if(spatial.x > 1570 && spatial.x < 2090 && spatial.y < 1180)
						{
							EntityUtils.removeAllWordBalloons(this);
							if(spatial.x >= 1630 && spatial.x <= 1670) tryGiveNoodle();
							else CharUtils.moveToTarget(player, 1650, 1125, false, tryGiveNoodle, new Point(20, 50)).setDirectionOnReached("right");
							return;
						}
					}
					break;
				
				case "gum_paint_noodle":
					if(gumCount >= 7)
					{
						removePlayerGum(7, "nostrand");
						player.get(Dialog).sayById("gum_for_noodle");
					}
					else
					{
						shellApi.getItem(_events.UNCOOKED_PASTA);
						player.get(Dialog).sayById("wrong_gum_noodle");
					}
					CharUtils.lockControls(player, false, false);
					break;
				
				case "use_metal_cup":
				case "use_plaster_cup":
					spatial = player.get(Spatial);
					if(spatial.x > 2000 && spatial.x < 2600 && spatial.y > 800 && spatial.y < 1310)
					{
						EntityUtils.removeAllWordBalloons(this);
						CharUtils.moveToTarget(player, 2250, 1185, false, getWaterCup, new Point(20, 40)).setDirectionOnReached("right");
						return;
					}
					break;
				
				case "steal_paint":
					var sreenEffects:ScreenEffects = new ScreenEffects();
					screenEffects.fadeToBlack(1, takeAwayArtSupplies, [screenEffects]);
					break;
			}
			
			if(event.indexOf("spoke_to_") != -1)
			{
				var id:String = event.substr("spoke_to_".length);
				if(_introSpokenTo.indexOf(id) == -1)
					_introSpokenTo.push(id);
				
				checkIfSpokenToAll();
			}
			
			super.eventTriggered( event, makeCurrent, init, removeEvent );
		}
		
		private function tryGiveDummyHead(...args):void
		{
			CharUtils.lockControls(player, true);
			_nostrand.get(Dialog).sayById("try_dummy_head");
		}
		
		private function tryGiveNoodle(...args):void
		{
			CharUtils.lockControls(player, true);
			_nostrand.get(Dialog).sayById("try_pasta");
		}
		
		private function giveSunflower(...args):void
		{
			SceneUtil.lockInput(this, true);
			_nostrand.get(Dialog).sayById("give_sunflower");
		}

		private function setupAssets():void
		{			
			var statue:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["statue"]);
			BitmapTimelineCreator.convertToBitmapTimeline(statue);
			statue.get(Timeline).gotoAndStop(shellApi.profileManager.active.gender);
			
			// Florians weights
			makeEntity( _hitContainer[ "weight" ]);
			
			// Prison door interaction
			var exitInt:SceneInteraction = new SceneInteraction();
			exitInt.reached.add(approachPrisonEntrance);
			getEntityById("exitInteraction").add(exitInt);
			
			// Basketball hoop - has to layer above player on platform 4
			var clip:MovieClip								=	_hitContainer[ "basketballHoop" ];
			convertContainer(clip, 1);
			var entity:Entity								=	makeEntity( clip , null );
			var platformDepth:PlatformDepthCollider			=	new PlatformDepthCollider( 2 );
			platformDepth.depth								=	4;			
			entity.add( platformDepth );
			TimelineUtils.convertClip(clip, this, entity, null, false);
			this.getEntityById("bounce_hoop").add(new TriggerHit(entity.get(Timeline)));
			this.addSystem(new TriggerHitSystem());
			
			// canvas
			if(!shellApi.checkEvent(_events.TAKE_AWAY_PAINT))
			{
				var canvas:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["canvas"]);
				canvas.add(new Id("canvas"));
				BitmapTimelineCreator.convertToBitmapTimeline(canvas, null, true, null, 1);
				var frameNum:int = 4;
				if(!shellApi.checkItemUsedUp(_events.SUNFLOWER))
				{
					frameNum = Math.min(Math.floor(currentDay / 3), 3);
				}
				canvas.get(Timeline).gotoAndStop(frameNum);
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["canvas"]);
			}
			
			// Seeds
			var seeds:Entity = getEntityById("sunflower_seeds");
			var seedClip:MovieClip = _hitContainer["seedAnimation"];
			if(seeds)
			{
				seeds.remove(Item)
				seeds.get(Display).visible = false;
				ToolTipCreator.removeFromEntity(seeds);
			}
			else
			{
				seedClip.removeChild(seedClip["sunflower1"]);
				seedClip.removeChild(seedClip["sunflower2"]);
				seedClip.removeChild(seedClip["sunflower3"]);
			}
			_seedsAnim = EntityUtils.createSpatialEntity(this, seedClip);
			_seedsAnim = BitmapTimelineCreator.convertToBitmapTimeline(_seedsAnim);
			_seedsAnim.get(Display).visible = false;
			
			// Water drip
			var waterDrip:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["waterDrip"]);
			waterDrip = BitmapTimelineCreator.convertToBitmapTimeline(waterDrip);
			waterDrip.get(Timeline).play();
			waterDrip.get(Timeline).handleLabel("ground", Command.create(waterDripSound, waterDrip),false);
			
			// Bust interaction
			var bustEnt:Entity = getEntityById("bustInteraction");
			var bustSceneInt:SceneInteraction = new SceneInteraction();
			bustSceneInt.reached.add(bustDescription);
			bustEnt.add(bustSceneInt);
			
			// Sunflower
			if(!shellApi.checkItemEvent(_events.SUNFLOWER))
			{
				_sunflowerAnim = EntityUtils.createSpatialEntity(this, _hitContainer["sunflowerAnim"]);
				_sunflowerAnim = BitmapTimelineCreator.convertToBitmapTimeline(_sunflowerAnim);
				var array:Array = DataUtils.getArray(shellApi.getUserField(_events.SUNFLOWER_FIELD, shellApi.island));	
				
				_sunflowerDays = DataUtils.getNumber(array[0]);
				_sunflowerLastWaterDay = DataUtils.getNumber(array[1]);
				if(!_sunflowerDays)_sunflowerDays = 0;
				_sunflowerAnim.get(Timeline).gotoAndStop(_sunflowerDays);
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["sunflowerAnim"]);
			}
			
			var i:int;
			if(!shellApi.checkEvent(_events.YARD_INTRO_SHOWN))
			{	
				bigTunaExercising();				
				removeEntity(getEntityById("sunflowerInteraction"));
			}
			else
			{				
				if(!shellApi.checkItemEvent(_events.SUNFLOWER))
				{
					var sunflowerInt:Entity = getEntityById("sunflowerInteraction");
					var sceneInteraction:SceneInteraction = new SceneInteraction();
					sceneInteraction.reached.add(sunflowerInteraction);
					sunflowerInt.add(sceneInteraction);
				}
				else
				{
					removeEntity(getEntityById("sunflowerInteraction"));
				}
			}
			
			setupBird();
			setupCanary();
			nostrandPainting();
			marionReading();
			florianPreening();
		}
		
		private function bustDescription(...args):void
		{
			player.get(Dialog).sayById("bust_description");
		}
		
		private function waterDripSound(waterDrip:Entity):void
		{			
			AudioUtils.playSoundFromEntity(waterDrip, SoundManager.EFFECTS_PATH + "drip_0" + GeomUtils.randomInt(1, 3) + ".mp3", 700, 0,1);
		}
		
		private function setupCanary():void
		{
			var clip:MovieClip = _hitContainer["canary"];
			DisplayUtils.moveToTop(clip);
			
			this.convertContainer(clip, PerformanceUtils.defaultBitmapQuality + 1.0);
			_canary = EntityUtils.createMovingEntity(this, clip);
			_canary = TimelineUtils.convertAllClips(clip, null, this, true, 32, _canary);
			randomCanaryChirp();
			
			_characterGroup.addTimelineFSM(_canary, true, new <Class>[SeagullIdleState, SeagullBeginFlightState, SeagullFlyState, SeagullLandState, SeagullEatingState], MovieclipState.STAND, false);
			
			var display:Display = _canary.get(Display);
			display.setContainer(SkinUtils.getSkinPartEntity(_patches, SkinUtils.HEAD).get(Display).displayObject);
			
			var spatial:Spatial = _canary.get(Spatial);
			var patchesSpatial:Spatial = _patches.get(Spatial);
			spatial.x = -10;
			spatial.y = -28;
			spatial.scale = 3;
			
			var motionTarget:MotionTarget = _canary.get(MotionTarget);
			motionTarget.targetX = spatial.x;
			motionTarget.targetY = spatial.y;
			
			_canary.add(new Seagull());
			_canary.add(new Audio());
			_canary.add(new AudioRange(700, 0, 1, Linear.easeIn));
		}
		
		private function randomCanaryChirp():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(GeomUtils.randomInRange(3,8), 1, birdChirp));
		}
		
		private function birdChirp():void
		{
			if(_canary.get(FSMControl).state.type == MovieclipState.STAND)
			{
				var head:Timeline = TimelineUtils.getChildClip(_canary, "head").get(Timeline);
				head.gotoAndPlay("chirp");
				AudioUtils.playSoundFromEntity(_patches, SoundManager.EFFECTS_PATH + "small_bird_call_0" + GeomUtils.randomInt(1,3) + ".mp3", 800, 1, 2, Linear.easeInOut);
			}
			randomCanaryChirp();
		}
		
		private function setupBird():void
		{
			updateNests();
			_birdAtNest = true;
			var clip:MovieClip = _hitContainer["seagull"];			
			DisplayUtils.moveToOverUnder(_hitContainer["nestFront"], player.get(Display).displayObject, false);
			DisplayUtils.moveToOverUnder(clip, _hitContainer["nestFront"], false);
			
			_seagull = EntityUtils.createMovingEntity(this, clip);			
			TimelineUtils.convertClip(clip, this, _seagull);
			if(AppConfig.mobile)
			{
				BitmapTimelineCreator.convertToBitmapTimeline(_seagull);
			}
			
			_characterGroup.addTimelineFSM(_seagull, true, new <Class>[SeagullIdleState, SeagullBeginFlightState, SeagullFlyState, SeagullLandState, SeagullEatingState, SeagullSittingAngryState, SeagullHopState], MovieclipState.STAND, false);
			
			_seagull.get(FSMControl).stateChange = new Signal();
			_seagull.get(FSMControl).stateChange.add(seagullStateChange);
			
			var motionTarget:MotionTarget = _seagull.get(MotionTarget);	
			var spatial:Spatial = _seagull.get(Spatial);
			var scaleX:Number = -1;
			if(_currentNest != null)
			{
				var nestSpatial:Spatial = _currentNest.get(Spatial);
				motionTarget.targetX = spatial.x = nestSpatial.x;
				motionTarget.targetY = spatial.y = nestSpatial.y;
				spatial.scaleX = scaleX = nestSpatial.scaleX;
			}
			else
			{
				motionTarget.targetX = spatial.x = -100;
				motionTarget.targetY = spatial.y = 0;
			}		
			
			_seagull.add(new Seagull(640, 180, scaleX));
			_seagull.add(new Audio());
			_seagull.add(new AudioRange(1000, 0, 1, Sine.easeIn));
			_seagull.remove(Sleep);
		}
		
		private function updateNests():void
		{
			var nestZone:Entity = getEntityById("nestZone");
			var nestFront:MovieClip = _hitContainer["nestFront"];
			
			// setup inital nests
			var nest1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["nest" + 1]);
			nest1 = BitmapTimelineCreator.convertToBitmapTimeline(nest1);
			nest1.get(Timeline).gotoAndStop(1);
			
			var nest2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["nest" + 2]);
			nest2 = BitmapTimelineCreator.convertToBitmapTimeline(nest2);
			nest2.get(Timeline).gotoAndStop(1);
			
			var nest3:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["nest" + 3]);
			nest3 = BitmapTimelineCreator.convertToBitmapTimeline(nest3);
			nest3.get(Timeline).gotoAndStop(1);
			
			if(shellApi.checkEvent(_events.EGGS_COLLECTED + "3"))
			{
				_currentNest = null;
				_hitContainer.removeChild(nestFront);
				removeEntity(nestZone);
				return;
			}
			else if(shellApi.checkEvent(_events.EGGS_COLLECTED + "2"))
			{
				nest3.get(Timeline).gotoAndStop(0);
				_currentNest = nest3;
				_currentEggNum = 3;
			}
			else if(shellApi.checkEvent(_events.EGGS_COLLECTED + "1"))
			{
				nest2.get(Timeline).gotoAndStop(0);
				_currentNest = nest2;
				_currentEggNum = 2;
				InteractionCreator.addToEntity(nest2, [InteractionCreator.CLICK]);		
				removeEntity(nest3);
			}			
			else
			{				
				nest1.get(Timeline).gotoAndStop(0);
				_currentNest = nest1;
				_currentEggNum = 1;
				removeEntity(nest2);
				removeEntity(nest3);
			}			
			
			// setup the zone
			var nestSpatial:Spatial = _currentNest.get(Spatial);
			if(!shellApi.checkEvent(_events.EGGS_COLLECTED + "3"))
			{				
				nestZone.get(Zone).entered.add(enteredNestZone);
				nestZone.get(Display).isStatic = false;
				
				var nestZoneSpatial:Spatial = nestZone.get(Spatial);				
				nestZoneSpatial.x = nestSpatial.x;
				nestZoneSpatial.y = nestSpatial.y;
				nestZoneSpatial.scaleX = nestSpatial.scaleX;				
			}
			else
			{
				// If we collected all, just have the bird at the last nest with no egg
				removeEntity(nestZone);
				_currentNest.get(Timeline).gotoAndStop(1);
				_currentEggNum = 3;
			}			
			
			nestFront.x = nestSpatial.x;
			nestFront.y = nestSpatial.y;
			nestFront.scaleX = nestSpatial.scaleX;
		}
		
		private function enteredNestZone(...args):void
		{			
			if(_birdAtNest)
			{
				// Bird Attack!!!
				CharUtils.lockControls(player);
				var playerFSM:FSMControl = player.get(FSMControl);
				
				if(playerFSM.state.type != CharacterState.STAND)
				{
					playerFSM.stateChange = new Signal();
					playerFSM.stateChange.add(playerStateChangeSeagullAttack);
				}
				else
				{
					playerStateChangeSeagullAttack(CharacterState.STAND, null);
				}
			}
			else if(!shellApi.checkEvent(_events.EGGS_COLLECTED + _currentEggNum))
			{
				// give egg
				shellApi.triggerEvent(_events.EGGS_COLLECTED + _currentEggNum, true);
				_currentNest.get(Timeline).gotoAndStop(1);				
				shellApi.getItem(_events.EGGS, null);
				_itemGroup.showItem(_events.EGGS);
			}
		}
		
		private function playerStateChangeSeagullAttack(state:String, entity:Entity):void 
		{
			if(state == CharacterState.STAND)
			{
				var playerSpatial:Spatial = player.get(Spatial);
				var seagullSpatial:Spatial = _seagull.get(Spatial);
				
				if(Math.abs(playerSpatial.y - seagullSpatial.y) < 100 && Math.abs(playerSpatial.x - seagullSpatial.x) < 300)
				{				
					_seagull.get(FSMControl).getState(MovieclipState.STAND).angryInterrupt = true;
					player.get(Motion).velocity = new Point(-300 * _seagull.get(Spatial).scaleX, -400);
					var playerFSM:FSMControl = player.get(FSMControl);
					playerFSM.setState(CharacterState.HURT);
					
					// clear out the signal
					if(playerFSM.stateChange)
					{
						playerFSM.stateChange.removeAll();
						playerFSM.stateChange = null;
					}
				}
				CharUtils.lockControls(player, false, false);
			}
		}
		
		private function seagullStateChange(state:String, entity:Entity):void
		{
			if(state == "beginFlight")
			{
				_birdAtNest = !_birdAtNest;
				_seagull.get(FSMControl).getState(MovieclipState.LAND).feeding = !_birdAtNest;	
			}
			else if(state == "eating")
			{
				var target:MotionTarget = _seagull.get(MotionTarget);
				if(_currentNest)
				{
					var spatial:Spatial = _currentNest.get(Spatial);
					target.targetX = spatial.x;
					target.targetY = spatial.y;
				}
				
				_seagull.get(FSMControl).stateChange.add(finishedEatingSeeds);
			}
			else if(state == "hop")
			{
				_seedsAnim.get(Timeline).gotoAndStop("less" + _less);
				_less++;
			}
		}
		
		private function finishedEatingSeeds(state:String, entity:Entity):void
		{
			if(state == MovieclipState.STAND)
			{
				_seagull.get(FSMControl).stateChange.remove(finishedEatingSeeds);
				removeEntity(_seedsAnim);
				
				if(!shellApi.checkItemEvent(_events.SUNFLOWER_SEEDS))
				{
					SceneUtil.setCameraTarget(this, player);
					SceneUtil.lockInput(this, false);
					var seeds:Entity = getEntityById("sunflower_seeds")
					seeds.add(new Item());
					seeds.get(Display).visible = true;		
					ToolTipCreator.addToEntity(seeds);
				}
			}
		}
		
		/**
		 * Generic inmate logic
		 */
		private function instantiateInmates():void
		{
			_bigTuna =	getEntityById( BIG_TUNA );		
			if(_bigTuna)
			{
				_bigTuna.remove(SceneInteraction);
				var sceneInt:SceneInteraction = new SceneInteraction();
				sceneInt.targetX = 2400;
				sceneInt.reached.add(playerReachedBigTuna);
				_bigTuna.add(sceneInt);
			}
			
			_florian =	getEntityById( FLORIAN );
			
			var collider:PlatformDepthCollider;
			
			_marion = getEntityById( MARION );	
			collider = new PlatformDepthCollider();
			collider.manualDepth = true;
			_marion.add(collider);
			collider.depth = 1;
			collider.priority = 2;
			
			_nostrand =	getEntityById( NOSTRAND );	
			collider = new PlatformDepthCollider();
			collider.manualDepth = true;
			_nostrand.add(collider);
			collider.depth = 6;
			
			_patches =	getEntityById( PATCHES );			
			_ratchet =	getEntityById( RATCHET );			
			_warden	=	getEntityById( WARDEN );
			Spatial( _warden.get( Spatial )).y				=	-1000;
			Display( _warden.get( Display )).visible		=	false;
		}
		
		private function playerReachedBigTuna(...args):void
		{
			_bigTuna.get(Dialog).sayById("grunt");
		}
		
		/**
		 * Big Tuna functions
		 */
		private function bigTunaExercising():void
		{
			if(!shellApi.checkEvent(_events.DRILLED_PLATE))
			{
				// Remove smile from his workout
				var scoreAnimation:Score						=	_animationLoader.animationLibrary.getAnimation( Score ) as Score;
				scoreAnimation.data.frames[ 0 ].events.pop();
				scoreAnimation.data.frames[ 0 ].events.pop();
				
				// Give Big Tuna the Hurl, Score animations
				var animControl:AnimationControl				=	_bigTuna.get( AnimationControl );
				var animEntity:Entity							=	animControl.getEntityAt();
				var animSequencer:AnimationSequencer			=	animEntity.get( AnimationSequencer );
				
				if( animSequencer == null )
				{
					animSequencer = new AnimationSequencer();
					animEntity.add( animSequencer );
				}
				
				var sequence:AnimationSequence					=	new AnimationSequence();
				sequence.loop 									=	true;
				sequence.add( new AnimationData( Hurl ));
				sequence.add( new AnimationData( Score ));
				
				CharUtils.getTimeline(_bigTuna).handleLabel("hurl", rattleTuna, false);
				CharUtils.getTimeline(_bigTuna).handleLabel("score", rattleTuna, false)
				
				animSequencer.currentSequence = sequence;
				animSequencer.start = true;
			}
		}
		
		private function rattleTuna():void
		{
			AudioUtils.playSoundFromEntity(_bigTuna, SoundManager.EFFECTS_PATH + "metal_rattle_02.mp3", 600, .5, 1.5, Linear.easeInOut);
		}
		
		/**
		 * Florian functions
		 */
		private function florianPreening():void
		{
			if(!shellApi.checkEvent(_events.DRILLED_PLATE))
			{
				// Remove caprisun ad lenseflare
				var flexAnimation:Flex							=	_animationLoader.animationLibrary.getAnimation( Flex ) as Flex;
				flexAnimation.data.frames[ 15 ].events.pop();
				
				// Give Florian the Proud, Stand, WeightLift animations
				var animControl:AnimationControl				=	_florian.get( AnimationControl );
				var animEntity:Entity							=	animControl.getEntityAt();
				var animSequencer:AnimationSequencer			=	animEntity.get( AnimationSequencer );
				
				if( animSequencer == null )
				{
					animSequencer = new AnimationSequencer();
					animEntity.add( animSequencer );
				}
				
				var sequence:AnimationSequence					=	new AnimationSequence();
				sequence.loop 									=	true;
				sequence.add( new AnimationData( WeightLifting ));
				sequence.add( new AnimationData( Proud ));
				sequence.add( new AnimationData( Flex ));
				sequence.add( new AnimationData( Stand, 250 ));
	
				animSequencer.currentSequence = sequence;
				animSequencer.start = true;
				
				var timeline:Timeline 							=	_florian.get( Timeline );
				timeline.handleLabel( "weightLifting", startLift, false );
				timeline.handleLabel( "proud", toggleBarBell, false );
			}
		}
		
		private function startLift():void
		{
			toggleBarBell( true );
		}
		
		private function toggleBarBell( toggleItemOff:Boolean = false ):void
		{
			if(!toggleItemOff)
				AudioUtils.playSoundFromEntity(_florian, SoundManager.EFFECTS_PATH + "metal_impact_12.mp3", 600, .5, 1.5, Linear.easeInOut);
			
			var barbellItem:Entity 							=	SkinUtils.getSkinPartEntity( _florian, SkinUtils.ITEM );
			var barbell:Entity 								=	getEntityById( "weight" );
	
			Display( barbellItem.get( Display )).visible	=	toggleItemOff;
			Display( barbell.get( Display )).visible 		=	!toggleItemOff;
		}
		
		/**
		 * Marion functions
		 */
		private function marionReading():void
		{			
			// Set Marion to Sit ( legs ) and Read
			CharUtils.setAnim( _marion, Sit, false, 0, 0, true );
			
			var joint:String;
			var animControl:AnimationControl				=	_marion.get( AnimationControl );
			var animEntity:Entity;
			var rigAnim:RigAnimation						=	animControl.getAnimAt( 1 );
			
			if( rigAnim == null )
			{
				animEntity									=	AnimationSlotCreator.create( _marion );
				rigAnim										=	animEntity.get( RigAnimation ) as RigAnimation;
			}
			
			for each( joint in _upperJoints )
			{
				rigAnim.addParts( joint );
			}
			rigAnim.next 									=	Read;
			rigAnim.loop									=	true;
		}
		
		/**
		 * Nostrand functions
		 */
		private function nostrandPainting():void
		{	
			var dialog:Dialog 								=	_nostrand.get( Dialog );
			dialog.faceSpeaker 								=	false;
			
			if(!shellApi.checkEvent(_events.TAKE_AWAY_PAINT))
			{
				// Force eyes on easel
				var thinkAnimation:Think						=	_animationLoader.animationLibrary.getAnimation( Think ) as Think;
				thinkAnimation.data.frames[ 0 ].events.pop();
				thinkAnimation.data.frames[ 0 ].events.pop();
				thinkAnimation.data.frames[ 0 ].events.pop();
				
				var frameEvent:FrameEvent						=	new FrameEvent( "setPart", "mouth", "thinking" );
				thinkAnimation.data.frames[ 0 ].events.push( frameEvent );		
				
				var eyes:Eyes									=	Eyes( _nostrand.get( Rig ).getPart( SkinUtils.EYES ).get( Eyes ));
				SkinUtils.setEyeStates( _nostrand, eyes.permanentState, EyeSystem.FRONT, true );
				
				// Give him the Think, Paint animations
				var animControl:AnimationControl				=	_nostrand.get( AnimationControl );
				var animEntity:Entity							=	animControl.getEntityAt();
				var animSequencer:AnimationSequencer			=	animEntity.get( AnimationSequencer );
				
				if( animSequencer == null )
				{
					animSequencer = new AnimationSequencer();
					animEntity.add( animSequencer );
				}
				
				var sequence:AnimationSequence					=	new AnimationSequence();
				sequence.loop 									=	true;
				sequence.add( new AnimationData( Think, 160 ));
				sequence.add( new AnimationData( Sword ));
				
				animSequencer.currentSequence = sequence;
				animSequencer.start = true;
			}
			else
			{
				takeAwayArtSupplies();			
			}
		}

		
		private function checkIfSpokenToAll():void
		{
			if(_introSpokenTo.indexOf(NOSTRAND) != -1 &&
				_introSpokenTo.indexOf(PATCHES) != -1 &&
				_introSpokenTo.indexOf(FLORIAN) != -1 &&
				_introSpokenTo.indexOf(MARION) != -1)
			{
				showWarden();
			}
		}
		
		private function showWarden():void
		{
			SceneUtil.lockInput( this );
			var spatial:Spatial	= _ratchet.get( Spatial );
			
			var actions:ActionChain = new ActionChain( this );
			actions.addAction( new PanAction( _ratchet ));
			actions.addAction( new TalkAction( _ratchet, "line_up" ));
			actions.addAction( new PanAction( player ));
			actions.addAction(new MoveAction(player, new Point(1150, 1530)));
			actions.addAction( new MoveAction( _ratchet, new Point( spatial.x - 100, spatial.y )));
			actions.addAction( new TalkAction( _patches, "meet_warden" ));		
			actions.addAction( new CallFunctionAction( moveInRatchet ));
			actions.addAction( new CallFunctionAction( fallInLine  ));
			actions.addAction( new MoveAction( _warden, new Point( 900, 1530 )));
			actions.addAction( new AnimationAction( _warden, Proud ));
			actions.addAction( new TalkAction( _warden, "statue" ));
			actions.addAction( new CallFunctionAction( meetPlayer ));
			actions.execute();
		}
		
		private function approachPrisonEntrance(...args):void
		{
			SceneUtil.lockInput( this );
			CharUtils.lockControls( player );
			
			CharUtils.moveToTarget( _ratchet, Spatial( player.get( Spatial )).x - 100, 1530, true, pushPlayerAnimation, new Point(50, 100) );
		}
		
		private function pushPlayerAnimation( $ratchet:Entity ):void
		{
			CharUtils.setDirection( _ratchet, true );
			CharUtils.setAnim( _ratchet, PointPistol );
			
			var timeline:Timeline =	_ratchet.get( Timeline );
			timeline.handleLabel( "ending", shovePlayer );
		}
		
		private function shovePlayer():void
		{
			var motion:Motion								=	player.get( Motion );
			motion.velocity.x								=	450;
			motion.velocity.y 								=	-250;
			
			CharUtils.setDirection(_ratchet, true);
			var dialog:Dialog								=	_ratchet.get( Dialog );
			
			var dialogId:String = shellApi.checkEvent(_events.YARD_INTRO_SHOWN) ? "nice_try" : "try_day1";
			dialog.sayById( dialogId);
			dialog.complete.addOnce( moveRatchetBack );
		}
		
		private function moveRatchetBack( dialogData:DialogData = null ):void
		{
			CharUtils.moveToTarget( _ratchet, 400, 1530, true, ratchetFaceYard );

			if( Spatial( player.get( Spatial )).x < 410 )
			{
				CharUtils.moveToTarget( player, 500, 1530, true, unlockPlayer );
			}
			else
			{
				unlockPlayer();
			}
		}
		
		private function ratchetFaceYard( $ratchet:Entity ):void
		{
			CharUtils.setDirection( _ratchet, true );
		}
		
		private function unlockPlayer(...args ):void
		{
			CharUtils.stateDrivenOn(player);
			CharUtils.lockControls( player, false, false );
			SceneUtil.lockInput( this, false );
		}		
		
		/**
		 * Utility functions
		 */
		private function makeEntity( clip:MovieClip, interactionHandler:Function = null ):Entity
		 {
			 if( PerformanceUtils.defaultBitmapQuality < PerformanceUtils.QUALITY_HIGH )
			 {
				 super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			 }
			 
			 var entity:Entity 								=	EntityUtils.createSpatialEntity( this, clip );
			 entity.add( new Id( clip.name ));
			 
			 if( interactionHandler )
			 {
				 InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				 ToolTipCreator.addToEntity( entity );
				 
				 var sceneInteraction:SceneInteraction		=	new SceneInteraction();
				 sceneInteraction.validCharStates			=	new <String>[ CharacterState.STAND ];
				 sceneInteraction.reached.add( interactionHandler );
				 entity.add( sceneInteraction );
			 }
			 
			 return entity;
		 }
		
		private function setMaxSpeed( character:Entity, maxVelocityX:Number ):void
		{
			var charMotion:CharacterMotionControl			=	character.get( CharacterMotionControl );
			if( !charMotion )
			{
				charMotion									=	new CharacterMotionControl();
				character.add( charMotion );
			}
			charMotion.maxVelocityX							=	maxVelocityX;		
		}
		
		private function reorderDepth( character:Entity ):void
		{
			var platformDepth:PlatformDepthCollider			=	new PlatformDepthCollider();
			
			platformDepth.manualDepth						=	true;
			platformDepth.depth								=	_lineDepth;
			platformDepth.priority							=	-_lineDepth;
			character.add(platformDepth);
			
			_lineDepth --;
		}
		
		private function fallInLine():void
		{
			var inmateName:String;
			var inmate:Entity;
			
			var animControl:AnimationControl;
			var animEntity:Entity;
			var rigAnim:RigAnimation;
			var animSequencer:AnimationSequencer;
			
			for each( inmateName in _inmates )
			{
				inmate										=	getEntityById( inmateName );
				
				_characterGroup.addFSM( inmate, true, null, CharacterState.STAND, true );
				animControl								=	inmate.get( AnimationControl );
				
				for( var number:int = 0; number < animControl.numSlots; number ++ )
				{
					animEntity							=	animControl.getEntityAt( number );
					rigAnim								=	animEntity.get( RigAnimation );
					
					rigAnim.end;
					rigAnim.next						=	Stand;
				}
				
				animSequencer							=	animEntity.get( AnimationSequencer );
				animSequencer.reset();
				
				getInLine( inmate, faceLeft );
				reorderDepth( inmate );
				
				SkinUtils.emptySkinPart( inmate, SkinUtils.ITEM );
				SkinUtils.emptySkinPart( inmate, SkinUtils.ITEM2 );
			}	
				
			getInLine( player, faceLeft );
			Spatial( _warden.get( Spatial )).y				=	1530;
			Display( _warden.get( Display )).visible		=	true;
			
			setMaxSpeed( _warden, 175 );
			setMaxSpeed( _ratchet, 155 );
			reorderDepth( _warden );
			reorderDepth( _ratchet );
			reorderDepth( player );
		}
		
		private function getInLine( inmate:Entity, handler ):void
		{
			var destination:Destination						=	CharUtils.moveToTarget( inmate, _linePosition, 1530, true, handler );
			destination.ignorePlatformTarget				=	true;
			
			_linePosition									+=	75;
		}
		
		private function faceLeft( inmate:Entity, faceRight:Boolean = false ):void
		{
			CharUtils.setDirection( inmate, faceRight );
		}
		
		private function meetPlayer():void
		{
			SceneUtil.setCameraTarget( this, _warden );
			
			var dialog:Dialog								=	_warden.get( Dialog );
			dialog.sayById( "new_guest" );
			
			dialog											=	player.get( Dialog );
			dialog.complete.addOnce( bringInRatchet );
			
			CharUtils.moveToTarget( _warden, Spatial( player.get( Spatial )).x - 200, 1530 );
			CharUtils.moveToTarget( _ratchet, Spatial( player.get( Spatial )).x - 300, 1530 );
			
			var inmateName:String;
			var inmate:Entity;
			//each( inmateName in _inmates )
			for( var number:int = _inmates.length - 1; number >= 0; number -- )
			{
				inmateName									=	_inmates[ number ];
				inmate										=	getEntityById( inmateName );
				reorderDepth( inmate );
				CharUtils.moveToTarget( inmate, Spatial( inmate.get( Spatial )).x - 400, 1530, true, Command.create( faceLeft, true ));
			}
			
			reorderDepth( _ratchet );
			reorderDepth( _warden );
		}
		
		private function moveInRatchet():void
		{
			SceneUtil.setCameraPoint( this, 900, 1530, false, 0.02 );
			CharUtils.moveToTarget( _ratchet, 800, 1530, true );
		}
		
		private function bringInRatchet( dialogData:DialogData ):void
		{
			reorderDepth( _ratchet );
			setMaxSpeed( _ratchet, 300 );
			
			var dialog:Dialog								=	_ratchet.get( Dialog );
			dialog.sayById( "silence" );
			CharUtils.moveToTarget( _ratchet, Spatial( _warden.get( Spatial )).x + 100, 1530, true );
		}
		
		private function bigTunaRushesPlayer():void
		{			
			var npcNodes:NodeList;
			var npcNode:NpcNode;
			var npc:Entity;
			var timeline:Timeline;
			
			npcNodes									=	systemManager.getNodeList( NpcNode );
			for( npcNode = npcNodes.head; npcNode; npcNode = npcNode.next )
			{
				npc										=	npcNode.entity;
				if( npc != _bigTuna )
				{
					CharUtils.setDirection( npc, false );
					
					if( npc != _ratchet && npc != player && npc != _warden )
					{
						CharUtils.setAnim( npc, Grief );
						
						timeline								=	npc.get( Timeline );
						timeline.handleLabel( "stand", Command.create( moveOutOfHisWay, npc ));
					}
					else if( npc == _ratchet )
					{
						setMaxSpeed( npc, 800 );
						CharUtils.moveToTarget( npc, Spatial( _warden.get( Spatial )).x - 150, 1530 );
					}
				}
			}
		}
		
		private function moveOutOfHisWay( character:Entity ):void
		{
			CharUtils.moveToTarget( character, Spatial( character.get( Spatial )).x + 850, 1530, true, Command.create( faceLeft, false ));
		}
		
		private function ratchetStopsBigTuna():void
		{
			reorderDepth( _bigTuna );
			CharUtils.moveToTarget( _bigTuna, Spatial( _ratchet.get( Spatial )).x, 1530, true, ratchetBeatsTuna );
		}
		
		private function ratchetBeatsTuna( bigTuna ):void
		{
			CharUtils.setAnim( _ratchet, Push );
			CharUtils.setAnim( _bigTuna, FightStance );
			CharUtils.setAnim( _warden, Grief );
			
			var dialog:Dialog								=	player.get( Dialog );
			dialog.sayById( "not_bb" );
			
			dialog											=	_bigTuna.get( Dialog );
			dialog.complete.addOnce( ratchetHaulsBigTunaOff );
		}
		
		private function ratchetHaulsBigTunaOff( dialogData:DialogData ):void
		{			
			var spatial:Spatial								=	_ratchet.get( Spatial );
			var tween:Tween									=	new Tween();
			tween.to( spatial, 7, { x : 200 });
			_ratchet.add( tween );		
			
			spatial											=	_bigTuna.get( Spatial );
			tween											=	new Tween();
			tween.to( spatial, 7, { x : 200 });
			_bigTuna.add( tween );
			
			SceneUtil.setCameraTarget( this, _warden );	
			var dialog:Dialog								=	_warden.get( Dialog );
			dialog.faceSpeaker								=	true;
			dialog.sayById( "wrap_up" );
			dialog.complete.addOnce( wardenExits );
		}
		
		private function wardenExits( dialogData:DialogData ):void
		{
			shellApi.completeEvent(_events.YARD_INTRO_SHOWN);
			SceneUtil.setCameraTarget( this, player );
			setMaxSpeed( _warden, 800 );
					
			CharUtils.setAnim( player, Pop );
			CharUtils.moveToTarget( _warden, 100, 1530, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, gotoWork));
		}
		
		private function gotoWork( ...args ):void
		{
			openSchedule(this);
		}
		
		private function getWaterCup(...args):void
		{
			SceneUtil.lockInput(this, true);
			CharUtils.setAnim(player, PointItem);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "prison_cup", false);
			CharUtils.getTimeline(player).handleLabel("ending", giveWaterCup);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "drip_05.mp3");
		}
		
		private function giveWaterCup(...args):void
		{
			shellApi.getItem(_events.CUP_OF_WATER, null, true);
			shellApi.removeItem(_events.METAL_CUP);
			shellApi.removeItem(_events.CUP_OF_PLASTER);
			shellApi.saveGame();
			SceneUtil.lockInput(this, false);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM);
		}
		
		private function plantSeeds(...args):void
		{
			shellApi.removeItem(_events.SUNFLOWER_SEEDS);
			var itemGroup:ItemGroup = super.getGroupById("itemGroup") as ItemGroup;
			itemGroup.takeItem(_events.SUNFLOWER_SEEDS, "sunflowerInteraction", "", null, seedsPlanted);
			shellApi.completeEvent(_events.PLANTED_SEEDS);
		}
		
		private function seedsPlanted():void
		{
			_sunflowerDays = 1;
			_sunflowerAnim.get(Timeline).gotoAndStop(_sunflowerDays);
			shellApi.setUserField(_events.SUNFLOWER_FIELD, _sunflowerDays.toString() + "," + currentDay, shellApi.island, true);
			SceneUtil.lockInput(this, false);
			player.get(Dialog).sayById("need_water");
		}

		private function sunflowerInteraction(player:Entity, interaction:Entity):void
		{
			// haven't gotten the sunflowers yet
			if(!shellApi.checkItemUsedUp(_events.SUNFLOWER_SEEDS))
			{
				player.get(Dialog).sayById("not_planted");
				return;
			}			
			
			// the total days has passed, pick the sunflower
			if(_sunflowerDays >= TOTAL_SUNFLOWER_DAYS)
			{
				shellApi.getItem(_events.SUNFLOWER, null, true);
				getEntityById("sunflowerInteraction").get(SceneInteraction).reached.removeAll();
				removeEntity(_sunflowerAnim);
				removeEntity(getEntityById("sunflowerInteraction"));
			}
			else if(_sunflowerDays <= 1)
			{
				player.get(Dialog).sayById("need_water");
			}
			else
			{
				player.get(Dialog).sayById("sunflower_not_ready");			
			}
		}
		
		private function waterPlants(...p):void
		{
			if(_sunflowerLastWaterDay < currentDay)
			{
				_wateredToday = true;
				shellApi.removeItem(_events.CUP_OF_WATER);
				shellApi.getItem(_events.METAL_CUP);
				var itemGroup:ItemGroup = super.getGroupById("itemGroup") as ItemGroup;
				itemGroup.takeItem(_events.CUP_OF_WATER, "sunflowerInteraction", "", null, showFlowerCartoon);
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "pour_water_on_dirt_01.mp3");
				
				_sunflowerDays++;
				_sunflowerLastWaterDay = currentDay;
				shellApi.setUserField(_events.SUNFLOWER_FIELD, _sunflowerDays.toString() + "," + _sunflowerLastWaterDay, shellApi.island, true);
			}
			else
			{
				player.get(Dialog).sayById("already_watered");
			}
		}
		
		private function showFlowerCartoon(...args):void
		{
			_sunflowerAnim.get(Timeline).gotoAndStop(_sunflowerDays);
		}
		
		private function wardenBustsNostrand(...args):void
		{
			var wardenDialog:Dialog = _warden.get(Dialog);
			wardenDialog.sayById("busted");
			wardenDialog.complete.addOnce(wardenBustsPlayer);
		}
		
		private function wardenBustsPlayer(...args):void
		{
			CharUtils.setAnim(player, Tremble);
			SceneUtil.delay(this, 1, Command.create(_warden.get(Dialog).sayById, "shirt"));
			SceneUtil.delay(this, 3, Command.create(CharUtils.setAnim, player, Stand));
		}
		
		private function takeAwayArtSupplies(screenEffects:ScreenEffects = null):void
		{
			shellApi.triggerEvent(_events.TAKE_AWAY_PAINT, true, shellApi.island);
			SkinUtils.emptySkinPart(_nostrand, SkinUtils.ITEM);
			removeEntity(getEntityById("canvas"));
			
			// Give him the Stand
			var animControl:AnimationControl				=	_nostrand.get( AnimationControl );
			var animEntity:Entity							=	animControl.getEntityAt();
			var animSequencer:AnimationSequencer			=	animEntity.get( AnimationSequencer );
			
			if( animSequencer == null )
			{
				animSequencer = new AnimationSequencer();
				animEntity.add( animSequencer );
			}
			
			var sequence:AnimationSequence					=	new AnimationSequence();
			sequence.loop 									=	true;
			sequence.add( new AnimationData( Stand));			
			animSequencer.currentSequence = sequence;
			animSequencer.start = true;
			
			if(screenEffects)
			{
				screenEffects.fadeFromBlack(1, lastLine);
			}
		}
		
		private function lastLine():void
		{
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.addAction(new TalkAction(_warden, "lesson"));
			actionChain.addAction(new MoveAction(_warden, new Point(2300, 1200), new Point(30, 30)));
			actionChain.addAction(new CallFunctionAction(removeEntity, _warden));
			actionChain.autoUnlock = true;
			actionChain.execute(unlockPlayer);
		}
		
		private function showLastDay():void
		{	
			removeEntity(_ratchet);			
			CharUtils.setAnim(_florian, Stand);
			CharUtils.setDirection(_florian, true);
			SkinUtils.emptySkinPart(_bigTuna, SkinUtils.ITEM);
			SkinUtils.emptySkinPart(_bigTuna, SkinUtils.ITEM2);
			SkinUtils.emptySkinPart(_florian, SkinUtils.ITEM);
			
			SceneUtil.lockInput(this, true);
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.addAction(new MoveAction(player, new Point(950, 1500), new Point(20, 100)));
			actionChain.addAction(new TalkAction(player, "last_time"));
			actionChain.addAction(new TalkAction(_patches, "hope"));
			actionChain.addAction(new TalkAction(player, "bird_too"));
			actionChain.addAction(new TalkAction(_patches, "mutual"));
			actionChain.addAction(new SetSpatialAction(_bigTuna, new Point(240, 1490)));
			actionChain.addAction(new SetSpatialAction(_florian, new Point(140, 1490)));
			actionChain.addAction(new AudioAction(player, SoundManager.EFFECTS_PATH + "door_hatch_01.mp3", 500, 2, 2));
			actionChain.addAction(new PanAction(_bigTuna, .1));
			actionChain.addAction(new AnimationAction(_bigTuna, Stomp));
			actionChain.addAction(new CallFunctionAction(shakeScreen))
			actionChain.addAction(new WaitAction(2));
			actionChain.addAction(new TalkAction(_bigTuna, "got_you_now"));
			actionChain.addAction(new PanAction(player));
			actionChain.addAction(new MoveAction(player, new Point(1150, 1500), new Point(20, 100), 50)).noWait = true;
			actionChain.addAction(new TalkAction(player, "help_seeds"));
			actionChain.addAction(new MoveAction(_bigTuna, new Point(940, 1500))).noWait = true;
			actionChain.addAction(new MoveAction(_florian, new Point(890, 1500))).noWait = true;
			actionChain.addAction(new TalkAction(_patches, "help"));
			actionChain.addAction(new CallFunctionAction(throwSeedsSavePlayer));			
			actionChain.execute();
		}
		
		private function shakeScreen():void
		{
			this.addSystem(new ShakeMotionSystem());
			
			var camera:Entity = this.getEntityById("camera");
			camera.add(new SpatialAddition());
			var shakeMotion:ShakeMotion = new ShakeMotion(new RectangleZone(-2, -3, 2, 3));
			camera.add(shakeMotion);
			SceneUtil.delay(this, .5, Command.create(removeShake, camera));
		}
		
		private function removeShake(camera:Entity):void
		{
			camera.remove(ShakeMotion);
		}
		
		private function throwSeedsSavePlayer():void
		{
			CharUtils.setAnim(_patches, Salute);	
			
			_seedsAnim.get(Display).visible = true;	
			var seedSpatial:Spatial = _seedsAnim.get(Spatial);			
			seedSpatial.x = 1000;
			seedSpatial.y = 1400;
			seedSpatial.scaleX *= -1;		
			
			var motionTarget:MotionTarget = _seagull.get(MotionTarget);
			_seagull.get(FSMControl).getState("eating").hop = false;
			motionTarget.targetX = 890;
			motionTarget.targetY = 1430;
					
			var seedTimeline:Timeline = _seedsAnim.get(Timeline);
			seedTimeline.gotoAndPlay("noSeeds");
			seedTimeline.handleLabel("hair", setHair);
		}
		
		private function setHair():void
		{
			_seedsAnim.get(Display).visible = false;
			SkinUtils.setSkinPart(_bigTuna, SkinUtils.HAIR, "pr_tuna_seeds");
			SkinUtils.setSkinPart(_florian, SkinUtils.HAIR, "pr_florian_seeds");
			
			var dialog:Dialog = _bigTuna.get(Dialog);
			dialog.sayById("cant_stop");			
			dialog.complete.addOnce(birdsAttack);
		}
		
		private function birdsAttack(...args):void
		{
			var loc:Point = DisplayUtils.localToLocal(_canary.get(Display).displayObject, _hitContainer);
			_canary.get(Display).setContainer(_hitContainer);
			EntityUtils.position(_canary, loc.x, loc.y);
			_canary.get(Spatial).scale = 1;
			
			var fsmControl:FSMControl = _canary.get(FSMControl);
			SeagullEatingState(fsmControl.getState("eating")).hop = false;
			SeagullLandState(fsmControl.getState(MovieclipState.LAND)).feeding = true;
			
			var target:MotionTarget = _canary.get(MotionTarget);
			target.targetX = 920;
			target.targetY = 1430;
			
			CharUtils.setAnimSequence(_bigTuna, new <Class>[Cry, Grief, Tremble], false);
			CharUtils.setAnimSequence(_florian, new <Class>[Grief, Cry], true);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, endLastTimeHere));
		}
		
		private function endLastTimeHere():void
		{
			shellApi.completeEvent(_events.ESCAPED_BIG_TUNA);
			CharUtils.moveToTarget(player, 200, 1500, false, leave);
		}
		
		private function leave(...args):void
		{
			if(shellApi.checkHasItem(_events.PRISON_FILES))
			{
				shellApi.loadScene(CellBlock);
			}
			else
			{
				shellApi.loadScene(MetalShop);
			}
		}
		
		private var _introSpokenTo:Array = new Array();
		private var _linePosition:Number = 1000;
		private var _lineDepth:Number = 0;
		
		private var _bigTuna:Entity;
		private var _florian:Entity;
		private var _marion:Entity;
		private var _nostrand:Entity;
		private var _patches:Entity;
		private var _ratchet:Entity;
		private var _warden:Entity;
		
		private var _upperJoints:Vector.<String> = new <String>[ CharUtils.ARM_BACK, CharUtils.ARM_FRONT, CharUtils.HAND_BACK, CharUtils.HAND_FRONT ]; 				
		private var _animationLoader:AnimationLoaderSystem;
		
		private const BIG_TUNA:String						=	"bigTuna";
		private const FLORIAN:String						=	"florian";
		private const MARION:String							=	"marion";
		private const NOSTRAND:String						=	"nostrand";
		private const PATCHES:String						=	"patches";
		private const RATCHET:String						=	"ratchet";
		private const WARDEN:String							=	"warden";		
		private const _inmates:Array						=	[ BIG_TUNA, FLORIAN, MARION, NOSTRAND, PATCHES ];
		
		private const TOTAL_SUNFLOWER_DAYS:Number = 5;
		private var _sunflowerDays:Number;
		private var _sunflowerLastWaterDay:Number;
		private var _sunflowerAnim:Entity;
		private var _wateredToday:Boolean = false;
		
		private const SEED_LOCATION:Point = new Point(1240, 1530);
		private var _less:int = 1;
		private var _seedsAnim:Entity;
		private var _currentNest:Entity;
		private var _currentEggNum:int = 0;
		private var _seagull:Entity;
		private var _birdAtNest:Boolean;
		private var _canary:Entity;
	}
}