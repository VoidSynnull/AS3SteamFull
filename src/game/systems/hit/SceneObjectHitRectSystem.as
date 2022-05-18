package game.systems.hit
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Motion;
	
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.data.sound.SoundAction;
	import game.nodes.entity.collider.SceneObjectCollisionRectNode;
	import game.nodes.hit.SceneObjectHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	/**
	 * Hit detection system for rectangular colliders against rectangular scene objects.
	 * 
	 */
	public class SceneObjectHitRectSystem extends GameSystem
	{
		public function SceneObjectHitRectSystem()
		{
			super(SceneObjectCollisionRectNode, updateNode);
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
				
		public function updateNode(node:SceneObjectCollisionRectNode, time:Number):void
		{
			// if we are colliding with the scene, don't try and check for hits
			//   against other scene objects to prevent pushing through walls.
			if(node.radialCollider != null && node.radialCollider.isHit)
			{
				return;
			}
			
			checkForHits(node);
		}
		
		private function checkForHits(node:SceneObjectCollisionRectNode):void
		{
			var hitNode:SceneObjectHitNode;
			var isPushing:Boolean = false;
			
			for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				// make sure nodes are not testing aginst themselves
				if( node.entity == hitNode.entity )
				{
					continue;
				}
				
				if(hitNode.hit.active)
				{
					if(checkHit(node, hitNode))
					{
						isPushing = hit(node, hitNode);
						
						updateHitList(node, hitNode);
						
						if(isPushing)
						{
							// play push sound
							EntityUtils.playAudioAction(hitNode.hitAudio, hitNode.hitAudioData,SoundAction.PUSH);
						}
					}	
				}
			}
			/*
			if( node.wallCollider )	
			{ 
				node.wallCollider.isHit = node.wallCollider.isPushing = isPushing;
				if( isPushing )
				{
					node.wallCollider.direction = node.motion.velocity.x;
				}
			}
			*/
		}

		/**
		 * Determine if collider and hit intersect, assuming both or rectangular.
		 * @param node
		 * @param hitNode
		 * @return 
		 */
		private function checkHit(node:SceneObjectCollisionRectNode, hitNode:SceneObjectHitNode):Boolean
		{
			var hitPosition:* = getHitPosition(hitNode);
			var offsetRight:Number = 0;
			var offsetLeft:Number = 0;
			var offsetTop:Number = 0;
			var offsetBottom:Number = 0;
			
			if(node.edge)
			{
				offsetRight = node.edge.rectangle.right;
				offsetLeft = -node.edge.rectangle.left;
				offsetTop = -node.edge.rectangle.top;
				offsetBottom = node.edge.rectangle.bottom;
			}
			
			if(hitNode.edge)
			{
				offsetRight -= hitNode.edge.rectangle.left;
				offsetLeft += hitNode.edge.rectangle.right;
				offsetTop -= hitNode.edge.rectangle.top;
				offsetBottom += hitNode.edge.rectangle.bottom;
			}
			
			if(node.motion.x > hitPosition.x - offsetLeft && 
			   node.motion.x < hitPosition.x + offsetRight &&
			   node.motion.y > hitPosition.y - offsetTop &&
			   node.motion.y < hitPosition.y + offsetBottom)
			{
				return(true);
			}
			
			return(false);
		}
		
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
		
		private function hit(node:SceneObjectCollisionRectNode, hitNode:SceneObjectHitNode):Boolean
		{
			var motion:Motion = node.motion;
			var offsetRight:Number = 0;
			var offsetLeft:Number = 0;
			var hitTop:Number = 0;
			var colliderBottom:Number = 0;
			var hitPosition:* = getHitPosition(hitNode);

			if(node.edge)
			{
				offsetRight = node.edge.rectangle.right;
				offsetLeft = -node.edge.rectangle.left;
				colliderBottom = node.edge.rectangle.bottom;
			}
			
			// apply inertia & reposition collider along x axis based on hit position
			// only apply velocity if collider is below hit
			if( motion.y + colliderBottom >= hitPosition.y )
			{
				if(hitNode.edge)
				{
					offsetRight -= hitNode.edge.rectangle.left;
					offsetLeft += hitNode.edge.rectangle.right;
					hitTop = -hitNode.edge.rectangle.top;
				}
				
				// get mass
				var hitMass:Number = 0;			//((MAX_SIZE - link0.mass) / MAX_SIZE);
				var colliderMass:Number = 1;	//((MAX_SIZE - link1.mass) / MAX_SIZE);
				if(node.mass != null && hitNode.mass != null)
				{
					hitMass = hitNode.mass.mass;
					colliderMass = node.mass.mass;
				}
				
				if(hitPosition.x > motion.x && (hitPosition.x - motion.x) < offsetRight)		// if hit is right of collider
				{
					motion.x = hitPosition.x - offsetLeft;		// reposition collider in respect to hit
					//hitPosition.x = motion.x + offsetRight;	// reposition hit in respect to collider
					if( motion.velocity.x > 0 )
					{
						if(!hitNode.hit.anchored)
						{
							applyCollisionForce( motion, colliderMass, hitMass, hitNode );
						}
						triggerPush( node, hitNode );
						return true;
					}
				}
				else if(hitPosition.x < motion.x && (motion.x - hitPosition.x) < offsetLeft)	// if hit is left of collider
				{
					motion.x = hitPosition.x + offsetRight;		// reposition collider in respect to hit
					//hitPosition.x = motion.x - offsetLeft;	// reposition hit in respect to collider
					if( motion.velocity.x < 0 )
					{
						if(!hitNode.hit.anchored)
						{
							applyCollisionForce( motion, colliderMass, hitMass, hitNode );
						}
						triggerPush( node, hitNode );
						return true;
					}
				}
			}
			return false;
		}
		
		private function applyCollisionForce( colliderMotion:Motion, colliderMass:Number, hitMass:Number, hitNode:SceneObjectHitNode):void
		{
			if( hitMass > 0 )
			{
				// apply inertial force in opposite direction of pushing force
				var interialForce:Number = (1 - colliderMass/(hitMass + colliderMass)) * -colliderMotion.velocity.x;
				if( colliderMotion.parentVelocity == null ){
					colliderMotion.parentVelocity = new Point( interialForce, 0 );
				} else {
					colliderMotion.parentVelocity.x += interialForce;
				}
				
				// transfer motion to hit
				if(hitNode.motion)
				{
					hitNode.motion.velocity.x = colliderMotion.velocity.x + interialForce;
				}
			}
			else if(hitNode.motion)
			{
				hitNode.motion.velocity.x = colliderMotion.velocity.x;
			}
		}
		
		/**
		 * Turn on wall hit, if applicable.
		 * Will cause push state in case of character.
		 * @param node
		 * @param hitNode
		 */
		private function triggerPush(node:SceneObjectCollisionRectNode, hitNode:SceneObjectHitNode):void
		{
			if( node.wallCollider && hitNode.hit.triggerPush )	
			{ 
				node.wallCollider.isHit = node.wallCollider.isPushing = true;
				node.wallCollider.direction = node.motion.velocity.x;
			}
		}

		private function updateHitList(collisionNode:SceneObjectCollisionRectNode, hitNode:SceneObjectHitNode):void
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
		
		private const X_ADJUST:Number = 10;
		private var _hits:NodeList;
		[Inject]
		public var _shellApi:ShellApi;
	}
}