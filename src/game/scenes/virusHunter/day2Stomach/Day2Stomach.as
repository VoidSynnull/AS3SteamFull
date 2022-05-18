package game.scenes.virusHunter.day2Stomach{
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
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.systems.CameraZoomSystem;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.creators.entity.BitmapTimelineCreator;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Stomach.systems.Day2StomachTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.components.SceneWeaponTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.systems.TentacleSystem;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class Day2Stomach extends ShipScene
	{
		private var _shipGroup:ShipGroup;
		private var _events:VirusHunterEvents;
		
		public var numChunks:uint = 3;
		
		public function Day2Stomach()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/day2Stomach/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override protected function allShipsLoaded():void
		{
			super.allShipsLoaded();
			
			var killCount:KillCount = new KillCount();
			killCount.count[EnemyType.VIRUS] = 0;
			killCount.count[EnemyType.RED_BLOOD_CELL] = 0;
			this.shellApi.player.add(killCount);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = this.events as VirusHunterEvents;
			
			//For falling treats
			this.addSystem(new ThresholdSystem());
			
			setupScene();
			setupFat();
			setupTreats();
			setupTentacles();
		}
		
		private function setupScene():void
		{
			_shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(this._hitContainer);
			
			_shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, 0.5, 40, 140, 5);
			
			this.addSystem(new Day2StomachTargetSystem(_shipGroup.enemyCreator, this._events), SystemPriorities.checkCollisions);
			
			var camera:CameraSystem = this.getSystem(CameraSystem) as CameraSystem;
			camera.scale = 0.65;
			
			var zoom:CameraZoomSystem = this.getSystem(CameraZoomSystem) as CameraZoomSystem;
			zoom.scaleTarget = 0.65;
		}
		
		/*********************************************************************************
		 * FAT SETUP
		 */
		
		private function setupFat():void
		{
			this.addSystem(new BitmapSequenceSystem(), SystemPriorities.animate);
			
			for(var i:uint = 1; i <= 8; i++)
			{
				var clip:MovieClip = this._hitContainer["fat" + i + "Art"];
				
				var fat:Entity = BitmapTimelineCreator.createBitmapTimeline(clip);
				var display:Display = fat.get(Display);
				display.displayObject.mouseChildren = false;
				display.displayObject.mouseEnabled = false;
				this.addEntity(fat);
				fat.add(new Id("fat" + i + "Art"));
				
				var timeline:Timeline = fat.get(Timeline);
				
				if(this.shellApi.checkEvent(this._events.STOMACH_FAT_CLEARED_ + i))
				{
					this.removeEntity(this.getEntityById("fat" + i));
					this.removeEntity(this.getEntityById("fat" + i + "Target"));
					timeline.gotoAndStop("end");
				}
				else timeline.labelReached.add(handleReachedFatLabel);
			}
			
			if(this.shellApi.checkEvent(this._events.STOMACH_FAT_CLEARED_ + 3))
			{
				for(var j:uint = 1; j <= 4; j++)
					this._hitContainer.removeChild(this._hitContainer["chunk" + j]);
			}
			
			if(this.shellApi.checkEvent(this._events.STOMACH_FAT_CLEARED_ + 4) &&
				this.shellApi.checkEvent(this._events.STOMACH_FAT_CLEARED_ + 5))
			{
				clip = this._hitContainer["bone"];
				clip.x = 2000;
				clip.y = 2000;
				clip.rotation = -60;
			}
		}
		
		private function handleReachedFatLabel(label:String):void
		{
			if(label == "start")
			{
				super.shellApi.triggerEvent("fatOpen");
			}
			else if(label == "break")
			{
				super.shellApi.triggerEvent("fatTear");	
			}
		}
		
		/*********************************************************************************
		 * TREAT SETUP
		 */
		
		private function setupTreats():void
		{
			for (var i:uint = 1; i <= 6; i++)
			{
				var sprite:Sprite = this.convertToBitmapSprite(this._hitContainer["treat" + i + "Art"]).sprite;
				DisplayUtils.moveToTop(sprite);
				
				if(this.shellApi.checkEvent(this._events.DOG_TREAT_CLEARED_ + i))
				{
					this._hitContainer.removeChild(sprite);
					this.removeEntity(this.getEntityById("treat" + i));
					this.removeEntity(this.getEntityById("treat" + i + "Target"));
				}
			}
			
			for(var j:uint = 1; j <= this.numChunks; j++)
				this.loadFile("chunk.swf", onFileLoaded, j);
		}
		
		private function onFileLoaded(clip:MovieClip, i:uint):void
		{
			var chunk:Entity = EntityUtils.createMovingEntity(this, clip, this._hitContainer);
			chunk.add(new Id("chunk" + i));
			chunk.add(new Sleep(false, true));
			
			TimelineUtils.convertClip( clip, this, chunk );
			Timeline(chunk.get(Timeline)).gotoAndStop(i - 1);
			
			chunk.get(Spatial).scale = 0.6;
			chunk.get(Display).alpha = 0;
			
			var motion:Motion = chunk.get(Motion);
			motion.acceleration.y = 600;
			motion.pause = true;
		}
		
		private function setupTentacles():void
		{
			var hasTentacles:Boolean = false;
			
			for(var i:uint = 8; i <= 10; i++)
			{
				if(!this.shellApi.checkEvent(this._events.WORM_CLEARED_ + i))
				{
					if(!hasTentacles) hasTentacles = true;
					
					var tentacle:Entity = new Entity();
					this.addEntity(tentacle);
					
					var sprite:Sprite = new Sprite();
					sprite.mouseChildren = false;
					sprite.mouseEnabled = false;
					tentacle.add(new Display(sprite, this._hitContainer));
					
					var spatial:Spatial;
					switch(i)
					{
						case 8: spatial = new Spatial(2260, 310); 	spatial.rotation = 90;	break;
						case 9: spatial = new Spatial(3800, 1650); 	spatial.rotation = 180;	break;
						case 10: spatial = new Spatial(2250, 2000); spatial.rotation = -90; break;
					}
					tentacle.add(spatial);
					
					tentacle.add(new Id("tentacle" + i + "Target"));
					tentacle.add(new Sleep(false, true));
					tentacle.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
					tentacle.add(new SceneWeaponTarget());
					
					var audio:Audio = new Audio();
					tentacle.add(audio);
					audio.play(SoundManager.EFFECTS_PATH + "tendrils_idle_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
					tentacle.add(new AudioRange(3000));
					
					var tent:Tentacle = new Tentacle();
					tent.target = this.shellApi.player.get(Spatial);
					tent.minSpeed = 1;
					tent.minMagnitude = 0.02;
					tentacle.add(tent);
					
					var target:DamageTarget = new DamageTarget();
					target.maxDamage = 10;
					target.damageFactor = new Dictionary();
					target.damageFactor[WeaponType.GUN] = 1;
					target.damageFactor[WeaponType.SCALPEL] = 1;
					target.hitParticleColor1 = Tentacle.BORDER_COLOR;
					target.hitParticleColor2 = Tentacle.BASE_COLOR;
					tentacle.add(target);
					
					var hazard:Hazard = new Hazard();
					hazard.damage = 0.2;
					hazard.coolDown = .75;
					tentacle.add(hazard);
				}
			}
			if(hasTentacles) this.addSystem(new TentacleSystem(), SystemPriorities.lowest);
		}
	}
}