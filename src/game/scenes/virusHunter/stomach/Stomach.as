package game.scenes.virusHunter.stomach{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.motion.WaveMotion;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.WaterSplash;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.stomach.components.Food;
	import game.scenes.virusHunter.stomach.components.StomachState;
	import game.scenes.virusHunter.stomach.cutscenes.DrinkCutScene;
	import game.scenes.virusHunter.stomach.particles.StomachAcid;
	import game.scenes.virusHunter.stomach.particles.StomachDrink;
	import game.scenes.virusHunter.stomach.systems.DrinkSystem;
	import game.scenes.virusHunter.stomach.systems.FoodSystem;
	import game.scenes.virusHunter.stomach.systems.StomachStateSystem;
	import game.scenes.virusHunter.stomach.systems.StomachTargetSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Steady;
	
	public class Stomach extends ShipScene
	{
		private var _state:StomachState;
		private var _stateEntity:Entity;
		private var shipGroup:ShipGroup;
		private var _interactiveContainer:DisplayObjectContainer;
		private var _events:VirusHunterEvents;
		
		public var virusSpawn:EnemySpawn;
		public var acid:Entity;
		public var numChunks:uint = 15;
		public var mouth:Entity;
		public var intestine:Entity;
		
		public function Stomach()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/stomach/";
			
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
			super.shellApi.player.add(killCount);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = this.events as VirusHunterEvents;
			
			this.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			this.addSystem(new BitmapSequenceSystem());
			
			setupPopup();
			setupScene();
			setupVirusZone();
			setupStomachAcid();
			setupMuscles();
			setupEatingAndDrinking();
			setupUlcer();
		}
		
		private function setupPopup():void
		{
			if(this.shellApi.checkEvent(this._events.SPLINTER_REMOVED))
			{
				if(this.shellApi.checkEvent(this._events.DRINK_CUTSCENE_PLAYED)) return;
				
				this.shellApi.completeEvent(this._events.DRINK_CUTSCENE_PLAYED);
				
				SceneUtil.addTimedEvent(this, new TimedEvent(3, -1, handlePopup));
			}
		}
		
		private function handlePopup():void
		{
			var cutscene:DrinkCutScene = new DrinkCutScene(this.overlayContainer);
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
			_state = new StomachState();
			_stateEntity = new Entity();
			_stateEntity.add(_state);
			this.addEntity(_stateEntity);
			
			shipGroup = this.getGroupById("shipGroup") as ShipGroup;
			shipGroup.createSceneWeaponTargets(this._hitContainer);
			
			this.addSystem(new StomachStateSystem(this, this._events), SystemPriorities.lowest);
			this.addSystem(new StomachTargetSystem(this, this._events), SystemPriorities.checkCollisions);
		}
		
		private function setupVirusZone():void
		{
			if(!this.shellApi.checkEvent(this._events.SPLINTER_REMOVED))
			{
				if(this.shellApi.checkEvent(this._events.SPLINTER_CUTSCENE_PLAYED)) return;
				
				this.virusSpawn = shipGroup.createOffscreenSpawn(EnemyType.VIRUS, 0);
				
				var virusZone:Entity = this.getEntityById("virusZone");
				var zone:Zone = virusZone.get(Zone);
				zone.entered.addOnce(handleZoneEntered);
			}
		}
		
		private function handleZoneEntered(zone:String, ship:String):void
		{
			this.playMessage("virus_attack", false);
			_state.state = _state.SPAWN_VIRUS;
			this.virusSpawn.max = 6;
		}
		
		private function setupStomachAcid():void
		{
			var bool:Boolean = this.shellApi.checkEvent(this._events.SPLINTER_REMOVED);
			
			var stomachAcid:StomachAcid = new StomachAcid();
			if(!bool) stomachAcid.init(1930, 2300, 0x66B4F075, 1600);
			else stomachAcid.init(2240, 1340, 0xDD7C307C, 2050);
			this.acid = EmitterCreator.create(this, this._hitContainer, stomachAcid, 0, 0, null, "acid", null, false);
			
			var sound:Entity = new Entity();
			this.addEntity(sound);
			
			if(!bool) sound.add(new Spatial(1930, 2300));
			else sound.add(new Spatial(1800, 1340)); //2240
			sound.add(new Audio());
			sound.add(new AudioRange(1200, 0.01));
			sound.add(new Id("acidSound"));
			
			var clip:MovieClip;
			if(!bool)
			{
				clip = this._hitContainer["foodAcid"];
				this._hitContainer["drinkAcid"].visible = false;
			}
			else
			{
				clip = this._hitContainer["drinkAcid"];
				this._hitContainer["foodAcid"].visible = false;
			}
			var sprite:Sprite = this.convertToBitmapSprite(clip).sprite;
			DisplayUtils.moveToTop(sprite);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
			entity.add(new SpatialAddition());
			
			var wave:WaveMotion = new WaveMotion();
			var waveData:WaveMotionData = new WaveMotionData();
			waveData.property = "y";
			if(!bool) waveData.magnitude = 4;
			else waveData.magnitude = 8;
			waveData.rate = 0.075;
			wave.data.push(waveData);
			entity.add(wave);
			
			if(this.shellApi.checkEvent(this._events.GOT_SHIELD))
				this.removeEntity(this.getEntityById("shieldBarrier"));
			else
			{
				entity.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
				
				var hazard:Hazard = new Hazard();
				hazard.damage = 0.2;
				hazard.coolDown = 1;
				entity.add(hazard);
			}
		}
		
		private function setupUlcer():void
		{
			var ulcer:Entity = TimelineUtils.convertClip(this._hitContainer["ulcerClip"]["animation"], this);
			ulcer.add(new Id("ulcerArt"));
			
			if(this.shellApi.checkEvent(_events.ULCER_CURED))
			{
				ulcer.get(Timeline).gotoAndStop("end");
				this.removeEntity(this.getEntityById("ulcer"));
			}
			else
			{
				ulcer.add(new Audio());
				
				if(this.shellApi.checkEvent(this._events.SPLINTER_REMOVED))
					SceneUtil.addTimedEvent(this, new TimedEvent(3, -1, handleUlcer));
				
				shipGroup.addSpawn(this.getEntityById("ulcerTarget"), EnemyType.RED_BLOOD_CELL, 15, new Point(40, 40), new Point(-100, -100), new Point(100, 100), 0.25);
			}
		}
		
		private function handleGush(ulcer:Entity):void
		{
			if(Math.random() < 0.005)
			{
				var audio:Audio = ulcer.get(Audio);
				audio.play(SoundManager.EFFECTS_PATH + "gush_01.mp3", SoundModifier.POSITION);
			}
		}
		
		private function handleUlcer():void
		{
			this.playMessage("stomach_secondary", false);
		}
		
		private function setupEatingAndDrinking():void
		{
			if(!this.shellApi.checkEvent(this._events.SPLINTER_REMOVED))
			{
				this.addSystem(new FoodSystem(this, this._events, acid), SystemPriorities.lowest);
				
				var container:MovieClip = this._hitContainer["foodContainer"];
				var display:DisplayObjectContainer = Display(this.shellApi.player.get(Display)).displayObject;
				var index:int = this._hitContainer.getChildIndex(display);
				this._hitContainer.setChildIndex(container, index + 1);
				container.mask = this._hitContainer["chunkMask"];
				
				for(var i:uint = 1; i <= this.numChunks; i++)
					this.loadFile("chunk.swf", onFileLoaded, i);
			}
			else
			{
				var stomachDrink:StomachDrink = new StomachDrink();
				stomachDrink.init(840, 0);
				var drink:Entity = EmitterCreator.create(this, this._hitContainer, stomachDrink, 0, 0, null, "drink", null, false);
				Display(drink.get(Display)).moveToFront();
				Emitter(drink.get(Emitter)).start = false;
				
				Steady(Emitter(acid.get(Emitter)).emitter.counter).rate = 200;
				
				this.addSystem(new DrinkSystem(this, this._events, acid, drink), SystemPriorities.lowest);
			}
		}
		
		private function onFileLoaded(clip:MovieClip, i:uint):void
		{
			this._hitContainer["foodContainer"].addChild(clip);
			var chunk:Entity = BitmapTimelineCreator.createBitmapTimeline(clip);
			chunk.add(new Id("chunk" + i));
			chunk.add(new Sleep(false, true));
			
			chunk.add(new Audio());
			chunk.add(new AudioRange(800, 0.01, 1));
			Timeline(chunk.get(Timeline)).gotoAndStop(3);
			
			var splash:WaterSplash = new WaterSplash();
			splash.init(0.5, 0x66B4F075);
			var emitter:Entity = EmitterCreator.create(this, this._hitContainer["foodAcid"], splash, 0, 0, chunk, "splash" + i, chunk.get(Spatial), false);
			
			chunk.get(Display).alpha = 0;
			var motion:Motion = new Motion();
			motion.friction = new Point();
			motion.pause = true;
			chunk.add(motion);
			
			chunk.add(new Food(emitter.get(Emitter)));
			
			this.addEntity(chunk);
		}
		
		private function setupMuscles():void
		{
			var entity:Entity;
			
			for(var i:uint = 1; i <= 2; i++)
			{
				entity = EntityUtils.createSpatialEntity(this, this._hitContainer["muscle" + i + "Clip"]);
				entity.add(new Sleep(false, true));
				entity.add(new Audio());
				entity.add(new AudioRange(800));
				this._hitContainer.setChildIndex(this._hitContainer["muscle" + i + "Clip"], this._hitContainer.numChildren - 1);
				TimelineUtils.convertClip(this._hitContainer["muscle" + i + "Clip"], this, entity);
				
				entity.get(Timeline).gotoAndStop("open");
				switch(i)
				{
					case 1: this.mouth = entity; 		break;
					case 2: this.intestine = entity; 	break;
				}
			}
			
			this.getEntityById("doorMouth").add(new Sleep(true, true));
			this.getEntityById("doorIntestine").add(new Sleep(true, true));
		}
	}
}