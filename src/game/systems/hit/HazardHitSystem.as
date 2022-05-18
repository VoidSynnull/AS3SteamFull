package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.HazardCollisionNode;
	import game.nodes.hit.HazardBitmapHitNode;
	import game.nodes.hit.HazardHitNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.MotionUtils;

	public class HazardHitSystem extends System
	{
		public function HazardHitSystem()
		{
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			this._defaultPriority = SystemPriorities.resolveParentCollisions;
		}

		override public function addToEngine(gameSystems:Engine):void
		{
			_colliderNodes = gameSystems.getNodeList( HazardCollisionNode );
			_hits = gameSystems.getNodeList( HazardHitNode );
			_bitmapHits = gameSystems.getNodeList( HazardBitmapHitNode );
		}
		
		override public function update(time:Number):void
		{
			var colliderNode:HazardCollisionNode;
			var hitNode:HazardHitNode;
			var motion:Motion;
			var hitDisplay:Display;
			var bitmapCollider:BitmapCollider;
			var bitmapHitNode:HazardBitmapHitNode;
			var isHit:Boolean = false;
			
			for(colliderNode = _colliderNodes.head; colliderNode; colliderNode = colliderNode.next)
			{
				motion = colliderNode.motion;
				
				if(colliderNode.collider.coolDown > 0)
				{
					colliderNode.collider.coolDown -= time;
					colliderNode.collider.isHit = false;
					break;
				}
				
				if(colliderNode.collider.interval > 0)
				{
					colliderNode.collider.interval -= time;
				}

				bitmapCollider = colliderNode.bitmapCollider;
				
				if(bitmapCollider)
				{
					if(bitmapCollider.color != 0)
					{
						for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next)
						{
							if(bitmapCollider.color == bitmapHitNode.bitmapHit.color && bitmapHitNode.hit.active)
							{
								hit(colliderNode, bitmapHitNode);
								return;
							}
						}
					}
				}
				
				for (hitNode = _hits.head; hitNode; hitNode = hitNode.next)
				{
					if (EntityUtils.sleeping(hitNode.entity) || colliderNode.entity == hitNode.entity || !hitNode.hit.active)
					{
						continue;
					}

					hitDisplay = hitNode.display;
					
					if(hitNode.hit.boundingBoxOverlapHitTest)
					{
						isHit = MotionUtils.checkOverlap(colliderNode, hitNode);
					}
					else
					{
						isHit = hitDisplay.displayObject.hitTestPoint(_shellApi.offsetX(colliderNode.motion.x), _shellApi.offsetY(colliderNode.motion.y), true);
					}
					
					if(isHit)
					{
						hit(colliderNode, hitNode);
						return;
					}
					else
					{
						colliderNode.collider.isHit = hitNode.hit.collided = false;
					}
				}
			}
		}
		
		private function hit(colliderNode:HazardCollisionNode, hitNode:Object):void
		{
			var hitX:Number;
			var hitY:Number;
			
			if(hitNode is HazardBitmapHitNode)
			{
				hitX = colliderNode.bitmapCollider.hitX;
				hitY = colliderNode.bitmapCollider.hitY;
			}
			else
			{
				hitX = hitNode.spatial.x;
				hitY = hitNode.spatial.y;
			}
			
			// trigger hit function if provided
			if (hitNode.hit.hitFunction != null) {
				hitNode.hit.hitFunction();
			}
			if( hitNode.hit.slipThrough )
			{
				// determine direction of movement
				if( colliderNode.motion.velocity.x > 0 )
					colliderNode.motion.velocity.x = hitNode.hit.velocity.x;
				else
					colliderNode.motion.velocity.x = -hitNode.hit.velocity.x;
				colliderNode.motion.velocity.y = -hitNode.hit.velocity.y;
			}
			else if( hitNode.hit.velocityByHitAngle )
			{
				var deltaX:Number = colliderNode.motion.x - hitX;
				var deltaY:Number = colliderNode.motion.y - hitY;
				var angle:Number = Math.atan2(deltaY, deltaX);
				var baseVelocity:Number = Math.abs(hitNode.hit.velocity.length);
								
				colliderNode.motion.velocity.x = Math.cos(angle) * baseVelocity;
				colliderNode.motion.velocity.y = Math.sin(angle) * baseVelocity;
			}
			else
			{
				if(hitX > colliderNode.motion.x)		// determine direction of knockback
				{
					colliderNode.motion.velocity.x = -hitNode.hit.velocity.x;
				}
				else
				{
					colliderNode.motion.velocity.x = hitNode.hit.velocity.x;
				}
				
				colliderNode.motion.velocity.y = -hitNode.hit.velocity.y;
			}

			colliderNode.collider.isHit = hitNode.hit.collided = true;
			colliderNode.currentHit.hit = hitNode.entity;
			
			colliderNode.motion.acceleration.x = 0;
			colliderNode.motion.acceleration.y = 0;
			
			EntityUtils.playAudioAction(colliderNode.hitAudio, hitNode.hitAudioData);
			colliderNode.collider.coolDown = hitNode.hit.coolDown;
			colliderNode.collider.interval = hitNode.hit.interval;
		}
		
		override public function removeFromEngine(gameSystems:Engine) : void
		{
			gameSystems.releaseNodeList(HazardCollisionNode);
			gameSystems.releaseNodeList(HazardHitNode);
			gameSystems.releaseNodeList(HazardBitmapHitNode);
			_colliderNodes = null;
			_hits = null;
		}
		
		[Inject]
		public var _shellApi:ShellApi;
		private var _colliderNodes : NodeList;
		private var _hits : NodeList;
		private var _bitmapHits : NodeList;
	}
}
