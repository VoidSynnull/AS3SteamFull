package game.scenes.virusHunter.day2Lungs{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
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
	import game.scenes.virusHunter.day2Lungs.components.HoleTentacle;
	import game.scenes.virusHunter.day2Lungs.data.HoleData;
	import game.scenes.virusHunter.day2Lungs.systems.HoleTentacleSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.systems.TentacleSystem;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	
	public class Day2Lungs extends ShipScene
	{
		private var _events:VirusHunterEvents;
		private var _shipGroup:ShipGroup;
		
		public function Day2Lungs()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/day2Lungs/";
			
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
			this._events = this.events as VirusHunterEvents;
			
			setupScene();
			setupAlveoli();
			setupTentacles();
		}
		
		private function setupScene():void
		{
			_shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			
			_shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, 0.5, 40, 140, 5);
			
			var camera:CameraSystem = this.getSystem(CameraSystem) as CameraSystem;
			camera.scale = 0.4;
			
			var zoom:CameraZoomSystem = this.getSystem(CameraZoomSystem) as CameraZoomSystem;
			zoom.scaleTarget = 0.4;
			zoom.scaleRate = 1;
		}
		
		private function setupAlveoli():void
		{
			this.addSystem(new BitmapSequenceSystem());
			
			for(var i:uint = 1; i <= 34; i++)
			{
				var alveolus:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["alveoli" + i]);
				alveolus.get(Timeline).gotoAndPlay(0);
				this.addEntity(alveolus);
			}
		}
		
		private function setupTentacles():void
		{
			if(this.shellApi.checkEvent(this._events.LUNG_WORMS_DEFEATED))
			{
				this.shellApi.triggerEvent(this._events.BOSS_BATTLE_ENDED);
				return;
			}
			
			this.shellApi.triggerEvent(this._events.BOSS_BATTLE_STARTED);
			
			var numTentacles:uint = 7;
			
			this.addSystem(new TentacleSystem(), SystemPriorities.lowest);
			this.addSystem(new HoleTentacleSystem(_shipGroup.enemyCreator, this._events, this.shellApi.player, numTentacles), SystemPriorities.lowest);
			
			for(var i:uint = 1; i <= numTentacles; i++)
			{
				var tentacle:Entity = new Entity();
				this.addEntity(tentacle);
				
				var data:HoleData = new HoleData(i);
				tentacle.add(new HoleTentacle(data));
				
				var sprite:Sprite = new Sprite();
				sprite.mouseChildren = false;
				sprite.mouseEnabled = false;
				tentacle.add(new Display(sprite, this._hitContainer["tentacles"]["container"]));
				
				tentacle.add(new Id("tentacle" + i + "Target"));
				tentacle.add(new Sleep(false, true));
				
				var clipHit:MovieClipHit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship");
				clipHit.shapeHit = true;
				clipHit.pointHit = true;
				tentacle.add(clipHit);
				
				tentacle.add(new Tween());
				
				var audio:Audio = new Audio();
				tentacle.add(audio);
				audio.play(SoundManager.EFFECTS_PATH + "tendrils_idle_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				tentacle.add(new AudioRange(3000));
				
				var spatial:Spatial = new Spatial();
				tentacle.add(spatial);
				switch(i)
				{
					case 1: data.x = 1570;	data.y = 230;	data.rotation = 85; 	break;
					case 2: data.x = 3060;	data.y = 190;	data.rotation = 90; 	break;
					case 3: data.x = 4270;	data.y = 570;	data.rotation = 155; 	break;
					case 4: data.x = 4270;	data.y = 1560;	data.rotation = -170; 	break;
					case 5: data.x = 3580;	data.y = 2435;	data.rotation = -115; 	break;
					case 6: data.x = 2475;	data.y = 2360;	data.rotation = -90; 	break;
					case 7: data.x = 1335;	data.y = 2265;	data.rotation = -80;	break;
				}
				spatial.x = data.x; spatial.y = data.y; spatial.rotation = data.rotation;
							
				var target:DamageTarget 				= new DamageTarget();
				target.damageFactor 					= new Dictionary();
				target.damageFactor[WeaponType.GUN] 	= 1;
				target.damageFactor[WeaponType.SCALPEL] = 1;
				target.hitParticleColor1 				= Tentacle.BORDER_COLOR;
				target.hitParticleColor2 				= Tentacle.BASE_COLOR;
				target.maxDamage 						= 10;
				tentacle.add(target);
				
				switch(i)
				{
					case 4: case 5:
						data.numSegments 	= 30;
						data.minDistance 	= 600;
						data.maxDistance 	= 1000;
						data.minSpeed 		= 2;
						data.maxSpeed 		= 5;
						data.minMagnitude 	= 0.05;
						data.maxMagnitude 	= 0.1;
					break;
					
					default:
						data.numSegments 	= 40;
						data.minDistance 	= 600;
						data.maxDistance 	= 1000;
						data.minSpeed 		= 2;
						data.maxSpeed 		= 5;
						data.minMagnitude 	= 0.05;
						data.maxMagnitude 	= 0.1;
					break;
				}
				
				var tent:Tentacle 	= new Tentacle(data.numSegments);
				tent.target 		= this.shellApi.player.get(Spatial);
				tent.minDistance 	= data.minDistance;
				tent.maxDistance 	= data.maxDistance;
				tent.minSpeed 		= data.minSpeed;
				tent.maxSpeed 		= data.maxSpeed;
				tent.minMagnitude 	= data.minMagnitude;
				tent.maxMagnitude 	= data.maxMagnitude;
				tentacle.add(tent);
				
				var hazard:Hazard 	= new Hazard();
				hazard.damage 		= 0.05;
				hazard.coolDown 	= 2;
				tentacle.add(hazard);
			}
		}
	}
}