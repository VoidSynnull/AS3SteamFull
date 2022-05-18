package game.scenes.survival5.sawmill
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.DepthChecker;
	import game.components.entity.Dialog;
	import game.components.entity.NPCDetector;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.hit.ValidHit;
	import game.components.motion.Destination;
	import game.components.motion.Mass;
	import game.components.motion.MotionTarget;
	import game.components.motion.MotionThreshold;
	import game.components.motion.Navigation;
	import game.components.motion.Proximity;
	import game.components.motion.PulleyConnecter;
	import game.components.motion.PulleyObject;
	import game.components.motion.PulleyRope;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Parachuting;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Ride;
	import game.data.animation.entity.character.Sneeze;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.ThrowReady;
	import game.data.animation.entity.character.Tremble;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.WaterSplash;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.survival5.ending.Ending;
	import game.scenes.survival5.sawmill.components.RotatingStep;
	import game.scenes.survival5.sawmill.components.SpinRound;
	import game.scenes.survival5.sawmill.systems.RotatingStepSystem;
	import game.scenes.survival5.sawmill.systems.SpinRoundSystem;
	import game.scenes.survival5.shared.Survival5Scene;
	import game.scenes.survival5.shared.whistle.ListenerData;
	import game.scenes.survival5.shared.whistle.WhistleListener;
	import game.systems.entity.NPCDetectionSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.ControlJumpState;
	import game.systems.entity.character.states.IdleState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.StandState;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.PulleySystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class Sawmill extends Survival5Scene
	{
		public function Sawmill()
		{
			super();
			this.whistleListeners.push(new ListenerData("buren", caughtByDog, 350, new Rectangle(1560, 900, 1500, 900), 2, 2, new Point(2045, 1260), new Point(3500, 1260)));
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/sawmill/";
			
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
			if(!shellApi.checkHasItem(_events.SURVIVAL_MEDAL))
			{
				if(shellApi.checkEvent(_events.ATTACHED_GEAR) && shellApi.checkEvent(_events.ATTACHED_ROPE) && shellApi.checkEvent(_events.HOOKED_CRATE))
				{
					preloadBearAndBeavers(true);
				}
				else
				{
					finishLoading();
				}
			}
			else
			{
				super.loaded();				
				setupPulley(false);
				setupWaterWheel();
				setupGears();
				
				player.add(new ValidHit("plank", "dirt", "logs", "water", "wall", "ceiling", "step", "wheelPlatform1", "wheelPlatform2", "crate"));
				this.removeEntity(getEntityById("buren"));
				_hitContainer.removeChild(_hitContainer["crateArea"]);
				_hitContainer.removeChild(_hitContainer["crate"]);
			}
			
			if(!PlatformUtils.isDesktop)
				GEAR_ROTATION /= 2;
		}
		
		private function finishLoading():void
		{
			super.loaded();
			
			setupBuren();
			setupGears();
			setupWaterWheel();	
			
			if(!shellApi.checkEvent(_events.HOOKED_CRATE))
			{
				setupPulley(false);	
				setupPushCrate();				
			}
			else
			{
				setupPulley(true);
				_hitContainer.removeChild(_hitContainer["crateArea"]);
				_hitContainer.removeChild(_hitContainer["crate"]);
			}
		}
		
		private function preloadBearAndBeavers(loadScene:Boolean = false):void
		{
			this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/" + this.shellApi.island + "/sawmill/bear.swf", Command.create(bearLoaded, loadScene));
		}
		
		private function bearLoaded(clip:MovieClip, loadScene:Boolean):void
		{
			_hitContainer.addChild(clip);
			clip.x = 2950;
			clip.y = 1250;
			
			this.convertContainer(clip);
			_bear = EntityUtils.createMovingEntity(this, clip, _hitContainer);
			_bear = TimelineUtils.convertClip(clip, this, _bear, null, false, 56);
			EntityUtils.turnOffSleep(_bear);			
				
			_max = getEntityById("max");
			EntityUtils.turnOffSleep(_max);
			Display(_max.get(Display)).setContainer(clip.char);
			
			for(var i:int = 0; i < BEAVER_NUM; i++)
			{
				this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/" + this.shellApi.island + "/sawmill/beaver.swf", beaverLoaded);
			}
			
			if(loadScene)
				finishLoading();
		}
		
		private function beaverLoaded(clip:MovieClip):void
		{
			_hitContainer.addChild(clip);
			clip.x = -100;
			clip.y = 1400;
			
			this.convertContainer(clip);
			var newBeaver:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			newBeaver.add(new Id("beaver" + _beavers.length));
			newBeaver = TimelineUtils.convertClip(clip, this, newBeaver);
			EntityUtils.turnOffSleep(newBeaver);			
			_beavers.push(newBeaver);
		}
		
		protected override function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var spatial:Spatial = player.get(Spatial);
			
			
			switch(event)
			{				
				case _events.USE_GEAR:					
					//if(spatial.x > 620 && spatial.x < 1500 && spatial.y < 1280)

					var gearSpot:MovieClip = _hitContainer["gearSpot"];
					var gearDestination:Destination = CharUtils.moveToTarget(player, gearSpot.x, gearSpot.y, false, atGears)
					gearDestination.setDirectionOnReached(CharUtils.DIRECTION_LEFT);
					gearDestination.validCharStates = new <String>[CharacterState.STAND];
					gearDestination.ignorePlatformTarget = true;

					break;
				
				case _events.USE_ROPE:
					var ropeSpot:MovieClip = _hitContainer["ropeSpot"];
					if(spatial.y < 850 && spatial.x > 450 && spatial.x < 1370)
					{
						CharUtils.moveToTarget(player, ropeSpot.x, ropeSpot.y, false, atRope).setDirectionOnReached(CharUtils.DIRECTION_LEFT);
						_hitContainer.removeChild(ropeSpot);	
					}
					else
					{
						// TODO :: Should say you need can't reach the other rope from here
						player.get(Dialog).sayById("no_use");
					}

					break;
				
				case _events.USE_WHISTLE:
					//if(spatial.x > 620 && spatial.x < 1420 && spatial.y > 900 &&
					if( shellApi.checkEvent(_events.ATTACHED_GEAR) && shellApi.checkEvent(_events.ATTACHED_ROPE) &&
						shellApi.checkEvent(_events.HOOKED_CRATE) && !shellApi.checkHasItem(_events.SURVIVAL_MEDAL))
					{
						//SceneUtil.lockInput(this, true, false);
						var whistleSpot:MovieClip = _hitContainer["whistleSpot"];
						var whistleDestination:Destination = CharUtils.moveToTarget(player, whistleSpot.x, whistleSpot.y, false, atWhistle)
						whistleDestination.validCharStates = new <String>[CharacterState.STAND];
						whistleDestination.ignorePlatformTarget = true;
						whistleDestination.setDirectionOnReached( CharUtils.DIRECTION_RIGHT );
						
						//shellApi.triggerEvent(_events.SHOW_ENDING, true);
					}
					else
					{
						super.onEventTriggered(event, makeCurrent, init, removeEvent);
					}
				
				default:
					break;
			}
		}
		
		private function atRope(player:Entity):void
		{
			_tuftKnot.get(Timeline).gotoAndStop("knot");
			_hitContainer["hiddenRope"].alpha = 1;
			_hitContainer["ropePile"].alpha = 1;
			
			if(shellApi.checkEvent(_events.ATTACHED_GEAR))
			{
				_tuftKnot.get(Mass).mass = KNOT_GEAR_MASS;
				removeCrateWalls();
				
				if(shellApi.checkEvent(_events.HOOKED_CRATE))
					preloadBearAndBeavers();
				else
					SceneUtil.delay(this, 2, updateProximity);
			}
			
			shellApi.triggerEvent(_events.ATTACHED_ROPE, true);
			shellApi.removeItem(_events.ROPE);
		}
		
		private function atGears(player:Entity):void
		{
			_pressurePlate.get(RotatingStep).gearAttached = true;
			_attachedGear.get(Display).visible = true;
			shellApi.triggerEvent(_events.ATTACHED_GEAR, true);
			
			if(shellApi.checkEvent(_events.ATTACHED_ROPE))
			{
				_tuftKnot.get(Mass).mass = KNOT_GEAR_MASS;
				removeCrateWalls();
				
				if(shellApi.checkEvent(_events.HOOKED_CRATE))
					preloadBearAndBeavers();
				else
					SceneUtil.delay(this, 2, updateProximity);
			}
			
			shellApi.removeItem(_events.GEAR);
		}
		
		private function updateProximity():void
		{
			var hookSpatial:Spatial = _hook.get(Spatial);
			var proximity:Proximity = _pushCrate.get(Proximity);
			proximity.zone2D = new RectangleZone(hookSpatial.x - 90, hookSpatial.y, hookSpatial.x + 50, hookSpatial.y + hookSpatial.height + 80);
			
			if(shellApi.checkEvent(_events.ATTACHED_GEAR) && shellApi.checkEvent(_events.ATTACHED_ROPE))
			{
				var motionBounds:MotionBounds = _pushCrate.get(MotionBounds);
				motionBounds.box.bottom = 920;
			}
		}
		
		private function addCrateWalls(entity:Entity = null):void
		{
			var validHit:ValidHit = player.get(ValidHit);
			validHit.hitIds["crateWall"] = true;
			validHit.hitIds["crateFloor"] = true;
		}
		
		private function removeCrateWalls(entity:Entity = null):void
		{
			var validHit:ValidHit = player.get(ValidHit);
			validHit.hitIds["crateWall"] = false;
			validHit.hitIds["crateFloor"] = false;
		}
		
		private function crateAndHook(crate:Entity):void
		{
			removeSystemByClass(SceneObjectHitRectSystem);
			this.removeEntity(crate, true);
			
			_hook.get(Timeline).gotoAndStop("crate");
			_hook.get(Mass).mass = HOOK_AND_CRATE_MASS;
			
			shellApi.triggerEvent(_events.HOOKED_CRATE, true);
			
			if(shellApi.checkEvent(_events.ATTACHED_GEAR) && shellApi.checkEvent(_events.ATTACHED_ROPE))
				preloadBearAndBeavers();
			
			_hook.get(PulleyObject).stopMoving.addOnce(addCrateWalls);
		}
		
		private function trapSet():void
		{
			if(shellApi.checkEvent(_events.ATTACHED_GEAR) && shellApi.checkEvent(_events.ATTACHED_ROPE) && shellApi.checkEvent(_events.HOOKED_CRATE))
			{
				_tuftKnot.get(Mass).mass = KNOT_MASS;
				DisplayUtils.moveToTop(_hook.get(Display).displayObject);
				player.get(Motion).zeroMotion();
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_17.mp3");
				
				if(!shellApi.checkEvent(_events.SHOW_ENDING) && !shellApi.checkHasItem(_events.SURVIVAL_MEDAL))
				{
					SceneUtil.lockInput(this, true, false);					
					CharUtils.setAnim(player, Tremble);
					_hook.get(PulleyObject).stopMoving.addOnce(playerTrappedSelf);
				}
			}
		}
		
		private function playerTrappedSelf(entity:Entity, showPopup:Boolean = false):void
		{
			if(showPopup)
			{
				shellApi.triggerEvent(_events.TRAPPED_SELF);
				var trappedSelfPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
				trappedSelfPopup.updateText("You trapped yourself! That was meant for Van Buren.", "Try Again");
				trappedSelfPopup.configData("trappedSelfPopup.swf", "scenes/survival5/shared/trappedSelfPopup/");
				trappedSelfPopup.popupRemoved.addOnce(reloadScene);
				addChildGroup(trappedSelfPopup);
			}
			else
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(playerTrappedSelf, entity, true)));
			}
		}
		
		private function pulleyStartMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + ROPE_MOVE_SOUND, true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function pulleyStopMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.stop(SoundManager.EFFECTS_PATH + ROPE_MOVE_SOUND);
			
			if(_hook.get(Spatial).y > 800)
			{
				audio.play(SoundManager.EFFECTS_PATH + "wood_heavy_impact_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			}
		}
		
		private function setupPushCrate():void
		{
			var objectCreator:SceneObjectCreator = new SceneObjectCreator();			
			var motion:Motion = new Motion();
			motion.friction = new Point(0, 0);
			motion.maxVelocity = new Point(1000, 1000);
			motion.minVelocity = new Point(0, 0); 
			motion.acceleration = new Point(0, MotionUtils.GRAVITY);
			motion.restVelocity = 100;
			
			var reference:MovieClip = _hitContainer["crateArea"];
			_pushCrate = objectCreator.createBox(_hitContainer["crate"], .25, _hitContainer, NaN, NaN, motion, null, new Rectangle(reference.x, reference.y, reference.width, reference.height), this, null, null, 600, true); 
			Platform(_pushCrate.get( Platform )).hitRect.offset(0, 40);
			_pushCrate.add(new SceneObjectCollider());
			_pushCrate.add(new RectangularCollider());
			_hitContainer.removeChild(reference);
			this.addSystem(new SceneObjectHitRectSystem());
			
			var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
			audioGroup.addAudioToEntity(_pushCrate, "crate");
			new HitCreator().addHitSoundsToEntity(_pushCrate, audioGroup.audioData, shellApi, "crate");
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			this.addSystem(new SceneObjectHitRectSystem());
			
			var proximity:Proximity = new Proximity(100, null);
			proximity.zoneTest = true;
			proximity.entered.addOnce(crateAndHook);
			_pushCrate.add(proximity);
			updateProximity();			
			
			this.addSystem(new ProximitySystem());
		}
		
		private function setupPulley(crateHooked:Boolean):void
		{			
			_hook = EntityUtils.createMovingEntity(this, _hitContainer["hook"]);
			BitmapTimelineCreator.convertToBitmapTimeline(_hook);
			_tuftKnot = EntityUtils.createMovingEntity(this, _hitContainer["tuftedKnot"]);
			BitmapTimelineCreator.convertToBitmapTimeline(_tuftKnot);

			var pulleyConnecter:PulleyConnecter = new PulleyConnecter();
			_hook.add(pulleyConnecter);
			_tuftKnot.add(pulleyConnecter);
			
			var knotPulleyObject:PulleyObject = new PulleyObject(_hook, 1030);
			_tuftKnot.add(new Audio());
			_tuftKnot.add(new AudioRange(800));
			_tuftKnot.add(knotPulleyObject);
			knotPulleyObject.wheel = createBitmapSprite(_hitContainer["pulleywheel1"]);
			knotPulleyObject.wheelSpeedMultiplier = -.45;
			knotPulleyObject.startMoving.add(pulleyStartMoving);
			knotPulleyObject.stopMoving.add(pulleyStopMoving);
			
			var hookPulleyObject:PulleyObject = new PulleyObject(_tuftKnot, 910);
			_hook.add(new Audio());
			_hook.add(new AudioRange(800));
			_hook.add(hookPulleyObject);
			hookPulleyObject.wheel = createBitmapSprite(_hitContainer["pulleywheel2"]);
			hookPulleyObject.wheelSpeedMultiplier = .45;
			hookPulleyObject.startMoving.add(pulleyStartMoving);
			hookPulleyObject.stopMoving.add(pulleyStopMoving);
			
			var rope1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["rope1"]);
			rope1.add(new PulleyRope(rope1.get(Spatial), _tuftKnot.get(Spatial)));
			var rope2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["rope2"]);
			rope2.add(new PulleyRope(rope2.get(Spatial), _hook.get(Spatial)));
			
			var hookMass:Number = KNOT_MASS;
			if(crateHooked)
			{
				hookMass = HOOK_AND_CRATE_MASS;
				_hook.get(Timeline).gotoAndStop("crate");
				
				if(!shellApi.checkEvent(_events.ATTACHED_GEAR) || !shellApi.checkEvent(_events.ATTACHED_ROPE))
					addCrateWalls();
			}
			
			var tuftMass:Number = KNOT_MASS;
			if(shellApi.checkEvent(_events.ATTACHED_ROPE))
			{
				_tuftKnot.get(Timeline).gotoAndStop("knot");
				_hitContainer["hiddenRope"].alpha = 1;
				_hitContainer["ropePile"].alpha = 1;
				
				if(shellApi.checkEvent(_events.ATTACHED_GEAR))
					tuftMass = KNOT_GEAR_MASS;				
			}
			
			_tuftKnot.add(new Mass(tuftMass));
			_hook.add(new Mass(hookMass));
			this.addSystem(new PulleySystem());			
		}
		
		private function setupGears():void
		{
			// Pressure plate and its saw/gears
			this.addSystem(new RotatingStepSystem());
			
			var bottomGear1:Entity = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["gear2"]));
			var bottomGear2:Entity = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["gear3"]));
			var saw:Entity = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["pressurePlate"]["saw"]));
			_attachedGear = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["pressurePlate"]["attachGear"]));
			
			var step:Entity = getEntityById("step");
			step.get(Display).visible = false;
			
			_pressurePlate = EntityUtils.createMovingEntity(this, _hitContainer["pressurePlate"]);
			var rotatingStep:RotatingStep = new RotatingStep(3, GEAR_ROTATION, step);
			rotatingStep.gear1 = bottomGear1.get(Motion);
			rotatingStep.gear2 = bottomGear2.get(Motion);
			rotatingStep.saw = saw.get(Motion);
			rotatingStep.attachedGear = _attachedGear.get(Motion);
			rotatingStep.gearAttached = shellApi.checkEvent(_events.ATTACHED_GEAR);
			rotatingStep.trapSet.add(trapSet);
			_pressurePlate.add(rotatingStep);
			
			// gears by the wheel, mostly always rotating
			var gear0:Entity = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["gear0"]));
			var gear1:Entity = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["gear1"]));			
			
			Motion(gear0.get(Motion)).rotationVelocity = -GEAR_ROTATION;
			Motion(gear1.get(Motion)).rotationVelocity = GEAR_ROTATION;
			
			if(!shellApi.checkEvent(_events.ATTACHED_GEAR))
			{
				Display(_attachedGear.get(Display)).visible = false;
			}
			
			var belt1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["belt1"]);
			var belt2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["belt2"]);
			BitmapTimelineCreator.convertToBitmapTimeline(belt1);
			BitmapTimelineCreator.convertToBitmapTimeline(belt2);
			
			belt1.get(Timeline).play();
			belt2.get(Timeline).play();
		}
		
		// Just rotating the platforms at the same speed as the water wheel. This is constant so nothing has to change
		private function setupWaterWheel():void
		{
			_waterWheel = EntityUtils.createMovingEntity(this, this.createBitmapSprite(_hitContainer["wheel"]));
			_waterWheel.get(Motion).rotationVelocity = -GEAR_ROTATION;
			
			var audio:Audio = new Audio();
			_waterWheel.add(audio);
			_waterWheel.add(new AudioRange(1200));
			audio.play(SoundManager.EFFECTS_PATH + "wood_large_creak_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE], 1.5);	
			
			getEntityById("wheelPlatform1").get(Motion).rotationVelocity = -GEAR_ROTATION;
			getEntityById("wheelPlatform1").get(Display).visible = false;
			getEntityById("wheelPlatform2").get(Motion).rotationVelocity = -GEAR_ROTATION;
			getEntityById("wheelPlatform2").get(Display).visible = false;
		}
		
		private function setupBuren():void
		{
			/* UPDATE WITH HITS */
			player.remove(DepthChecker);
			player.add(new ValidHit("plank", "dirt", "logs", "water", "wall", "ceiling", "step", "wheelPlatform1", "wheelPlatform2", "crate"));
			
			_buren = getEntityById("buren");
			EntityUtils.removeInteraction(_buren);
			EntityUtils.turnOffSleep(_buren);
			DisplayUtils.moveToOverUnder(this.createBitmapSprite(_hitContainer["stump"]), _buren.get(Display).displayObject, true);	
			MotionBounds(_buren.get(MotionBounds)).box.width = 3600;
		}
		
		// Start of end sequence
		private function atWhistle(player:Entity):void
		{		
			AudioUtils.stop(this, SoundManager.MUSIC_PATH + "Survival_5_Main_Theme.mp3");
			CharUtils.lockControls(player, true, true);
			_currentMouth = SkinUtils.getSkinPart(player, SkinUtils.MOUTH).value;
			
			this.removeSystemByClass(NPCDetectionSystem);
			_buren.remove(NPCDetector);
			_buren.remove(WhistleListener);	
			_buren.remove(Destination);
			_buren.remove(Navigation);
			
			_buren.add(new CharacterMotionControl());
			var fsmControl:FSMControl = new FSMControl(super.shellApi);
			_buren.add(fsmControl);
			new FSMStateCreator().createCharacterStateSet(new <Class>[IdleState, StandState, ControlJumpState, RunState, LandState, WalkState], _buren);
			fsmControl.setState(CharacterState.STAND);			
			
			CharUtils.setAnim(player, Sneeze);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "wwwhistle",false);
			var timeline:Timeline = player.get(Timeline);
			timeline.handleLabel( "fire", playWhistleSound );	
			timeline.handleLabel( "ending", duckDown );	
			
			shellApi.triggerEvent(_events.SHOW_ENDING, true);
		}
		
		private function playWhistleSound():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "whistle_blow_01.mp3");
		}
		
		private function duckDown():void
		{
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM, false);
			CharUtils.setAnim(player, DuckDown);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, panCameraRight));
		}
		
		private function panCameraRight():void
		{
			var spatial:Spatial = _buren.get(Spatial);
			spatial.x = 100;
			spatial.y = 100;
			
			var stump:MovieClip = _hitContainer["cameraPanSpot"];
			SceneUtil.setCameraPoint(this, stump.x, stump.y, false, .02);
			SceneUtil.addTimedEvent(this, new TimedEvent(5.5, 1, moveCameraToBuren));
		}
		
		private function moveCameraToBuren():void
		{
			shellApi.triggerEvent("revenge");
			var spatial:Spatial = _buren.get(Spatial);
			var playerSpatial:Spatial = player.get(Spatial);
			spatial.x = playerSpatial.x - 140;
			spatial.y = playerSpatial.y;
			CharUtils.setDirection(_buren, true);
			CharUtils.setAnim(_buren, ThrowReady);
			
			SceneUtil.setCameraTarget(this, _buren, false, .1);
			SceneUtil.addTimedEvent(this, new TimedEvent(2.5, 1, burenBehindPlayer));
		}
		
		private function burenBehindPlayer():void
		{
			var dialog:Dialog = _buren.get(Dialog);
			dialog.sayById("got_you");
			dialog.complete.addOnce(burenTrappedPlayer);
			
			CharUtils.setState(player, CharacterState.STAND);
			SkinUtils.setSkinPart(player, SkinUtils.MOUTH, "cry", true);
			CharUtils.setDirection(player, false);	
			
			var crateSpot:MovieClip = _hitContainer["crateSpot"];
			MotionTarget(player.get(MotionTarget)).targetX = crateSpot.x;
			MotionTarget(player.get(MotionTarget)).targetY = crateSpot.y;
			_hitContainer.removeChild(crateSpot);
			
			var controlJump:ControlJumpState = new FSMStateCreator().createCharacterState(ControlJumpState, player) as ControlJumpState;
			controlJump.faceRight = false;			
			CharUtils.setState(player, "controlJump");
			
			player.get(Dialog).sayById("yikes");				
		}
		
		private function burenTrappedPlayer(...args):void
		{
			shellApi.triggerEvent("caught");
			CharUtils.setAnim(_buren, Stand);
			CharUtils.setAnim(player, Grief);
			var dialog:Dialog = _buren.get(Dialog);
			dialog.sayById("clever");
			dialog.complete.add(burenCompletedDialog);
		}
		
		private function burenCompletedDialog(dialogData:DialogData):void
		{
			if(dialogData.id == "trophy")
			{
				CharUtils.setAnim(_max, Ride);
				CharUtils.getPart(_max, CharUtils.LEG_BACK).get(Display).visible = false;
				CharUtils.getPart(_max, CharUtils.FOOT_BACK).get(Display).visible = false;
				
				var bearSpatial:Spatial = _bear.get(Spatial);
				bearSpatial.x = 2950;
				bearSpatial.y = 1210;
				_bear.get(Timeline).gotoAndPlay("run");
				_bear.get(Motion).velocity.x = -450;
				
				var threshold:Threshold = new Threshold("x", "<");
				threshold.threshold = 2060;
				threshold.entered.addOnce(raiseBear);
				_bear.add(threshold);
				
				shellApi.triggerEvent("bear_enters");
				
				this.addSystem(new ThresholdSystem());				
				SceneUtil.setCameraTarget(this, _bear, false);
			}
		}
		
		// raise the bear up and slow down
		private function raiseBear():void
		{			
			_bear.remove(Threshold);
			_bear.get(Spatial).y -= 40;
			_bear.get(Motion).acceleration.x = 250;
			
			SkinUtils.setSkinPart(_max, SkinUtils.MOUTH, "talk");
			CharUtils.assignDialog(_bear, this, "max", false, -.15, .6);
			var dialog:Dialog = _bear.get(Dialog);
			dialog.sayById("tally");
			dialog.complete.addOnce(maxDoneTally);
			
			var motionThreshold:MotionThreshold = new MotionThreshold("velocity", ">");
			motionThreshold.axisValue = "x";
			motionThreshold.threshold = -50;
			motionThreshold.entered.addOnce(stopBear);
			_bear.add(motionThreshold);
			addSystem(new MotionThresholdSystem());
		}
		
		private function maxDoneTally(...args):void
		{
			SkinUtils.setSkinPart(_max, SkinUtils.MOUTH, "prisoner4");
		}
		
		private function stopBear():void
		{
			_bear.get(Motion).velocity = new Point(0, 0);
			_bear.get(Motion).acceleration = new Point(0, 0);
			
			var timeline:Timeline = _bear.get(Timeline);
			timeline.gotoAndPlay("stoppingFromRun");
			timeline.handleLabel("swiping", breakCrate, true);
		}
		
		private function breakCrate():void
		{
			shellApi.triggerEvent("break_crate");
			var timeline:Timeline = _hook.get(Timeline);
			timeline.gotoAndPlay("break");
			timeline.handleLabel("broke", burenRunBack);			
		}		
		
		private function burenRunBack():void
		{
			SceneUtil.setCameraTarget(this, _buren, false);
			CharUtils.setAnim(player, Stand);
			
			var dialog:Dialog = _buren.get(Dialog);		
			dialog.sayById("ahh");
			dialog.complete.addOnce(burenBackToWheel);
			
			var burenSpot:MovieClip = _hitContainer["burenWalkSpot"];
			var motionTarget:MotionTarget = _buren.get(MotionTarget);
			motionTarget.targetX = burenSpot.x;
			motionTarget.targetY = burenSpot.y;		
			CharUtils.setState(_buren, "controlJump");
			
			_hitContainer.removeChild(burenSpot);		
		}
		
		private function burenBackToWheel(...args):void
		{
			_bear.get(Timeline).gotoAndPlay("walk");
			_bear.get(Spatial).x += 80;
			shellApi.camera.camera.scaleRate = .05;
			shellApi.camera.camera.scaleTarget = .7;
			
			var dialog:Dialog = _buren.get(Dialog);
			dialog.sayById("aim");
			dialog.complete.addOnce(burenTakesAim);
		}
		
		private function burenTakesAim(...args):void
		{
			CharUtils.setAnim(_buren, ThrowReady);
			CharUtils.getTimeline(_buren).handleLabel("ready", burenAiming);
		}
		
		private function burenAiming():void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("not");
			dialog.complete.addOnce(playerJumpAttack);
		}
		
		private function playerJumpAttack(...args):void
		{
			var whistleSpot:MovieClip = _hitContainer["whistleSpot"];
			var motionTarget:MotionTarget = player.get(MotionTarget);
			motionTarget.targetX = whistleSpot.x;
			motionTarget.targetY = whistleSpot.y;	
			CharUtils.setState(player, CharacterState.JUMP);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.3, 1, burenJumpBackToWheel));
		}
		
		private function burenJumpBackToWheel():void
		{			
			shellApi.triggerEvent("gear_reattached");
			var spark:WaterSplash = new WaterSplash();
			spark.init(1, 0x666666, 0x999999, 10, 6);			
			var emitter:Entity = EmitterCreator.create(this, _hitContainer["sparkSpot"], spark);
			
			var jumpSpot:MovieClip = _hitContainer["burenJumpSpot"];
			var motionTarget:MotionTarget = _buren.get(MotionTarget);
			motionTarget.targetX = jumpSpot.x;
			motionTarget.targetY = jumpSpot.y;		
			CharUtils.setState(_buren, "controlJump");
			
			_buren.get(FSMControl).stateChange = new Signal();
			_buren.get(FSMControl).stateChange.add(burenStuckOnWheel);
		}
		
		private function burenStuckOnWheel(state:String, entity:Entity):void
		{
			if(state == CharacterState.STAND)
			{
				shellApi.triggerEvent("stuck");
				SkinUtils.setSkinPart(player, SkinUtils.MOUTH, _currentMouth, true);
				CharUtils.setAnim(_buren, Parachuting);
				CharUtils.removeCollisions(_buren);
				_buren.remove(FSMControl);
				_buren.remove(FSMMaster);
				_buren.remove(CurrentHit);
				CharUtils.setState(_buren, CharacterState.STAND);
				SceneUtil.setCameraTarget(this, _waterWheel, true);
				
				var wheelSpatial:Spatial = _waterWheel.get(Spatial);
				var burenSpatial:Spatial = _buren.get(Spatial);
				SceneUtil.zeroRotation(_buren);
				var radius:Number = 265;
				burenSpatial.x = wheelSpatial.x + radius;
				
				_buren.add(new SpinRound(_waterWheel, radius, -wheelSpatial.rotation));
				this.addSystem(new SpinRoundSystem());
				
				_buren.get(Motion).rotationVelocity = -GEAR_ROTATION;
				bringInBeavers();
			}
		}
		
		private function bringInBeavers():void
		{
			var endLoc:Point = new Point(_hitContainer["beaverSpot"].x, _hitContainer["beaverSpot"].y);			
			
			for each(var beaver:Entity in _beavers)
			{				
				TweenUtils.entityTo(beaver, Spatial, 3, {x:endLoc.x, y:endLoc.y, onComplete:beaverAtSpot, onCompleteParams:[beaver]});
				beaver.get(Timeline).gotoAndPlay("swim");				
				endLoc.x += 250;
			}
			
			var threshold:Threshold = _buren.get(Threshold);
			
			if(!threshold)
			{
				threshold = new Threshold();
				_buren.add(threshold);
			}
			
			threshold.operator = ">";
			threshold.property = "y";
			threshold.threshold = endLoc.y - 120;
			threshold.entered.add(burenReadyForHit);
			
			bringOverPlayerAndBear();
		}
		
		private function bringOverPlayerAndBear():void
		{
			shellApi.camera.camera.scaleRate = .03;
			shellApi.camera.camera.scaleTarget = .9;
			
			var whistleSpot:MovieClip = _hitContainer["whistleSpot"];
			var spatial:Spatial = _bear.get(Spatial);
			spatial.x = whistleSpot.x + 200;
			spatial.y = 1050;
			
			var finalSpot:MovieClip = _hitContainer["finalPlayerSpot"];			
			CharUtils.moveToTarget(player, finalSpot.x, spatial.y, true);
			player.get(CharacterMotionControl).maxVelocityX = 200;
			
			_bear.get(Motion).velocity.x = -190;
			var threshold:Threshold = _bear.get(Threshold);
			if(!threshold)
			{
				threshold = new Threshold();
				_bear.add(threshold);
			}
			
			threshold.property = "x";
			threshold.operator = "<";
			threshold.threshold = finalSpot.x + 200;
			threshold.entered.addOnce(bearFinalStop);
		}
		
		private function playerFinalDialog():void
		{
			var playerDialog:Dialog = player.get(Dialog);
			playerDialog.sayById("own_medicine");
			playerDialog.complete.addOnce(playerSaidMedicine);
		}
		
		private function playerSaidMedicine(...args):void
		{
			var dialog:Dialog = _bear.get(Dialog);
			dialog.sayById("last_hunt");
			dialog.complete.addOnce(lastHuntSaid);	
			
			SkinUtils.setSkinPart(_max, SkinUtils.MOUTH, "talk");
		}
		
		private function bearFinalStop():void
		{
			_bear.get(Motion).velocity.x = 0;
			_bear.get(Timeline).gotoAndPlay("idle");
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, playerFinalDialog));
		}
		
		private function lastHuntSaid(...args):void
		{
			SkinUtils.setSkinPart(_max, SkinUtils.MOUTH, "prisoner4");
			
			CharUtils.setAnim(player, Proud);
			CharUtils.getTimeline(player).handleLabel("ending", Command.create(SceneUtil.addTimedEvent, this, new TimedEvent(2, 1, playerDoneProud)));
		}
		
		private function beaverAtSpot(beaver:Entity):void
		{
			if(Id(beaver.get(Id)).id.indexOf("1") != -1)
				beaver.get(Spatial).scaleX *= -1;
			
			beaver.get(Timeline).gotoAndPlay("turnStart");
		}
		
		private function burenReadyForHit():void
		{
			shellApi.triggerEvent("buren_dunked");
			_beavers[0].get(Timeline).gotoAndPlay("bonked");
			SceneUtil.addTimedEvent(this, new TimedEvent(.4, 1, burenHitTwo));
			
			var splash:WaterSplash = new WaterSplash();
			splash.init(.5, 0x00CCFF, 0x0033FF, 12, 5);			
			var emitter:Entity = EmitterCreator.create(this, _hitContainer["beaverSpot"], splash, 50, -120);
		}
		
		private function burenHitTwo():void
		{
			_beavers[1].get(Timeline).gotoAndPlay("bonked");
			
			var splash:WaterSplash = new WaterSplash();
			splash.init(.5, 0x00CCFF, 0x0033FF, 12, 5);			
			var emitter:Entity = EmitterCreator.create(this, _hitContainer["beaverSpot"], splash, 200, -120);
		}
		
		private function playerDoneProud():void
		{
			var itemGroup:ItemGroup = this.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.SURVIVAL_MEDAL, null, takeEndPhoto);					
			//shellApi.completedIsland();
			shellApi.removeEvent(_events.SHOW_ENDING);
		}
		
		private function takeEndPhoto():void
		{
			super.shellApi.takePhoto( "13168", Command.create(shellApi.loadScene, Ending) );
		}
		
		private var GEAR_ROTATION:Number = 80;
		private const KNOT_MASS:Number = 10;
		private const HOOK_AND_CRATE_MASS:Number = 700;
		private const KNOT_GEAR_MASS:Number = 850;
		private const HOOK_MASS:Number = 20;
		private const BEAVER_NUM:Number = 2;
		private const ROPE_MOVE_SOUND:String = "rope_wood_pulley_01_loop.mp3";
		
		private var _buren:Entity;
		private var _max:Entity;
		private var _attachedGear:Entity;
		private var _pressurePlate:Entity;
		private var _waterWheel:Entity;
		
		private var _tuftKnot:Entity;
		private var _pushCrate:Entity;
		private var _hook:Entity;
		private var _bear:Entity;
		private var _currentMouth:*;
		
		private var _beavers:Vector.<Entity> = new Vector.<Entity>();
	}
}