package game.scenes.virusHunter.shipDemo.systems
{
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.virusHunter.shared.components.EnemyGroup;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shipDemo.nodes.SeekerEnemyNode;
	
	public class SeekerEnemySystem extends ListIteratingSystem
	{
		public function SeekerEnemySystem(creator:EnemyCreator)
		{
			super(SeekerEnemyNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:SeekerEnemyNode, time:Number):void
		{
			if(node.seeker.state == node.seeker.INACTIVE)
			{
				//node.entity.remove(MovieClipHit);
				//node.entity.remove(SeekerEnemy);
				_creator.releaseEntity(node.entity, false);
				return;
			}
			
			if(node.seeker.lifetime <= 0)
			{
				node.sleep.ignoreOffscreenSleep = false;
			}

			if( node.damageTarget.damage >= node.damageTarget.maxDamage)
			{
				node.seeker.state = node.seeker.DIE;
			}

			if(node.seeker.state == node.seeker.DIE || node.sleep.sleeping)
			{
				node.seeker.state = node.seeker.INACTIVE;
				
				if(!node.sleep.sleeping) 
				{ 
					node.pointValue._redeem = true; 
					_creator.createDelayedEnemyExplosion(node.spatial.x, node.spatial.y, node.entity);
				}

				var enemyGroup:EnemyGroup = node.entity.get(EnemyGroup);
				
				if(enemyGroup)
				{
					enemyGroup.remaining--;
				}
			}
			else
			{
				node.seeker.lifetime -= time;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SeekerEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
	}
}