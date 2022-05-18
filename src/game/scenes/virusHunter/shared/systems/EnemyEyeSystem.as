package game.scenes.virusHunter.shared.systems
{
	import ash.core.Engine;
	
	import game.scenes.virusHunter.shared.nodes.EnemyEyeNode;
	import game.systems.GameSystem;
	
	public class EnemyEyeSystem extends GameSystem
	{
		public function EnemyEyeSystem()
		{
			super(EnemyEyeNode, updateNode);
		}
		
		private function updateNode(node:EnemyEyeNode, time:Number):void
		{
			if(node.display.container)
			{
				var ratio:Number = (node.damageTarget.maxDamage - node.damageTarget.damage) / node.damageTarget.maxDamage;
				node.display.container["back"].alpha = ratio;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(EnemyEyeNode);
			super.removeFromEngine(systemManager);
		}
	}
}