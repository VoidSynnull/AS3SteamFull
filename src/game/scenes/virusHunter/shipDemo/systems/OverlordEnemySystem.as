package game.scenes.virusHunter.shipDemo.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	
	import game.components.motion.TargetEntity;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shipDemo.nodes.OverlordEnemyNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;

	public class OverlordEnemySystem extends GameSystem
	{
		public function OverlordEnemySystem(creator:EnemyCreator)
		{
			super(OverlordEnemyNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:OverlordEnemyNode, time:Number):void
		{
			if(node.overlord.state == node.overlord.INACTIVE)
			{
				//node.entity.remove(MovieClipHit);
				//node.entity.remove(OverlordEnemy);
				_creator.releaseEntity(node.entity, false);
				return;
			}
			
			if( node.damageTarget.damage >= node.damageTarget.maxDamage )
			{
				node.overlord.state = node.overlord.DIE;
			}
			
			if(node.overlord.state == node.overlord.DIE)
			{
				_creator.createDelayedEnemyExplosion(node.spatial.x, node.spatial.y, node.entity);
				node.overlord.state = node.overlord.INACTIVE;
				node.pointValue._redeem = true;
			}
			
			if(node.entity.get(WeaponSlots))
			{
				var weaponEntity:Entity = node.entity.get(WeaponSlots).active;
				var weaponControl:WeaponControl = weaponEntity.get(WeaponControl);
				
				if(node.overlord.state == node.overlord.ATTACK)
				{
					var targetDistance:Number = GeomUtils.spatialDistance(node.spatial, node.entity.get(TargetEntity).target);
					
					if(targetDistance < node.overlord.attackDistance)
					{
						weaponControl.fire = true;
					}
					else
					{
						weaponControl.fire = false;
					}
				}
				else
				{
					weaponControl.fire = false;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(OverlordEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
	}
}