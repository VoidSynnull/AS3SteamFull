package game.scenes.virusHunter.day2Mouth{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
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
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Mouth.particles.ToothDrip;
	import game.scenes.virusHunter.day2Mouth.systems.Day2MouthTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.SceneWeaponTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.systems.TentacleSystem;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class Day2Mouth extends ShipScene
	{
		private var _shipGroup:ShipGroup;
		private var _events:VirusHunterEvents;
		
		public function Day2Mouth()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/virusHunter/day2Mouth/";
			
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
			setupMainStreetDoor();
			setupCuts();
			setupTeethDrips();
			setupTentacles();
			setupWorms();
		}
		
		private function setupScene():void
		{
			_shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(this._hitContainer);
			
			_shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, 0.5, 40, 140, 5);
			
			this.addSystem(new Day2MouthTargetSystem(_shipGroup.enemyCreator, this._events), SystemPriorities.checkCollisions);
			
			var zoom:CameraZoomSystem = this.getSystem(CameraZoomSystem) as CameraZoomSystem;
			zoom.scaleTarget = 0.5;
			zoom.scaleRate = 1;
		}
		
		private function setupMainStreetDoor():void
		{
			if(!this.shellApi.checkEvent(this._events.WORM_BOSS_DEFEATED))
				this.getEntityById("doorMainStreet").add(new Sleep(true, true));
		}
		
		private function setupCuts():void
		{
			this.addSystem(new BitmapSequenceSystem(), SystemPriorities.animate);
			
			for(var i:uint = 1; i <= 5; i++)
			{
				var clip:MovieClip = this._hitContainer["cut" + i + "Art"]["animation"];
				var cut:Entity = BitmapTimelineCreator.createBitmapTimeline(clip);
				this.addEntity(cut);
				cut.add(new Id("cut" + i + "Art"));
				cut.add(new Audio());
				
				if(this.shellApi.checkEvent(_events.DOG_CUT_CURED_ + i))
				{
					cut.get(Timeline).gotoAndStop("end");
					this.removeEntity(this.getEntityById("cut" + i));
				}
				else
				{
					var y:int;
					if(i == 2 || i == 3) y = 100;
					else y = -100;
					_shipGroup.addSpawn(this.getEntityById("cut" + i + "Target"), EnemyType.RED_BLOOD_CELL, 15, new Point(40, 40), new Point(-30, y), new Point(30, y), 0.5);
				}
			}
		}
		
		private function setupTeethDrips():void
		{
			var drip:ToothDrip = new ToothDrip();
			drip.init(new Point(220, 270), new Point(2355, 560));
			var emitter:Entity = EmitterCreator.create(this, this._hitContainer, drip, 0, 0, null, "toothDrip", null);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(0, 0, Command.create(handleDrip, emitter)));
		}
		
		private function handleDrip(emitter:Entity):void
		{
			if(Math.random() < 0.02)
				Emitter(emitter.get(Emitter)).emitter.start();
		}
		
		private function setupTentacles():void
		{
			var hasTentacles:Boolean = false;
			
			for(var i:uint = 1; i <= 2; i++)
			{
				if(!this.shellApi.checkEvent(this._events.WORM_CLEARED_ + i))
				{
					hasTentacles = true;
					
					var tentacle:Entity = new Entity();
					this.addEntity(tentacle);
					
					var sprite:Sprite = new Sprite();
					sprite.mouseChildren = false;
					sprite.mouseEnabled = false;
					tentacle.add(new Display(sprite, this._hitContainer));
					
					var spatial:Spatial;
					switch(i)
					{
						case 1: spatial = new Spatial(4460, 330); 	spatial.rotation = 75; 		break;
						case 2: spatial = new Spatial(2960, 1970); 	spatial.rotation = -45; 	break;
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
					
					var tent:Tentacle = new Tentacle(30);
					tent.target = this.shellApi.player.get(Spatial);
					tent.minDistance = 800;
					tent.maxDistance = 1400;
					tent.maxMagnitude = 0.12;
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
		
		private function setupWorms():void
		{
			var hasWorms:Boolean = false;
			
			if(this.shellApi.checkEvent(this._events.RETRACT_WORMS))
			{
				this.shellApi.removeEvent(this._events.RETRACT_WORMS);
				this.handleWormCameraPan();
			}
			
			for(var i:uint = 1; i <= 9; i++)
			{
				var sprite:Sprite = super.convertToBitmapSprite(this._hitContainer["worm" + i + "Art"]).sprite;
				DisplayUtils.moveToTop(sprite);
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
				var sleep:Sleep = new Sleep();
				entity.add(sleep);
				entity.add(new Id("worm" + i));
				
				var tween:Tween = new Tween();
				entity.add(tween);
				
				if(this.shellApi.checkEvent(this._events.WORM_CLEARED_ + i))
				{
					this.removeEntity(this.getEntityById("worm" + i + "Color"));
					sleep.sleeping = false;
					sleep.ignoreOffscreenSleep = true;
					
					if(!this.shellApi.checkEvent(this._events.WORM_RETRACTED_ + i))
					{
						this.shellApi.completeEvent(this._events.WORM_RETRACTED_ + i);
						
						switch(i)
						{
							//Already removed in Mouth
							case 1: case 2:
								this.removeEntity(entity);
								break;
							
							//Retract to the right
							case 3: case 6:
								this.retractWorm(entity, true);
								break;
							
							//Retract to the left
							case 4: case 5: case 7: case 8: case 9:
								this.retractWorm(entity, false);
								break;
						}
					}
					else this.removeEntity(entity);
				}
				else
				{
					hasWorms = true;
					
					this.scaleIn(entity.get(Spatial), tween);
				}
			}
			
			if(hasWorms)
			{
				this.getEntityById("doorLungs").add(new Sleep(true, true));
				
				var eatingSound:Entity = new Entity();
				this.addEntity(eatingSound);
				
				var audio:Audio = new Audio();
				eatingSound.add(audio);
				audio.play(SoundManager.EFFECTS_PATH + "worms_eating_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				
				eatingSound.add(new AudioRange(1300));
				eatingSound.add(new Spatial(4300, 1870));
			}
		}
		
		private function handleWormCameraPan():void
		{
			SceneUtil.lockInput(this);
			
			var camera:CameraSystem = this.getSystem(CameraSystem) as CameraSystem;
			camera.target = new Spatial(4260, 1800);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(5, -1, Command.create(handleCameraPlayer, camera)));
		}
		
		private function handleCameraPlayer(camera:CameraSystem):void
		{
			SceneUtil.lockInput(this, false);
			
			camera.target = this.shellApi.player.get(Spatial);
		}
		
		private function retractWorm(worm:Entity, retractRight:Boolean):void
		{
			var tween:Tween = worm.get(Tween);
			var spatial:Spatial = worm.get(Spatial);
			var rotation:Number;
			var object:Object;
			
			if(retractRight)
			{
				rotation = spatial.rotation + 20;
				var x:Number = spatial.x + 1000;
				
				object = { rotation:rotation, x:x, ease:Quad.easeInOut, onComplete:handleWormMoved, onCompleteParams:[worm] };
				tween.to(spatial, 5, object);
			}
			else
			{
				rotation = spatial.rotation - 40;
				x = spatial.x - 1000;
				var y:Number = spatial.y + 1000;
				
				object = { rotation:rotation, x:x, y:y, ease:Quad.easeInOut, onComplete:handleWormMoved, onCompleteParams:[worm] };
				tween.to(spatial, 5, object);
			}
		}
		
		private function handleWormMoved(worm:Entity):void
		{
			this.removeEntity(worm);
		}
		
		private function scaleIn(spatial:Spatial, tween:Tween):void
		{
			tween.to(spatial, Utils.randNumInRange(1, 2), {scaleX:1, ease:Quad.easeInOut, onComplete:scaleOut, onCompleteParams:[spatial, tween]});
		}
		
		private function scaleOut(spatial:Spatial, tween:Tween):void
		{
			tween.to(spatial, Utils.randNumInRange(1, 2), {scaleX:1.1, ease:Quad.easeInOut, onComplete:scaleIn, onCompleteParams:[spatial, tween]});
		}
	}
}