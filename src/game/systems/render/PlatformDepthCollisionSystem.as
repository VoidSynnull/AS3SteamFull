package game.systems.render
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.nodes.render.PlatformDepthColliderNode;
	import game.nodes.render.PlatformDepthCollisionNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class PlatformDepthCollisionSystem extends System
	{
		private var _colliders:NodeList;
		private var _collisions:NodeList;
		private var _containers:Dictionary = new Dictionary();
		
		public function PlatformDepthCollisionSystem()
		{
			this._defaultPriority = SystemPriorities.render;
		}
		
		override public function update(time:Number):void
		{
			for(var colliderNode:PlatformDepthColliderNode = this._colliders.head; colliderNode; colliderNode = colliderNode.next)
			{	
				if(EntityUtils.sleeping(colliderNode.entity))
				{
					continue;
				}
				
				if(!colliderNode.platformDepthCollider.manualDepth)
				{
					if(colliderNode.currentHit)
					{
						colliderNode.platformDepthCollider.depth = 0;
						
						for(var collisionNode:PlatformDepthCollisionNode = this._collisions.head; collisionNode; collisionNode = collisionNode.next)
						{
							if(colliderNode.currentHit.hit == collisionNode.entity)
							{
								break;
							}
						}
						
						if(collisionNode)
						{
							colliderNode.platformDepthCollider.depth = collisionNode.platformDepthCollision.depth;
						}
					}
				}
			}
			
			var container:DisplayObjectContainer = null;
			
			for(var node1:PlatformDepthColliderNode = this._colliders.head; node1; node1 = node1.next)
			{
				container = node1.display.displayObject.parent;
				
				if(node1.platformDepthCollider.depthInvalidated)
				{
					for(var node2:PlatformDepthColliderNode = this._colliders.head; node2; node2 = node2.next)
					{
						if(node1 == node2)
						{
							continue;
						}
						
						if(node2.display.displayObject.parent != container)
						{
							continue;
						}
						
						var index1:int = container.getChildIndex(node1.display.displayObject);
						var index2:int = container.getChildIndex(node2.display.displayObject);
						
						var depth1:Number = node1.platformDepthCollider.depth;
						var depth2:Number = node2.platformDepthCollider.depth;
						
						if(depth1 > depth2)
						{
							if(index1 > index2)
							{
								container.swapChildrenAt(index1, index2);
							}
						}
						else if(depth1 < depth2)
						{
							if(index1 < index2)
							{
								container.swapChildrenAt(index1, index2);
							}
						}
						else
						{
							if(node1.platformDepthCollider.priority != node2.platformDepthCollider.priority)
							{
								if(node1.platformDepthCollider.priority > node2.platformDepthCollider.priority)
								{
									if(index1 < index2)
									{
										container.swapChildrenAt(index1, index2);
									}
								}
								else
								{
									if(index1 > index2)
									{
										container.swapChildrenAt(index1, index2);
									}
								}
							}
						}
					}
					node1.platformDepthCollider.depthInvalidated = false;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			this._colliders = systemManager.getNodeList(PlatformDepthColliderNode);
			this._collisions = systemManager.getNodeList(PlatformDepthCollisionNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(PlatformDepthColliderNode);
			systemManager.releaseNodeList(PlatformDepthCollisionNode);
			
			this._colliders = null;
			this._collisions = null;
			
			super.removeFromEngine(systemManager);
		}
	}
}