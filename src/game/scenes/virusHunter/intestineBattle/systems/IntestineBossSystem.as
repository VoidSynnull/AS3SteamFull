package game.scenes.virusHunter.intestineBattle.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.systems.CameraZoomSystem;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.intestineBattle.components.IntestineBoss;
	import game.scenes.virusHunter.intestineBattle.nodes.IntestineBossNode;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class IntestineBossSystem extends System
	{
		public function IntestineBossSystem(scene:ShipScene, events:VirusHunterEvents)
		{
			_scene = scene;
			_events = events;
		}
		
		override public function update(time:Number):void
		{	
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var boss:IntestineBoss = bossNode.intestineBoss;
			var tentacle:Entity = _scene.getEntityById(IntestineBoss.TENTACLE, bossNode.entity);
			var damageTarget:DamageTarget = tentacle.get(DamageTarget) as DamageTarget;
			var hurtTimeline:Entity;
			
			if(damageTarget)
			{
				if(damageTarget.damage < damageTarget.maxDamage && (boss.state == IntestineBoss.FOLLOW || boss.state == IntestineBoss.STRIKE))
				{
					if(damageTarget.isHit)
					{
						damageTarget.isHit = false;
						tentacle.get(Audio).play(SoundManager.EFFECTS_PATH + "squish_09.mp3");
						
						hurtTimeline = _scene.getEntityById(IntestineBoss.HURT, bossNode.entity);
						
						if(hurtTimeline.get(Sleep).sleeping)
						{
							switchAnimation(IntestineBoss.IDLE, IntestineBoss.HURT);
							addFrameHandler("end", IntestineBoss.HURT, resumeIdle);
						}
						
						Timeline(tentacle.get(Timeline)).gotoAndPlay("hurt");
					}
				}
			}
			
			switch(boss.state)
			{
				case IntestineBoss.INTRO:
					if(!_stateSetup)
					{
						_stateSetup = true;
						
						addFrameHandler("emerge", boss.state, handleEmerged);
					}
				break;
				
				case IntestineBoss.BEGIN:
					_stateSetup = false;
					boss.state = IntestineBoss.IDLE;
					switchAnimation(IntestineBoss.INTRO, IntestineBoss.IDLE);
					SceneUtil.addTimedEvent(_scene, new TimedEvent(1, 1, unlockPlayer));
				break;
				
				case IntestineBoss.IDLE:
					if(!_stateSetup)
					{
						_stateSetup = true;
					}
									
					_stateTime += time;
					
					if(_stateTime > 2)
					{
						_stateTime = 0;
						_stateSetup = false;
						boss.state = IntestineBoss.FOLLOW;
					}
				break;
				
				case IntestineBoss.FOLLOW:
					var spatial:Spatial = tentacle.get(Spatial);
					var yTarget:Number;
					var tween:Tween;
					
					if(!_stateSetup)
					{
						var sleep:Sleep = tentacle.get(Sleep);
						sleep.sleeping = false;
						
						if(Math.random() > .5)
						{
							spatial.scaleY = 1;
							spatial.y = _scene.sceneData.bounds.height;
							yTarget = _scene.sceneData.bounds.height - 160;
						}
						else
						{
							spatial.scaleY = -1;
							spatial.y = 440;
							yTarget = 540;
						}
						
						spatial.x = bossNode.intestineBoss.target.x;
						
						tween = tentacle.get(Tween);
						tween.to(spatial, 1, { y : yTarget });
						
						_stateSetup = true;
					}
					else
					{
						var deltaX:Number = bossNode.intestineBoss.target.x - spatial.x;
					
						spatial.x += deltaX * .035;
					}
					
					_stateTime += time;
					
					var followTime:Number = 2;
					
					if(damageTarget.damage > damageTarget.maxDamage * .5)
					{
						followTime = 1;
					}
					
					if(_stateTime > followTime)
					{
						_stateTime = 0;
						_stateSetup = false;
						boss.state = IntestineBoss.STRIKE;
					}
					break;
				
				case IntestineBoss.STRIKE :
					if(!_stateSetup)
					{
						strike();
						
						_stateSetup = true;
					}
					
					if(damageTarget.damage > damageTarget.maxDamage)
					{
						_stateSetup = false;
						_stateTime = 0;
						tentacle.remove(MovieClipHit);
						tentacle.remove(DamageTarget);
						boss.vulnerableToTarget = true;
						boss.state = IntestineBoss.WEAKENED;
						
						hurtTimeline = _scene.getEntityById(IntestineBoss.HURT, bossNode.entity);
						
						if(hurtTimeline.get(Sleep).sleeping)
						{
							switchAnimation(IntestineBoss.IDLE, IntestineBoss.WEAKENED);
							addFrameHandler("end", IntestineBoss.WEAKENED, switchIdle);
						}
						else
						{
							switchAnimation(IntestineBoss.HURT, IntestineBoss.WEAKENED);
							addFrameHandler("end", IntestineBoss.WEAKENED, switchIdle);
						}
					}
				break;
				
				case IntestineBoss.IDLE_WEAKENED:
					if(!_stateSetup)
					{
						_stateSetup = true;
					}
					
					_stateTime += time;
					
					if(_stateTime > 3)
					{
						//_stateTime = 0;
						//_stateSetup = false;
						boss.state = IntestineBoss.DIE;
						showWBCSwarm();
						switchAnimation(IntestineBoss.IDLE_WEAKENED, IntestineBoss.DIE);
						addFrameHandler("end", IntestineBoss.DIE, bossDead);
					}
				break;
				
				case IntestineBoss.HURT:
					//advanceState(bossNode, IntestineBoss.REVIVE);
				break;
				
				case IntestineBoss.REVIVE:
					//advanceState(bossNode, IntestineBoss.WEAKENED);
				break;
				
				case IntestineBoss.WEAKENED:
					
				break;
				
				case IntestineBoss.DIE:
					//advanceState(bossNode, IntestineBoss.INTRO);
				break;
			}
		}
		
		private function showWBCSwarm():void
		{
			var shipGroup:ShipGroup = super.group.getGroupById("shipGroup") as ShipGroup;
			shipGroup.createWhiteBloodCellSwarm(new Spatial(1540, 450));
		}
		
		private function bossDead():void
		{
			this._scene.shellApi.completeEvent(this._events.INTESTINE_BOSS_DEFEATED);
			this._scene.shellApi.triggerEvent(this._events.BOSS_BATTLE_ENDED);
			
			var shipGroup:ShipGroup = super.group.getGroupById("shipGroup") as ShipGroup;
			shipGroup.whiteBloodCellExit();
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var dieTimeline:Entity = _scene.getEntityById(IntestineBoss.DIE, bossNode.entity);
			dieTimeline.get(Sleep).sleeping = true;
			var sceneExit:Entity = _scene.getEntityById("doorBloodStream");
			Sleep(sceneExit.get(Sleep)).sleeping = false;
			_scene.addSceneItem(WeaponType.SCALPEL, 1500, 580);
		}
		
		private function resumeIdle():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var tentacle:Entity = _scene.getEntityById(IntestineBoss.TENTACLE, bossNode.entity);
			var damageTarget:DamageTarget = tentacle.get(DamageTarget) as DamageTarget;
			
			if(damageTarget != null)
			{
				if(damageTarget.damage < damageTarget.maxDamage)
				{
					switchAnimation(IntestineBoss.HURT, IntestineBoss.IDLE);
				}
			}
		}
		
		private function switchIdle():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			bossNode.intestineBoss.state = IntestineBoss.IDLE_WEAKENED;
			switchAnimation(IntestineBoss.WEAKENED, IntestineBoss.IDLE_WEAKENED);
		}
		
		private function unlockPlayer():void
		{
			_scene.lockControls(false);

			var cameraSystem:CameraSystem = _scene.getSystem(CameraSystem) as CameraSystem;
			cameraSystem.target = _scene.shellApi.player.get(Spatial);
			cameraSystem.rate = .2;
		}
				
		private function retract():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var tentacle:Entity = _scene.getEntityById(IntestineBoss.TENTACLE, bossNode.entity);
			var spatial:Spatial = tentacle.get(Spatial);
			var sleep:Sleep = tentacle.get(Sleep);
			var tween:Tween = tentacle.get(Tween);
			
			if(spatial.scaleY == -1)
			{
				tween.to(spatial, .5, { delay : 1, y : spatial.y - 400, onComplete : hidden });
			}
			else
			{
				tween.to(spatial, .5, { delay : 1, y : spatial.y + 400, onComplete : hidden });
			}
		}
		
		private function strike():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var tentacle:Entity = _scene.getEntityById(IntestineBoss.TENTACLE, bossNode.entity);
			var spatial:Spatial = tentacle.get(Spatial);
			var sleep:Sleep = tentacle.get(Sleep);
			var tween:Tween = tentacle.get(Tween);
	
			if(spatial.scaleY == -1)
			{
				tween.to(spatial, .5, { y : spatial.y + spatial.height * .65, onComplete : retract });
			}
			else
			{
				tween.to(spatial, .5, { y : spatial.y - spatial.height * .65, onComplete : retract });
			}
		}
		
		private function hidden():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var tentacle:Entity = _scene.getEntityById(IntestineBoss.TENTACLE, bossNode.entity);
			var spatial:Spatial = tentacle.get(Spatial);
			var sleep:Sleep = tentacle.get(Sleep);
			var damageTarget:DamageTarget = tentacle.get(DamageTarget) as DamageTarget;
			
			if(!bossNode.intestineBoss.vulnerableToTarget)
			{
				bossNode.intestineBoss.state = IntestineBoss.IDLE;
			}
			
			sleep.sleeping = true;
		}
		
		private function handleEmerged():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var boss:IntestineBoss = bossNode.intestineBoss;

			var cameraZoom:CameraZoomSystem = _scene.getSystem(CameraZoomSystem) as CameraZoomSystem;
			cameraZoom.scaleTarget = 1;
			cameraZoom.scaleRate = .008;
			
			addFrameHandler("end", IntestineBoss.INTRO, begin);
		}
		
		private function begin():void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var boss:IntestineBoss = bossNode.intestineBoss;
			boss.state = IntestineBoss.BEGIN;
		}
		
		private function addFrameHandler(label:String, state:String, handler:Function):void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var timelineEntity:Entity = _scene.getEntityById(state, bossNode.entity);
			var timeline:Timeline = timelineEntity.get(Timeline);
			
			timeline.handleLabel(label, handler);
		}
		
		private function switchAnimation(current:String, next:String):void
		{
			var bossNode:IntestineBossNode = _bossNodes.head as IntestineBossNode;
			var timelineEntity:Entity = _scene.getEntityById(current);
			var sleep:Sleep = timelineEntity.get(Sleep);
			
			sleep.sleeping = true;
			
			timelineEntity = _scene.getEntityById(next, bossNode.entity);
			sleep = timelineEntity.get(Sleep);
			
			sleep.sleeping = false;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_bossNodes = systemManager.getNodeList(IntestineBossNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(IntestineBossNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _scene:ShipScene;
		private var _events:VirusHunterEvents;
		private var _bossNodes:NodeList;
		private var _stateSetup:Boolean = false;
		private var _stateTime:Number = 0;
	}
}