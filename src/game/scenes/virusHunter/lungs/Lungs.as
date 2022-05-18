package game.scenes.virusHunter.lungs
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.Group;
	import engine.systems.CameraSystem;
	import engine.systems.CameraZoomSystem;
	
	import game.components.Emitter;
	import game.components.motion.FollowTarget;
	import game.components.motion.WaveMotion;
	import game.components.motion.MotionControlBase;
	import game.components.motion.Navigation;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.display.BitmapWrapper;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scene.template.CameraGroup;
	import game.scenes.virusHunter.lungs.busCutScene.BusCutScene;
	import game.scenes.virusHunter.lungs.components.AirFlow;
	import game.scenes.virusHunter.lungs.components.Alveoli;
	import game.scenes.virusHunter.lungs.components.Boss;
	import game.scenes.virusHunter.lungs.components.BossArm;
	import game.scenes.virusHunter.lungs.components.BossBody;
	import game.scenes.virusHunter.lungs.components.BossClaw;
	import game.scenes.virusHunter.lungs.components.BossHead;
	import game.scenes.virusHunter.lungs.components.BossState;
	import game.scenes.virusHunter.lungs.particles.Smoke;
	import game.scenes.virusHunter.lungs.systems.AirFlowSystem;
	import game.scenes.virusHunter.lungs.systems.AlveoliSystem;
	import game.scenes.virusHunter.lungs.systems.BossArmSystem;
	import game.scenes.virusHunter.lungs.systems.BossBodySystem;
	import game.scenes.virusHunter.lungs.systems.BossClawSystem;
	import game.scenes.virusHunter.lungs.systems.BossSystem;
	import game.scenes.virusHunter.lungs.systems.SmokeSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.motion.NavigationSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.TimelineUtils;
	
	public class Lungs extends ShipScene
	{
		public var shipGroup:ShipGroup;
		private var _events:VirusHunterEvents;
		
		private var lungBoss:Entity;
		
		public var screenFx:ScreenEffects = new ScreenEffects();
		public var explosion:Sprite;
		public var joeHealth:Entity;
		
		public function Lungs()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/lungs/";
			super.initialScale = super.minCameraScale = .5;
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
			_events = this.events as VirusHunterEvents;
			
			this.addSystem(new BitmapSequenceSystem());
			
			setupPopups();
			setupScene();
			setupAirFlow();
			setupSmoke();
			setupAlveoli();
			setupBoss();
		}

		private function setupPopups():void
		{
			if(this.shellApi.checkEvent(this._events.GOT_ANTIGRAV))
			{
				if(this.shellApi.checkEvent(this._events.LUNG_BOSS_DEFEATED) ||
					this.shellApi.checkEvent(this._events.BUS_CUTSCENE_PLAYED)) return;
				
				this.shellApi.completeEvent(this._events.BUS_CUTSCENE_PLAYED);
				
				SceneUtil.addTimedEvent(this, new TimedEvent(3, -1, handlePopup));
			}
		}
		
		private function handlePopup():void
		{
			var cutscene:BusCutScene = new BusCutScene(this.overlayContainer);
			cutscene.removed.addOnce(handleRemoved);
			this.addChildGroup(cutscene);
			
			SceneUtil.lockInput(this);
		}
		
		private function handleRemoved(group:Group):void
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function setupScene():void
		{
			shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			shipGroup.createSceneWeaponTargets(this._hitContainer);
		}
		
		private function setupAirFlow():void
		{
			if(!this.shellApi.checkEvent(this._events.GOT_ANTIGRAV))
			{
				this.addSystem(new AirFlowSystem(), SystemPriorities.lowest);
				this.shellApi.player.add(new AirFlow());
				
				var motion:Motion = this.shellApi.player.get(Motion);
				motion.acceleration = new Point(0, 300);
				
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, handleAirFlowWarning));
			}
			else
			{
				this.removeEntity(this.getEntityById("airflow"));
				this.removeEntity(this.getEntityById("airWall"));
			}
		}
		
		private function handleAirFlowWarning():void
		{
			this.playMessage("air_currents", false, "antigrav_offline");
		}
		
		private function setupSmoke():void
		{
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginFill(0x000000, 0);
			sprite.graphics.drawRect(0, 0, this.shellApi.viewportWidth * 4, this.shellApi.viewportHeight * 4);
			sprite.graphics.endFill();
			
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			sprite.x = -this.shellApi.viewportWidth;
			sprite.y = -this.shellApi.viewportHeight;
			this.groupContainer.addChild(sprite);
			
			var smoke:Smoke = new Smoke();
			var rectangle:Rectangle = new Rectangle(sprite.x, sprite.y, sprite.width, sprite.height);
			smoke.init(50, rectangle);
			var emitter:Entity = EmitterCreator.create(this, sprite, smoke, 0, 0, null, "smoke");
			emitter.add(new Sleep(false, true));
			
			this.addSystem(new SmokeSystem(this.shellApi.player.get(Spatial), emitter.get(Emitter)), SystemPriorities.lowest);
		}
		
		private function setupAlveoli():void
		{
			this.addSystem(new AlveoliSystem(), SystemPriorities.lowest);
			
			for(var i:uint = 1; i <= 6; i++)
			{
				var alveolus:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["alveoliFront" + i]);
				alveolus.add(new Id("alveolus" + i));
				alveolus.add(new Sleep());
				Timeline(alveolus.get(Timeline)).gotoAndStop("resting");
				alveolus.add(new Alveoli());
				this.addEntity(alveolus);
			}
		}
		
		private function setupBoss():void
		{
			if(!this.shellApi.checkEvent(this._events.LUNG_BOSS_DEFEATED))
			{
				this.explosion = screenFx.createBox(super.shellApi.viewportWidth * 2, super.shellApi.viewportHeight * 2, 0xFFFFFF);
				this.explosion.alpha = 0;
				this.explosion.mouseEnabled = false;
				this.explosion.x = -this.shellApi.viewportWidth;
				this.explosion.y = -this.shellApi.viewportHeight;
				this.groupContainer.addChild(this.explosion);
				
				this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/" + this.shellApi.island + "/shared/joeLifeBar.swf", onLifeBarLoaded);
				
				this.getEntityById("doorJoesCondo").add(new Sleep(true, true));
				
				this.loadFile("boss.swf", bossLoaded);
			}
		}
		
		private function onLifeBarLoaded(clip:MovieClip):void
		{
			this.joeHealth = new Entity();
			this.addEntity(this.joeHealth);
			
			var spatial:Spatial = new Spatial();
			spatial.scale = 2;
			spatial.x = super.shellApi.viewportWidth - 550;
			spatial.y = super.shellApi.viewportHeight - 170;
			this.joeHealth.add(spatial);
			
			var display:Display = new Display(clip, this.groupContainer);
			display.visible = false;
			this.joeHealth.add(display);
		}
		
		private function bossLoaded(clip:MovieClip):void
		{
			clip.mouseChildren = false;
			
			var motion:Motion;
			var sprite:Sprite;
			var i:uint = 0;
			
			this.addSystem(new BossSystem(this, this._events), SystemPriorities.lowest);
			this.addSystem(new BossBodySystem(), SystemPriorities.lowest);
			this.addSystem(new BossArmSystem(), SystemPriorities.lowest);
			this.addSystem(new BossClawSystem(this), SystemPriorities.lowest);
			this.addSystem(new FollowTargetSystem());
			this.addSystem(new BoundsCheckSystem());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new NavigationSystem());
			
			lungBoss = new Entity();
			this.addEntity(lungBoss);
			
			lungBoss.add(new Id("boss"));
			lungBoss.add(new Display(clip, this._hitContainer));
			lungBoss.add(new Spatial(1100, 3800));
			lungBoss.add(new Sleep(false, true));
			lungBoss.add(new Audio());
			lungBoss.add(new Navigation(new Point(50, 50)));
			
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.acceleration = 600;
			motionControlBase.maxVelocityByTargetDistance = 300;
			motionControlBase.freeMovement = true;
			lungBoss.add(motionControlBase);
			
			motion = new Motion();
			lungBoss.add(motion);
			motion.maxVelocity = new Point(300, 300);
			motion.friction = new Point(100, 100);
			
			var wave:WaveMotion = new WaveMotion();
			var waveData:WaveMotionData = new WaveMotionData();
			waveData.property = "y";
			waveData.magnitude = 10;
			waveData.rate = 0.2;
			wave.data.push(waveData);
			
			waveData = new WaveMotionData();
			waveData.property = "x";
			waveData.magnitude = 10;
			waveData.rate = 0.1;
			wave.data.push(waveData);
			lungBoss.add(new SpatialAddition());
			lungBoss.add(wave);
			
			var boss:Boss = new Boss();
			lungBoss.add(boss);
			
			var bossState:BossState = new BossState();
			lungBoss.add(bossState);
			
			var enemySpawn:EnemySpawn = shipGroup.addSpawn(lungBoss, EnemyType.VIRUS, 0, new Point(0, 0), new Point(0, 0), new Point(0, 0), 0);
			enemySpawn.alwaysAquire = true;
			enemySpawn.ignoreOffScreenSleep = false;
			
			//Boss Body
			var body:Entity = EntityUtils.createMovingEntity(this, clip["body"]);
			var bossBody:BossBody = new BossBody(lungBoss);
			body.add(bossBody);
			body.add(bossState);
			body.add(new Id("body"));
			motion = body.get(Motion);
			motion.rotationAcceleration = 50;
			motion.rotationMaxVelocity = 100;
			
			EntityUtils.addParentChild( body, lungBoss );
			
			//Boss Head
			sprite = this.convertToBitmapSprite(clip["head"]["headBase"]).sprite;
			var head:Entity = EntityUtils.createSpatialEntity(this, sprite);
			var bossHead:BossHead = new BossHead();
			head.add(bossHead);
			head.add(bossState);
			head.add(new Id("head"));
			
			bossHead.damage = BitmapTimelineCreator.createBitmapTimeline(clip["head"]["damage"]);
			bossHead.damage.get(Display).visible = false;
			this.addEntity(bossHead.damage);
			bossHead.damage.get(Timeline).gotoAndStop("start");
			
			//Can't BitmapTimeline the crack, since it has no width/height for its first frame, causing crashes.
			bossHead.crack = EntityUtils.createSpatialEntity(this, clip["head"]["crack"]);
			Display(bossHead.crack.get(Display)).moveToFront();
			TimelineUtils.convertClip(clip["head"]["crack"], this, bossHead.crack, head);
			bossHead.crack.get(Timeline).gotoAndStop("start");
			
			EntityUtils.addParentChild( head, lungBoss );
			
			//Boss Claw
			for(i = 1; i <= 4; i++)
			{
				var wrapper:BitmapWrapper = this.convertToBitmapSprite(clip["body"]["arm" + i]["claw"]);
				var claw:Entity = EntityUtils.createSpatialEntity(this, wrapper.sprite);
				var bossClaw:BossClaw = new BossClaw();
				claw.add(bossClaw);
				claw.add(bossState);
				claw.add(new Id("claw" + i));
				
				EntityUtils.addParentChild( claw, lungBoss );
				
				motion = new Motion();
				claw.add(motion);
				motion.maxVelocity = new Point(400, 400);
				motion.friction = new Point(100, 100);
			}
			
			//Boss Arm
			for(i = 1; i <= 4; i++)
			{
				var bitmap:Bitmap;
				
				bitmap = this.convertToBitmap(clip["body"]["arm" + i]["armMask"]).bitmap;
				//bitmap.parent.setChildIndex(bitmap, 0);
				
				bitmap = this.convertToBitmap(clip["body"]["arm" + i]["arm"]).bitmap;
				//bitmap.parent.setChildIndex(bitmap, 0);
				
				var damage:Entity = BitmapTimelineCreator.createBitmapTimeline(clip["body"]["arm" + i]["damage"]);
				damage.get(Display).visible = false;
				this.addEntity(damage);
				
				damage.get(Timeline).gotoAndStop("start");
				damage.add(new Id("arm" + i + "damage"));
				
				var previous:Entity = null;
				
				var container:DisplayObjectContainer = clip["body"]["arm" + i];
				for(var u:uint = 1; u <= 6; u++)
				{
					var dot:Sprite = new Sprite();
					dot.graphics.beginFill(0xFDFE38);
					dot.graphics.drawEllipse(-50, -70, 100, 140);
					dot.graphics.endFill();
					
					sprite = this.convertToBitmapSprite(dot).sprite;
					container.addChildAt(sprite, 1);
					
					var segment:Entity = EntityUtils.createSpatialEntity(this, sprite);
					var bossArm:BossArm = new BossArm();
					segment.add(bossArm);
					segment.add(bossState);
					
					var hazard:Hazard = new Hazard();
					hazard.damage = 0.01;
					hazard.coolDown = 1;
					segment.add(hazard);
					
					segment.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
					var damageTarget:DamageTarget = new DamageTarget();
					damageTarget.damageFactor = new Dictionary();
					damageTarget.maxDamage = 12; //12
					damageTarget.damageFactor[WeaponType.GUN] = 1;
					damageTarget.damageFactor[WeaponType.SCALPEL] = 1;
					segment.add(damageTarget);
					
					EntityUtils.addParentChild( segment, lungBoss );
					
					segment.add(new Sleep(true, true));
					segment.add(new Id("segment" + i + u));
					
					var followTarget:FollowTarget = new FollowTarget();
					followTarget.offset = new Point(0, 30);
					followTarget.properties = new <String> ["x", "y"];
					followTarget.rate = 0.1;
					
					if(previous == null)
					{
						followTarget.target = this.getEntityById("claw" + i).get(Spatial);
						segment.add(followTarget);
						previous = segment;
					}
					else
					{
						followTarget.target = previous.get(Spatial);
						segment.add(followTarget);
						previous = segment;
					}
					
					var bounds:MotionBounds = new MotionBounds();
					if(u == 6) bounds.box = new Rectangle(-10, -300, 10, 300);
					else bounds.box = new Rectangle(-50, -600, 50, 300);
					segment.add(bounds);
				}
			}
			
			var zone:Entity = super.getEntityById("bossTriggerZone");
			Zone(zone.get(Zone)).entered.addOnce(startIntro);
		}
		
		private function startIntro(...args):void
		{
			SceneUtil.lockInput(this, true, false);
			CharUtils.lockControls(this.shellApi.player, true, true);
			MotionUtils.zeroMotion(this.shellApi.player);
			
			this.getEntityById("doorHeart").add(new Sleep(true, true));
			
			for(var j:uint = 1; j <= 4; j++)
			{
				this.getEntityById("claw" + j).get(BossClaw).isActive = true;
				
				for(var i:uint = 1; i <= 6; i++)
				{
					var segment:Entity = this.getEntityById("segment" + j + i);
					
					var display:DisplayObjectContainer = Display(segment.get(Display)).displayObject;
					Display(segment.get(Display)).container.setChildIndex(display, 1);
					
					segment.get(BossArm).isActive = true;
					segment.get(Sleep).sleeping = false;
				}
			}
			
			this.shellApi.triggerEvent(this._events.BOSS_BATTLE_STARTED);
			this.playMessage("virus_attack", false);
			
			var camera:CameraSystem = this.getSystem(CameraSystem) as CameraSystem;
			camera.target = lungBoss.get(Spatial);
			camera.rate = 0.06;
			
			BossState(lungBoss.get(BossState)).state = BossState.INTRO_STATE;
		}
	}
}