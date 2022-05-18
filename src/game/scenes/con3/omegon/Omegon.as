package game.scenes.con3.omegon
{
	import com.greensock.easing.Elastic;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.DepthChecker;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.Hazard;
	import game.components.hit.HitTest;
	import game.components.hit.Platform;
	import game.components.motion.FollowTarget;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.character.part.eye.EyeBallData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitData;
	import game.data.sound.SoundModifier;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.con3.Con3Events;
	import game.scenes.con3.ending.Ending;
	import game.scenes.con3.omegon.omegonArm.OmegonArm;
	import game.scenes.con3.omegon.omegonArm.OmegonArmSystem;
	import game.scenes.con3.omegon.omegonHand.OmegonHand;
	import game.scenes.con3.omegon.omegonHand.OmegonHandSystem;
	import game.scenes.con3.omegon.omegonLaserControl.OmegonLaserControl;
	import game.scenes.con3.omegon.omegonLaserControl.OmegonLaserControlSystem;
	import game.scenes.con3.shared.ElectricPulseGroup;
	import game.scenes.con3.shared.Ray;
	import game.scenes.con3.shared.WeaponHudGroup;
	import game.scenes.con3.shared.WrappedSignal;
	import game.scenes.con3.shared.laserPulse.LaserPulseSystem;
	import game.scenes.con3.shared.rayBlocker.RayBlocker;
	import game.scenes.con3.shared.rayBlocker.RayBlockerSystem;
	import game.scenes.con3.shared.rayCollision.RayCollision;
	import game.scenes.con3.shared.rayCollision.RayCollisionSystem;
	import game.scenes.con3.shared.rayReflect.RayReflectSystem;
	import game.scenes.con3.shared.rayReflect.RayToReflectCollision;
	import game.scenes.con3.shared.rayRender.RayRender;
	import game.scenes.con3.shared.rayRender.RayRenderSystem;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Omegon extends PlatformerGameScene
	{
		private var laser_arm_left:Entity;
		private var laser_arm_right:Entity;
		
		public var laser_control:Entity;
		
		private var laser_left:Entity;
		private var laser_right:Entity;
		
		private var laser_hazard_left:Entity;
		private var laser_hazard_right:Entity;
		
		private var ray_left:Entity;
		private var ray_right:Entity;
		
		private var hand_arm_left:Entity;
		private var hand_arm_right:Entity;
		
		private var hand_left:Entity;
		private var hand_right:Entity;
		
		private var hand_platform_left:Entity;
		private var hand_platform_right:Entity;
		
		private var hand_hazard_left:Entity;
		private var hand_hazard_right:Entity;
		
		private var eye_left:Entity;
		private var eye_right:Entity;
		
		private var eye_shield_left:Entity;
		private var eye_shield_right:Entity;
		
		private var power_source_left:Entity;
		private var power_source_right:Entity;
		
		private var power_hit_left:Entity;
		private var power_hit_right:Entity;
		
		private var fuse_1_left:Entity;
		private var fuse_2_left:Entity;
		private var fuse_1_right:Entity;
		private var fuse_2_right:Entity;
		
		private var panel_left:Entity;
		private var panel_right:Entity;
		
		private var responder_left:Entity;
		private var responder_right:Entity;
		
		private var mouth:Entity;
		
		private var explosionSequence:BitmapSequence;
		
		private var playerHazard:HazardCollider;
		
		public function Omegon()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/omegon/";
			
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
			
			this.shellApi.completeEvent("weapons_powered_up");
			
			this.shellApi.eventTriggered.add(eventTriggered);
			
			this.createBitmap(this._hitContainer["head"]);
			
			this.addSystem(new ThresholdSystem());
			this.addSystem(new ShakeMotionSystem());
			this.addSystem(new BitmapSequenceSystem());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new HitTestSystem());
			this.addSystem(new HazardHitSystem());
			this.addSystem(new RayRenderSystem());
			this.addSystem(new RayCollisionSystem());
			this.addSystem(new RayReflectSystem());
			this.addSystem(new LaserPulseSystem());
			this.addSystem(new RayBlockerSystem());
			
			this.addSystem(new OmegonArmSystem());
			this.addSystem(new OmegonHandSystem());
			this.addSystem(new OmegonLaserControlSystem());
			
			this.player.remove(DepthChecker);
			
			this.setupCamera();
			this.setupAlphaonLook();
			this.setupHUD();
			this.setupFuses();
			this.setupPowerSources();
			this.setupPowerHits();
			this.setupHands();
			this.setupHandPlatforms();
			this.setupHandHazards();
			this.setupHandArms();
			this.setupHandPulses();
			this.setupEyes();
			this.setupLaserArms();
			this.setupLaserRays();
			this.setupLaserHazards();
			this.setupLaserSources();
			this.setupMouth();
			
			this.setupLaserControl();
			this.setupOmegonHands();
			this.setupOmegonLaserArms();
			
			this.setupIntro();
			//this.startFight();
			//this.onEyeDestroyed(true);
		}
		
		private function setupCamera():void
		{
			this.shellApi.camera.camera.scaleTarget = this.shellApi.viewportWidth / this.sceneData.cameraLimits.width;
			this.shellApi.camera.scale = this.shellApi.camera.camera.scaleTarget;
		}
		
		private function fixTheseStupidCharacters():void
		{
			var spatial:Spatial = this.player.get(Spatial);
			spatial.x = 330;
			spatial.y = 1146;
			
			var omegon:Entity = this.getEntityById("omegon");
			if(omegon)
			{
				CharUtils.setDirection(omegon, false);
			}
		}
		
		private function onLaserHit(player:Entity, hitId:String):void
		{
			if(this.playerHazard && !this.player.get(HazardCollider))
			{
				this.player.add(this.playerHazard);
				//this.playerBlocker.remove(EntityIdList);
				CharUtils.stateDrivenOn(this.player);
			}
		}
		
		private function setupAlphaonLook():void
		{
			var colorSet:ColorSet;
			
			// HAIR
			var hairEntity:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.HAIR_COLOR );
			colorSet = hairEntity.get( ColorSet );
			colorSet.setColorAspect( 11657972, SkinUtils.HAIR_COLOR );
			
			// SKIN
			var skinEntity:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.SKIN_COLOR );
			colorSet = skinEntity.get( ColorSet );
			colorSet.setColorAspect( 8177389, SkinUtils.SKIN_COLOR );
			
			if(!PlatformUtils.isMobileOS)
			{
				var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 2, 1, true );
				var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
				
				//Can't apply the filters to the player's Display because it breaks laser collisions. Can't even explain that...
				//Don't let players change looks at this point. HUD buttons are disabled.
				var parts:Array = ["facial", "hair", "pants", "shirt", "overpants", "overshirt", "pack", CharUtils.HEAD_PART, SkinUtils.FOOT1, SkinUtils.FOOT2, SkinUtils.HAND1, SkinUtils.HAND2, CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK];
				
				for each(var part:String in parts)
				{
					var entity:Entity = CharUtils.getPart(this.player, part);
					
					if(entity)
					{
						var display:Display = entity.get( Display );
						
						if(display)
						{
							display.displayObject.filters = [colorGlow, whiteOutline];
						}
					}
				}
			}
		}
		
		private function setupMouth():void
		{
			this.mouth = EntityUtils.createSpatialEntity(this, this._hitContainer["mouth"]);
			this.mouth.add(new Tween());
		}
		
		private function startRoar(stopRoar:Boolean = true):void
		{
			var spatial:Spatial = this.mouth.get(Spatial);
			
			var tween:Tween = this.mouth.get(Tween);
			tween.killAll();
			
			var object:Object = {y:605, ease:Elastic.easeOut};
			if(stopRoar)
			{
				object.onComplete = this.stopRoar;
			}
			tween.to(spatial, 1.5, object);
			
			spatial.y = 565;
		}
		
		private function stopRoar():void
		{
			var tween:Tween = this.mouth.get(Tween);
			tween.killAll();
			tween.to(this.mouth.get(Spatial), 2, {y:565, delay:1.5});
		}
		
		private function setupIntro():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(0.25, 1, fixTheseStupidCharacters));
			
			SceneUtil.lockInput(this);
			
			var omegon:Entity = this.getEntityById("omegon");
			
			var wave:WaveMotion = new WaveMotion();
			wave.add(new WaveMotionData("y", 20, 0.03));
			omegon.add(wave);
			omegon.add(new SpatialAddition());
			
			DisplayUtils.moveToTop(this._hitContainer["black_intro"]);
			DisplayUtils.moveToTop(Display(this.player.get(Display)).displayObject);
			DisplayUtils.moveToTop(Display(omegon.get(Display)).displayObject);
			
			DisplayUtils.moveToTop(this._hitContainer["eye_glow_left"]);
			DisplayUtils.moveToTop(this._hitContainer["eye_glow_right"]);
			
			this._hitContainer["eye_glow_left"].alpha = 0;
			this._hitContainer["eye_glow_right"].alpha = 0;
			
			Dialog(omegon.get(Dialog)).sayById("alphaon");
			Dialog(omegon.get(Dialog)).complete.add(dialogComplete);
		}
		
		private function dialogComplete(data:DialogData):void
		{
			if(data.id == "true_form")
			{
				var omegon:Entity = this.getEntityById("omegon");
				var tween:Tween = this.getGroupEntityComponent(Tween);
				tween.to(omegon.get(Display), 2, {alpha:0, onComplete:omegonFadeOutComplete});
			}
		}
		
		private function omegonFadeOutComplete():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "event_08.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(this._hitContainer["eye_glow_left"], 3, {alpha:1, onComplete:omegonEyeFadeInComplete});
			tween.to(this._hitContainer["eye_glow_right"], 3, {alpha:1});
		}
		
		private function omegonEyeFadeInComplete():void
		{
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(this._hitContainer["black_intro"], 1, {alpha:0, onComplete:waitMore});
		}
		
		private function waitMore():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, startFight));
		}
		
		private function setupLaserControl():void
		{
			this.laser_control = new Entity();
			this.addEntity(this.laser_control);
			
			this.laser_control.add(new OmegonLaserControl());
			this.laser_control.add(new Tween());
		}
		
		private function startFight():void
		{
			SceneUtil.lockInput(this, false);
			
			this.removeEntity(this.getEntityById("omegon"));
			
			this._hitContainer.removeChild(this._hitContainer["black_intro"]);
			this._hitContainer.removeChild(this._hitContainer["eye_glow_left"]);
			this._hitContainer.removeChild(this._hitContainer["eye_glow_right"]);
			
			DisplayUtils.moveToTop(Display(this.laser_arm_left.get(Display)).displayObject);
			DisplayUtils.moveToTop(Display(this.laser_arm_right.get(Display)).displayObject);
			
			OmegonLaserControl(this.laser_control.get(OmegonLaserControl)).state = "ground";
			OmegonHand(this.hand_left.get(OmegonHand)).state = "attack";
			OmegonHand(this.hand_right.get(OmegonHand)).state = "attack";
			
			this.startRoar();
		}
		
		private function setupOmegonLaserArms():void
		{
			var omegonLaserArm:OmegonLaserArm;
			var shake:ShakeMotion;
			
			omegonLaserArm 						= new OmegonLaserArm();
			omegonLaserArm.hand 				= this.hand_left;
			omegonLaserArm.laser 				= this.laser_left;
			this.laser_arm_left.add(omegonLaserArm);
			
			shake = new ShakeMotion(new RectangleZone(-2.5, -2.5, 2.5, 2.5));
			shake.active = false;
			shake.speed = 0.02;
			this.laser_arm_left.add(shake);
			this.laser_arm_left.add(new SpatialAddition());
			
			omegonLaserArm 						= new OmegonLaserArm();
			omegonLaserArm.hand 				= this.hand_right;
			omegonLaserArm.laser 				= this.laser_right;
			this.laser_arm_right.add(omegonLaserArm);
			
			shake = new ShakeMotion(new RectangleZone(-2.5, -2.5, 2.5, 2.5));
			shake.active = false;
			shake.speed = 0.02;
			this.laser_arm_right.add(shake);
			this.laser_arm_right.add(new SpatialAddition());
			
			OmegonLaserControl(this.laser_control.get(OmegonLaserControl)).laser_arm_left = this.laser_arm_left;
			OmegonLaserControl(this.laser_control.get(OmegonLaserControl)).laser_arm_right = this.laser_arm_right;
		}
		
		private function setupHUD():void
		{
			var hud:Hud = this.getGroupById(Hud.GROUP_ID) as Hud;
			hud.disableButton(Hud.COSTUMIZER);
			hud.disableButton(Hud.INVENTORY);
			
			var weaponHudGroup:WeaponHudGroup = this.addChildGroup( new WeaponHudGroup( shellApi )) as WeaponHudGroup;
		}
		
		private function setupEyes():void
		{
			this.eye_left = TimelineUtils.convertClip(this._hitContainer["eye_left"], this, null, null, false);
			this.eye_right = TimelineUtils.convertClip(this._hitContainer["eye_right"], this, null, null, false);
			
			this.eye_shield_left = TimelineUtils.convertClip(this._hitContainer["eye_shield_left"], this);
			this.eye_shield_right = TimelineUtils.convertClip(this._hitContainer["eye_shield_right"], this);
			
			var entity:Entity;
			var spatial:Spatial;
			var blocker:RayBlocker;
			
			//Eye hit left
			entity = EntityUtils.createSpatialEntity(this, this._hitContainer.addChild(new Sprite()));
			entity.add(new Id("eye_hit_left"));
			entity.add(new EntityIdList());
			
			spatial = entity.get(Spatial);
			spatial.x = 400;
			spatial.y = 590;
			
			Display(entity.get(Display)).visible = false;
			
			blocker = new RayBlocker();
			blocker.shape.graphics.beginFill(0, 1);
			blocker.shape.graphics.drawRect(-50, -10, 100, 20);
			blocker.shape.graphics.endFill();
			entity.add(blocker);
			
			entity.add(new HitTest(Command.create(onEyeHit, this.eye_left), false));
			
			//Eye hit right
			entity = EntityUtils.createSpatialEntity(this, this._hitContainer.addChild(new Sprite()));
			entity.add(new Id("eye_hit_right"));
			entity.add(new EntityIdList());
			
			spatial = entity.get(Spatial);
			spatial.x = 590;
			spatial.y = 590;
			
			Display(entity.get(Display)).visible = false;
			
			blocker = new RayBlocker();
			blocker.shape.graphics.beginFill(0, 1);
			blocker.shape.graphics.drawRect(-50, -10, 100, 20);
			blocker.shape.graphics.endFill();
			entity.add(blocker);
			
			entity.add(new HitTest(Command.create(onEyeHit, this.eye_right), false));
		}
		
		private function onEyeHit(eye_hit:Entity, hitId:String, eye:Entity):void
		{
			var timeline:Timeline = eye.get(Timeline);
			
			if(timeline.currentIndex >= 14 && timeline.currentIndex <= 22)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "glass_break_03.mp3", 1, false, [SoundModifier.EFFECTS]);
				
				timeline.gotoAndStop("destroyed");
				timeline.handleLabel("destroyed", onEyeDestroyed);
				
				this.startRoar();
			}
		}
		
		private function onEyeDestroyed(cheat:Boolean = false):void
		{
			var timeline:Timeline;
			
			if(!cheat)
			{
				timeline = this.eye_left.get(Timeline);
				if(timeline.currentIndex != 23) return;
				
				timeline = this.eye_right.get(Timeline);
				if(timeline.currentIndex != 23) return;
			}
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_down_06.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			OmegonHand(this.hand_left.get(OmegonHand)).state = "damaged";
			OmegonHand(this.hand_right.get(OmegonHand)).state = "damaged";
			
			this.startRoar(false);
			
			this.shellApi.completeEvent(Con3Events(this.events).OMEGON_DEFEATED);
			
			SceneUtil.setCameraPoint(this, 490, 525);
			
			var entity:Entity = this.getEntityById("camera");
			Spatial(entity.get(Spatial)).scale += 0.1;
			
			var shake:ShakeMotion = new ShakeMotion();
			shake.shakeZone = new RectangleZone(-10, -10, 10, 10);
			shake.speed = 0.03;
			entity.add(shake);
			entity.add(new SpatialAddition());
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, startExplosions));
		}
		
		private function startExplosions():void
		{
			this.explosionSequence = BitmapTimelineCreator.createSequence(this._hitContainer["explosion"]);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 8, createExplosion));
			
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xFFFFFF, 1);
			shape.graphics.drawRect(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight);
			shape.graphics.endFill();
			this.overlayContainer.addChild(shape);
			
			this.flashScreen(shape, 1);
		}
		
		private function createExplosion():void
		{
			var entity:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["explosion"], true, false, this.explosionSequence);
			this.addEntity(entity);
			
			this.overlayContainer.addChild(Display(entity.get(Display)).displayObject);
			
			this.moveExplosion(entity);
			
			var timeline:Timeline = entity.get(Timeline);
			timeline.gotoAndPlay(Utils.randNumInRange(0, timeline.totalFrames));
			timeline.handleLabel("end", Command.create(moveExplosion, entity), false);
		}
		
		private function moveExplosion(entity:Entity):void
		{
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = Utils.randNumInRange(0, this.shellApi.viewportWidth);
			spatial.y = Utils.randNumInRange(0, this.shellApi.viewportHeight);
		}
		
		private function flashScreen(shape:Shape, duration:Number):void
		{
			shape.alpha = 1;
			
			if(duration > 0.2)
			{
				var tween:Tween = this.getGroupEntityComponent(Tween);
				tween.to(shape, duration, {alpha:0, onComplete:flashScreen, onCompleteParams:[shape, duration * 0.92]});
			}
			else
			{
				shape.parent.removeChild(shape);
				// remove charged weapons
				shellApi.removeEvent(Con3Events(events).WEAPONS_POWERED_UP);
				SkinUtils.setSkinPart(player,SkinUtils.ITEM, "empty",true);
				this.shellApi.takePhoto("13437", Command.create(this.shellApi.loadScene, Ending));
			}
		}
		
		private function setupHandPulses():void
		{
			var follow:FollowTarget;
			
			//Responder left
			this.responder_left = EntityUtils.createMovingEntity(this, this._hitContainer["hand_responder_1"]);
			TimelineUtils.convertClip(this._hitContainer["hand_responder_1"], this, this.responder_left, null, false);
			Timeline(this.responder_left.get(Timeline)).gotoAndStop("offEnd");
			this.responder_left.add(new Id("hand_responder_1"));
			
			this.responder_left.remove(Sleep);
			this.responder_left.sleeping = false;
			
			follow = new FollowTarget(this.hand_left.get(Spatial));
			follow.offset = new Point(0, -40);
			this.responder_left.add(follow);
			
			//Responder right
			this.responder_right = EntityUtils.createMovingEntity(this, this._hitContainer["hand_responder_2"]);
			TimelineUtils.convertClip(this._hitContainer["hand_responder_2"], this, this.responder_right, null, false);
			Timeline(this.responder_right.get(Timeline)).gotoAndStop("offEnd");
			this.responder_right.add(new Id("hand_responder_2"));
			
			this.responder_right.remove(Sleep);
			this.responder_right.sleeping = false;
			
			follow = new FollowTarget(this.hand_right.get(Spatial));
			follow.offset = new Point(0, -40);
			this.responder_right.add(follow);
			
			var pulseGroup:ElectricPulseGroup = this.addChildGroup(new ElectricPulseGroup()) as ElectricPulseGroup;
			pulseGroup.createPanels(this._hitContainer["panel_1"], this, this._hitContainer, onPulse, "hand_responder_");
			
			//Panel left
			this.panel_left = this.getEntityById("panel_1");
			Display(this.panel_left.get(Display)).alpha = 0;
			follow = new FollowTarget(this.hand_left.get(Spatial));
			follow.offset = new Point(0, -50);
			this.panel_left.add(follow);
			
			//Panel right
			this.panel_right = this.getEntityById("panel_2");
			Display(this.panel_right.get(Display)).alpha = 0;
			follow = new FollowTarget(this.hand_right.get(Spatial));
			follow.offset = new Point(0, -50);
			this.panel_right.add(follow);
		}
		
		private function onPulse(responder:Entity):void
		{
			if(responder == this.responder_left)
			{
				OmegonHand(this.hand_left.get(OmegonHand)).pulse_hit();
			}
			else
			{
				OmegonHand(this.hand_right.get(OmegonHand)).pulse_hit();
			}
		}
		
		private function setupOmegonHands():void
		{
			var omegonHand:OmegonHand;
			
			omegonHand 					= new OmegonHand();
			omegonHand.isLeft 			= true;
			omegonHand.hand_platform 	= this.hand_platform_left;
			omegonHand.hand_hazard		= this.hand_hazard_left;
			omegonHand.power_hit 		= this.power_hit_left;
			omegonHand.power_source 	= this.power_source_left;
			omegonHand.laser_arm_left	= this.laser_arm_left;
			omegonHand.laser_arm_right	= this.laser_arm_right;
			omegonHand.laser_control 	= this.laser_control;
			omegonHand.laser_left		= this.laser_left;
			omegonHand.laser_right		= this.laser_right;
			omegonHand.removedPlatform	= this.hand_platform_left.remove(Platform) as Platform;
			
			HitTest(omegonHand.power_hit.get(HitTest)).onEnter.add(omegonHand.power_hit_hit);
			
			this.hand_left.add(omegonHand);
			
			omegonHand 					= new OmegonHand();
			omegonHand.isLeft 			= false;
			omegonHand.hand_platform 	= this.hand_platform_right;
			omegonHand.hand_hazard		= this.hand_hazard_right;
			omegonHand.power_hit 		= this.power_hit_right;
			omegonHand.power_source 	= this.power_source_right;
			omegonHand.laser_arm_left	= this.laser_arm_left;
			omegonHand.laser_arm_right	= this.laser_arm_right;
			omegonHand.laser_control 	= this.laser_control;
			omegonHand.laser_left		= this.laser_left;
			omegonHand.laser_right		= this.laser_right;
			omegonHand.removedPlatform	= this.hand_platform_right.remove(Platform) as Platform;
			
			HitTest(omegonHand.power_hit.get(HitTest)).onEnter.add(omegonHand.power_hit_hit);
			
			this.hand_right.add(omegonHand);
		}
		
		private function setupLaserArms():void
		{
			this.laser_arm_left = EntityUtils.createSpatialEntity(this, this._hitContainer["laser_arm_left"]);
			this.laser_arm_right = EntityUtils.createSpatialEntity(this, this._hitContainer["laser_arm_right"]);
			
			this.laser_arm_left.add(new Tween());
			this.laser_arm_right.add(new Tween());
			
			DisplayUtils.moveToTop(Display(this.laser_arm_left.get(Display)).displayObject);
			DisplayUtils.moveToTop(Display(this.laser_arm_right.get(Display)).displayObject);
		}
		
		private function setupLaserHazards():void
		{
			this.laser_hazard_left = this.getEntityById("laser_hazard_left");
			this.laser_hazard_right = this.getEntityById("laser_hazard_right");
			
			this.laser_hazard_left.remove(Sleep);
			this.laser_hazard_right.remove(Sleep);
			
			Display(this.laser_hazard_left.get(Display)).visible = false;
			Display(this.laser_hazard_right.get(Display)).visible = false;
			
			this.laser_hazard_left.add(new FollowTarget(this.laser_arm_left.get(Spatial)));
			this.laser_hazard_right.add(new FollowTarget(this.laser_arm_right.get(Spatial)));
			
			this.laser_hazard_left.remove(HitData);
			this.laser_hazard_right.remove(HitData);
			
			var audioGroup:AudioGroup = this.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			audioGroup.addAudioToEntity(this.laser_hazard_left);
			audioGroup.addAudioToEntity(this.laser_hazard_right);
		}
		
		private function setupLaserSources():void
		{
			var timeline:Timeline;
			
			this.laser_left = EntityUtils.createSpatialEntity(this, this._hitContainer["laser_arm_left"]["laser"]);
			TimelineUtils.convertClip(this._hitContainer["laser_arm_left"]["laser"], this, this.laser_left);
			timeline = this.laser_left.get(Timeline);
			timeline.gotoAndStop("offEnd");
			timeline.handleLabel("onEnd", handleLaserLeftOn, false);
			timeline.handleLabel("offEnd", handleLaserLeftOff, false);
			
			this.laser_left.remove(Sleep);
			
			this.laser_right = EntityUtils.createSpatialEntity(this, this._hitContainer["laser_arm_right"]["laser"]);
			TimelineUtils.convertClip(this._hitContainer["laser_arm_right"]["laser"], this, this.laser_right);
			timeline = this.laser_right.get(Timeline);
			timeline.gotoAndStop("offEnd");
			timeline.handleLabel("onEnd", handleLaserRightOn, false);
			timeline.handleLabel("offEnd", handleLaserRightOff, false);
			
			this.laser_right.remove(Sleep);
		}
		
		private function setupLaserRays():void
		{
			this.ray_left = EntityUtils.createSpatialEntity(this, this._hitContainer["laser_arm_left"]["laser"].addChildAt(new Sprite(), 0));
			this.ray_left.add(new Id("laser_ray_left"));
			this.ray_left.add(new Ray(2000));
			this.ray_left.add(new RayRender(1000, 0xFF7DB5, 20));
			this.ray_left.add(new RayCollision());
			this.ray_left.add(new RayToReflectCollision());
			this.ray_left.add(new EntityIdList());
			
			this.ray_right = EntityUtils.createSpatialEntity(this, this._hitContainer["laser_arm_right"]["laser"].addChildAt(new Sprite(), 0));
			this.ray_right.add(new Id("laser_ray_right"));
			this.ray_right.add(new Ray(2000));
			this.ray_right.add(new RayRender(1000, 0xFF7DB5, 20));
			this.ray_right.add(new RayCollision());
			this.ray_right.add(new RayToReflectCollision());
			this.ray_right.add(new EntityIdList());
		}
		
		private function setupHandHazards():void
		{
			this.hand_hazard_left = this.getEntityById("hand_hazard_left");
			this.hand_hazard_right = this.getEntityById("hand_hazard_right");
			
			this.hand_hazard_left.remove(Sleep);
			this.hand_hazard_left.sleeping = false;
			
			this.hand_hazard_right.remove(Sleep);
			this.hand_hazard_right.sleeping = false;
			
			Display(this.hand_hazard_left.get(Display)).visible = false;
			Display(this.hand_hazard_right.get(Display)).visible = false;
			
			var follow:FollowTarget;
			
			follow = new FollowTarget(this.hand_left.get(Spatial));
			follow.offset = new Point(0, 40);
			this.hand_hazard_left.add(follow);
			
			follow = new FollowTarget(this.hand_right.get(Spatial));
			follow.offset = new Point(0, 40);
			this.hand_hazard_right.add(follow);
		}
		
		private function setupHandArms():void
		{
			this.hand_arm_left = EntityUtils.createDisplayEntity(this, this._hitContainer["hand_arm_left"]);
			this.hand_arm_right = EntityUtils.createDisplayEntity(this, this._hitContainer["hand_arm_right"]);
			
			this.hand_arm_left.add(new OmegonArm(this.hand_left.get(Spatial)));
			this.hand_arm_right.add(new OmegonArm(this.hand_right.get(Spatial)));
		}
		
		private function setupHands():void
		{
			this.hand_left = EntityUtils.createSpatialEntity(this, this._hitContainer["hand_left"]);
			this.hand_right = EntityUtils.createSpatialEntity(this, this._hitContainer["hand_right"]);
			
			this.hand_left.add(new Tween());
			this.hand_right.add(new Tween());
			
			this.hand_left.remove(Sleep);
			this.hand_left.sleeping = false;
			
			this.hand_right.remove(Sleep);
			this.hand_right.sleeping = false;
			
			var threshold:Threshold;
			
			threshold = new Threshold("y", ">=");
			threshold.threshold = 1050;
			threshold.entered.add(this.playSmash);
			this.hand_left.add(threshold);
			
			threshold = new Threshold("y", ">=");
			threshold.threshold = 1050;
			threshold.entered.add(this.playSmash);
			this.hand_left.add(threshold);
		}
		private function playSmash():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_impact_03.mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function setupHandPlatforms():void
		{
			this.hand_platform_left = this.getEntityById("hand_platform_left");
			this.hand_platform_right = this.getEntityById("hand_platform_right");
			
			Platform(this.hand_platform_left.get(Platform)).stickToPlatforms = true;
			Platform(this.hand_platform_right.get(Platform)).stickToPlatforms = true;
			
			//Platform(this.hand_platform_left.get(Platform)).top = true;
			//Platform(this.hand_platform_right.get(Platform)).top = true;
			
			Display(this.hand_platform_left.get(Display)).visible = false;
			Display(this.hand_platform_right.get(Display)).visible = false;
			
			var follow:FollowTarget;
			
			follow = new FollowTarget(this.hand_left.get(Spatial));
			follow.offset = new Point(0, -25);
			this.hand_platform_left.add(follow);
			
			follow = new FollowTarget(this.hand_right.get(Spatial));
			follow.offset = new Point(0, -25);
			this.hand_platform_right.add(follow);
		}
		
		private function setupFuses():void
		{
			this.fuse_1_left = EntityUtils.createSpatialEntity(this, this._hitContainer["fuse_1_left"]);
			this.fuse_2_left = EntityUtils.createSpatialEntity(this, this._hitContainer["fuse_2_left"]);
			this.fuse_1_right = EntityUtils.createSpatialEntity(this, this._hitContainer["fuse_1_right"]);
			this.fuse_2_right = EntityUtils.createSpatialEntity(this, this._hitContainer["fuse_2_right"]);
			
			TimelineUtils.convertClip(this._hitContainer["fuse_1_left"], this, this.fuse_1_left, null, false);
			TimelineUtils.convertClip(this._hitContainer["fuse_2_left"], this, this.fuse_2_left, null, false);
			TimelineUtils.convertClip(this._hitContainer["fuse_1_right"], this, this.fuse_1_right, null, false);
			TimelineUtils.convertClip(this._hitContainer["fuse_2_right"], this, this.fuse_2_right, null, false);
			
			var wrappedSignal:WrappedSignal;
			var entity:Entity;
			
			entity = this.getEntityById("target1");
			wrappedSignal = new WrappedSignal();
			wrappedSignal.signal.addOnce(Command.create(onFuseHit, this.fuse_1_left));
			entity.add(wrappedSignal);
			
			entity = this.getEntityById("target2");
			wrappedSignal = new WrappedSignal();
			wrappedSignal.signal.addOnce(Command.create(onFuseHit, this.fuse_2_left));
			entity.add(wrappedSignal);
			
			entity = this.getEntityById("target3");
			wrappedSignal = new WrappedSignal();
			wrappedSignal.signal.addOnce(Command.create(onFuseHit, this.fuse_1_right));
			entity.add(wrappedSignal);
			
			entity = this.getEntityById("target4");
			wrappedSignal = new WrappedSignal();
			wrappedSignal.signal.addOnce(Command.create(onFuseHit, this.fuse_2_right));
			entity.add(wrappedSignal);
		}
		
		private function onFuseHit(fuse_hit:Entity, fuse:Entity):void
		{
			this.removeEntity(fuse_hit);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "glass_break_03.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var timeline:Timeline = fuse.get(Timeline);
			timeline.gotoAndStop("off");
			timeline.handleLabel("off", Command.create(onFuseOff, fuse));
			
			this.startRoar();
		}
		
		private function onFuseOff(fuse:Entity):void
		{
			if(fuse == this.fuse_1_left || fuse == this.fuse_2_left)
			{
				if(Timeline(this.fuse_1_left.get(Timeline)).currentIndex == 1 && Timeline(this.fuse_2_left.get(Timeline)).currentIndex == 1)
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_down_07.mp3", 1, false, [SoundModifier.EFFECTS]);
					
					Timeline(this.eye_shield_left.get(Timeline)).gotoAndPlay("off");
					Timeline(this.eye_left.get(Timeline)).gotoAndPlay("damaged");
				}
			}
			else if(fuse == this.fuse_1_right || fuse == this.fuse_2_right)
			{
				if(Timeline(this.fuse_1_right.get(Timeline)).currentIndex == 1 && Timeline(this.fuse_2_right.get(Timeline)).currentIndex == 1)
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_down_07.mp3", 1, false, [SoundModifier.EFFECTS]);
					
					Timeline(this.eye_shield_right.get(Timeline)).gotoAndPlay("off");
					Timeline(this.eye_right.get(Timeline)).gotoAndPlay("damaged");
				}
			}
		}
		
		private function setupPowerSources():void
		{
			this.power_source_left = TimelineUtils.convertClip(this._hitContainer["hand_left"]["power_source"], this, null, null, false);
			this.power_source_right = TimelineUtils.convertClip(this._hitContainer["hand_right"]["power_source"], this, null, null, false);
			
			Timeline(this.power_source_left.get(Timeline)).gotoAndStop("on");
			Timeline(this.power_source_right.get(Timeline)).gotoAndStop("on");
			
			this.power_source_left.remove(Sleep);
			this.power_source_left.sleeping = false;
			
			this.power_source_right.remove(Sleep);
			this.power_source_right.sleeping = false;
		}
		
		private function setupPowerHits():void
		{
			this.power_hit_left = EntityUtils.createSpatialEntity(this, this._hitContainer["hand_left"].addChild(new Sprite()));
			this.power_hit_left.add(new Id("power_hit_left"));
			this.power_hit_left.add(new EntityIdList());
			
			Spatial(this.power_hit_left.get(Spatial)).y = 15;
			Display(this.power_hit_left.get(Display)).visible = false;
			
			var blocker:RayBlocker = new RayBlocker();
			blocker.shape.graphics.beginFill(0, 1);
			blocker.shape.graphics.drawRect(-50, -5, 100, 10);
			blocker.shape.graphics.endFill();
			this.power_hit_left.add(blocker);
			
			this.power_hit_left.add(new HitTest());
			
			this.power_hit_left.remove(Sleep);
			this.power_hit_left.sleeping = false;
			
			this.power_hit_right = EntityUtils.createSpatialEntity(this, this._hitContainer["hand_right"].addChild(new Sprite()));
			this.power_hit_right.add(new Id("power_hit_right"));
			this.power_hit_right.add(new EntityIdList());
			
			Spatial(this.power_hit_right.get(Spatial)).y = 15;
			Display(this.power_hit_right.get(Display)).visible = false;
			
			blocker = new RayBlocker();
			blocker.shape.graphics.beginFill(0, 1);
			blocker.shape.graphics.drawRect(-50, -5, 100, 10);
			blocker.shape.graphics.endFill();
			this.power_hit_right.add(blocker);
			
			this.power_hit_right.add(new HitTest());
			
			this.power_hit_right.remove(Sleep);
			this.power_hit_right.sleeping = false;
		}
		
		private function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "shield_activated")
			{
				this.playerHazard = this.player.remove(HazardCollider) as HazardCollider;
				//this.playerBlocker.add(new EntityIdList());
			}
			else if(event == "shield_deactivated")
			{
				//this.playerBlocker.remove(EntityIdList);
				if(this.playerHazard)
				{
					this.player.add(this.playerHazard);
				}
			}
		}
		
		private function handleLaserLeftOn():void
		{
			Ray(this.ray_left.get(Ray)).length = 2000;
			Hazard(this.laser_hazard_left.get(Hazard)).active = true;
			Audio(this.laser_hazard_left.get(Audio)).playCurrentAction( "idle" );
		}
		
		private function handleLaserLeftOff():void
		{
			Ray(this.ray_left.get(Ray)).length = 0;
			Hazard(this.laser_hazard_left.get(Hazard)).active = false;
			Audio(this.laser_hazard_left.get(Audio)).stopActionAudio( "idle" );
		}
		
		private function handleLaserRightOn():void
		{
			Ray(this.ray_right.get(Ray)).length = 2000;
			Hazard(this.laser_hazard_right.get(Hazard)).active = true;
			Audio(this.laser_hazard_right.get(Audio)).playCurrentAction( "idle" );
		}
		
		private function handleLaserRightOff():void
		{
			Ray(this.ray_right.get(Ray)).length = 0;
			Hazard(this.laser_hazard_right.get(Hazard)).active = false;
			Audio(this.laser_hazard_right.get(Audio)).stopActionAudio( "idle" );
		}
	}
}