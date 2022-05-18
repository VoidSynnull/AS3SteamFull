package game.scenes.testIsland.zomCatapult.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.testIsland.zomCatapult.nodes.ProjectileNode;
	
	public class ProjectileSystem extends ListIteratingSystem
	{
		public function ProjectileSystem()
		{
			super(ProjectileNode, onUpdate);
		}
		
		private function onUpdate(node:ProjectileNode, time:Number):void
		{
			if(node.projectile.body.velocity.x <= 50){
				node.projectile.power = 0;
			}
		}
	}
}