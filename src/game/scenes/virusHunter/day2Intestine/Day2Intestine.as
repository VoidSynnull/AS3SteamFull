package game.scenes.virusHunter.day2Intestine{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Intestine.components.NerveMove;
	import game.scenes.virusHunter.day2Intestine.systems.Day2IntestineTargetSystem;
	import game.scenes.virusHunter.day2Intestine.systems.NerveMoveSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.SceneWeaponTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.systems.TentacleSystem;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	public class Day2Intestine extends ShipScene
	{
		private var _shipGroup:ShipGroup;
		private var _events:VirusHunterEvents;
		
		public function Day2Intestine()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/day2Intestine/";
			
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
			
			setupScene();
			setupMuscles();
			setupNerves();
			setupTentacles();
		}
		
		private function setupScene():void
		{
			_shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(this._hitContainer);
			
			_shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, 0.5, 40, 140, 5);
			
			this.addSystem(new Day2IntestineTargetSystem(_shipGroup.enemyCreator, this._events), SystemPriorities.checkCollisions);
		}
		
		private function setupMuscles():void
		{
			var letter:Array = ["A", "B"];
			
			for(var i:uint = 1; i <= 6; i++)
			{
				for(var j:uint = 0; j <= 1; j++)
				{
					var clip:MovieClip = this._hitContainer["muscle" + i + letter[j]];
					var sprite:Sprite = this.convertToBitmapSprite(clip).sprite;
					DisplayUtils.moveToTop(sprite);
				}
			}
		}
		
		private function setupNerves():void
		{
			this.addSystem(new NerveMoveSystem());
			
			for(var i:uint = 1; i <= 7; i++)
			{
				var clip:MovieClip = this._hitContainer["nerve" + i];
				var sprite:Sprite = this.convertToBitmapSprite(clip).sprite;
				DisplayUtils.moveToTop(sprite);
				var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
				entity.add(new Sleep());
				entity.add(new Id("nerve" + i));
				entity.add(new Audio());
				entity.add(new NerveMove());
			}
		}
		
		private function setupTentacles():void
		{
			var hasTentacles:Boolean = false;
			
			for(var i:uint = 3; i <= 7; i++)
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
						case 3: spatial = new Spatial(710, 1360); 	spatial.rotation = 90;	break;
						case 4: spatial = new Spatial(490, 550); 	spatial.rotation = 0;	break;
						case 5: spatial = new Spatial(1800, 50); 	spatial.rotation = 90; 	break;
						case 6: spatial = new Spatial(1430, 925); 	spatial.rotation = 0; 	break;
						case 7: spatial = new Spatial(2600, 1900); 	spatial.rotation = 90; 	break;
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
					
					var tent:Tentacle = new Tentacle(12);
					tent.target = this.shellApi.player.get(Spatial);
					tent.minDistance = 200;
					tent.maxDistance = 800;
					tent.minMagnitude = 0.05;
					tent.maxMagnitude = 0.2;
					tent.minSpeed = 1;
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
					hazard.coolDown = 1;
					tentacle.add(hazard);
				}
			}
			
			if(hasTentacles) this.addSystem(new TentacleSystem(), SystemPriorities.lowest);
		}
	}
}