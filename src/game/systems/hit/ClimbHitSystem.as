package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.ClimbCollisionNode;
	import game.nodes.hit.ClimbBitmapHitNode;
	import game.nodes.hit.ClimbHitNode;
	import game.nodes.hit.WallBitmapHitNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;

	public class ClimbHitSystem extends GameSystem
	{
		public function ClimbHitSystem()
		{
			super(ClimbCollisionNode, updateNode, null, null);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(ClimbHitNode);
			_bitmapHits = systemManager.getNodeList(ClimbBitmapHitNode);
		}
				
		private function updateNode(node:ClimbCollisionNode, time:Number):void
		{
			var motion:Motion = node.motion;
			var hitDisplay:Display;
			var hitNode:ClimbHitNode;
			var bitmapHitNode:ClimbBitmapHitNode
			var offsetY:Number = 0;
			var edge:Edge;
			var bitmapCollider:BitmapCollider = node.bitmapCollider;
						
			if(bitmapCollider != null)
			{
				if(bitmapCollider.centerColor != 0)
				{
					for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
					{
						if(node.validHit != null)
						{
							if(bitmapHitNode.id != null)
							{
								//if(collisionNode.validHit.hitIds[hitNode.id.id] == collisionNode.validHit.inverse)
								if(!node.validHit.hitIds[bitmapHitNode.id.id] && !node.validHit.inverse
									|| node.validHit.hitIds[bitmapHitNode.id.id] && node.validHit.inverse)
								{
									continue;
								}
							}
						}
						if(bitmapCollider.centerColor == bitmapHitNode.bitmapHit.color)
						{
							bitmapHit(node, bitmapHitNode);
							return;
						}
					}
				}
			}
			
			for ( hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{				
				if (!EntityUtils.sleeping(hitNode.entity))
				{
					hitDisplay = hitNode.display;
					
					edge = node.edge;
					
					if(edge != null)
					{
						offsetY = edge.rectangle.bottom;
					}
					
					if(node.validHit != null)
					{
						if(hitNode.id != null)
						{
							//if(collisionNode.validHit.hitIds[hitNode.id.id] == collisionNode.validHit.inverse)
							if(!node.validHit.hitIds[hitNode.id.id] && !node.validHit.inverse
								|| node.validHit.hitIds[hitNode.id.id] && node.validHit.inverse)
							{
								continue;
							}
						}
					}
					
					if (hitDisplay.displayObject.hitTestPoint(_shellApi.offsetX(node.motion.x), (_shellApi.offsetY(node.motion.y) + offsetY), true))
					{
						hit(node, hitNode, hitDisplay);
						return;
					}
				}
			}

			node.collider.isHit = false;
		}
		
		private function hit(node:ClimbCollisionNode, hitNode:*, hitDisplay:Display = null):void
		{
			if( !node.collider.isHit )	// set this only once when first coming contact with Climb hit 
			{
				node.collider.isHit = true;
				
				if(hitDisplay != null)
				{
					node.motion.x = hitDisplay.displayObject.x;
				}
			}
			/*
			var parentMotion:Motion = Entity(hitNode.entity).get(Motion);
			
			if (parentMotion != null)
			{
				node.motion.parentVelocity = parentMotion.velocity;
			}
			*/
			node.currentHit.hit = hitNode.entity;
		}
		
		private function bitmapHit(node:ClimbCollisionNode, hitNode:ClimbBitmapHitNode):void
		{
			if( !node.collider.isHit )	// set this only once when first coming contact with Climb hit 
			{
				node.collider.isHit = true;
			}

			node.currentHit.hit = hitNode.entity;
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ClimbCollisionNode);
			systemManager.releaseNodeList(ClimbHitNode);
			systemManager.releaseNodeList(WallBitmapHitNode);
			_hits = null;
			super.removeFromEngine(systemManager);
		}
		
		private var _bitmapHits:NodeList;
		private var _hits:NodeList;
		[Inject]
		public var _shellApi:ShellApi;
	}
}
