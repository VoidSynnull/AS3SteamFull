package game.scenes.virusHunter.intestineBattle
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.CameraSystem;
	import engine.systems.CameraZoomSystem;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.brain.virus.Virus;
	import game.scenes.virusHunter.intestine.components.AcidDrip;
	import game.scenes.virusHunter.intestine.particles.AcidSplash;
	import game.scenes.virusHunter.intestine.systems.AcidDripSystem;
	import game.scenes.virusHunter.intestineBattle.components.IntestineBoss;
	import game.scenes.virusHunter.intestineBattle.systems.IntestineBossSystem;
	import game.scenes.virusHunter.intestineBattle.systems.SceneWeaponTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class IntestineBattle extends ShipScene
	{
		private var _events:VirusHunterEvents;
		
		public function IntestineBattle()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{	
			super.groupPrefix = "scenes/virusHunter/intestineBattle/";
			
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
			
			setupBoss();
			setupAcid();
			
			setupAnimations();
			
			//SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, removeStuff));
			
			var shipGroup:ShipGroup = super.getGroupById("shipGroup") as ShipGroup;
			shipGroup.createSceneWeaponTargets(super._hitContainer);
			
			super.addSystem(new SceneWeaponTargetSystem(this), SystemPriorities.checkCollisions);
		}
		
		private function removeStuff():void
		{
			/*
			var shipGroup:ShipGroup = super.getGroupById("shipGroup") as ShipGroup;
			shipGroup.removeWeapon(super.shellApi.player, WeaponType.SCALPEL);
			shipGroup.removeWeapon(super.shellApi.player, WeaponType.GOO);
			shipGroup.removeWeapon(super.shellApi.player, WeaponType.ANTIGRAV);
			shipGroup.removeWeapon(super.shellApi.player, WeaponType.SHOCK);
			shipGroup.removeWeapon(super.shellApi.player, WeaponType.SHIELD);
			*/
			/*
			var shipGroup:ShipGroup = super.getGroupById("shipGroup") as ShipGroup;
			shipGroup.createWhiteBloodCellSwarm(new Spatial(500, 500));
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, removeWBC));
			*/
			super.lockControls(true);
			//trace("updated");
		}
		
		private function setupAnimations():void
		{
			var clips:Array = ["fat1Art"];
			var abovePlayer:Array = ["fat1Art"];
			var entity:Entity;
			var sleep:Sleep;
			var timeline:Timeline;
			
			for(var n:int = 0; n < clips.length; n++)
			{
				entity = TimelineUtils.convertClip(super._hitContainer[clips[n]]["animation"], this);
				entity.add(new Id(clips[n]));
				entity.add(new Spatial(super._hitContainer[clips[n]].x, super._hitContainer[clips[n]].y));
				entity.add(new Id(clips[n]));
				sleep = entity.get(Sleep);
				sleep.useEdgeForBounds = true;
				timeline = entity.get(Timeline);
				timeline.labelReached.add(handleReachedFatLabel);
			}
			
			var playerDisplay:Display = super.shellApi.player.get(Display);
			var playerDepth:int = playerDisplay.container.getChildIndex(playerDisplay.displayObject);
			var nextClip:Sprite;
			
			for(n = 0; n < abovePlayer.length; n++)
			{
				nextClip = super._hitContainer[abovePlayer[n]];
				super._hitContainer.setChildIndex(nextClip, playerDepth);
			}
		}
		
		private function handleReachedFatLabel(label:String):void
		{
			if(label == "fatOpen")
			{
				super.shellApi.triggerEvent("fatOpen");
			}
			else if(label == "fatTear")
			{
				super.shellApi.triggerEvent("fatTear");	
			}
		}
		
		private function removeWBC():void
		{
			var shipGroup:ShipGroup = super.getGroupById("shipGroup") as ShipGroup;
			shipGroup.whiteBloodCellExit();
		}
		
		private function startIntro(...args):void
		{
			this.shellApi.triggerEvent(this._events.BOSS_BATTLE_STARTED);
			
			var smallScene:Rectangle = super.shellApi.camera.camera.area.clone();
			smallScene.x += 500;
			smallScene.width -= 500;
			super.shellApi.camera.camera.area = smallScene;
			
			super.lockControls(true);
			
			_cameraTarget = new Spatial(1500, 600);
			
			// set the camera target to a new static spatial to get it to pan to a point...it is reset in the boss 
			var cameraSystem:CameraSystem = super.getSystem(CameraSystem) as CameraSystem;
			cameraSystem.target = _cameraTarget;
			cameraSystem.rate = .04; // temporarily decrease the pan rate.
			var cameraZoom:CameraZoomSystem = super.getSystem(CameraZoomSystem) as CameraZoomSystem;
			cameraZoom.scaleTarget = 1.5;  // camera will zoom into 1.5x scale.
			
			var timelineEntity:Entity = super.getEntityById(IntestineBoss.INTRO, _boss);
			Sleep(timelineEntity.get(Sleep)).sleeping = false;
		}
		
		private function setupBoss():void
		{
			if(this.shellApi.checkEvent(this._events.INTESTINE_BOSS_DEFEATED))
			{
				if(!super.shellApi.checkEvent(VirusHunterEvents(super.events).GOT_SCALPEL))
				{
					super.addSceneItem(WeaponType.SCALPEL, 1500, 580);
				}
				
				return;
			}
			
			var bossTriggerZone:Entity = super.getEntityById("bossTriggerZone");
			Zone(bossTriggerZone.get(Zone)).entered.addOnce(startIntro);
			
			var sceneExit:Entity = super.getEntityById("doorBloodStream");
			Sleep(sceneExit.get(Sleep)).sleeping = true;
			Sleep(sceneExit.get(Sleep)).ignoreOffscreenSleep = true;
			
			super.addSystem(new IntestineBossSystem(this, this._events), SystemPriorities.lowest);
			
			var boss:IntestineBoss = new IntestineBoss();
			var bossStates:Array = [IntestineBoss.DIE, IntestineBoss.HURT, IntestineBoss.IDLE, IntestineBoss.IDLE_WEAKENED, IntestineBoss.INTRO, IntestineBoss.REVIVE, IntestineBoss.WEAKENED];
			var state:String;
			var clip:MovieClip;
			var sleep:Sleep;
			var spatial:Spatial;
			var display:Display = new Display();
			display.displayObject = new Sprite();
			super._hitContainer.addChild(display.displayObject);
			spatial = new Spatial(1507, 420);
			spatial.rotation = 180;
			
			_boss = new Entity();
			_boss.add(boss);
			_boss.add(spatial);
			_boss.add(display);
			boss.state = IntestineBoss.INTRO;
			boss.target = super.shellApi.player.get(Spatial);
			
			for(var n:int = 0; n < bossStates.length; n++)
			{
				state = bossStates[n];
				clip = super.getAsset(state + ".swf");
				sleep = new Sleep(true, true);

				display.displayObject.addChild(clip);
				
				var timelineEntity:Entity = TimelineUtils.convertAllClips(clip, _boss, this);
				timelineEntity.add(new Id(state));
				timelineEntity.add(sleep);
				timelineEntity.add(new Display(clip));
				timelineEntity.add(new Spatial(0, 0));
			}
			
			super.addEntity(_boss);
			
			var tentacle:Entity = new Entity();
			var tentacleDisplay:MovieClip = super._hitContainer.addChild(super.getAsset("boss_tentacle.swf")) as MovieClip;
			tentacle.add(new Display(tentacleDisplay, super._hitContainer));
			tentacle.add(new Spatial());
			tentacle.add(new Sleep(true, true));
			tentacle.add(new Id("tentacle"));
			tentacle.add(new Tween());
			tentacle.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
			tentacle.add(new Audio());
			var damageTarget:DamageTarget = new DamageTarget();
			damageTarget.damageFactor = new Dictionary();
			damageTarget.maxDamage = 15;
			damageTarget.damageFactor[WeaponType.GUN] = 1;
			tentacle.add(damageTarget);
			var hazard:Hazard = new Hazard();
			hazard.damage = 0.4;
			hazard.coolDown = 1;
			tentacle.add(hazard);
			tentacle.add(new Tween());
			TimelineUtils.convertClip(tentacleDisplay.glob, this, tentacle, _boss);
			super.addEntity(tentacle);
			//EntityUtils.addParentChild(tentacle, _boss, true);
		}
		
		/*********************************************************************************
		 * ACID SETUP
		 */
		
		private function setupAcid():void
		{
			this.addSystem(new AcidDripSystem(this), SystemPriorities.lowest);
			var endYs:Array = [950, 975];
			
			for(var i:uint = 1; i <= 2; i++)
			{
				//Create sack entity
				var clip:MovieClip = this._hitContainer["sack" + i];
				var sack:Entity = EntityUtils.createSpatialEntity(this, clip);
				sack.add(new Id("sack" + i));
				sack.add(new Sleep());
				sack.add(new Audio());
				sack.add(new AudioRange(600, 0.01, 1));
				
				//Add timeline
				TimelineUtils.convertClip( clip, this, sack );
				Timeline(sack.get( Timeline )).gotoAndStop("begin");
				
				//Add acid entity
				clip = this._hitContainer["acid" + i];
				var acid:Entity = EntityUtils.createSpatialEntity(this, clip);
				acid.get(Display).visible = false;
				acid.add(new Id("acid" + i));
				
				//Add particles
				var splash:AcidSplash = new AcidSplash();
				splash.init(acid.get(Spatial).x, endYs[i - 1]);
				var emitter:Entity = EmitterCreator.create(this, this._hitContainer, splash, 0, 0, null, "acidSplash" + i, null, false);
				
				//Add AcidDrip component
				sack.add(new AcidDrip(acid, emitter, endYs[i - 1]));
				
				//Add Hazard and MovieClipHit for damaging the ship
				var target:Hazard = new Hazard();
				target.damage = 0.1;
				target.coolDown = 1;
				acid.add(target);
				
				acid.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
			}
		}
		
		private var _cameraTarget:Spatial;
		private var _boss:Entity;
	}
}