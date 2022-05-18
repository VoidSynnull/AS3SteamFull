/**
 * A hit system for setting entity position and motion based on collisions with a movieclip or bitmap-based platform.
 */

package game.systems.hit
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.Platform;
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.EmitterHitData;
	import game.data.scene.hit.HitAudioData;
	import game.data.scene.hit.HitDataComponent;
	import game.data.scene.hit.MoverHitData;
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.nodes.hit.PlatformBitmapHitNode;
	import game.nodes.hit.PlatformHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.MotionUtils;

	public class PlatformHitSystem extends GameSystem
	{
		public function PlatformHitSystem()
		{
			super(PlatformCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(PlatformHitNode);
			_bitmapHits = systemManager.getNodeList(PlatformBitmapHitNode);
		}

		private function updateNode(collisionNode:PlatformCollisionNode, time:Number):void
		{
			var motion:Motion = collisionNode.motion;
			var platformDisplay:DisplayObjectContainer;
			var edge:Edge = collisionNode.edge;
			var offsetX:Number = 0;
			var offsetY:Number = 0;
			var bitmapCollider:BitmapCollider = collisionNode.bitmapCollider;
			var hitNode:PlatformHitNode;
			var bitmapHitNode:PlatformBitmapHitNode;
			var moverHitData:MoverHitData;
			var isHit:Boolean;
			var stickToPlatforms:Boolean;
			
			collisionNode.collider.collisionAngleDegrees = 0;
			
			if(bitmapCollider.platformColor != 0)
			{
				for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
				{
					if(bitmapCollider.platformColor == bitmapHitNode.bitmapHit.color)
					{
						setPlatform(bitmapCollider.platformHitY, collisionNode, bitmapHitNode.entity, bitmapHitNode.hitAudioData, isStickToPlatform(bitmapHitNode.hit, bitmapHitNode.bitmapHit.data) );
						return;
					}
				}
			}
			
			for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				// if platform is sleeping, or nodes are testing aginst themselves continue to next
				if (EntityUtils.sleeping(hitNode.entity) || collisionNode.entity == hitNode.entity )	
				{ 
					continue; 
				}	
				
				if(collisionNode.validHit != null)
				{
					if(hitNode.id != null)
					{
						if(!collisionNode.validHit.hitIds[hitNode.id.id] && !collisionNode.validHit.inverse
							|| collisionNode.validHit.hitIds[hitNode.id.id] && collisionNode.validHit.inverse)
						{
							continue;
						}
					}
				}

				// get y offset of collider from edge
				if(edge != null)
				{
					offsetY = edge.rectangle.bottom;
				}
				
				platformDisplay = hitNode.display.displayObject;
				// if hitRect has been defined use for collision check, otherwise use display
				isHit = false;
				if( hitNode.hit.hitRect != null )
				{
					if(hitNode.motion)
					{
						var posX:Number = ((motion.x + offsetX) - hitNode.motion.x)* super.group.shellApi.screenManager.appScale;
						var posY:Number = ((motion.y + offsetY) - hitNode.motion.y)* super.group.shellApi.screenManager.appScale;;
						isHit = ( hitNode.hit.hitRect.contains( posX, posY ) );
					}
				}
				else
				{	
					isHit = platformDisplay.hitTestPoint(_shellApi.offsetX(motion.x + offsetX), _shellApi.offsetY(motion.y + offsetY), true);		
					//_shellApi.logWWW("isHit: " + isHit);
				}
				
				if( isHit )
				{
					if(platformHit(hitNode, collisionNode, offsetY, time))
					{
						collisionNode.collider.collisionAngleDegrees = MotionUtils.getPositionComponent(hitNode).rotation;
						//_shellApi.logWWW("isHit & platformHit");
					}
				}
			}
		}
		
		private function isStickToPlatform( platformHit:Platform = null, hitData:HitDataComponent = null ):Boolean
		{
			// TODO :: Stick to Platform seems a little hacky, should readdress. - Bard
			var stickToPlatform:Boolean;
			if( platformHit != null )
			{
				stickToPlatform = platformHit.stickToPlatforms;
			}
			
			if( hitData != null )
			{
				if( !stickToPlatform )
				{
					if( hitData is MoverHitData )
					{
						stickToPlatform = MoverHitData(hitData).stickToPlatforms;
					}
				}
			}
			return stickToPlatform;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(PlatformCollisionNode);
			systemManager.releaseNodeList(PlatformHitNode);
			systemManager.releaseNodeList(PlatformBitmapHitNode);
			_hits = null;
			_bitmapHits = null;
			super.removeFromEngine(systemManager);
		}
				
		/**
		 * Check a movieclip based platform to see if an entity is hitting it.  If there is a collidion, adjust the y position based on the entity's distance from the center
		 * @param hitNode
		 * @param collisionNode
		 * @param offsetY - y offset determined by collider's edge
		 * @param time
		 * @return 
		 */
		private function platformHit(hitNode:PlatformHitNode, collisionNode:PlatformCollisionNode, offsetY:Number, time:Number):Boolean
		{
			// get the y position of where the collider and platform would intersect (takes platform angle into account)
			var baseY:Number = ( hitNode.hit.hitRect ) ? getYBaseFromRect( hitNode, collisionNode ) : getYBaseFromDisplay( hitNode, collisionNode );
			// we don't 'force' the characters y position to clamp to the _platforms y position until
			// it is within a minimum distance or collider's current velocity, which ever is larger.
			// This makes the clamping a bit smoother at low speeds and still allows accurate hittests when it is moving at high speed.		
			var platformDistance:Number = Math.max(MIN_HIT_DIST, Math.ceil(collisionNode.motion.velocity.length) * time);
			var stickToPlatforms:Boolean = isStickToPlatform( hitNode.hit );

			// if collider is within 'range' of platform
			if (Math.abs(baseY - collisionNode.motion.y - offsetY) <= platformDistance)
			{				
				//_shellApi.logWWW("platformHit : in range");
				var velocityYOffset:Number = 0;
				
				if (hitNode.motion != null && hitNode.motion.velocity)
				{
					//_shellApi.logWWW("platformHit : motion != null && vel");
					// apply hit's x motion to collider's parent x motion (y motion needs to be dealt with separately)
					if(hitNode.motion.velocity.x != 0)
					{
						if(collisionNode.motion.parentVelocity == null)	{ collisionNode.motion.parentVelocity = new Point(0,0); }
						collisionNode.motion.parentVelocity.x = hitNode.motion.velocity.x * collisionNode.motion.parentMotionFactor;
					}
					
					// determine y offset based on platform movement along y
					if(hitNode.motion.velocity.y > 0)
					{
						velocityYOffset = hitNode.motion.velocity.y * time * .5;
					}
					else if(hitNode.motion.velocity.y < 0)
					{
						velocityYOffset = hitNode.motion.velocity.y * time;
					}
					
					// if platforming is moving along y, turn stickToPlatforms regardless 
					if(velocityYOffset != 0)
					{
						stickToPlatforms = true;
					}
				}
				
				return(setPlatform(baseY - offsetY + velocityYOffset, collisionNode, hitNode.entity, hitNode.hitAudioData, stickToPlatforms));
			}
			
			return(false);
		}
		
		private function getYBaseFromRect(hitNode:PlatformHitNode, collisionNode:PlatformCollisionNode):Number
		{
			var hitPosition:* = MotionUtils.getPositionComponent(hitNode);
			var hitRotation:Number = hitPosition.rotation;
			
			if(hitNode.hit.limitHitRectAngle)
			{
				if (hitRotation <= -180)
				{
					hitRotation += 360;
				}
				else if (hitRotation >= 180)
				{
					hitRotation -= 360;
				}
				
				while(hitRotation > 45 || hitRotation < -45)
				{
					if(hitRotation > 45)
					{
						hitRotation -= 90;
					}
					else if(hitRotation < -45)
					{
						hitRotation += 90;
					}
				}
			}
			
			/*
			// visual debug of rotation correction.
			if(hitPosition.rotation != hitRotation)
			{
				NapeMotion(hitNode.entity.get(NapeMotion)).body.rotation = hitRotation * Math.PI / 180;
			}
			*/
			var platformAngle:Number = Math.tan(hitRotation * Math.PI / 180);			
			var xDelta:Number = collisionNode.motion.x - hitPosition.x;
			if(hitNode.hit.top)
			{
				return (hitPosition.y + hitNode.hit.hitRect.top * .9) + (xDelta * platformAngle);
			}
			else
			{
				return (hitPosition.y + hitNode.hit.hitRect.top + hitNode.hit.hitRect.height/2) + (xDelta * platformAngle);
			}
		}
		
		
		private function getYBaseFromDisplay(hitNode:PlatformHitNode, collisionNode:PlatformCollisionNode):Number
		{
			var hit:DisplayObjectContainer = hitNode.display.displayObject;
			var platformAngle:Number = Math.tan(hit.rotation * Math.PI / 180);
			var xDelta:Number = collisionNode.motion.x - hit.x;
			if(hitNode.hit.top)
			{
				return (hit.y + hit.getBounds(hit).top * .9) + (xDelta * platformAngle);
			}
			else
			{
				return hit.y + (xDelta * platformAngle);
			}
		}

		/**
		 * Set's the entities y position to the platform position.  Will also zero out acceleration and velocity if the entity is set to stick to platforms.
		 * @param platformY - y position collider in order to be positioned on platform)
		 * @param collisionNode
		 * @param hitEntity
		 * @param hitAudioData
		 * @param stickToPlatforms
		 * @return 
		 * 
		 */
		private function setPlatform(platformY:Number, collisionNode:PlatformCollisionNode, hitEntity:Entity, hitAudioData:HitAudioData, stickToPlatforms:Boolean):Boolean
		{
			var hit:Boolean = false;
			
			// hit is true if stickToPlatforms is on, collider has downward motion, or collider has parent motion
			if(stickToPlatforms)
			{
				hit = true;
			}
			else if(collisionNode.motion.velocity.y >= 0 || ( collisionNode.motion.parentAcceleration && collisionNode.motion.parentAcceleration.y > 0 ) || ( collisionNode.motion.parentVelocity && collisionNode.motion.parentVelocity.y > 0 ))
			{
				hit = true;
			}
						
			if(hit)
			{
				if(collisionNode.collider.ignoreNextHit)
				{
					if(platformY - collisionNode.currentHit.hitY > 10)
					{
						collisionNode.collider.ignoreNextHit = false;
					}
					else
					{
						return(false);
					}
				}
				
				// update currentHit to reflect platform
				collisionNode.currentHit.hit = hitEntity;
				collisionNode.collider.isHit = true;
				collisionNode.motion.y = platformY;
				collisionNode.currentHit.hitX = collisionNode.motion.x;
				collisionNode.currentHit.hitY = collisionNode.motion.y;
				
				if(stickToPlatforms || collisionNode.motion.velocity.y > 0)
				{
					// if colliding with platform for first time (accelration is still positive) play sound
					if(collisionNode.motion.acceleration.y > 0)
					{
						EntityUtils.playAudioAction(collisionNode.hitAudio, hitAudioData);
						EntityUtils.playEmitterAction( collisionNode.emitterHit, hitEntity.get( EmitterHitData ));
					}
					// zero colliders y motion
					if(collisionNode.collider.adjustMotion)
					{
						collisionNode.motion.acceleration.y = 0;
						collisionNode.motion.velocity.y = 0;
					}
				}
							
				return(true);
			}
			
			return(false);
		}
			
		private const MIN_HIT_DIST:int = 100;
		
		[Inject]
		public var _shellApi:ShellApi;
		private var _hits:NodeList;
		private var _bitmapHits:NodeList;
	}
}
