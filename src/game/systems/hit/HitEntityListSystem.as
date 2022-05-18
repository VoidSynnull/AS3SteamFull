package game.systems.hit
{
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.hit.CurrentHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class HitEntityListSystem extends GameSystem
	{
		public function HitEntityListSystem()
		{
			super(CurrentHitNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.checkCollisions;
		}
		
		private function updateNode(node:CurrentHitNode, time:Number):void
		{
			if(node.currentHit.hit != null)
			{
				var entityIdList:EntityIdList = node.currentHit.hit.get(EntityIdList);
				
				if(entityIdList != null)
				{
					var id:String;
					
					if(node.id != null)
					{
						id = node.id.id;
					}
					else
					{
						id = node.entity.name;
					}
					
					if(entityIdList.entities.indexOf(id) < 0)
					{
						entityIdList.entities.push(id);
					}
				}
			}
		}
	}
}