package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.SceneCollisionNode;
	import game.nodes.hit.CeilingBitmapHitNode;
	import game.nodes.hit.CeilingHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	public class CeilingHitSystem extends GameSystem
	{
		public function CeilingHitSystem()
		{
			super(SceneCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(CeilingHitNode);
			_bitmapHits = systemManager.getNodeList(CeilingBitmapHitNode);
		}
		
		private function updateNode(node:SceneCollisionNode, time:Number):void
		{
			if(node.climbCollider)
			{
				if(node.climbCollider.isHit)
				{
					return;
				}
			}
			
			var hitNode:CeilingHitNode;
			var bitmapHitNode:CeilingBitmapHitNode;
			var motion:Motion;
			var hitDisplay:Display;
			var bitmapCollider:BitmapCollider = node.bitmapCollider;
			
			motion = node.motion;
			
			if (motion.velocity.y <= 0)
			{
				if(bitmapCollider.color != 0)
				{
					for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
					{
						if(bitmapCollider.color == bitmapHitNode.bitmapHit.color)
						{
							setHit(node, bitmapHitNode);
							return;
						}
					}
				}
				
				for (hitNode = _hits.head; hitNode; hitNode = hitNode.next)
				{
					if (EntityUtils.sleeping(hitNode.entity))
					{
						continue;
					}
					
					hitDisplay = hitNode.display;
					
					if (hitDisplay.displayObject.hitTestObject(node.display.displayObject))
					{
						setHit(node, hitNode);
						break;
					}
				}
			}
		}

		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SceneCollisionNode);
			systemManager.releaseNodeList(CeilingHitNode);
			systemManager.releaseNodeList(CeilingBitmapHitNode);
			_hits = null;
			_bitmapHits = null;
			super.removeFromEngine(systemManager);
		}
		
		private function setHit(collisionNode:SceneCollisionNode, hitNode:*):void
		{
			collisionNode.motion.zeroMotion("y");
			collisionNode.currentHit.hit = hitNode.entity;
			
			if(collisionNode.edge)
			{
				collisionNode.motion.y -= collisionNode.edge.rectangle.top;
			}
		}

		private var _bitmapHits:NodeList;
		private var _hits:NodeList;
	}
}
