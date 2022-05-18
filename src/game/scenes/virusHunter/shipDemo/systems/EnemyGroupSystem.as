package game.scenes.virusHunter.shipDemo.systems
{
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.virusHunter.shared.components.EnemyGroup;
	import game.scenes.virusHunter.shared.creators.PickupCreator;
	import game.scenes.virusHunter.shipDemo.nodes.EnemyGroupNode;
	import game.scenes.virusHunter.shipDemo.nodes.ShooterEnemyNode;
	
	public class EnemyGroupSystem extends ListIteratingSystem
	{
		public function EnemyGroupSystem(creator:PickupCreator)
		{
			super(EnemyGroupNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:EnemyGroupNode, time:Number):void
		{
			if(node.enemyGroup.remaining == 0)
			{
				if(node.enemyGroup.spawnPickup != null)
				{
					_creator.create(node.spatial.x, node.spatial.y, node.enemyGroup.spawnPickup);
					node.enemyGroup.spawnPickup = null;
				}
			}
			
			if(node.sleep.sleeping)
			{
				node.entity.remove(EnemyGroup);
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ShooterEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:PickupCreator;
	}
}