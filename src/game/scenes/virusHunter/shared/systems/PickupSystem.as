package game.scenes.virusHunter.shared.systems
{
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.group.Scene;
	
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.creators.ShipCreator;
	import game.scenes.virusHunter.shared.data.PickupType;
	import game.scenes.virusHunter.shared.nodes.HazardNode;
	import game.scenes.virusHunter.shared.nodes.PickupNode;
	import game.scenes.virusHunter.shipDemo.nodes.ShooterEnemyNode;
	import game.util.ScreenEffects;
	
	public class PickupSystem extends ListIteratingSystem
	{
		public function PickupSystem(scene:Scene, shipCreator:ShipCreator)
		{
			super(PickupNode, updateNode);
			_scene = scene;
			_shipCreator = shipCreator;
			_screenEffects = new ScreenEffects();
		}
		
		private function updateNode(node:PickupNode, time:Number):void
		{
			if(node.sleep.sleeping && node.pickup.lifetime <= 0)
			{
				_scene.removeEntity(node.entity, true);
			}
			
			node.pickup.lifetime -= time;
			
			if(node.spatial.x > _scene.sceneData.bounds.width)
			{
				node.motion.velocity.x = -Math.abs(node.motion.velocity.x);
			}
			else if(node.spatial.x < _scene.sceneData.bounds.x)
			{
				node.motion.velocity.x = Math.abs(node.motion.velocity.x);
			}
			
			if(node.spatial.y > _scene.sceneData.bounds.height)
			{
				node.motion.velocity.y = -Math.abs(node.motion.velocity.y);
			}
			else if(node.spatial.y < _scene.sceneData.bounds.y)
			{
				node.motion.velocity.y = Math.abs(node.motion.velocity.y);
			}
			
			if(node.hit.isHit)
			{
				var hitEntity:Entity = _scene.getEntityById(node.hit._colliderId);
				var damageTarget:DamageTarget;
				
				switch(node.type.type)
				{
					case PickupType.HEALTH :
						damageTarget = hitEntity.get(DamageTarget);
						damageTarget.damage = 0;
					break;
					
					case PickupType.UPGRADE :
						_shipCreator.changeGunLevel(hitEntity, 1);	
					break;
					
					case PickupType.BOMB :
						var hazardNode:HazardNode;
						var enemyEntity:Entity;

						for(hazardNode = _hazardNodes.head; hazardNode; hazardNode = hazardNode.next)
						{
							enemyEntity = hazardNode.entity;
							damageTarget = enemyEntity.get(DamageTarget);
							damageTarget.damage += 4;
						}
						
						_screenEffects.screenFlash(_scene.overlayContainer, _scene.shellApi.viewportWidth, _scene.shellApi.viewportHeight);
					break;
				}
				
				playAudio(hitEntity);
				
				super.group.removeEntity(node.entity, true);
			}
		}
		
		private function playAudio(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions["pickup"];
				
				if(soundData != null)
				{			
					audio.play(soundData.asset, false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ShooterEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			_hazardNodes = systemManager.getNodeList(HazardNode);
			super.addToEngine(systemManager);
		}
		
		private var _scene:Scene;
		private var _shipCreator:ShipCreator;
		private var _hazardNodes:NodeList;
		private var _screenEffects:ScreenEffects;
	}
}