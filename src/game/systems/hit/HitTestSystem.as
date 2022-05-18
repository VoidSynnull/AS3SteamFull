package game.systems.hit
{
	import game.nodes.hit.HitTestNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class HitTestSystem extends GameSystem
	{
		public function HitTestSystem()
		{
			super(HitTestNode, updateNode);
			super._defaultPriority = SystemPriorities.checkCollisions;
		}
		
		public function updateNode(node:HitTestNode, time:Number):void
		{
			var hitId:String;
			
			//Iterate through all of the colliding entities to compare them to our current hitIds.
			for each(hitId in node.entityIdList.entities)
			{
				var index:int = node.hit.hitIds.indexOf(hitId);
				
				/*
				If the hitId already exists in the hitIds Vector, then splice it out.
				Whatever remains in this Vector is not part of the entities Vector,
				and has exited the collision.
				*/
				if(index > -1)
				{
					node.hit.hitIds.splice(index, 1);
				}
				/*
				If the hitId doesn't exist in the hitIds Vector, then this is its first time
				being here, and has entered the collision.
				*/
				else
				{
					node.hit.onEnter.dispatch(node.entity, hitId);
				}
			}
			
			//Anything that hasn't been spliced out wasn't in the entities Vector, so it's not colliding anymore.
			for each(hitId in node.hit.hitIds)
			{
				node.hit.onExit.dispatch(node.entity, hitId);
			}
			
			//Copy the entities Vector to the hitIds Vector. These are the existing collisions.
			node.hit.hitIds.length = 0;
			for each(hitId in node.entityIdList.entities)
			{
				node.hit.hitIds.push(hitId);
			}
			
			//The node is hit if anything is colliding with it.
			node.hit.hit = node.hit.hitIds.length > 0;
		}
	}
}