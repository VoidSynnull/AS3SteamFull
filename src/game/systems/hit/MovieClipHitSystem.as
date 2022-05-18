package game.systems.hit
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	
	import engine.ShellApi;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.hit.MovieClipHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class MovieClipHitSystem extends GameSystem
	{
		public function MovieClipHitSystem()
		{
			super(MovieClipHitNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.checkCollisions;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			var hitNode:MovieClipHitNode;
			
			for (hitNode = super.nodeList.head; hitNode; hitNode = hitNode.next )
			{	
				hitNode.hit.collider = null;
			}
			
			systemManager.releaseNodeList(MovieClipHitNode);
			
			super.removeFromEngine(systemManager);
		}
		
		/*
		for (var n:Number = 0; n < ships.length; n++)
		{
		nextShip = ships[n];
		
		checkStaticHits(nextShip);
		
		for (var m:Number = n + 1; m < ships.length; m++)
		{
		}*/
		private function updateNode(node:MovieClipHitNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			var hitDisplayObject:DisplayObjectContainer;
			var targetHitDisplayObject:DisplayObjectContainer;
			var hitNode:MovieClipHitNode;

			// TODO : make this loop more efficient...clips don't need to check hits if they've already been checked by others
			for (hitNode = super.nodeList.head; hitNode; hitNode = hitNode.next )
			{				
				if (EntityUtils.sleeping(hitNode.entity) || node == hitNode)
				{
					continue;
				}
								
				if(!node.hit.validHitTypes[hitNode.hit.type])
				{
					continue;
				}
				
				targetHitDisplayObject = node.display.displayObject;
				hitDisplayObject = hitNode.display.displayObject;
				
				if(hitNode.hit.hitDisplay)
				{
					hitDisplayObject = hitNode.hit.hitDisplay;
				}
				
				if(hitNode.hit.pointHit)
				{					
					if (hitDisplayObject.hitTestPoint(_shellApi.offsetX(node.spatial.x), _shellApi.offsetY(node.spatial.y), hitNode.hit.shapeHit))
					{
						hit(hitNode, node);
						return;
					}
				}
				else
				{
					if(node.hit.hitDisplay)
					{
						targetHitDisplayObject = node.hit.hitDisplay;
					}
					
					if (hitDisplayObject.hitTestObject(targetHitDisplayObject))
					{
						hit(hitNode, node);
						return;
					}
				}
			}
		}
		
		private function hit(hitNode:MovieClipHitNode, colliderNode:MovieClipHitNode):void
		{
			colliderNode.hit.isHit = true;
			hitNode.hit.isHit = true;
			
			colliderNode.hit.collider = hitNode.entity;
			hitNode.hit.collider = colliderNode.entity;
			
			var hitId:Id = hitNode.id;
			var colliderId:Id = colliderNode.id;
			var hitList:EntityIdList = hitNode.entityIdList;
			var colliderList:EntityIdList = colliderNode.entityIdList;
			
			if(hitId)
			{
				colliderNode.hit._colliderId = hitId.id;
				if(colliderList && colliderList.entities.indexOf(hitId.id) == -1)
					colliderList.entities.push(hitId.id);
			}
			
			if(colliderId)
			{
				hitNode.hit._colliderId = colliderId.id;
				if(hitList && hitList.entities.indexOf(colliderId.id) == -1)
					hitList.entities.push(colliderId.id);
			}
		}
		
		[Inject]
		public var _shellApi:ShellApi;
	}
}