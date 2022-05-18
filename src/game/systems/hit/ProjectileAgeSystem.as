package game.systems.hit
{
	import ash.core.Engine;
	
	import game.components.hit.Projectile;
	import game.creators.motion.ProjectileCreator;
	import game.nodes.hit.ProjectileNode;
	import game.systems.GameSystem;
	
	public class ProjectileAgeSystem extends GameSystem
	{
		public function ProjectileAgeSystem(creator:ProjectileCreator)
		{
			super(ProjectileNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:ProjectileNode, time:Number):void
		{
			var projectile:Projectile = node.projectile;
			
			projectile.lifespan -= time;
			
			if (projectile.lifespan <= 0)
			{
				if(node.spatial.scale <= 0)
				{
					_creator.releaseEntity(node.entity);
				}
				else
				{
					node.spatial.scale -= .1;
				}
			}
			else if(node.projectile.spin != 0)
			{
				node.motion.rotation += node.projectile.spin;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ProjectileNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:ProjectileCreator;
	}
}