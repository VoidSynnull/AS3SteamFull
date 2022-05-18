package game.scenes.backlot.cityDestroy.systems
{
	import engine.components.Spatial;
	
	import game.scenes.backlot.cityDestroy.nodes.HealthNode;
	import game.systems.GameSystem;
	
	public class HealthSystem extends GameSystem
	{
		public function HealthSystem()
		{
			super(HealthNode, updateNode);
		}
		
		public function updateNode(node:HealthNode, time:Number):void
		{
			if(node.health.health > 0)
				node.health.dead = false;
			
			if(node.health.dead)
				return;
			
			if(node.health.health <= 0)
			{
				node.health.died.dispatch();
				node.health.health = 0;
				node.health.dead = true;
			}
			
			if(node.health.healthBar != null)
			{
				var healthBar:Spatial = node.health.healthBar.get(Spatial);
				
				if(node.health.horizontal)
					healthBar.scaleX = node.health.health / node.health.maxHealth * node.health.healthScale.x;
				else
					healthBar.scaleY = node.health.health / node.health.maxHealth * node.health.healthScale.y;
			}
		}
	}
}