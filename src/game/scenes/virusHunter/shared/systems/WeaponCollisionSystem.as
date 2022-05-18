package game.scenes.virusHunter.shared.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.creators.entity.EmitterCreator;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.Burst;
	import game.scenes.virusHunter.shared.creators.ProjectileCreator;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.nodes.DamageTargetNode;
	import game.scenes.virusHunter.shared.nodes.HazardNode;
	import game.scenes.virusHunter.shared.nodes.MeleeCollisionNode;
	import game.scenes.virusHunter.shared.nodes.ProjectileCollisionNode;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	public class WeaponCollisionSystem extends System
	{
		public function WeaponCollisionSystem(creator:ProjectileCreator)
		{
			_creator = creator; 
		}
		
		override public function update(time:Number):void
		{
			var hitNode:DamageTargetNode;
			var projectileNode:ProjectileCollisionNode;
			var meleeNode:MeleeCollisionNode;
			var hazardNode:HazardNode;
			
			for(projectileNode = _projectileNodes.head; projectileNode; projectileNode = projectileNode.next)
			{
				if(projectileNode.hit.isHit)
				{
					for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
					{
						if (EntityUtils.sleeping(hitNode.entity))
						{
							continue;
						}
						
						if(projectileNode.hit.collider == hitNode.entity)
						{
							if(hitNode.damageTarget.damageFactor == null || hitNode.damageTarget.damageFactor[projectileNode.type.type])
							{
								hitNode.damageTarget.isHit = true;
								hitNode.damageTarget.damage += projectileNode.projectile.damage;
								createBurst(projectileNode.spatial.x, projectileNode.spatial.y, projectileNode.display.container, projectileNode.type.type, hitNode.damageTarget.hitParticleColor1, hitNode.damageTarget.hitParticleColor2);
								playAudio(hitNode.entity, "projectileImpact");
								_creator.releaseEntity(projectileNode.entity);
								break;
							}
							else if(hitNode.damageTarget.reactToInvulnerableWeapons)
							{
								createBurst(projectileNode.spatial.x, projectileNode.spatial.y, projectileNode.display.displayObject.parent, "noEffect");
								playAudio(hitNode.entity, "projectileImpact");
								_creator.releaseEntity(projectileNode.entity);
								break;
							}
						}
					}
				}
			}
			
			for(meleeNode = _meleeNodes.head; meleeNode; meleeNode = meleeNode.next)
			{
				if (EntityUtils.sleeping(meleeNode.entity))
				{
					continue;
				}
				
				meleeNode.melee.timeSinceLastDamageEffect += time;
				
				if(meleeNode.hit.isHit && meleeNode.melee.active)
				{
					for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
					{
						if (EntityUtils.sleeping(hitNode.entity))
						{
							continue;
						}
						
						if(meleeNode.hit.collider == hitNode.entity)
						{
							var offsetPosition:Point;
							
							if((hitNode.damageTarget.damageFactor == null || hitNode.damageTarget.damageFactor[meleeNode.type.type]))
							{
								hitNode.damageTarget.isHit = true;
								hitNode.damageTarget.damage += meleeNode.weapon.damage * time;
								
								if(meleeNode.melee.timeSinceLastDamageEffect >= meleeNode.melee.minimumDamageEffectInterval)
								{
									offsetPosition = GeomUtils.getPointOffsetFromRotation(meleeNode.parent.parent.get(Spatial).x, meleeNode.parent.parent.get(Spatial).y, meleeNode.spatial.rotation, meleeNode.melee.range + Math.random() * -40, 0);
									
									meleeNode.melee.timeSinceLastDamageEffect = 0;
									createBurst(offsetPosition.x, offsetPosition.y, hitNode.display.container, meleeNode.type.type, hitNode.damageTarget.hitParticleColor1, hitNode.damageTarget.hitParticleColor2);
								}
							}
							else
							{
								if(meleeNode.melee.timeSinceLastDamageEffect >= meleeNode.melee.minimumDamageEffectInterval && hitNode.damageTarget.reactToInvulnerableWeapons)
								{
									offsetPosition = GeomUtils.getPointOffsetFromRotation(meleeNode.parent.parent.get(Spatial).x, meleeNode.parent.parent.get(Spatial).y, meleeNode.spatial.rotation, meleeNode.melee.range + Math.random() * -40, 0);
									
									meleeNode.melee.timeSinceLastDamageEffect = 0;
									createBurst(offsetPosition.x, offsetPosition.y, hitNode.display.container, "noEffect");
								}
							}
							
							break;
						}
					}
				}
			}
			
			for(hazardNode = _hazardNodes.head; hazardNode; hazardNode = hazardNode.next)
			{
				if (EntityUtils.sleeping(hazardNode.entity))
				{
					continue;
				}
				
				for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
				{
					if(hitNode.damageTarget.cooldownWait > 0)
					{
						hitNode.damageTarget.cooldownWait -= time;
					}
					
					if(hazardNode.hit.isHit && hazardNode.hazard.damage > 0)
					{
						if (EntityUtils.sleeping(hitNode.entity) || hazardNode.entity == hitNode.entity)
						{
							continue;
						}

						if(hazardNode.hit.collider == hitNode.entity)
						{
							if((hitNode.damageTarget.damageFactor == null || hitNode.damageTarget.damageFactor[hazardNode.hit.type]) && hitNode.damageTarget.cooldownWait <= 0)
							{
								hitNode.damageTarget.isHit = true;
								hitNode.damageTarget.damage += hazardNode.hazard.damage;
								hitNode.damageTarget.lastPointOfImpact = hazardNode.spatial;
								playAudio(hitNode.entity, "enemyImpact");
								createBurst(hitNode.spatial.x, hitNode.spatial.y, hitNode.display.container, "impact");
								
								if(!isNaN(hitNode.damageTarget.cooldown))
								{
									hitNode.damageTarget.cooldownWait = hazardNode.hazard.coolDown;
								}
							}
							
							break;
						}
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			_hits = systemManager.getNodeList(DamageTargetNode);
			_projectileNodes = systemManager.getNodeList(ProjectileCollisionNode);
			_meleeNodes = systemManager.getNodeList(MeleeCollisionNode);
			_hazardNodes = systemManager.getNodeList(HazardNode);
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(DamageTargetNode);
			systemManager.releaseNodeList(ProjectileCollisionNode);
			systemManager.releaseNodeList(MeleeCollisionNode);
			systemManager.releaseNodeList(HazardNode);
			super.removeFromEngine(systemManager);
		}
		
		private function createBurst(x:Number, y:Number, container:DisplayObjectContainer, type:String, color1:uint = 0, color2:uint = 0, velocity = 1):void
		{
			var emitter:Burst = new Burst();

			if(color1 != 0 && color2 != 0)
			{
				emitter.init(velocity, color1, color2);
			}
			else
			{
				switch(type)
				{
					case WeaponType.GUN :
						emitter.init(1.25, 0x33afbf03, 0xffeaef16);
						//emitter.init(1, 0x33330000, 0xffff0000);
					break;
					
					case WeaponType.GOO :
						emitter.init(1.25, 0x33003300, 0xff00ff00);
					break;
					
					case WeaponType.SCALPEL :
						emitter.init(1.25, 0x33afbf03, 0xffeaef16);
						//emitter.init(1.5, 0x33330000, 0xffff0000);
					break;
					
					case WeaponType.SHOCK :
						//emitter.init(1, 0x330000ff, 0xffffffff);
						emitter.init(1, 0x33d1efff, 0xffffffff);
					break;
					
					case "impact" :
						emitter.init(2, 0x33ffcc00, 0xffff6600);
					break;
					
					case WeaponType.ENEMY_GUN :
						emitter.init(2, 0x33ffcc00, 0xffff6600);
					break;
									
					default:
						emitter.init(1, 0xffffffff);
					
				}
			}
			
			var entity:Entity = EmitterCreator.create(super.group, container, emitter);	
			entity.get(Spatial).x = x;
			entity.get(Spatial).y = y;
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			
			entity.add(sleep);
			Emitter(entity.get(Emitter)).remove = true;
		}
		
		private function playAudio(entity:Entity, action:String):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions[action];
				
				if(soundData != null)
				{		
					audio.play(soundData.asset, false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				}
			}
		}
		
		private var _creator:ProjectileCreator;
		private var _hits:NodeList;
		private var _projectileNodes:NodeList;
		private var _meleeNodes:NodeList;
		private var _hazardNodes:NodeList;
	}
}

