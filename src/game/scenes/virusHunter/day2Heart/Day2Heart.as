package game.scenes.virusHunter.day2Heart{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.CameraZoomSystem;
	import engine.util.Command;
	
	import game.components.motion.WaveMotion;
	import game.components.motion.MotionControlBase;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.WaveMotionData;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Heart.components.WormBody;
	import game.scenes.virusHunter.day2Heart.components.WormBoss;
	import game.scenes.virusHunter.day2Heart.components.WormMass;
	import game.scenes.virusHunter.day2Heart.systems.WormBodySystem;
	import game.scenes.virusHunter.day2Heart.systems.WormBossSystem;
	import game.scenes.virusHunter.day2Heart.systems.WormMassSystem;
	import game.scenes.virusHunter.day2Heart.systems.WormTentacleSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.systems.TentacleSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.ScreenEffects;
	import game.util.Utils;
	
	public class Day2Heart extends ShipScene
	{
		private var _events:VirusHunterEvents;
		public var shipGroup:ShipGroup;
		public var explosion:Sprite;
		public var screenFx:ScreenEffects = new ScreenEffects();
		
		public function Day2Heart()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/day2Heart/";
			
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
			
			setupScene();
			setupFat();
			setupPulses();
			setupValves();
			setupBoss();
		}
		
		private function setupScene():void
		{
			this.shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			
			this.shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, 0.5, 40, 140, 5);
			
			var zoom:CameraZoomSystem = this.getSystem(CameraZoomSystem) as CameraZoomSystem;
			zoom.scaleTarget = 0.5;
			zoom.scaleRate = 1;
		}
		
		private function setupFat():void
		{
			for(var i:uint = 1; i <= 11; i++)
			{
				var fat:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["fat" + i]);
				fat.get(Timeline).gotoAndPlay(0);
				this.addEntity(fat);
			}
		}
		
		private function setupPulses():void
		{
			for(var i:uint = 1; i <= 8; i++)
			{
				var pulse:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["pulse" + i]);
				pulse.get(Display).moveToBack();
				pulse.get(Timeline).gotoAndPlay(0);
				this.addEntity(pulse);
			}
		}
		
		private function setupValves():void
		{
			for(var i:uint = 1; i <= 2; i++)
			{
				var clip:MovieClip = this._hitContainer["valve" + i];
				var sprite:Sprite = this.convertToBitmapSprite(clip).sprite;
				DisplayUtils.moveToTop(sprite);
			}
		}
		
		private function setupBoss():void
		{
			this.shellApi.triggerEvent(this._events.BOSS_BATTLE_ENDED);
			
			if(!this.shellApi.checkEvent(this._events.WORM_BOSS_DEFEATED))
			{
				this.explosion = screenFx.createBox(super.shellApi.viewportWidth * 2, super.shellApi.viewportHeight * 2, 0xFFFFFF);
				this.explosion.alpha = 0;
				this.explosion.mouseEnabled = false;
				this.explosion.mouseChildren = false;
				this.explosion.x = -this.shellApi.viewportWidth;
				this.explosion.y = -this.shellApi.viewportHeight;
				this.groupContainer.addChild(this.explosion);
				
				this.loadFile("boss.swf", bossLoaded);
			}
			else
			{
				this.removeEntity(this.getEntityById("valve"));
				this._hitContainer["valve1"].rotation += 70;
				this._hitContainer["valve2"].rotation -= 70;
			}
		}
		
		private function bossLoaded(clip:MovieClip):void
		{
			clip.mouseChildren = false;
			var sprite:Sprite;
			
			this.addSystem(new WormBossSystem(this, this._events), SystemPriorities.lowest);
			this.addSystem(new WormBodySystem(), SystemPriorities.lowest);
			this.addSystem(new WormMassSystem(), SystemPriorities.lowest);
			this.addSystem(new WormTentacleSystem(shipGroup.enemyCreator), SystemPriorities.lowest);
			this.addSystem(new TentacleSystem());
			this.addSystem(new FollowTargetSystem());
			this.addSystem(new WaveMotionSystem());
			
			//Create Worm Boss Entity
			var boss:Entity = new Entity();
			this.addEntity(boss);
			
			//Add Boss Components
			var wormBoss:WormBoss = new WormBoss();
			boss.add(wormBoss);									//Worm Boss
			
			boss.add(new Id("boss"));							//ID
			boss.add(new Spatial(2800, 900));					//Spatial
			boss.add(new Display(clip, this._hitContainer));	//Display
			boss.add(new Motion());								//Motion
			boss.add(new Sleep(false, true));					//Sleep
			boss.add(new SpatialAddition());					//Spatial Addition
			
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "boss_breathing_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			boss.add(audio);
			boss.add(new AudioRange(3000));
			
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
			boss.add(wave);										//Wave Motion
			
			var motionBase:MotionControlBase = new MotionControlBase();
			motionBase.acceleration = 600;
			motionBase.maxVelocityByTargetDistance = 300;
			motionBase.freeMovement = true;
			boss.add(motionBase);								//Motion Control Base
			
			var head:Entity = BitmapTimelineCreator.createBitmapTimeline(clip["head"]);
			var display:DisplayObjectContainer = Display(head.get(Display)).displayObject;
			display.parent.setChildIndex(display, display.parent.numChildren - 2);
			
			head.get(Timeline).gotoAndPlay(0);
			this.addEntity(head);
			
			//Create Worm Mass Entities
			for(var i:uint = 1; i <= 4; i++)
			{
				var mass:Entity = BitmapTimelineCreator.createBitmapTimeline(clip["masses"]["side" + i]["mass"]);
				mass.add(new Id("mass" + i));
				
				var wormMass:WormMass = new WormMass(boss, wormBoss);
				mass.add(wormMass);
				
				mass.add(new Sleep(false, true));
				mass.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
				mass.add(new Audio());
				
				var hazard:Hazard = new Hazard();
				hazard.damage = 0.01;
				hazard.coolDown = 1;
				mass.add(hazard);
				
				var tween:Tween = new Tween();
				var mc:MovieClip = clip["masses"]["side" + i];
				var object:Object = {scaleX:1.03, scaleY:1.03, ease:Quad.easeInOut, onComplete:scaleIn, onCompleteParams:[mc, tween]};
				tween.to(mc, Utils.randNumInRange(1, 2), object);
				mass.add(tween);
				
				var target:DamageTarget = new DamageTarget();
				target.maxDamage = 10;
				target.damageFactor = new Dictionary();
				target.damageFactor[WeaponType.GUN] = 1;
				target.damageFactor[WeaponType.SCALPEL] = 1;
				target.hitParticleColor1 = Tentacle.BORDER_COLOR;
				target.hitParticleColor2 = Tentacle.BASE_COLOR;
				mass.add(target);
				
				EntityUtils.addParentChild(mass, boss);
				this.addEntity(mass);
			}
			
			//Create Worm Body Entity
			sprite = this.convertToBitmapSprite(clip["body"]).sprite;
			var body:Entity = EntityUtils.createMovingEntity(this, sprite);
			body.get(Display).moveToBack();
			body.add(new Id("body"));								//ID
			body.add(new WormBody(wormBoss));						//Worm Body
			body.add(new Sleep(false, true));						//Sleep
			
			EntityUtils.addParentChild(body, boss);					//Parent/Child
			
			var zone:Entity = super.getEntityById("bossTriggerZone");
			Zone(zone.get(Zone)).entered.addOnce(Command.create(startIntro, boss));
		}
		
		private function startIntro(zone:String, ship:String, boss:Entity):void
		{
			this.playMessage("heartworm_attack", false, "virus_attack");
			
			this.shellApi.triggerEvent(this._events.BOSS_BATTLE_STARTED);
			WormBoss(boss.get(WormBoss)).state = WormBoss.SETUP_STATE;
		}
		
		private function scaleIn(clip:MovieClip, tween:Tween):void
		{
			tween.to(clip, Utils.randNumInRange(1, 2), {scaleX:0.97, scaleY:0.97, ease:Quad.easeInOut, onComplete:scaleOut, onCompleteParams:[clip, tween]});
		}
		
		private function scaleOut(clip:MovieClip, tween:Tween):void
		{
			tween.to(clip, Utils.randNumInRange(1, 2), {scaleX:1.03, scaleY:1.03, ease:Quad.easeInOut, onComplete:scaleIn, onCompleteParams:[clip, tween]});
		}
	}
}