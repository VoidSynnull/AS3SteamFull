package game.systems.hit
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitAudioData;
	import game.data.scene.hit.MoverHitData;
	import game.nodes.entity.collider.BitmapCollisionNode;
	import game.nodes.entity.collider.PlatformReboundCollisionNode;
	import game.nodes.hit.BitmapHitAreaNode;
	import game.nodes.hit.PlatformBitmapReboundHitNode;
	import game.nodes.hit.PlatformReboundHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	
	public class PlatformReboundHitSystem extends GameSystem
	{
		public function PlatformReboundHitSystem()
		{
			super(PlatformReboundCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_hits = systemManager.getNodeList(PlatformReboundHitNode);
			_bitmapHits = systemManager.getNodeList(PlatformBitmapReboundHitNode);
			
			_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			_hitAreaNode = _hitAreaNodes.head;
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			_hitAreaNode = null;
			_hitAreaNodes = null;
			
			systemManager.releaseNodeList(BitmapCollisionNode);
			systemManager.releaseNodeList(BitmapHitAreaNode);
			
			super.removeFromEngine(systemManager);
		}
		
		override public function update(time:Number):void
		{
			if(_hitAreaNode == null)
			{
				_hitAreaNode = _hitAreaNodes.head;
			}
			else
			{
				super.update(time);
			}
		}
		
		private function updateNode(collisionNode:PlatformReboundCollisionNode, time:Number):void
		{			
			var motion:Motion = collisionNode.motion;
			var platformDisplay:DisplayObjectContainer;
			var edge:Edge = collisionNode.edge;
			var offsetX:Number = 0;
			var offsetY:Number = 0;
			var bitmapCollider:BitmapCollider = collisionNode.bitmapCollider;
			var hitNode:PlatformReboundHitNode;
			var bitmapHitNode:PlatformBitmapReboundHitNode;
			var moverHitData:MoverHitData;
			var isHit:Boolean;
			
			collisionNode.collider.collisionAngleDegrees = 0;
			
			if(bitmapCollider.platformColor != 0)
			{
				for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
				{
					if(bitmapCollider.platformColor == bitmapHitNode.bitmapHit.color)
					{
						moverHitData = bitmapHitNode.bitmapHit.data as MoverHitData;
						
						setBounceBitmapPlatform(bitmapCollider.platformHitY, collisionNode, moverHitData.bounce, bitmapHitNode.entity, bitmapHitNode.hitAudioData);
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
						//if(collisionNode.validHit.hitIds[hitNode.id.id] == collisionNode.validHit.inverse)
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
					var posX:Number = (motion.x + offsetX) - hitNode.motion.x;
					var posY:Number = (motion.y + offsetY) - hitNode.motion.y;
					isHit = ( hitNode.hit.hitRect.contains( posX, posY ) );
				}
				else
				{	
					isHit = platformDisplay.hitTestPoint(_shellApi.offsetX(motion.x + offsetX), _shellApi.offsetY(motion.y + offsetY), true);		
				}
				
				if( isHit )
				{
					setBouncePlatform( hitNode, collisionNode, offsetY, time);
					collisionNode.collider.collisionAngleDegrees = MotionUtils.getPositionComponent(hitNode).rotation;
				}
			}
		}
		
		private function setBounceBitmapPlatform(platformY:Number, collisionNode:PlatformReboundCollisionNode, bounce:Number, hitEntity:Entity, hitAudioData:HitAudioData):void
		{
			if(collisionNode.bitmapCollider.platformColor != 0 /*&& collisionNode.motion.velocity.length > 0*/)
			{
				var offsetY:Number = 0;
				
				if(collisionNode.edge)
				{
					offsetY = collisionNode.edge.rectangle.bottom;
				}
				
				while(checkHit(collisionNode.motion.x, platformY + offsetY - 1, collisionNode.bitmapCollider.platformColor))
				{
					platformY--;
				}
				
				collisionNode.currentHit.hit = hitEntity;
				collisionNode.collider.isHit = true;
				collisionNode.motion.y = platformY;
				collisionNode.currentHit.hitX = collisionNode.motion.x;
				collisionNode.currentHit.hitY = collisionNode.motion.y;
				bounce += collisionNode.collider.bounce; 
				var collisionAngle:Number = getCollisionAngle(collisionNode.currentHit.hitX, collisionNode.currentHit.hitY + offsetY, collisionNode.bitmapCollider.platformColor);
				var velocity:Point = collisionNode.motion.velocity;
				
				if(Math.abs(collisionAngle) < .08)
				{
					collisionAngle = 0;
					
					if(velocity.length < collisionNode.motion.restVelocity)
					{
						collisionNode.motion.acceleration.y = 0;
						collisionNode.motion.velocity.y = 0;
					}
				}
				
				var colCos:Number = Math.cos(collisionAngle);
				var colSin:Number = Math.sin(collisionAngle);
				
				//rotate velocity vector
				var vx1:Number = colCos * velocity.x + colSin * velocity.y;
				var vy1:Number = colCos * velocity.y - colSin * velocity.x;
				
				//_rebound with rotated vector
				vy1 *= bounce;
				
				//rotate back
				velocity.x = colCos*vx1 - colSin*vy1;
				velocity.y = colCos*vy1 + colSin*vx1;
				
				if(velocity.y > 100)
				{
					if(collisionNode.motion.acceleration.y > 0)
					{
						EntityUtils.playAudioAction(collisionNode.hitAudio, hitAudioData);
					}
				}
				
				collisionNode.collider.collisionAngleDegrees = collisionAngle * 180 / Math.PI;
			}
			else
			{
				collisionNode.currentHit.hit = hitEntity;
				collisionNode.collider.isHit = true;
				collisionNode.motion.acceleration.y = 0;
				collisionNode.motion.velocity.y = 0;
			}
		}
		
		/**
		 * Handles collisions in which the colliding needs to bounce off of the platform.
		 * Calculates bounce trajectory given current angles. 
		 * @param hitNode
		 * @param collisionNode
		 * @param offsetY - y offset determined by collider's edge
		 * @param time
		 * @return 
		 */
		private function setBouncePlatform(hitNode:PlatformReboundHitNode, collisionNode:PlatformReboundCollisionNode, offsetY:Number, time:Number):void
		{
			collisionNode.currentHit.hit = hitNode.entity;
			collisionNode.collider.isHit = true;
			
			if(collisionNode.motion.velocity.length > 0)
			{
				var hitPosition:* = MotionUtils.getPositionComponent(hitNode);
				var collisionAngle:Number = hitPosition.rotation * Math.PI / 180;
				var cos:Number = Math.cos(collisionAngle);
				var sin:Number = Math.sin(collisionAngle);
				var platformAngle:Number = Math.tan(hitPosition.rotation * Math.PI / 180);
				var xDelta:Number = collisionNode.motion.x - hitPosition.x;
				
				//var baseY:Number = hitPosition.y + (xDelta * platformAngle);
				// get the y position of where the collider and platform would intersect (takes platform angle into account)
				var baseY:Number = ( hitNode.hit.hitRect ) ? getYBaseFromRect( hitNode, collisionNode ) : getYBaseFromDisplay( hitNode, collisionNode );
				var velocity:Point = collisionNode.motion.velocity;
				var x1:Number = collisionNode.motion.x - hitPosition.x;
				var y1:Number = collisionNode.motion.y - hitPosition.y;
				
				if(Math.abs(collisionAngle) < .08)
				{
					if(velocity.length < collisionNode.motion.restVelocity)
					{
						collisionNode.motion.acceleration.y = 0;
						collisionNode.motion.velocity.y = 0;
					}
				}
				
				// Apply advanced coordinate rotation equation to find y position relative to a line with an angle of 0.
				var rotatedPosition:Point = new Point();
				rotate(rotatedPosition, x1, y1, sin, cos, true);
				
				var rotatedVelocity:Point = new Point();
				rotate(rotatedVelocity, velocity.x, velocity.y, sin, cos, true);
				
				//_rebound with rotated vector
				if(rotatedVelocity.y >= 0)
				{
					rotatedPosition.y = -offsetY;
				}
				else
				{
					return;
				}
				
				var bounce:Number = hitNode.hit.bounce + collisionNode.collider.bounce;
				
				rotatedVelocity.y *= bounce;
				
				rotate(velocity, rotatedVelocity.x, rotatedVelocity.y, sin, cos);
				
				// Apply inverse of coordinate rotation to get the correct x/y and velocity with the angled line.
				x1 = cos * rotatedPosition.x - sin * rotatedPosition.y;
				y1 = cos * rotatedPosition.y + sin * rotatedPosition.x;
				
				collisionNode.motion.x = hitPosition.x + x1;
				//collisionNode.motion.y = hitPosition.y + y1;
				collisionNode.motion.y = baseY + y1;
				collisionNode.currentHit.hitX = collisionNode.motion.x;
				collisionNode.currentHit.hitY = collisionNode.motion.y;
			}
		}
		
		private function getYBaseFromDisplay(hitNode:PlatformReboundHitNode, collisionNode:PlatformReboundCollisionNode):Number
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
		
		private function getYBaseFromRect(hitNode:PlatformReboundHitNode, collisionNode:PlatformReboundCollisionNode):Number
		{
			var hitPosition:* = MotionUtils.getPositionComponent(hitNode);
			var platformAngle:Number = Math.tan(hitPosition.rotation * Math.PI / 180);
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
		
		private function rotate(target:*, x:Number, y:Number, sin:Number, cos:Number, reverse:Boolean = false):*
		{
			if(reverse)
			{
				target.x = x * cos + y * sin;
				target.y = y * cos - x * sin;
			}
			else
			{
				target.x = x * cos - y * sin;
				target.y = y * cos + x * sin;
			}
			
			return(target);
		}
		
		private function getCollisionAngle(x:Number, y:Number, color:uint):Number 
		{
			var hitTestRadius:Number = _hitAreaNode.bitmapHitArea.hitTestRadius;
			var hitTestRadialSteps:Number = _hitAreaNode.bitmapHitArea.hitTestRadialSteps;
			var scanAngle:Number = 0;
			var bx:Number = x + hitTestRadius*Math.cos(scanAngle);
			var by:Number = y + hitTestRadius*Math.sin(scanAngle);
			var hitting:Boolean = notEmpty(bx, by);
			var numHits:Number = 0;
			var px1:Number = 0;
			var py1:Number = 0;
			var px2:Number = 0;
			var py2:Number = 0;
			
			while (scanAngle < 2*Math.PI) 
			{
				scanAngle += 2*Math.PI/hitTestRadialSteps;
				bx = x + hitTestRadius*Math.cos(scanAngle);
				by = y + hitTestRadius*Math.sin(scanAngle);
				
				if (hitting != notEmpty(bx, by)) 
				{
					hitting = !hitting;
					numHits++;
					if (numHits > 2) 
					{
						break;
					}
					else if (numHits > 1) 
					{
						px2 = bx;
						py2 = by;
					}
					else 
					{
						px1 = bx;
						py1 = by;
					}
				}
			}
			
			return(Math.atan2(py2 - py1, px2 - px1));
		}
		
		private function checkHit(x:Number, y:Number, color:uint):Boolean
		{
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			var hitColor:uint = hitArea.getPixel((x * hitAreaSpatial.scale) + hitAreaSpatial.x, (y * hitAreaSpatial.scale) + hitAreaSpatial.y);
			
			return(hitColor == color);
		}
		
		private function notEmpty(x:Number, y:Number):Boolean
		{
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			var hitColor:uint = hitArea.getPixel((x * hitAreaSpatial.scale) + hitAreaSpatial.x, (y * hitAreaSpatial.scale) + hitAreaSpatial.y);
			
			return(hitColor != 0);
		}
		
		private var _hitAreaNode:BitmapHitAreaNode;
		private var _hitAreaNodes:NodeList;
		[Inject]
		public var _shellApi:ShellApi;
		private var _hits:NodeList;
		private var _bitmapHits:NodeList;
	}
}