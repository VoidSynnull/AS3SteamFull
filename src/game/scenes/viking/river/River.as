package game.scenes.viking.river
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.audio.HitAudio;
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Player;
	import game.components.entity.character.Talk;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.ShakeMotion;
	import game.components.motion.TargetEntity;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.render.VerticalDepth;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.Tremble;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterDialogGroup;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.scenes.survival5.chase.scenes.EndlessRunnerScene;
	import game.scenes.viking.VikingEvents;
	import game.scenes.viking.falls.Falls;
	import game.scenes.viking.river.depthScale.DepthScale;
	import game.scenes.viking.river.depthScale.DepthScaleSystem;
	import game.scenes.viking.river.raftEddyCollision.Eddy;
	import game.scenes.viking.river.raftEddyCollision.Raft;
	import game.scenes.viking.river.raftEddyCollision.RaftEddyCollisionSystem;
	import game.scenes.viking.river.thrownRock.ThrownRock;
	import game.scenes.viking.river.thrownRock.ThrownRockSystem;
	import game.systems.SystemPriorities;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.AccelerateToTargetRotationSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.VehicleMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.render.VerticalDepthSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.Utils;
	import game.utils.LoopingSceneUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class River extends EndlessRunnerScene
	{
		private var raft:Entity;
		private var rock:Entity;
		private var rockSplash:Entity;
		private var attacker:Entity;
		private var raftHealth:Array = [];
		
		public function River()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/river/";
			
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
			
			this.addSystem(new VehicleMotionSystem(), SystemPriorities.moveComplete);
			this.addSystem(new RotateToTargetSystem(), SystemPriorities.move);
			this.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);
			this.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);
			this.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			this.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			this.addSystem(new AccelerateToTargetRotationSystem(), SystemPriorities.move);
			this.addSystem(new NavigationSystem(), SystemPriorities.update);
			this.addSystem(new DestinationSystem(), SystemPriorities.update);	
			this.addSystem(new TargetEntitySystem(), SystemPriorities.update);
			this.addSystem(new BitmapSequenceSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new DepthScaleSystem());
			this.addSystem(new ThrownRockSystem());
			this.addSystem(new VerticalDepthSystem());
			this.addSystem(new ThresholdSystem());
			this.addSystem(new RaftEddyCollisionSystem());
			this.addSystem(new ShakeMotionSystem());
			
			this.addLoopers();
			setupPlayer();
			LoopingSceneUtils.createMotion(this, cameraStationary, finishedRace);
			this.triggerLayers();
			this.triggerObstacles();
			
			this.setupRaft();
			this.setupRock();
			this.setupAttacker();
			this.setupRaftNPCs();
			this.setupRockSplash();
			this.setupEddys();
			
			SceneUtil.setCameraPoint(this, 0, 0, true);
		}
		
		private function setupEddys():void
		{
			for(var index:int = 1; this.getEntityById("eddy" + index); ++index)
			{
				var eddy:Entity = this.getEntityById("eddy" + index);
				eddy.add(new Eddy());
			}
		}
		
		override protected function finishedRace(...args):void
		{
			super.finishedRace(args);
			
			this.raft.remove(MotionBounds);
			this.raft.remove(MotionControl);
			this.raft.remove(MotionTarget);
			
			if(this.raftHealth.length != 0)
			{
				var motion:Motion = this.raft.get(Motion);
				motion.zeroMotion();
				motion.friction.setTo(0, 0);
				motion.acceleration.setTo(0, 0);
				motion.velocity.x = 500;
				
				var threshold:Threshold = new Threshold("x", ">=");
				threshold.threshold = this.shellApi.viewportWidth + 200;
				threshold.entered.addOnce(this.loadFalls);
				this.raft.add(threshold);
				
				this.shellApi.completeEvent(VikingEvents(this.events).RIVER_COMPLETED);
			}
		}
		
		private function loadFalls(...args):void
		{
			this.shellApi.loadScene(Falls);
		}
		
		private function setupRockSplash():void
		{
			this.rockSplash = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["rockSplash"], true, true);
			this.rockSplash.add(new VerticalDepth());
			this.rockSplash.add(new DepthScale(300, 600, 0.8, 1.2, false));
			this.addEntity(this.rockSplash);
			
			DisplayUtils.moveToTop(Display(this.rockSplash.get(Display)).displayObject);
			
			Timeline(this.rockSplash.get(Timeline)).handleLabel("end", hideRockSplash, false);
		}
		
		private function hideRockSplash():void
		{
			Display(this.rockSplash.get(Display)).visible = false;
		}
		
		private function addLoopers():void
		{
			var raceObstacleCreator:RaceSegmentCreator = new RaceSegmentCreator();
			var data:XML = SceneUtil.mergeSharedData( this, "segmentPatterns.xml", "ignore" );
			
			raceObstacleCreator.createSegments( this, data, _hitContainer, _audioGroup );
		}
		
		private function setupRock():void
		{
			var clip:MovieClip = this._hitContainer["rock"];
			
			this.rock = EntityUtils.createSpatialEntity(this, clip);
			this.rock.add(new DepthScale(300, 600, 0.8, 1.2, false));
			this.rock.add(new SpatialAddition());
			this.rock.add(new Tween());
			this.rock.add(new VerticalDepth());
			
			var thrown:ThrownRock = new ThrownRock();
			thrown.shadow = this._hitContainer["shadow"];
			thrown.active = false;
			thrown.throwTime = 1.8;
			this.rock.add(thrown);
		}
		
		private function throwRock():void
		{
			this.rock.remove(FollowTarget);
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim(this.attacker, 1);
			if(!rigAnim)
			{
				var animationSlot:Entity = AnimationSlotCreator.create( this.attacker );
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			rigAnim.next = Throw;
			rigAnim.partsApplied.length = 0;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK);
			
			var thrown:ThrownRock = this.rock.get(ThrownRock);
			thrown.active = true;
			thrown.elapsedTime = 0;
			
			var attackerSpatial:Spatial = this.attacker.get(Spatial);
			
			var rockSpatial:Spatial = this.rock.get(Spatial);
			rockSpatial.x = attackerSpatial.x;
			rockSpatial.y = attackerSpatial.y;
			
			var raftSpatial:Spatial = this.raft.get(Spatial);
			var x:Number = raftSpatial.x + Utils.randNumInRange(-25, 25);
			var y:Number = raftSpatial.y;
			
			var tween:Tween = this.rock.get(Tween);
			tween.to(rockSpatial, 1.8, {x:x, y:y, ease:Linear.easeNone, onComplete:this.splashRock});
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "object_fall_01.mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function splashRock():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_05.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.holdRock));
			
			Display(this.rockSplash.get(Display)).visible = true;
			Timeline(this.rockSplash.get(Timeline)).gotoAndPlay("start");
			
			var splashSpatial:Spatial = this.rockSplash.get(Spatial);
			var rockSpatial:Spatial = this.rock.get(Spatial);
			splashSpatial.x = rockSpatial.x;
			splashSpatial.y = rockSpatial.y + 20;
			
			this.checkForRockCollision();
			
			rockSpatial.x = rockSpatial.y = -100;
		}
		
		private function holdRock(dontThrow:Boolean = false):void
		{
			var rigAnim:RigAnimation = CharUtils.getRigAnim(this.attacker, 1);
			if(!rigAnim)
			{
				var animationSlot:Entity = AnimationSlotCreator.create( this.attacker );
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			
			rigAnim.next = PointItem;
			rigAnim.partsApplied.length = 0;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK);
			
			var timeline:Timeline = AnimationControl(this.attacker.get(AnimationControl)).getEntityAt(1).get(Timeline);
			timeline.handleLabel("pointing", stopHands);
			
			if(!dontThrow)
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.throwRock));
			}
		}
		
		private function checkForRockCollision():void
		{
			var rockSpatial:Spatial = this.rock.get(Spatial);
			
			var raftDisplay:DisplayObject = Display(this.raft.get(Display)).displayObject;
			var raftBounds:Rectangle = raftDisplay.getBounds(raftDisplay.parent);
			
			if(rockSpatial.x < raftBounds.left) return;
			if(rockSpatial.x > raftBounds.right) return;
			if(Math.abs(rockSpatial.y - raftBounds.bottom) > 30) return;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_break_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			if(this.raftHealth.length)
			{
				var npc:Entity = this.raftHealth.pop();
				CharUtils.setAnim(npc, Dizzy);
				SkinUtils.setSkinPart(npc, SkinUtils.EYES, "dazed");
				
				var tween:Tween = this.getGroupEntityComponent(Tween);
				tween.to(npc.get(Spatial), 0.5, {y:-70});
				
				var shake:ShakeMotion = this.raft.get(ShakeMotion);
				shake.active = true;
				
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, stopShaking));
				
				if(this.raftHealth.length == 0)
				{
					SceneUtil.lockInput(this, true);
					SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(this.shellApi.loadScene, River)));
				}
			}
		}
		
		private function stopShaking():void
		{
			ShakeMotion(this.raft.get(ShakeMotion)).active = false;
		}
		
		private function setupAttacker():void
		{
			this.attacker = this.getEntityById("attacker");
			Npc(this.attacker.get(Npc)).ignoreDepth = true;
			DisplayUtils.moveToBack(Display(this.attacker.get(Display)).displayObject);
			
			CharUtils.setAnim(this.attacker, Run);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.25, 1, Command.create(setEyes, this.attacker)));
			
			this.holdRock(true);
		}
		
		private function stopHands():void
		{
			Timeline(AnimationControl(this.attacker.get(AnimationControl)).getEntityAt(1).get(Timeline)).stop();
			
			Display(this.rock.get(Display)).visible = true;
			
			EntityUtils.followTarget(this.rock, this.attacker, 1, new Point(25));
		}
		
		private function setEyes(npc:Entity):void
		{
			var eyes:Entity = SkinUtils.getSkinPartEntity(npc, SkinUtils.EYES);
			var eye:Eyes = eyes.get(Eyes);
			eye.pupilsFollow = true;
			
			eye.targetDisplay = this._hitContainer["raft"];
		}
		
		private function setupRaft():void
		{	
			var clip:MovieClip = this._hitContainer["raft"];
			DisplayUtils.moveToTop(clip);
			
			this.createBitmap(clip["raftLog"]);
			
			this.raft = new Entity();
			this.addEntity(this.raft);
			
			this.raft.add(new Id("raft"));
			this.raft.add(new Spatial(190, 465));
			this.raft.add(new Display(clip));
			this.raft.add(new Edge(-162, -90, 315, 90));
			this.raft.add(new RadialCollider());
			this.raft.add(new SceneCollider());
			this.raft.add(new ZoneCollider());
			this.raft.add(new CurrentHit());
			this.raft.add(new Audio());
			this.raft.add(new HitAudio());
			this.raft.add(new MotionControl());
			this.raft.add(new Player());
			this.raft.add(new MotionTarget());
			this.raft.add(new Navigation());
			this.raft.add(new MotionBounds(new Rectangle(0, 260, 960, 370)));
			this.raft.add(new DepthScale(350, 600, 0.8, 1.2));
			this.raft.add(new VerticalDepth());
			this.raft.add(new Raft());
			this.raft.add(new SpatialAddition());
			
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-7, -7, 7, 7));
			shake.active = false;
			shake.speed = 0.05;
			this.raft.add(shake);
			
			var wave:WaveMotion = new WaveMotion();
			wave.add(new WaveMotionData("rotation", 0, 20, "sin", 0, true));
			this.raft.add(wave);
			
			var motion:Motion 			= new Motion();
			motion.maxVelocity 			= new Point(200, 80);
			motion.friction 			= new Point(120, 120);
			this.raft.add(motion);
			
			var motionControlBase:MotionControlBase 			= new MotionControlBase();
			motionControlBase.acceleration 						= 600;
			motionControlBase.stoppingFriction 					= 800;
			motionControlBase.accelerationFriction 				= 0;
			motionControlBase.freeMovement 						= true;
			motionControlBase.rotationDeterminesAcceleration 	= false;
			motionControlBase.moveFactor 						= 0.3;
			this.raft.add(motionControlBase);
			
			var targetEntity:TargetEntity 	= new TargetEntity();
			targetEntity.target 			= this.shellApi.inputEntity.get(Spatial);
			targetEntity.applyCameraOffset 	= true;
			this.raft.add(targetEntity);
			
			var emitter:Emitter2D;
			
			emitter = new Emitter2D();
			emitter.counter = new Steady(70);
			emitter.addInitializer(new ImageClass(Blob, [7], true, 70));
			emitter.addInitializer(new Position(new RectangleZone(150, -5, 165, 5)));
			emitter.addInitializer(new Velocity(new RectangleZone(-300, 0, -300, 0)));
			emitter.addInitializer(new Lifetime(1.05));
			emitter.addInitializer(new ScaleImageInit(0.5, 1));
			emitter.addInitializer(new RotateVelocity(-20, 20));
			emitter.addAction(new ColorChange(0xFF22A0D2, 0xFFFFFFFF));
			emitter.addAction(new Rotate());
			emitter.addAction(new RandomDrift(100, 20));
			emitter.addAction(new Move());
			emitter.addAction(new Age());
			
			EmitterCreator.create(this, clip, emitter);
			
			emitter = new Emitter2D();
			emitter.counter = new Steady(50);
			emitter.addInitializer(new ImageClass(Dot, [2], true, 50));
			emitter.addInitializer(new Position(new RectangleZone(-140, -5, 165, 5)));
			emitter.addInitializer(new Velocity(new RectangleZone(-100, -100, -100, -100)));
			emitter.addInitializer(new Lifetime(0.7));
			emitter.addInitializer(new ScaleImageInit(0.5, 1));
			emitter.addInitializer(new RotateVelocity(-20, 20));
			emitter.addAction(new ColorChange(0xFF22A0D2, 0xFFFFFFFF));
			emitter.addAction(new Rotate());
			emitter.addAction(new RandomDrift(100, 20));
			emitter.addAction(new Move());
			emitter.addAction(new Age());
			emitter.addAction(new Accelerate(0, 260));
			
			EmitterCreator.create(this, clip, emitter);
			
			var char:CharacterDialogGroup = this.getGroupById(CharacterDialogGroup.GROUP_ID) as CharacterDialogGroup;
			char.assignDialog(this.raft);
		}
		
		private function setupRaftNPCs():void
		{
			var npc1:Entity = this.getEntityById("npc1");
			SkinUtils.applyLook(npc1, SkinUtils.getLook(this.shellApi.player));
			
			this.removeEntity(this.shellApi.player);
			
			var animations:Array = [Grief, Tremble, Grief, Cry];
			
			var clip:MovieClip = this._hitContainer["raft"];
			
			for(var index:int = 1; index <= 4; ++index)
			{
				var npc:Entity = this.getEntityById("npc" + index);
				
				this.raftHealth.push(npc);
				
				clip.addChildAt(Display(npc.get(Display)).displayObject, 1);
				
				Npc(npc.get(Npc)).ignoreDepth = true;
				
				var leg:Entity = CharUtils.getPart(npc, CharUtils.LEG_BACK);
				Display(leg.get(Display)).visible = false;
				
				var foot:Entity = CharUtils.getPart(npc, CharUtils.FOOT_BACK);
				Display(foot.get(Display)).visible = false;
				
				CharUtils.setAnimSequence(npc, new <Class>[animations[index - 1]], true);
				
				ToolTipCreator.removeFromEntity(npc);
			}
			
			this.shellApi.player = this.raft;
			
			var dialog:Dialog = this.raft.get(Dialog);
			dialog.dialogPositionPercents = new Point(0, 1.5);
			dialog.faceSpeaker = false;
			dialog.sayById("npc2");
			dialog.start.add(this.talkStart);
			dialog.complete.add(this.talkStop);
		}
		
		private function talkStart(data:DialogData):void
		{
			var npc:Entity = this.getEntityById(data.id);
			Talk(npc.get(Talk)).isStart = true;
		}
		
		private function talkStop(data:DialogData):void
		{
			var npc:Entity = this.getEntityById(data.id);
			Talk(npc.get(Talk)).isEnd = true;
			
			if(data.id == "npc4")
			{
				EntityUtils.followTarget(this.attacker, this.raft, 0.002, null, false, new <String>["x"]);
				SceneUtil.addTimedEvent(this, new TimedEvent(6, 1, this.throwRock));
			}
		}
	}
}