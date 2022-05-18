package game.scenes.timmy.chase
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
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
	
	import game.components.Emitter;
	import game.components.audio.HitAudio;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.Player;
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
	import game.components.motion.WaveMotion;
	import game.components.render.VerticalDepth;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Stand;
	import game.data.sound.SoundModifier;
	import game.managers.EntityPool;
	import game.scene.template.CharacterGroup;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.scenes.survival5.chase.scenes.EndlessRunnerScene;
	import game.scenes.timmy.TimmyEvents;
	import game.scenes.timmy.chase.trashTruck.TrashTruck;
	import game.scenes.timmy.chase.trashTruck.TrashTruckSystem;
	import game.scenes.timmy.timmysStreet.TimmysStreet;
	import game.scenes.viking.river.depthScale.DepthScale;
	import game.scenes.viking.river.depthScale.DepthScaleSystem;
	import game.scenes.viking.river.thrownRock.ThrownRock;
	import game.scenes.viking.river.thrownRock.ThrownRockSystem;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TweenEntityAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.AccelerateToTargetRotationSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.render.VerticalDepthSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	import game.util.Utils;
	import game.utils.LoopingSceneUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Chase extends EndlessRunnerScene
	{
		private var totalMobile:Entity;
		private var timmy:Entity;
		private var corrina:Entity;
		
		// projectiles pool
		private var trashPool:EntityPool;
		
		private var trashTruck:Entity;
		
		private var health:int = 5;
		
		// trash throw timing
		private var startInterval:Number = 4.0;
		private var minInterval:Number = 0.5;
		private var intervalDelta:Number = 0.5;
		private var trashInterval:Number = startInterval;
		
		private var waves:Array = [1,1,1,1,2,2,2,3,3];
		private var waveIndex:int = 0;
		// current flying trash count
		private var throwCount:int;
		
		private var race_complete:Boolean = false;
		private var _events:TimmyEvents;
		private var trashTimer:TimedEvent;
		
		private const TRASH:String = "trash";
		private const SPLASH:String = "splash";
		
		private const SPEED_UP_SOUND:String = SoundManager.EFFECTS_PATH + "car_drive_away_01.mp3"; 
		private const TRUCK_RUN_SOUND:String = SoundManager.EFFECTS_PATH + "car_idle_01_L.mp3"; 
		private const SKID_SOUND:String = SoundManager.EFFECTS_PATH + "transport_brakes_01.mp3";
		private const SPLASH_SOUND:String = SoundManager.EFFECTS_PATH + "splat_01.mp3"; 
		private const THROW_SOUND:String = SoundManager.EFFECTS_PATH + "object_fall_01.mp3"; 
		private const HIT_SOUND:String = SoundManager.EFFECTS_PATH + "wood_break_01.mp3";
		private var totalHit:Entity;
		
		public function Chase()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/chase/";
			
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
			
			this.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);
			this.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);
			this.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			this.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			this.addSystem(new AccelerateToTargetRotationSystem(), SystemPriorities.move);
			this.addSystem(new NavigationSystem(), SystemPriorities.update);
			this.addSystem(new DestinationSystem(), SystemPriorities.update);	
			this.addSystem(new TargetEntitySystem(), SystemPriorities.update);
			this.addSystem(new ThrownRockSystem());
			this.addSystem(new BitmapSequenceSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new DepthScaleSystem());
			this.addSystem(new VerticalDepthSystem());
			this.addSystem(new ThresholdSystem());
			this.addSystem(new ShakeMotionSystem());
			
			setupPlayer();
			setupTotalMobile();
			addLoopers();
			setupTrashTruck();
			setupCorrina();
			
			LoopingSceneUtils.createMotion(this, cameraStationary, finishedRace);
			
			this.triggerLayers();
			this.triggerObstacles();
			this.shellApi.camera.camera.scaleTarget = 0.8;
			this.shellApi.camera.scale = 0.8;
			SceneUtil.setCameraPoint(this, 200, 900, true);
		}
		
		private function setupTrashTruck():void
		{
			this.addSystem(new TrashTruckSystem());
			// trash truck stays at leading edge of scene during entire chase, moves up and down on the road, drops trash.
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				trashTruck = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["trashTruck"],true,true,null,PerformanceUtils.defaultBitmapQuality+0.5);
				Timeline(trashTruck.get(Timeline)).play();
				trashTruck.add(new Motion());
				this.addEntity(trashTruck);
			}else{
				trashTruck = EntityUtils.createMovingTimelineEntity(this, _hitContainer["trashTruck"],null,true);
			}
			var truck:TrashTruck = new TrashTruck(850,960,100,2.2);
			trashTruck.add(truck);
			trashTruck.add(new DepthScale(700, 900, 0.8, 1.0, false));
			setupTrash();
			trashTimer = SceneUtil.addTimedEvent(this, new TimedEvent(2.2, 1, this.readyTrashThrow),"t");
			// SOUND
			AudioUtils.play(this,TRUCK_RUN_SOUND, 1.5,true,null,"roll");
		}
		
		// fires trash ball at interval, intervl gets shorter after each trash ball
		private function setupTrash():void
		{
			trashPool = new EntityPool();
			trashPool.setSize(TRASH,7);
			
			var clip:MovieClip = this._hitContainer[TRASH];
			var seq:BitmapSequence = BitmapTimelineCreator.createSequence(clip);
			var trash:Entity;
			var shadow:DisplayObject = this._hitContainer["shadow"];
			for (var i:int = 0; i < 7; i++) 
			{
				clip = _hitContainer.addChild(clip) as MovieClip;
				trash = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,seq,PerformanceUtils.defaultBitmapQuality+0.2);
				this.addEntity(trash);
				trash.add(new DepthScale(700, 900, 0.7, 1.0, false));
				trash.add(new SpatialAddition());
				trash.add(new Tween());
				trash.add(new VerticalDepth());
				trash.add(new Id(TRASH+i));
				trash.add(new Sleep(false,true));
				trash.add(new Motion());
				var thrown:ThrownRock = new ThrownRock();
				shadow = _hitContainer.addChild(this.convertToBitmapSprite(shadow, _hitContainer, false, PerformanceUtils.defaultBitmapQuality).sprite);
				thrown.shadow = shadow;
				thrown.active = false;
				thrown.throwTime = 1.7;
				trash.add(thrown);
				trashPool.release(trash, TRASH);
			}
			
			setupTrashSplash();
		}
		
		private function setupTrashSplash():void
		{			
			trashPool.setSize(SPLASH,7);
			var clip:MovieClip = _hitContainer["part"];
			var trashSplash:Entity
			for (var i:int = 0; i < 7; i++) 
			{
				clip = _hitContainer.addChild(clip) as MovieClip;
				var trashEmitter:Emitter2D = new Emitter2D();
				trashEmitter.addInitializer( new BitmapImage(BitmapUtils.createBitmapData(_hitContainer["part"])) );
				trashEmitter.addInitializer( new ScaleImageInit(0.4,1) );		
				trashEmitter.addInitializer( new ColorInit(0x69966, 0x666600) );
				trashEmitter.addInitializer( new Rotation(-90,90) );
				trashEmitter.addInitializer( new RotateVelocity(-4,4) );
				trashEmitter.addInitializer( new Position( new EllipseZone( new Point(0,0), 10, 10 ) ));
				trashEmitter.addInitializer( new Velocity( new EllipseZone( new Point(0,0), 200, -500 ) ));
				trashEmitter.addInitializer( new Lifetime( 0.2, 0.4 ) );
				//trashEmitter.addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 170, 90, GeomUtils.degreeToRadian(-135), GeomUtils.degreeToRadian(-45) ) ) );
				
				trashEmitter.addAction( new Accelerate(0, 250) );
				trashEmitter.addAction( new RandomDrift( 30, 30 ) );
				trashEmitter.addAction( new Rotate() );	
				trashEmitter.addAction( new Age( Quadratic.easeIn ) );
				trashEmitter.addAction( new Move() );
				trashEmitter.addAction( new Fade() );
				//trashEmitter.addAction( new Accelerate( 0, 20 ) );
				trashEmitter.addAction( new LinearDrag( 0.5 ) );
				
				trashSplash = EmitterCreator.create(this, _hitContainer, trashEmitter, 0, 0, null,null, null); 	
				trashSplash.add(new VerticalDepth());
				trashSplash.add(new DepthScale(700, 900, 0.7, 1.0, false));
				trashSplash.add(new Id("splash"+i));
				trashSplash.add(new Sleep(false,true));
				
				DisplayUtils.moveToTop(Display(trashSplash.get(Display)).displayObject);
				
				trashPool.release(trashSplash, SPLASH);
			}
		}
		
		private function hideTrashSplash(trashSplash:Entity):void
		{
			if(trashPool.getPool(SPLASH).indexOf(trashSplash) == -1){
				//Display(trashSplash.get(Display)).visible = false;
				TweenUtils.entityTo(trashSplash,Display,0.4,{alpha:0, onComplete:Command.create(trashPool.release,trashSplash, SPLASH)});
				//trashPool.release(trashSplash, SPLASH);
			}
		}
		
		// prepare and throw wave of trash
		private function readyTrashThrow():void
		{			
			if(!race_complete && health > 0){
				throwCount = waves[waveIndex];
				for (var i:int = 0; i < throwCount; i++) 
				{
					var trash:Entity = trashPool.request(TRASH);
					// trash frame
					var rand:int = GeomUtils.randomInt(0,6);
					Timeline(trash.get(Timeline)).gotoAndStop(rand);
					
					var thrown:ThrownRock = trash.get(ThrownRock);
					thrown.active = true;
					thrown.elapsedTime = 0;
					
					var motion:Motion = trash.get(Motion);
					motion.rotationVelocity = Utils.randNumInRange(-25,25);
					
					// starting point of throw
					var attackerSpatial:Spatial = trashTruck.get(Spatial);
					var start:Point = new Point(attackerSpatial.x,attackerSpatial.y);
					
					// landing point
					var targetSpatial:Spatial = totalMobile.get(Spatial);
					var end:Point;
					if(i == 0){
						end = new Point(targetSpatial.x,targetSpatial.y);
					}
					else{
						end = new Point(Utils.randNumInRange(90,700),Utils.randNumInRange(880,1150));
					}
					SceneUtil.addTimedEvent(this, new TimedEvent(0.15*i, 1, Command.create(throwTrash,start,end,trash,i),"throwDelay"));
				}
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(trashTruck));
			}
		}
		
		// throw single piece of trash
		private function throwTrash(start:Point, end:Point, trash:Entity, index:int):void
		{
			var thrown:ThrownRock = trash.get(ThrownRock);
			thrown.throwTime = 1 + Utils.randNumInRange(0.4, 1.0);
			
			start.y += Utils.randNumInRange(-40,40);
			start.x += Utils.randNumInRange(-10,10);
			
			end.x += Utils.randNumInRange(-50, 25) + 25;
			end.y += Utils.randNumInRange(-50, 25) + 25;
			end.y -=30;
			
			var trashSpatial:Spatial = trash.get(Spatial);
			trashSpatial.x = start.x;
			trashSpatial.y = start.y;
			TweenUtils.entityTo(trash, Spatial, thrown.throwTime, {x:end.x, y:end.y, ease:Linear.easeNone, onComplete:Command.create(splashtrash,trash,index)});
			AudioUtils.play(this, THROW_SOUND, 1, false, [SoundModifier.EFFECTS]);
			trace("throw: "+index);
		}
		
		private function splashtrash(trash:Entity, index:int):void
		{						
			trace("splash: "+index);
			AudioUtils.play(this, SPLASH_SOUND, 1, false, [SoundModifier.EFFECTS]);
			
			checkFortrashCollision(trash);
			
			var trashSplash:Entity = trashPool.request(SPLASH);
			Display(trashSplash.get(Display)).visible = true;
			Display(trashSplash.get(Display)).alpha = 1;
			
			
			var trashEmit:Emitter2D = Emitter(trashSplash.get(Emitter)).emitter;
			trashEmit.counter = new TimePeriod(60,0.8,Quadratic.easeOut);
			
			//trashEmit.addEventListener( EmitterEvent.EMITTER_EMPTY, Command.create(hideTrashSplash,trashSplash), false, 0, true );
			//GlassParticles(trashEmit).spark(60,250);
			SceneUtil.delay(this, 1.0, Command.create(hideTrashSplash,trashSplash));
			
			var splashSpatial:Spatial = trashSplash.get(Spatial);
			var trashSpatial:Spatial = trash.get(Spatial);
			splashSpatial.x = trashSpatial.x;
			splashSpatial.y = trashSpatial.y + 20;
			
			trashSpatial.x = -200;
			
			throwCount--;
			if(throwCount <= 0){
				setNextThrow(trash,index);
			}
			
			trashPool.release(trash, TRASH);
		}
		
		private function setNextThrow(trash:Entity,index:int):void
		{
			// speed up throw delay
			if(trashInterval > minInterval){
				trashInterval -= intervalDelta;
			}else{
				trashInterval = minInterval;
			}
			// how much trash falls out next time
			if(waveIndex >= waves.length-1){
				if(health > 0){
					race_complete = true;
				}
			}
			else{
				waveIndex++;
				TweenUtils.entityTo(corrina, Spatial, 1.4, {x:corrina.get(Spatial).x - 40});
			}
			
			// continue launching trash until end
			if(!race_complete){
				trashTimer = SceneUtil.addTimedEvent(this, new TimedEvent(trashInterval, 1, readyTrashThrow),"t");				
			}
			else{
				startEnding();
			}
		}		
		
		
		private function checkFortrashCollision(trash:Entity):void
		{
			var trashSpatial:Spatial = trash.get(Spatial);
			
			var display:DisplayObject = Display(this.totalHit.get(Display)).displayObject;
			var bounds:Rectangle = display.getRect(display.parent);
			if(!bounds.contains(trashSpatial.x, trashSpatial.y)){
				return;
			}
			
			AudioUtils.play(this, HIT_SOUND, 1, false, [SoundModifier.EFFECTS]);
			AudioUtils.play(this, SPLASH_SOUND, 1, false, [SoundModifier.EFFECTS]);
			
			if(this.health >= 1)
			{
				this.health -= 1;
				//coated with trash
				animateGrief();
				updateTrashCoating();
				
				var shake:ShakeMotion = this.totalMobile.get(ShakeMotion);
				shake.active = true;
				
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, stopShaking));
				
				if(this.health == 0)
				{
					fallBack();
				}
			}
		}
		
		private function animateGrief():void
		{
			var animations:Array = [Grief, Stand];
			
			CharUtils.setAnimSequence(player, new <Class>[animations[0]], false);	
		}
		
		private function updateTrashCoating():void
		{
			// 5 hp =  no trash, 4 hp = total dirty, 3  =  timmy dirty, 2 = wagon, 1 = player, 0 you lose!
			var totalDsplay:Display = totalMobile.get(Display);
			var activeClip:MovieClip;
			switch(health)
			{
				case 5:
				{
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("totalTrash")).visible = false;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("wagonTrash")).visible = false;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("playerTrash")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("shirt_garbage")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("head_garbage")).visible = false;
					break;
				}
				case 4:
				{
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("totalTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("wagonTrash")).visible = false;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("playerTrash")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("shirt_garbage")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("head_garbage")).visible = false;
					break;
				}
				case 3:
				{
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("totalTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("wagonTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("playerTrash")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("shirt_garbage")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("head_garbage")).visible = false;
					break;
				}
				case 2:
				{
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("totalTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("wagonTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("playerTrash")).visible = false;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("shirt_garbage")).visible = true;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("head_garbage")).visible = true;
					break;
				}
				case 1:
				{
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("totalTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("wagonTrash")).visible = true;
					MovieClip(MovieClip(totalDsplay.displayObject).getChildByName("playerTrash")).visible = true;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("shirt_garbage")).visible = true;
					MovieClip(EntityUtils.getDisplayObject(timmy).getChildByName("head_garbage")).visible = true;
					break;
				}
					
				default:
				{
					break;
				}
			}
		}
		
		private function setTrashDisplay(char:Entity, target:Entity):void
		{
			
			MotionUtils.zeroMotion(char);
			CharUtils.setDirection(char,false);
			//merge char graphics with target
			var targDisplay:Display = EntityUtils.getDisplay(target);
			var charDisplay:Display = EntityUtils.getDisplay(char);
			var charHolder:MovieClip = targDisplay.displayObject as MovieClip;
			// position and push char into container
			Display(char.get(Display)).setContainer(charHolder);
			EntityUtils.position(char, 0, 0);
		}
		
		private function fallBack():void
		{
			if(trashTimer){
				trashTimer.stop();
			}
			// kill control
			SceneUtil.lockInput(this, true);
			CharUtils.stateDrivenOff(player);
			CharUtils.stateDrivenOff(totalMobile);
			Motion(totalMobile.get(Motion)).zeroMotion();
			Motion(totalMobile.get(Motion)).zeroAcceleration();
			totalMobile.remove(MotionControl);
			totalMobile.remove(MotionBounds);
			totalMobile.remove(MotionTarget);
			// SOUND
			
			TweenUtils.entityTo(totalMobile, Spatial, 2.2,{x:-350 ,onComplete:reloadScene});
		}
		
		private function reloadScene(...p):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, Command.create(this.shellApi.loadScene, Chase)));
		}
		
		private function stopShaking():void
		{
			ShakeMotion(this.totalMobile.get(ShakeMotion)).active = false;
		}
		
		private function setupCorrina():void
		{
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				corrina = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["corrina"],true,true,null,PerformanceUtils.defaultBitmapQuality+0.5);
				Timeline(corrina.get(Timeline)).play();
				this.addEntity(corrina);
			}else{
				corrina = EntityUtils.createMovingTimelineEntity(this, _hitContainer["corrina"],null,true);
			}
			corrina.add(new Sleep(false,true));
			corrina.add(new DepthScale(700, 900, 0.8, 1.0, false));
		}
		
		// trash truck stays at leading edge of scene during entire chase, moves up and down on the road, drops trash.
		private function setupTotalMobile():void
		{
			timmy = getEntityById("timmy");
			timmy.add(new Sleep(false,true));
			timmy.add(new Motion());
			
			var clip:MovieClip = this._hitContainer["totalMobile"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality+0.5);
			}
			DisplayUtils.moveToTop(clip);
			
			totalMobile = EntityUtils.createMovingTimelineEntity(this, clip,null,true);
			
			totalMobile.add(new Id("totalMobile"));
			totalMobile.add(new Edge(-200, -160, 330, 160));
			totalMobile.add(new RadialCollider());
			totalMobile.add(new SceneCollider());
			totalMobile.add(new ZoneCollider());
			totalMobile.add(new CurrentHit());
			totalMobile.add(new Audio());
			totalMobile.add(new HitAudio());
			totalMobile.add(new MotionControl());
			totalMobile.add(new Player());
			totalMobile.add(new MotionTarget());
			totalMobile.add(new Navigation());
			totalMobile.add(new MotionBounds(new Rectangle(70, 850, 700, 330)));
			totalMobile.add(new DepthScale(700, 900, 0.7, 1.0, false));
			totalMobile.add(new VerticalDepth());
			totalMobile.add(new Sleep(false,true));
			totalMobile.add(new SpatialAddition());
			
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-7, -7, 7, 7));
			shake.active = false;
			shake.speed = 0.05;
			totalMobile.add(shake);
			
			var wave:WaveMotion = new WaveMotion();
			wave.add(new WaveMotionData("rotation", 0, 20, "sin", 0, true));
			totalMobile.add(wave);
			
			var motion:Motion 			= new Motion();
			motion.maxVelocity 			= new Point(200, 80);
			motion.friction 			= new Point(120, 120);
			totalMobile.add(motion);
			
			var motionControlBase:MotionControlBase 			= new MotionControlBase();
			motionControlBase.acceleration 						= 600;
			motionControlBase.stoppingFriction 					= 800;
			motionControlBase.accelerationFriction 				= 0;
			motionControlBase.freeMovement 						= true;
			motionControlBase.rotationDeterminesAcceleration 	= false;
			motionControlBase.moveFactor 						= 0.3;
			totalMobile.add(motionControlBase);
			
			var targetEntity:TargetEntity 	= new TargetEntity();
			targetEntity.target 			= this.shellApi.inputEntity.get(Spatial);
			targetEntity.applyCameraOffset 	= true;
			totalMobile.add(targetEntity);
			
			bindCharacterToClip(player, totalMobile, "mount1");
			bindCharacterToClip(timmy, totalMobile, "mount2",0,0,false);
			
			var follow:FollowTarget = new FollowTarget(totalMobile.get(Spatial));
			clip = this._hitContainer["totalHit"];
			totalHit = EntityUtils.createSpatialEntity(this, clip);
			Display(totalHit.get(Display)).visible = false;
			follow = new FollowTarget(totalMobile.get(Spatial));
			totalHit.add(follow);
			
			updateTrashCoating();
		}
		
		private function bindCharacterToClip(char:Entity, target:Entity, clipId:String, offsetX:Number = 0, offsetY:Number = 0, lockAnim:Boolean = true):void
		{
			if(lockAnim){
				CharUtils.setAnim(char,Stand);
				CharacterGroup(getGroupById("characterGroup",this)).removeFSM(char);
			}
			MotionUtils.zeroMotion(char);
			CharUtils.setDirection(char,false);
			//merge char graphics with target
			var targDisplay:Display = EntityUtils.getDisplay(target);
			var charDisplay:Display = EntityUtils.getDisplay(char);
			var charHolder:MovieClip = targDisplay.displayObject.getChildByName(clipId) as MovieClip;
			// position and push char into container
			Display(char.get(Display)).setContainer(charHolder);
			EntityUtils.position(char, 0, 0);
		}
		
		private function addLoopers():void
		{
			var raceObstacleCreator:RaceSegmentCreator = new RaceSegmentCreator();
			var data:XML = SceneUtil.mergeSharedData( this, "segmentPatterns.xml", "ignore" );
			
			raceObstacleCreator.createSegments( this, data, _hitContainer, _audioGroup );
		}
		
		
		private function startEnding():void
		{
			shellApi.triggerEvent(_events.CHASE_COMPLETE,true,true);
			if(trashTimer){
				trashTimer.stop();
			}
			// kill control
			SceneUtil.lockInput(this, true);
			CharUtils.stateDrivenOff(player);
			CharUtils.stateDrivenOff(totalMobile);
			Motion(totalMobile.get(Motion)).zeroMotion();
			Motion(totalMobile.get(Motion)).zeroAcceleration();
			totalMobile.remove(MotionControl);
			totalMobile.remove(MotionBounds);
			totalMobile.remove(MotionTarget);
			TrashTruck(trashTruck.get(TrashTruck)).setState(TrashTruck.STOP);
			TweenUtils.entityTo(corrina,Spatial,1.6,{x:corrina.get(Spatial).x -150, y:1200});
			Display(corrina.get(Display)).moveToFront();
			TweenUtils.entityTo(totalMobile,Spatial,1.6,{x:corrina.get(Spatial).x, y:1150});		
			//SOUND
			AudioUtils.play(this, SPEED_UP_SOUND,1.5,false);	
			var actions:ActionChain = new ActionChain(this);
			actions.addAction(new TalkAction(timmy, "getting_away"));
			actions.addAction(new TweenEntityAction(trashTruck,Spatial,2.0,{x:2100})).noWait = true;
			actions.addAction(new WaitAction(2.05));
			actions.addAction(new TalkAction(player, "watch_out"));
			actions.addAction(new TalkAction(timmy, "faster"));
			actions.addAction(new CallFunctionAction(chaseOffScreen));
			actions.execute();
		}
		
		private function chaseOffScreen(...p):void
		{
			TweenUtils.entityTo(totalMobile, Spatial, 3.0, {x:2100, ease:Back.easeOut}, "", 0.4);
			TweenUtils.entityTo(corrina, Spatial, 3.5, {x:2000, ease:Back.easeOut, onComplete:crashOffscreen}, "", 0.3);
		}
		
		private function crashOffscreen():void
		{
			// shake scene
			// SOUND skid + crash + smoosh
			AudioUtils.stop(this,TRUCK_RUN_SOUND,"roll");
			AudioUtils.play(this, SKID_SOUND, 1.5);
			SceneUtil.delay(this, 0.1,Command.create(AudioUtils.play,this, SKID_SOUND, 1.5));
			SceneUtil.delay(this, 0.4,Command.create(AudioUtils.play,this, SPLASH_SOUND, 1.3, false, null,null,1.3));
			SceneUtil.delay(this, 0.6,fadeScreen);
		}
		private function fadeScreen():void
		{
			LoopingSceneUtils.stopSceneMotion(this, true);
			SceneUtil.delay(this, 0.4,concludeRace);
		}
		
		private function concludeRace(...p):void
		{
			SceneUtil.delay(this, 1.0, Command.create(shellApi.loadScene,TimmysStreet));			
		}
		
		
		
		
		
		
	}
}