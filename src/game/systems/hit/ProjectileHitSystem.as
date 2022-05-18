package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.creators.motion.ProjectileCreator;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.hit.ProjectileCollisionNode;
	import game.nodes.hit.ProjectileHitNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	
	public class ProjectileHitSystem extends GameSystem
	{
		public function ProjectileHitSystem(creator:ProjectileCreator)
		{
			super(ProjectileCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			_creator = creator;
		}
		
		private function updateNode(node:ProjectileCollisionNode, time:Number):void
		{
			var isHit:Boolean = false;
			
			node.collider.hits.length = 0;
			
			for (var hitNode:ProjectileHitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				if (EntityUtils.sleeping(hitNode.entity))
				{
					continue;
				}
				
				if(MotionUtils.checkOverlap(node, hitNode))
				{
					isHit = true;
					node.collider.hits.push(hitNode.id.id);
					
					if(hitNode.projectile.removeOnHit)
					{
						_creator.releaseEntity(hitNode.entity);
					}
				}
			}
			
			node.collider.isHit = isHit;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_hits = systemManager.getNodeList(ProjectileHitNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			_hits = null;
			
			systemManager.releaseNodeList(ProjectileHitNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private var _hits:NodeList;
		private var _creator:ProjectileCreator;
	}
}