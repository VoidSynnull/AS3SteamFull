package game.scenes.virusHunter.brain.systems
{
	import com.greensock.TimelineMax;
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.components.scene.SceneInteraction;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.brain.Brain;
	import game.scenes.virusHunter.brain.components.IKReachBatch;
	import game.scenes.virusHunter.brain.components.NeuronReach;
	import game.scenes.virusHunter.brain.components.TentacleReach;
	import game.scenes.virusHunter.brain.neuron.Neuron;
	import game.scenes.virusHunter.brain.nodes.BrainBossNode;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.nodes.VirusMotionNode;
	import game.util.SceneUtil;
	
	public class BrainBossSystem extends ListIteratingSystem
	{
		public function BrainBossSystem($container:DisplayObjectContainer, $group:Brain)
		{
			_sceneGroup = $group;
			_container = $container;
			super(BrainBossNode, updateNode);
		}
		
		private function updateNode($node:BrainBossNode, $time:Number):void{
			// check for pulsing neuron
			//_node = $node;
			_node = super.nodeList.head;

			if(_node.brainBoss.active){
				if($node.brainBoss.onNeuron.pulsing == true && $node.brainBoss.shocked == false){
					shock();
				}
	
				// update spawn point
				var spawnSpatial:Spatial = Spatial(_node.brainBoss.spawnPoint.get(Spatial));
				spawnSpatial.x = _node.spatial.x;
				spawnSpatial.y = _node.spatial.y;
				
				// init boss if it hasn't already
				if(_init == false){
					init();
				}
				
				// ensure tenticles stay in their "sockets"
				if(_expanded == true){
					var tRight:DisplayObject = _node.display.displayObject["tenticleRight"];
					var tLeft:DisplayObject = _node.display.displayObject["tenticleLeft"];
					var sockets:DisplayObject = _node.display.displayObject["tenticleSockets"];
					
					tRight.x = sockets.x + 24;
					tRight.y = sockets.y;
					
					tLeft.x = sockets.x - 24;
					tLeft.y = sockets.y;
				}
				
				// check for player and attack player if close enough (_attackRadius)
				if(_expanded && !_shocked && !_jumping)
				{
					if(distanceToPlayer() <= _attackRadius && !_attacking)
					{
						//trace("start attack timer");
						SceneUtil.addTimedEvent(_sceneGroup, new TimedEvent(1, 1, attackPlayer));
					} 
					else if(_attacking == true)
					{
						// if player goes beyond distance - reset after a second
						if(distanceToPlayer() > _attackRadius)
						{
							_attacking = false;
							// start reset timer
							SceneUtil.addTimedEvent(_sceneGroup, new TimedEvent(1, 1, resetAttack));
						}
					}
				}
			}
		}
		
		private function init():void
		{
			// run first at the start
			_init = true;
			// check for end of initial intro - then startIdle()
			_node.timeline.handleLabel("idle", beginBattle, true); // listen once
			
			// check for spawnVirus frame events
			_node.timeline.handleLabel("spawnVirus", spawnVirus, false);
			_node.timeline.handleLabel("spawnVirus1", spawnVirus, true); // from intro
			_node.timeline.handleLabel("spawnVirus2", spawnVirus, true); // from intro
			_node.timeline.handleLabel("spawnVirus3", spawnVirus, true); // from intro
			_node.timeline.handleLabel("spawnVirus4", spawnVirus, true); // from intro
			
			_node.timeline.handleLabel("endDeath", removeEntity, true);
			
			// listen for bloodstream entry - to turn off looping events
			
			var backRoomDoor:Entity = _sceneGroup.getEntityById("doorBloodStream");
			SceneInteraction(backRoomDoor.get(SceneInteraction)).reached.add(reachedDoor);
			
			// spawn off screen viruses
			
			_offScreenSpawn = ShipGroup(_sceneGroup.getGroupById("shipGroup")).createOffscreenSpawn(EnemyType.VIRUS, 12, .5, 40, 140, 5);
			_offScreenSpawn.max = 0;
			
		}
				
		private function beginBattle():void
		{
			startIdle();
			SceneUtil.setCameraTarget(_sceneGroup as Scene, _sceneGroup.getEntityById("player"));
			_sceneGroup.playMessage("brain_bossInvuln", false);
		}
		
		private function reachedDoor($interactor:Entity, $interacted:Entity):void{
			// shut down virus loops
			//this.trash();
		}
		
		private function startIdle():void{
			
			
			_expanded = true;
			
			/**
			 * start idle functionality
			 * Move tenticles
			 * spawn viruses every so often
			 */
			/*
			if(_spawnTimer){
				if(!_spawnTimer.running){
					_spawnTimer = new Timer(6000, 1);
					_spawnTimer.addEventListener(TimerEvent.TIMER_COMPLETE, readySpawnVirus);
					_spawnTimer.start();
				}
			} else {
				_spawnTimer = new Timer(6000, 1);
				_spawnTimer.addEventListener(TimerEvent.TIMER_COMPLETE, readySpawnVirus);
				_spawnTimer.start();
			}
			*/
		}
		
		/*private function readySpawnVirus($event:TimerEvent):void
		{
			// need to remove this loop when exiting scene - (it's bugging out in blood stream)
			//_spawnTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, readySpawnVirus);

			_node.timeline.gotoAndPlay("spawn");
			
			// spawn another 6 seconds later (and repeat)
			
			_spawnTimer = new Timer(6000, 1);
			_spawnTimer.addEventListener(TimerEvent.TIMER_COMPLETE, readySpawnVirus);
			_spawnTimer.start();
			
		}*/
		
		private function attackPlayer():void
		{
			_attacking = true;
			
			if(distanceToPlayer() <= _attackRadius && !_shocked && !_jumping){
				//extend tenticles towards player
				TentacleReach(_node.brainBoss.leftTentacle.get(TentacleReach)).reverting = false;
				TentacleReach(_node.brainBoss.rightTentacle.get(TentacleReach)).reverting = false;
	
				TentacleReach(_node.brainBoss.leftTentacle.get(TentacleReach)).reaching = true;
				TentacleReach(_node.brainBoss.rightTentacle.get(TentacleReach)).reaching = true;
			}
		}
		
		private function resetAttack():void
		{
			_attacking = false;
			//retract tentacles
			if(distanceToPlayer() > _attackRadius){
				TentacleReach(_node.brainBoss.leftTentacle.get(TentacleReach)).reaching = false;
				TentacleReach(_node.brainBoss.rightTentacle.get(TentacleReach)).reaching = false;
			}
		}
		
		private function spawnVirus():void{
			
			var radians:Number = (_node.spatial.rotation + 90) * (Math.PI/180);
			
			var spawnPoint:Point = new Point(_node.spatial.x - 230 * Math.cos(radians),_node.spatial.y - 230 * Math.sin(radians));
			
			trace("SPAWN VIRUS") 
			
			var shipGroup:ShipGroup = _sceneGroup.getGroupById("shipGroup") as ShipGroup;
			shipGroup.enemyCreator.create(EnemyType.VIRUS, null, spawnPoint.x, spawnPoint.y, null, null, 0, true, true); // ERROR: Not working if all viruses are destroyed
			
			var audio:Audio = _node.entity.get( Audio );
			if( !audio )
			{
				audio = new Audio();
				_node.entity.add( audio );
			}
			
			audio.play( SoundManager.EFFECTS_PATH + SPAWN_VIRUS, false );
			
			if(_virusToSpawn > 0)
			{
				_virusToSpawn--;
				//_node.timeline.gotoAndPlay("spawn");
				//_node.timeline.gotoAndPlay("spawnVirus");
				_node.timeline.handleLabel("spawnFinished", continueSpawning, true);
			} else {
				// reset timer for virus to spawn viruses again in 15 seconds
				_timer = SceneUtil.addTimedEvent(_sceneGroup, new TimedEvent(15, 1, playSpawnVirusAnimation));
			}
		}
		
		private function shock():void
		{
			_timer.stop();
			_timer = null;
			
			_shocked = true;
			TentacleReach(_node.brainBoss.leftTentacle.get(TentacleReach)).reaching = false;
			TentacleReach(_node.brainBoss.rightTentacle.get(TentacleReach)).reaching = false;
			
			
			var audio:Audio = _node.entity.get(Audio);
			
			if( audio == null )
			{
				audio = new Audio();
				
				_node.entity.add(audio);
			}
			
			audio.play( SoundManager.EFFECTS_PATH + ELECTRIC_ZAP, false, SoundModifier.POSITION );
			// cancel spawn
			//_spawnTimer.stop();
			//_spawnTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, spawnVirus);
			
			/**
			 * Shock and weaken the brain boss.
			 * Brainboss takes damage on initial shock.
			 * Brainboss is weakened and can be striked.
			 * Shock resets all neurons.  
			 * 
			 * After brainboss is weakened for a time, recover and jump to a new neuron
			 */
			
			_timelineMax = new TimelineMax({repeat:-1, yoyo:true});
			_timelineMax.append(new TweenMax(_node.display.displayObject, 0.2, {glowFilter:{color:0xCCFF33, alpha:1, blurX:15, blurY:15, quality:2}, colorMatrixFilter:{contrast:1.7, brightness:2}}));
			_timelineMax.append(new TweenMax(_node.display.displayObject, 0.2, {glowFilter:{color:0xCCFF33, alpha:0, blurX:15, blurY:15, quality:2, remove:true}, colorMatrixFilter:{}}));
			
			// play shock animation and put boss into weakened state
			_node.timeline.gotoAndPlay("shock");
			_node.timeline.handleLabel("weak", endShock);
			_node.timeline.handleLabel("inAir", jump);
			_node.timeline.handleLabel("landFinished", delayedVirusSpawn);
			_node.brainBoss.shocked = true;
			
			// focus camera on boss
			SceneUtil.setCameraTarget(_sceneGroup as Scene, _node.entity);
			
			// stun/destroy all viruses
			var node:VirusMotionNode;
			var nodeList:NodeList = super.systemManager.getNodeList(VirusMotionNode);
			
			for (node = nodeList.head; node; node = node.next)
			{
				node.damageTarget.damage = node.damageTarget.maxDamage; // destroy virus
			}
			
			// recover timer
			if(_node.brainBoss.landingNeurons.length > _node.brainBoss.landIndex)
			{
				SceneUtil.addTimedEvent(_sceneGroup, new TimedEvent(5, 1, recover));
			}
		}
		
		private function recover():void
		{
			// recover
			_node.timeline.gotoAndPlay("revive");
		}
		
		private function delayedVirusSpawn():void
		{
			SceneUtil.addTimedEvent(_sceneGroup, new TimedEvent(1, 1, playSpawnVirusAnimation));
		}
		
		private function continueSpawning():void
		{
			//_node.timeline.gotoAndPlay("spawnVirus");
			_node.timeline.gotoAndPlay("spawn");
		}
		
		private function playSpawnVirusAnimation():void
		{
			//SceneUtil.setCameraTarget(_sceneGroup as Scene, _node.entity);
			_node.timeline.gotoAndPlay("spawn");
			
			//_node.timeline.gotoAndPlay("spawnVirus");
			_virusToSpawn = _totalVirusToSpawn;
			/*
			_node.timeline.handleLabel("spawnVirus1", spawnVirus, true); // from intro
			_node.timeline.handleLabel("spawnVirus2", spawnVirus, true); // from intro
			_node.timeline.handleLabel("spawnVirus3", spawnVirus, true); // from intro
			_node.timeline.handleLabel("spawnVirus4", spawnVirus, true); // from intro
			*/
		}
		
		private function endShock():void{
			// focus back on player
			SceneUtil.setCameraTarget(_sceneGroup as Scene, _sceneGroup.getEntityById("player"));
			
			// reset all neurons
			_timelineMax.clear();
			
			TweenMax.to(_node.display.displayObject, 0.2, {glowFilter:{color:0xCCFF33, alpha:0, blurX:15, blurY:15, quality:2, remove:true}, colorMatrixFilter:{}});
			
			var neurons:IKReachBatch = _sceneGroup.getEntityById("neurons").get(IKReachBatch);
			
			for each( var ikReachEntity:Entity in neurons.ikReachBatch)
			{
				var neuron:NeuronReach = ikReachEntity.get(NeuronReach);
				neuron.reaching = false; // turn off reaching - to reset it
			}
			
			if(_node.brainBoss.landingNeurons.length <= _node.brainBoss.landIndex)
			{
				destroyBoss();
			}
		}
		
		private function jump():void
		{
			_jumping = true;
			//_totalVirusToSpawn += 1;
			
			if(_node.brainBoss.landIndex > 2)
			{
				_offScreenSpawn.max += 1;
			}
			
			//_offScreenSpawn.max += 1;
			
			// target next neuron on list
			
			if(_node.brainBoss.landingNeurons.length > _node.brainBoss.landIndex){
				var nextNeuron:Neuron = _node.brainBoss.landingNeurons[_node.brainBoss.landIndex];
				_node.brainBoss.landIndex++;
				
				_node.brainBoss.onNeuron = nextNeuron;
				
				//as3.x = centerX + radius * cos(angle)
				//as3.y = centerY + radius * sin(angle)
				// jump to next node
				var neuronCRadius:Number = 275; // the distance from the head to the center of the neuron (measured on timeline)
				var nextRot:Number = nextNeuron.display.rotation;
				var nextRadians:Number = nextRot * (Math.PI/180);
				var nextPoint:Point = new Point(nextNeuron.display.x + neuronCRadius * Math.cos(nextRadians), nextNeuron.display.y + neuronCRadius * Math.sin(nextRadians));
				
				
				TweenLite.to(_node.spatial, 2, {x:nextPoint.x, y:nextPoint.y, rotation:nextRot, onComplete:landBoss});
				
				// increase the amount of virus's in the scene
				
			} else {
				// no more neurons to jump on - destroy boss virus
			}
			
		}
		
		private function landBoss():void{
			_shocked = false;
			_jumping = false;
			_node.timeline.gotoAndPlay("land");
			_node.brainBoss.shocked = false;
			
			var audio:Audio = _node.entity.get(Audio);
			
			if( audio == null )
			{
				audio = new Audio();
				
				_node.entity.add(audio);
			}
			
			audio.play( SoundManager.EFFECTS_PATH + LANDING, false, SoundModifier.POSITION );
			
			startIdle();
		}
		
		private function localToLocal(fr:DisplayObject, to:DisplayObject):Point {
			// super awesome useful snippet :)
			return to.globalToLocal(fr.localToGlobal(new Point()));
		}
		
		private function distanceToPlayer():Number{
			var pD:DisplayObject = Display(_sceneGroup.getEntityById("player").get(Display)).displayObject;
			var bD:DisplayObject = _node.display.displayObject;
			
			return Math.sqrt((pD.x - bD.x)*(pD.x - bD.x) + (pD.y - bD.y)*(pD.y - bD.y));
		}
		
		private function destroyBoss():void{
			_offScreenSpawn.max = 0;
			_expanded = false;
			//trash();
			_node.timeline.gotoAndPlay("death");
			var shipGroup:ShipGroup = _sceneGroup.getGroupById("shipGroup") as ShipGroup;
			shipGroup.createWhiteBloodCellSwarm(_node.spatial);
			var audio:Audio = _node.entity.get( Audio );
			if( !audio )
			{
				audio = new Audio();
				_node.entity.add( audio );
			}
			
			audio.play( SoundManager.EFFECTS_PATH + WHITE_BLOOD_CELL_SWARM, false );
		}
		
		private function removeEntity():void{
			_sceneGroup.spawnDevice(_node.spatial);
			_node.display.visible = false;
			var shipGroup:ShipGroup = _sceneGroup.getGroupById("shipGroup") as ShipGroup;
			shipGroup.whiteBloodCellExit();
			// spawn device
		}
		/*
		private function trash():void{
			// kill all events
			if(_spawnTimer){
				_spawnTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, readySpawnVirus);
				_spawnTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, spawnVirus);
				_spawnTimer = null;
			}
			if(_attackTimer){
				_attackTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, resetAttack);
				_attackTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, attackPlayer);
				_attackTimer = null;
			}
		}
		*/
		private var _attackRadius:Number = 360;
		
		//private var _attackTimer:Timer;
		private static const ELECTRIC_ZAP:String = "electric_zap_06.mp3";
		private static const SPAWN_VIRUS:String = "flesh_impact_06.mp3";
		private static const LANDING:String = "small_pow_01.mp3";
		private static const WHITE_BLOOD_CELL_SWARM:String = "consume_virus_L.mp3";
		private var _expanded:Boolean = false;
		private var _init:Boolean = false; // run init first
		private var _shocked:Boolean = false;
		private var _jumping:Boolean = false;
		private var _spawning:Boolean = false;
		private var _attacking:Boolean = false;
		//private var _spawnTimer:Timer;
		private var _node:BrainBossNode;
		private var _sceneGroup:Brain;
		private var _container:DisplayObjectContainer;
		
		private var _timelineMax:TimelineMax;
		
		private var _timer:TimedEvent;
		
		private var _offScreenSpawn:EnemySpawn;
		
		private var _brain:Brain;
		private var _virusToSpawn:int = 0;
		private var _totalVirusToSpawn:int = 3;
	}
}