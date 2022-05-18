package game.scenes.testIsland.zomCatapult.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.testIsland.zomCatapult.ZomCatapult;
	import game.scenes.testIsland.zomCatapult.nodes.ZombieNode;
	
	public class ZombieSystem extends ListIteratingSystem
	{
		public function ZombieSystem()
		{
			super(ZombieNode, onUpdate);
		}
		
		private function onUpdate(node:ZombieNode, time:Number):void
		{
			if(node.spatial.x < 300 && !ZomCatapult(node.entity.group).lost){
				ZomCatapult(node.entity.group).youLose();
			}
			
			/*if(node.zombie.health <= 0){
				removeZombie(node);
			}*/
		
		}
		
		private function removeZombie(node:ZombieNode):void
		{
			ZomCatapult(node.entity.group).zombieCreator.create();
			node.zombie.body.space = null;
			node.entity.group.removeEntity(node.entity);
		}
	}
}