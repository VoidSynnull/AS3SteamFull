package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.SceneObjectCollisionCircleNode;
	import game.nodes.hit.SceneObjectHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;

	/**
	 * Hit detection system for spherical colliders against circular scene objects.
	 * 
	 */
	public class SceneObjectHitCircleSystem extends GameSystem
	{
		public function SceneObjectHitCircleSystem()
		{
			super(SceneObjectCollisionCircleNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.checkCollisions;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(SceneObjectHitNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SceneObjectHitNode);
			_hits = null;
			super.removeFromEngine(systemManager);
		}
				
		public function updateNode(node:SceneObjectCollisionCircleNode, time:Number):void
		{
			var hitNode:SceneObjectHitNode;
			
			// if we are colliding with the scene, don't try and check for hits
			//   against other scene objects to prevent pushing through walls.
			if(node.radialCollider != null && node.radialCollider.isHit)
			{
				return;
			}
			
			for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				if(hitNode.hit.active && hitNode.entity != node.entity)
				{
					if(checkHit(node, hitNode))
					{
						node.sceneObjectCollider.isHit = true;
						hit(node, hitNode);
						updateHitList(node, hitNode);
					} 
					else 
					{
						node.sceneObjectCollider.isHit = false;
					}
				}
			}
		}

		/**
		 * Determine if collider and hit entity have intersected, assumes both collider & hit are circular.
		 * @param node
		 * @param hitNode
		 * @return 
		 */
		private function checkHit(node:SceneObjectCollisionCircleNode, hitNode:SceneObjectHitNode):Boolean
		{
			// get component bearing hit Entity's posiion
			var hitPosition:* = getHitPosition(hitNode);
			
			// determine minimum distance between collider and hit before they would intersect
			var minDistBetween:Number = 0
			if(node.edge)
			{
				minDistBetween = node.edge.rectangle.right;
			}
			
			if(hitNode.edge)
			{
				minDistBetween += hitNode.edge.rectangle.right;
			}
			
			// collision is true if distance between collider and hit is less their combined bounds
			return (GeomUtils.dist(node.motion.x, node.motion.y, hitPosition.x, hitPosition.y) < minDistBetween);
		}
		
		/**
		 * Returns appropriate Component that holds current position of hit Entity.
		 * @param hitNode
		 * @return - either Motion of Spatial, in that priority
		 */
		private function getHitPosition(hitNode:SceneObjectHitNode):*
		{
			var hitPosition:*;
			
			if(hitNode.motion)
			{
				hitPosition = hitNode.motion;
			}
			else
			{
				hitPosition = hitNode.spatial;
			}
			
			return(hitPosition);
		}
		
		/**
		 * Manage hit between circular collider and hit.
		 * Determines velocity to apply to both, to resolve collision.
		 * @param node
		 * @param hitNode
		 * 
		 */
		private function hit(node:SceneObjectCollisionCircleNode, hitNode:SceneObjectHitNode):void
		{
			var motion:Motion = node.motion;
			var offset:Number = 0;
			var hitOffset:Number = 0;
			var hitPosition:* = getHitPosition(hitNode);
			var isHit:Boolean = false;
			
			if(node.edge)
			{
				offset = node.edge.rectangle.right;
			}
			
			if(hitNode.edge)
			{
				hitOffset = hitNode.edge.rectangle.right;
			}
			
			var minDistance:Number = offset + hitOffset;				// minimum distance between collider & hit to not intersect
			var dx:Number = hitPosition.x - motion.x;
			var dy:Number = hitPosition.y - motion.y;
			var angle:Number = Math.atan2(dy, dx);						// angle between collider & hit
			var cosine:Number = Math.cos(angle);
			var sine:Number = Math.sin(angle);
			var tx:Number = motion.x + cosine * minDistance;	// minimum position for collider to not intersect hit
			var ty:Number = motion.y + sine * minDistance;
			var minVelocityX:Number = 0;
			var minVelocityY:Number = 0;
			var collisionSpring:Number = SPRING_COLLISION;
			var ax:Number = (tx - hitPosition.x) * collisionSpring;
			var ay:Number = (ty - hitPosition.y) * collisionSpring;
			var factor1:Number = 1;
			var factor2:Number = 1;

			if(node.mass != null && hitNode.mass != null)
			{
				factor1 = hitNode.mass.mass;
				factor2 = node.mass.mass;
			}
			
			// seperate collider and hit from each other
			motion.x -= ax;
			motion.y -= ay;
			hitPosition.x += ax;
			hitPosition.y += ay;
			
			// velocity applied to collider determined by distance of reposition and mass factor
			motion.velocity.x -= ax * factor1;
			motion.velocity.y -= ay * factor1;
			
			// velocity applied to hit (if has Motion) determined by distance of reposition and mass factor 
			// minImpulseVelocity allows for a minimum velocity to always be applied to hit when colliding
			if(hitNode.motion)
			{
				if(hitNode.hit.minImpulseVelocity != 0)
				{
					minVelocityX = cosine * hitNode.hit.minImpulseVelocity;
					minVelocityY = sine * hitNode.hit.minImpulseVelocity;
				}
				
				hitNode.motion.velocity.x += minVelocityX + ax * factor2;
				hitNode.motion.velocity.y += minVelocityY + ay * factor2;
			}
			
			if( node.wallCollider && hitNode.hit.triggerPush )	
			{ 
				node.wallCollider.isHit = node.wallCollider.isPushing = true;
				node.wallCollider.direction = node.motion.velocity.x;
			}
		}
		
		private function updateHitList(collisionNode:SceneObjectCollisionCircleNode, hitNode:SceneObjectHitNode):void
		{
			var hits:EntityIdList = hitNode.hits;
			
			if(hits != null)
			{
				var id:String;
				
				if(collisionNode.id)
				{
					id = collisionNode.id.id;
				}
				else
				{
					id = collisionNode.entity.name;
				}
				
				if(hits.entities.indexOf(id) < 0)
				{
					hits.entities.push(id);
				}
			}
		}
		
		private const SPRING_COLLISION:Number = .7;
		private var _hits:NodeList;
	}
}