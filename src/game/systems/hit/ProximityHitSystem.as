package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.hit.ProximityHitNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.Utils;
	
	public class ProximityHitSystem extends System
	{
		public function ProximityHitSystem()
		{
			super._defaultPriority = SystemPriorities.checkCollisions;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function update(time:Number):void
		{
			var node:ProximityHitNode;
			var colliderNode:ProximityHitNode;
			var distance:Number;
			var deltaX:Number;
			var deltaY:Number;
			var totalWidth:Number;
			var totalHeight:Number;
			var isHit:Boolean = false;
			
			for( node = _nodes.head; node; node = node.next )
			{
				node.hit.isHit = false;
				node.hit.colliderId = null;
			}
			
			for( node = _nodes.head; node; node = node.next )
			{
				if(EntityUtils.sleeping(node.entity))
				{
					continue;
				}
				
				for( colliderNode = node.next; colliderNode; colliderNode = colliderNode.next )
				{
					if(EntityUtils.sleeping(colliderNode.entity))
					{
						continue;
					}
					
					isHit = false;
					
					if(node.hit.hitRange > 0)
					{
						distance = Utils.distance(node.spatial.x, node.spatial.y, colliderNode.spatial.x, colliderNode.spatial.y);

						if(distance < node.hit.hitRange)
						{
							isHit = true;
						}
					}
					else if(node.hit.hitWidth > 0)
					{
						deltaX = Math.abs(node.spatial.x - colliderNode.spatial.x);
						deltaY = Math.abs(node.spatial.y - colliderNode.spatial.y);
						totalWidth = node.hit.hitWidth + colliderNode.hit.hitWidth;
						totalHeight = node.hit.hitHeight + colliderNode.hit.hitHeight;
						
						if(deltaX <= totalWidth && deltaY <= totalHeight)
						{
							isHit = true;
						}
					}
					
					if(isHit)
					{
						node.hit.isHit = colliderNode.hit.isHit = true;
						node.hit.colliderX = colliderNode.spatial.x;
						node.hit.colliderY = colliderNode.spatial.y;
						node.hit.colliderId = colliderNode.id.id;
						node.hit.colliderWidth = colliderNode.hit.hitWidth;
						node.hit.colliderHeight = colliderNode.hit.hitHeight;
						node.hit.colliderEntity = colliderNode.entity;
						colliderNode.hit.colliderX = node.spatial.x;
						colliderNode.hit.colliderY = node.spatial.y;
						colliderNode.hit.colliderId = node.id.id;
						colliderNode.hit.colliderWidth = node.hit.hitWidth;
						colliderNode.hit.colliderHeight = node.hit.hitHeight;
						colliderNode.hit.colliderEntity = node.entity;
					}
				}
			}
		}

		override public function addToEngine( systemsManager:Engine ) : void
		{
			_nodes = systemManager.getNodeList(ProximityHitNode);
		}
		
		override public function removeFromEngine( systemsManager:Engine ) : void
		{
			systemsManager.releaseNodeList(ProximityHitNode);
			_nodes = null;
		}
		
		private var _nodes:NodeList;
	}
}