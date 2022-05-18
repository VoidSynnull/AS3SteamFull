package game.systems.motion
{
	import game.components.motion.SceneObjectMotion;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.SceneObjectMotionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.MotionUtils;
	
	public class SceneObjectMotionSystem extends GameSystem
	{
		public function SceneObjectMotionSystem()
		{
			super(SceneObjectMotionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		public function updateNode(node:SceneObjectMotionNode, time:Number):void
		{
			var hit:Boolean = false;
			var objectMotion:SceneObjectMotion = node.sceneObjectMotion;
			
			// check for collison with motion bounds, apply rebound velocity
			if(node.motionBounds)
			{
				if(node.motionBounds.bottom)
				{
					node.motion.velocity.y = -Math.abs(node.motion.velocity.y) * objectMotion.edgeReboundFactor;
				}
				else if(node.motionBounds.top)
				{
					node.motion.velocity.y = Math.abs(node.motion.velocity.y) * objectMotion.edgeReboundFactor;
				}
				
				if(node.motionBounds.left)
				{
					node.motion.velocity.x = Math.abs(node.motion.velocity.x) * objectMotion.edgeReboundFactor;
				}
				else if(node.motionBounds.right)
				{
					node.motion.velocity.x = -Math.abs(node.motion.velocity.x) * objectMotion.edgeReboundFactor;
				}
			}
			
			if(objectMotion.rotateByVelocity)
			{
				var r:Number = node.spatial.width / 2 * node.spatial.scale;
				
				// more accurate equation for rotation based on speed
				
				node.spatial.rotation += 360 * node.motion.velocity.x / (2 * Math.PI * r) * time;
			}
			
			if(node.bouncePlatformCollider != null && node.bouncePlatformCollider.isHit)
			{
				hit = true;
				
				if(objectMotion.rotateByPlatform)
				{
					var rotation:Number = node.bouncePlatformCollider.collisionAngleDegrees;
					
					if (rotation < -90)
					{
						rotation += 180;
					}
					else if (rotation >= 90)
					{
						rotation -= 180;
					}
					
					// The motion smoothing system will cause this to 'ease' to the next rotation visually.
					node.motion.rotation = rotation;
				}
			}
			
			if(node.platformCollider != null && node.platformCollider.isHit)
			{
				hit = true;
			}

			if(node.waterCollider != null && node.waterCollider.isHit)
			{
				hit = true;
			}

			if(node.radialCollider != null && node.radialCollider.isHit)
			{
				hit = true;
			}
				
			if(hit)
			{
				if(objectMotion.platformFriction != 0)
				{
					if( node.motion.friction )
					{
						node.motion.friction.x = objectMotion.platformFriction;
					}
				}
			}
			else
			{
				if(objectMotion.applyGravity)
				{
					node.motion.acceleration.y = MotionUtils.GRAVITY;
				}
				
				if(objectMotion.platformFriction != 0)
				{
					if( node.motion.friction )
					{
						node.motion.friction.x = 0;
					}
				}
			}
		}
	}
}