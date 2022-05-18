package game.scenes.virusHunter.intestine{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.intestine.components.AcidDrip;
	import game.scenes.virusHunter.intestine.components.IntestineState;
	import game.scenes.virusHunter.intestine.particles.AcidSplash;
	import game.scenes.virusHunter.intestine.systems.AcidDripSystem;
	import game.scenes.virusHunter.intestine.systems.IntestineStateSystem;
	import game.scenes.virusHunter.intestine.systems.IntestineTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Intestine extends ShipScene
	{
		private var _state:IntestineState;
		private var _stateEntity:Entity;
		private var _shipGroup:ShipGroup;
		private var _events:VirusHunterEvents;
		public var virusSpawn:EnemySpawn;
		public var numChunks:uint = 10;
		public var currentChunk:uint = 1;
		
		public function Intestine()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/intestine/";
			
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
			
			this.addSystem(new BitmapSequenceSystem());
			
			setupScene();
			setupVirusZones();
			setupAcid();
			setupFoodChunks();
			setupBlockages();
			setupCramp();
		}
		
		/*********************************************************************************
		 * SHIP SCENE SETUP
		 */
		
		private function setupScene():void
		{
			_state = new IntestineState();
			_stateEntity = new Entity();
			_stateEntity.add(_state);
			this.addEntity(_stateEntity);
			
			_shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(this._hitContainer);
			
			this.addSystem(new IntestineStateSystem(this), SystemPriorities.lowest);
			this.addSystem(new IntestineTargetSystem(this, this._events), SystemPriorities.checkCollisions);
		}
		
		/*********************************************************************************
		 * VIRUS SETUP
		 */
		
		private function setupVirusZones():void
		{
			this.virusSpawn = _shipGroup.createOffscreenSpawn(EnemyType.VIRUS, 0);
			
			for(var i:uint = 1; i <= 3; i++)
			{
				var virusZone:Entity = this.getEntityById("virus" + i + "Zone");
				var zone:Zone = virusZone.get(Zone);
				zone.pointHit = true;
				zone.entered.addOnce(handleZoneEntered);
			}
		}
		
		private function handleZoneEntered(zone:String, ship:String):void
		{
			switch(zone)
			{
				case "virus1Zone":
					_state.state = _state.SPAWN_VIRUS_1;
					this.virusSpawn.max = 2;
					break;
				case "virus2Zone":
					_state.state = _state.SPAWN_VIRUS_2;
					this.virusSpawn.max = 4;
					break;
				case "virus3Zone":
					_state.state = _state.SPAWN_VIRUS_3;
					this.virusSpawn.max = 6;
					break;
			}
		}
		
		/*********************************************************************************
		 * ACID SETUP
		 */
		
		private function setupAcid():void
		{
			this.addSystem(new AcidDripSystem(this), SystemPriorities.lowest);
			var endYs:Array = [500, 575, 1050, 1400, 1450, 1850, 1875, 2300, 2300, 2075, 2200, 2725, 2725, 2725];
			
			for(var i:uint = 1; i <= 14; i++)
			{
				//Create sack entity
				var clip:MovieClip = this._hitContainer["sack" + i];
				var sack:Entity = BitmapTimelineCreator.createBitmapTimeline(clip);
				sack.add(new Id("sack" + i));
				sack.add(new Sleep());
				sack.add(new Audio());
				sack.add(new AudioRange(600, 0.01, 1));
				
				//Add acid entity
				clip = this._hitContainer["acid" + i];
				var sprite:Sprite = this.convertToBitmapSprite(clip).sprite;
				var acid:Entity = EntityUtils.createSpatialEntity(this, sprite);
				acid.get(Display).visible = false;
				acid.add(new Id("acid" + i));
				
				acid.add(new Audio());
				acid.add(new AudioRange(600, 0.01, 1));
				
				//Add particles
				var splash:AcidSplash = new AcidSplash();
				splash.init(acid.get(Spatial).x, endYs[i - 1]);
				var emitter:Entity = EmitterCreator.create(this, this._hitContainer, splash, 0, 0, null, "acidSplash" + i, null, false);
				
				//Add AcidDrip component
				sack.add(new AcidDrip(acid, emitter, endYs[i - 1]));
				
				//Add Hazard and MovieClipHit for damaging the ship
				var target:Hazard = new Hazard();
				target.damage = 0.1;
				target.coolDown = .75;
				acid.add(target);
				
				acid.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
				
				this.addEntity(sack);
			}
		}
		
		/*********************************************************************************
		 * FOOD CHUNK SETUP
		 */
		
		private function setupFoodChunks():void
		{
			/**
			 * This loads twice as many food chunks as numChunks. For every blockage hit, 2 chunks will spawn.
			 * chunk + i && chunk + (i + 10)
			 */
			for(var i:uint = 1; i <= this.numChunks * 2; i++)
				this.loadFile("chunk.swf", onFileLoaded, i);
		}
		
		private function onFileLoaded(clip:MovieClip, i:uint):void
		{
			this._hitContainer.addChild(clip);
			var chunk:Entity = BitmapTimelineCreator.createBitmapTimeline(clip);
			chunk.add(new Id("chunk" + i));
			chunk.add(new Sleep(false, true));
			chunk.add(new Tween());
			
			chunk.get(Display).alpha = 0;
			
			var motion:Motion = new Motion();
			motion.acceleration.y = 600;
			motion.pause = true;
			chunk.add(motion);
			
			this.addEntity(chunk);
		}
		
		/*********************************************************************************
		 * BLOCKAGE SETUP
		 */
		
		private function setupBlockages():void
		{
			for(var i:uint = 1; i <= 8; i++)
			{
				var clip:MovieClip = this._hitContainer["blockage" + i + "Clip"];
				if(this.shellApi.checkEvent(_events.BLOCKAGE_CLEARED_ + i))
				{
					clip.visible = false;
					this.removeEntity(this.getEntityById("blockage" + i));
					this.removeEntity(this.getEntityById("blockage" + i + "Target"));
				}
				else
				{
					var target:DamageTarget = this.getEntityById("blockage" + i + "Target").get(DamageTarget);
					target.hitParticleColor1 = 0xB08F5F;
					target.hitParticleColor2 = 0x55C26B;
					clip.gotoAndStop(1);
				}
			}
		}
		
		/*********************************************************************************
		 * CRAMP SETUP
		 */
		
		private function setupCramp():void
		{
			if(this.shellApi.checkEvent(_events.CRAMP_CURED))
			{
				this._hitContainer["coinClip"].visible = false;
				this.removeEntity(this.getEntityById("coin"));
				this.removeEntity(this.getEntityById("nerve"));
				this.removeEntity(this.getEntityById("nerveTarget"));
				for(var i:uint = 1; i <= 2; i++)
				{
					this._hitContainer["muscle" + i + "Clip"].scaleX = 0.8;
					this._hitContainer["muscle" + i + "Clip"].scaleY = 0.6;
				}
			}
			else SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, handleCramp));
		}
		
		private function handleCramp():void
		{
			/**
			 * There's a crash here related to ShipDialogWindow line 48. A character (Dr. Lange) is null when she should already
			 * be loaded with the shared npcs.xml characters.
			 */
			this.playMessage("intestine_secondary", false, "intestine_secondary");
		}
	}
}