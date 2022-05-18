package game.scenes.virusHunter.brain{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.timeline.TimelineMaster;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.brain.components.BrainBoss;
	import game.scenes.virusHunter.brain.components.HitPoints;
	import game.scenes.virusHunter.brain.components.IKReachBatch;
	import game.scenes.virusHunter.brain.components.NeuronReach;
	import game.scenes.virusHunter.brain.components.TentacleReach;
	import game.scenes.virusHunter.brain.neuron.Neuron;
	import game.scenes.virusHunter.brain.systems.BrainBossSystem;
	import game.scenes.virusHunter.brain.systems.BrainSceneTargetSystem;
	import game.scenes.virusHunter.brain.systems.NeuronReachSystem;
	import game.scenes.virusHunter.brain.systems.TentacleReachSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.Virus;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.SystemPriorities;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Brain extends ShipScene
	{
		public function Brain()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/brain/";
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
			
			_events = super.events as VirusHunterEvents;
			
			_shipGroup = super.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(super._hitContainer);
			
			initDoor();
			initNeurons();
			if(!super.shellApi.checkEvent(_events.BRAIN_BOSS_DEFEATED)) 
			{ 
				// ready brainZone - upon crossing, init the boss
				var zone:Entity = super.getEntityById("brainZone");
				Zone(zone.get(Zone)).entered.addOnce(zoneEntered);
				
				initViruses();
			}
			else
			{
				super._hitContainer.removeChild(super._hitContainer["boss"]);
				
				if(!super.shellApi.checkEvent(VirusHunterEvents(super.events).GOT_SCALPEL))
				{
					super.addSceneItem(WeaponType.ANTIGRAV, 1860, 1690);
				}
			}
			setupAnimations();
			
			_shipGroup.addSpawn(super.getEntityById("bloodFlowTarget"), EnemyType.RED_BLOOD_CELL, 6, new Point(80, -40), new Point(0, -40), new Point(0, -140), .5);
		}
		
		private function setupAnimations():void
		{
			var clips:Array = ["bloodFlowArt"];
			var entity:Entity;
			var sleep:Sleep;
			
			for(var n:int = 0; n < clips.length; n++)
			{
				entity = TimelineUtils.convertClip(super._hitContainer[clips[n]]["animation"], this);
				entity.add(new Id(clips[n]));
				entity.add(new Spatial(super._hitContainer[clips[n]].x, super._hitContainer[clips[n]].y));
				entity.add(new Id(clips[n]));
				sleep = entity.get(Sleep);
				sleep.useEdgeForBounds = true;
			}
		}
		
		private function initDoor():void{
			// add in dynamic wall
			//var wallEntity:Entity = super.getEntityById("muscleWall");
			//wallEntity.add(new Wall());
			
			// timeline animation
			var timeline:Timeline = new Timeline();
			
			_brainDoor = new Entity()
				.add(new Display(super._hitContainer["muscleArt"]))
				.add(new Spatial())
				.add(timeline)
				.add(new Id("muscleArt"))
				.add(new TimelineMaster());
			
			var timelineClip:TimelineClip = new TimelineClip();
			timelineClip.mc = super._hitContainer["muscleArt"];
			_brainDoor.add(timelineClip);
			
			TimelineUtils.parseMovieClip( timeline, timelineClip.mc );
			timelineClip.mc.gotoAndStop(1);
			timeline.reset();

			// add in hit for nerve - for electrobolt
			super.addSystem(new BrainSceneTargetSystem(super._hitContainer, this), SystemPriorities.autoAnim);
			super.addEntity(_brainDoor);	
		}
		
		private function zoneEntered(zoneId:String, entityId:String):void{
			startGame();
			super.shellApi.triggerEvent( _events.BRAIN_BOSS_STARTED, false );
		}
		
		private function initViruses():void
		{
			super.addSystem(new BrainBossSystem(super._hitContainer, this), SystemPriorities.autoAnim);
			
			var landingNeurons:Vector.<Neuron> = new Vector.<Neuron>;
			landingNeurons.push(_neurons[5]);
			landingNeurons.push(_neurons[11]);
			landingNeurons.push(_neurons[9]);
			landingNeurons.push(_neurons[15]);
			//landingNeurons.push(_neurons[10]);
			
			// create a spawn point for virus's from the "mother" - that follows her
			var spawnPoint:Entity = new Entity()
				.add(new Display())
				.add(new Spatial());
			
			super.addEntity(spawnPoint);
			
			// init boss virus
			// start on neuron "n3"
			_bossVirus = new Entity()
				.add(new Id("bossVirus"))
				.add(new BrainBoss(_neurons[2], landingNeurons, spawnPoint))
				.add(new HitPoints(100))
				.add(new Display(super._hitContainer["boss"]))
				.add(new Spatial(super._hitContainer["boss"].x, super._hitContainer["boss"].y));
			
			//Display(_bossVirus.get(Display)).displayObject.cacheAsBitmap = true;
			
			// timeline animation
			var timeline:Timeline = new Timeline();
			_bossVirus.add(timeline);
			_bossVirus.add(new TimelineMaster());
			
			var timelineClip:TimelineClip = new TimelineClip();
			timelineClip.mc = super._hitContainer["boss"];
			_bossVirus.add(timelineClip);
			
			TimelineUtils.parseMovieClip( timeline, timelineClip.mc );
			timelineClip.mc.gotoAndStop(1);
			//timeline.reset();
			
			var virus:Virus = new Virus();
			var enemySpawn:EnemySpawn = _shipGroup.addSpawn(spawnPoint, EnemyType.VIRUS, 0, new Point(0,0), new Point(0,0), new Point(0,0), 0.5);
			
			_bossVirus.add(enemySpawn);
			
			super.addEntity(_bossVirus);
			
			// setup boss virus tentacles
			super.addSystem(new TentacleReachSystem(super._hitContainer, this), SystemPriorities.autoAnim);
			
			var hazard:Hazard = new Hazard();
			hazard.velocity = new Point(4, 4);
			hazard.damage = 0.2;
			hazard.coolDown = .75;
			
			var hitLeft:MovieClipHit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship");
			hitLeft.hitDisplay = super._hitContainer["clawHitLeft"];
			
			var hitRight:MovieClipHit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship");
			hitRight.hitDisplay = super._hitContainer["clawHitRight"];
			
			var clawHitLeft:Entity = new Entity()
				.add(new Id("leftClaw"))
				.add(new Display(super._hitContainer["clawHitLeft"]))
				.add(new Spatial(super._hitContainer["clawHitLeft"].x , super._hitContainer["clawHitLeft"].y))
				.add(hazard)
				.add(hitLeft);
			
			var clawHitRight:Entity = new Entity()
				.add(new Id("rightClaw"))
				.add(new Display(super._hitContainer["clawHitRight"]))
				.add(new Spatial(super._hitContainer["clawHitRight"].x , super._hitContainer["clawHitRight"].y))
				.add(hazard)
				.add(hitRight);
			
			super.addEntity(clawHitLeft);
			super.addEntity(clawHitRight);

			BrainBoss(_bossVirus.get(BrainBoss)).rightTentacle = new Entity()
				.add(new TentacleReach("ikNode_", Display(_bossVirus.get(Display)).displayObject["tenticleRight"], 30))
				.add(new Display(Display(_bossVirus.get(Display)).displayObject["tenticleRight"]))
				.add(hitRight);
			
			BrainBoss(_bossVirus.get(BrainBoss)).leftTentacle = new Entity()
				.add(new TentacleReach("ikNode_", Display(_bossVirus.get(Display)).displayObject["tenticleLeft"], 30))
				.add(new Display(Display(_bossVirus.get(Display)).displayObject["tenticleLeft"]))
				.add(hitLeft);
			
			IKReachBatch(_ikArmatures.get(IKReachBatch)).tentacleBatch.push(BrainBoss(_bossVirus.get(BrainBoss)).rightTentacle, BrainBoss(_bossVirus.get(BrainBoss)).leftTentacle);
			
			var tentacleReach:TentacleReach = BrainBoss(_bossVirus.get(BrainBoss)).rightTentacle.get(TentacleReach);
			
			tentacleReach.reaching = false;
			tentacleReach.reachPoint = new Point(tentacleReach.display["ikNode_0"].x, tentacleReach.display["ikNode_0"].y);
			tentacleReach.revertPoint = new Point(tentacleReach.display["ikNode_0"].x, tentacleReach.display["ikNode_0"].y);
			tentacleReach.targetEntity = super.getEntityById("player");
			
			tentacleReach = BrainBoss(_bossVirus.get(BrainBoss)).leftTentacle.get(TentacleReach);
			
			tentacleReach.reaching = false;
			tentacleReach.reachPoint = new Point(tentacleReach.display["ikNode_0"].x, tentacleReach.display["ikNode_0"].y);
			tentacleReach.revertPoint = new Point(tentacleReach.display["ikNode_0"].x, tentacleReach.display["ikNode_0"].y);
			tentacleReach.targetEntity = super.getEntityById("player");
			
			super.addEntity(BrainBoss(_bossVirus.get(BrainBoss)).rightTentacle);
			super.addEntity(BrainBoss(_bossVirus.get(BrainBoss)).leftTentacle);
			
			// setup hits for boss - boss is invulnerable to guns -wrb
			/*
			_bossVirus.add(new MovieClipHit(EnemyType.ENEMY_HIT));
			MovieClipHit(_bossVirus.get(MovieClipHit)).shapeHit = true; 
			
			var damageTarget:DamageTarget = new DamageTarget();
			damageTarget.damageFactor = new Dictionary();
			damageTarget.maxDamage = 5;
			damageTarget.damageFactor[WeaponType.GUN] = 1;
			
			_bossVirus.add(damageTarget);
			
			_shipGroup.addDamageFactor(_bossVirus, WeaponType.GUN);
			*/
		}
		
		private function initNeurons():void
		{
			// init NeuronReachSystem
			super.addSystem(new NeuronReachSystem(super._hitContainer, this), SystemPriorities.autoAnim);
			var damageTarget:DamageTarget;
			var hit:MovieClipHit;
			var ikEntity:Entity;
			var neuron:Neuron;
			var sleep:Sleep;
			var timeline:Timeline;
			// wrap all neuron MCs into Neuron
			var ikArmatures:Vector.<Entity> = new Vector.<Entity>;
			for(var c:int = 1; c <= 16; c++){
				neuron = new Neuron(super._hitContainer["n"+c], this);
				
				// pulse first neuron
				if(c == 1){
					neuron.pulse();
				}
				
				_neurons.push(neuron);
				//_neurons[c-1].pulse();
				
				sleep = new Sleep();
				//sleep.useEdgeForBounds = true;
				
				// process neuron into NeuronReach armature
				ikEntity = new Entity()
					.add(sleep)
					.add(new Spatial())
					.add(new NeuronReach("ikNode_", super._hitContainer["n"+c], 31, 0, neuron))
					.add(new Display(super._hitContainer["n"+c]));
				
				hit = new MovieClipHit(EnemyType.ENEMY_HIT,"shipMelee");
				//hit.hitDisplay = super._hitContainer["n"+c];
				hit.hitDisplay = super._hitContainer["n"+c]["ikNode_1"];
				ikEntity.add(hit);
				
				damageTarget = _shipGroup.addDamageFactor(ikEntity, WeaponType.SHOCK);
				damageTarget.reactToInvulnerableWeapons = false;
				
				// add in interactivity for testing
				//var interaction:Interaction = InteractionCreator.addToEntity(ikEntity, [InteractionCreator.DOWN]);
				//interaction.down.add(downClicked);
				
				super.addEntity(ikEntity);
				
				neuron.neuronReach = ikEntity;

				ikArmatures.push(ikEntity);
			}
			
			_ikArmatures = new Entity()
				.add(new Id("neurons"))
				.add(new IKReachBatch(ikArmatures));
			
			super.addEntity(_ikArmatures);
		}
		
		private function startGame():void
		{
			// focus on boss and start boss logic
			SceneUtil.setCameraTarget(this, _bossVirus); // zoom in on boss virus first	
			BrainBoss(_bossVirus.get(BrainBoss)).active = true; // "turn on" boss virus
			Timeline(_bossVirus.get(Timeline)).reset();
		}
				
		private function downClicked($entity:Entity):void{
			if(!NeuronReach($entity.get(NeuronReach)).reaching){
				/**
				 * BELOW IS DEPRECIATED
				 * Important - But necessary to include these in the new events when they are ready (electrobolt)
				 * So don't forget to carry them over :)
				 */
				NeuronReach($entity.get(NeuronReach)).targetEntity = super.getEntityById("player");
				NeuronReach($entity.get(NeuronReach)).reverting = false;
				NeuronReach($entity.get(NeuronReach)).reachPoint = new Point(NeuronReach($entity.get(NeuronReach)).display["ikNode_1"].x, NeuronReach($entity.get(NeuronReach)).display["ikNode_1"].y);
				NeuronReach($entity.get(NeuronReach)).reaching = true;
				NeuronReach($entity.get(NeuronReach)).connectedToPoint = null;
				NeuronReach($entity.get(NeuronReach)).pauseMotion = false;
				NeuronReach($entity.get(NeuronReach)).connectedTo = null;
			} else {
				NeuronReach($entity.get(NeuronReach)).reaching = false;
				/*
				// sever all pulse links
				if(NeuronReach($entity.get(NeuronReach)).connectedTo){
				var connectedNeuron:Neuron = NeuronReach($entity.get(NeuronReach)).connectedTo.neuron;
				
				while(connectedNeuron != null){
				connectedNeuron.pulsing = false;
				connectedNeuron = connectedNeuron.connectedNeuron; // next connected Neuron
				}
				}
				
				NeuronReach($entity.get(NeuronReach)).connectedTo = null;
				NeuronReach($entity.get(NeuronReach)).neuron.connectedNeuron = null;
				NeuronReach($entity.get(NeuronReach)).reaching = false;
				*/
			}
		}
				
		public function spawnDevice($spatial:Spatial):void{
			trace("Spawn DEVICE!");
			$spatial = super.shellApi.player.get(Spatial);
			super.addSceneItem(WeaponType.ANTIGRAV, $spatial.x, $spatial.y);
			super.shellApi.triggerEvent( _events.BRAIN_BOSS_DEFEATED, true );
		}
		
		private var _brainDoor:Entity;
		private var _events:VirusHunterEvents;
		private var _brainDoorNerve:Entity;
		private var _bossVirus:Entity;
		private var _pulseFreq:Number = 1.0; // how many pulses a neuron has in average over 1 second.
		private var _neurons:Vector.<Neuron> = new Vector.<Neuron>;
		private var _ikArmatures:Entity;
		private var _shipGroup:ShipGroup;
		
	}
}