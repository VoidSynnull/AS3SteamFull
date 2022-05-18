package game.scenes.virusHunter.shipDemo.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	
	import game.components.motion.TargetEntity;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shipDemo.components.SnakeEnemy;
	import game.scenes.virusHunter.shipDemo.nodes.SnakeEnemyNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	public class SnakeEnemySystem extends GameSystem
	{
		public function SnakeEnemySystem(creator:EnemyCreator)
		{
			super(SnakeEnemyNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:SnakeEnemyNode, time:Number):void
		{
			if(node.snake.state == node.snake.INACTIVE)
			{
				//node.entity.remove(MovieClipHit);
				//node.entity.remove(SnakeEnemy);
				_creator.releaseEntity(node.entity, false);
				return;
			}
			
			if(node.snake.state == node.snake.WAITING_TO_DIE)
			{
				node.snake.deathWait -= time;
				
				if(node.snake.deathWait <= 0)
				{
					node.snake.state = node.snake.DIE;
				}
				else
				{
					return;
				}
			}

			if( node.damageTarget.damage >= node.damageTarget.maxDamage )
			{
				node.snake.state = node.snake.DIE;	
			}
			
			if(node.snake.state == node.snake.DIE)
			{
				if(node.snake.next != null)
				{
					var nextSnake:SnakeEnemy = node.snake.next.get(SnakeEnemy);
					
					if(nextSnake)
					{
						nextSnake.state = nextSnake.WAITING_TO_DIE;
					}
				}
				
				_creator.createDelayedEnemyExplosion(node.spatial.x, node.spatial.y, node.entity);
				
				node.enemyGroup.remaining--;
				node.snake.state = node.snake.INACTIVE;
				node.pointValue._redeem = true;
			}
			else if(node.snake.state == node.snake.ATTACK)
			{
				var targetDistance:Number = GeomUtils.spatialDistance(node.spatial, node.entity.get(TargetEntity).target);
				var weaponEntity:Entity = node.entity.get(WeaponSlots).active;
				var weaponControl:WeaponControl = weaponEntity.get(WeaponControl);
				
				if(targetDistance < node.snake.attackDistance)
				{
					weaponControl.fire = true;
				}
				else
				{
					weaponControl.fire = false;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SnakeEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
	}
}

