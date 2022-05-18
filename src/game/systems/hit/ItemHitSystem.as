package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.ItemCollisionNode;
	import game.nodes.hit.ItemHitNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;

	public class ItemHitSystem extends System
	{
		private var _motionNodes : NodeList;
		private var _hits : NodeList;

		public function ItemHitSystem()
		{
			gotItem = new Signal(Entity);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}

		override public function addToEngine( gameSystems : Engine ) : void
		{
			_motionNodes = gameSystems.getNodeList( ItemCollisionNode );
			_hits = gameSystems.getNodeList( ItemHitNode );
		}
		
		override public function update( time : Number ) : void
		{
			var motionNode:ItemCollisionNode;
			var hitNode:ItemHitNode;
			
			for ( motionNode = _motionNodes.head; motionNode; motionNode = motionNode.next )
			{
				for ( hitNode = _hits.head; hitNode; hitNode = hitNode.next )
				{
					if (EntityUtils.sleeping(hitNode.entity) || hitNode.hit.isHit)
					{
						continue;
					}
					
					var deltaX:Number = Math.abs(hitNode.spatial.x - motionNode.spatial.x);
					var deltaY:Number = Math.abs(hitNode.spatial.y - motionNode.spatial.y);
					
					if(deltaX < hitNode.hit.minRangeX && deltaY < hitNode.hit.minRangeY)
					{
						setHit(hitNode);
						return;
					}
				}
			}
		}

		override public function removeFromEngine( gameSystems : Engine ) : void
		{
			gotItem.removeAll();
			gameSystems.releaseNodeList( ItemCollisionNode );
			gameSystems.releaseNodeList( ItemHitNode );
			_motionNodes = null;
			_hits = null;
		}

		private function setHit(node:ItemHitNode):void
		{
			node.hit.isHit = true;
			gotItem.dispatch(node.entity);
			node.entity.group.removeEntity(node.entity);
		}
		
		public var gotItem:Signal;
	}
}
