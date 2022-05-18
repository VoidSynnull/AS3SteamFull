/**
 * A hit system that checks bitmap data for overlap with points along a ray extending from a characters center along the velocity vector.
 *    This system doesn't alter an entity's motion or position directly, simply sets their bitmap collider to match the hit data
 *    that corresponds to the color of the pixel they're hitting.  Only checks for pixels that are included in the dictionary that is
 *    passed in on creation.
 */

package game.systems.hit
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.BitmapCollider;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitData;
	import game.nodes.entity.collider.BitmapCollisionNode;
	import game.nodes.hit.BitmapHitAreaNode;
	import game.systems.GameSystem;

	public class BitmapCollisionSystem extends GameSystem
	{
		public function BitmapCollisionSystem(bitmapHitData:Dictionary, wrapX:uint)
		{
			super(BitmapCollisionNode, updateNode, null, null);
			_bitmapHitData = bitmapHitData;
			_wrapX = wrapX;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function update(time:Number):void
		{
			if(canvas != null) 
			{ 
				canvas.graphics.clear(); 
			}
			
			if(_hitAreaNode == null)
			{
				_hitAreaNode = _hitAreaNodes.head;
			}
			else
			{
				super.update(time);
			}
		}
		
		private function updateNode(collisionNode:BitmapCollisionNode, time:Number):void
		{			
			var motion:Motion = collisionNode.motion;

			// RLH: wrapping for bitmaps
			var offsetX:Number = 0;
			if (_wrapX != 0)
				offsetX -= (Math.floor(motion.x/_wrapX)*_wrapX);
			
			var speedX:Number = motion.totalVelocity.x;
			var speedY:Number = motion.totalVelocity.y;
			
			if(collisionNode.collider.addAccelerationToVelocityVector)
			{
				speedX += motion.acceleration.x;
				speedY += motion.acceleration.y;
			}
			
			checkHits(motion.x + offsetX, motion.y, speedX * time, speedY * time, collisionNode);
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			_hitAreaNode = _hitAreaNodes.head;
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			_bitmapHitData = null;
			_hitAreaNode = null;
			_hitAreaNodes = null;
			
			systemManager.releaseNodeList(BitmapCollisionNode);
			systemManager.releaseNodeList(BitmapHitAreaNode);
						
			super.removeFromEngine(systemManager);
		}
		
		// This hittest checks for a 'ray' of pixels extending from the characters center in the direction and length of their velocity.
		public function checkHits(x:Number, y:Number, velocityX:Number, velocityY:Number, collisionNode:BitmapCollisionNode):Boolean
		{
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			// current color of the pixel being tested.
			var hitColor:uint = hitArea.getPixel(x * hitAreaSpatial.scale + hitAreaSpatial.x, y * hitAreaSpatial.scale + hitAreaSpatial.y);
			// the data associated with a particular hitColor
			var hitData:HitData = _bitmapHitData[hitColor];
			var collider:BitmapCollider = collisionNode.collider;
			var isHit:Boolean = false;
			
			if(hitData != null)
			{
				isHit = true;
				
				if(collisionNode.validHit != null)
				{
					//if(collisionNode.validHit.hitIds[hitData.id] == collisionNode.validHit.inverse)
					if(!collisionNode.validHit.hitIds[hitData.id] && !collisionNode.validHit.inverse
						|| collisionNode.validHit.hitIds[hitData.id] && collisionNode.validHit.inverse)
					{
						isHit = false;
					}
				}
			
				if(isHit)
				{
					collider.centerColor = hitData.color;
					collider.centerHitX = x;
					collider.centerHitY = y;	
				}
			}
			
			if(velocityX != 0 || velocityY != 0)
			{
				// total distance to test for hits.  Simplified distance formula since we're starting at origin to get velocity vector.
				var dist:Number = Math.sqrt((velocityX * velocityX) + (velocityY * velocityY));
				var targetX:Number;       // the x and y we're testing.
				var targetY:Number;
				var offsetX:Number = 0;   // if an entity has an 'edge' test from there rather than the origin.
				var offsetY:Number = 0;
				var index:uint;           // used to deterimine the point along the velocity vector being tested.
				var negativeIndex:Number = 0;
				var ratioX:Number = velocityX / dist;
				var ratioY:Number = velocityY / dist;
				
				if(collisionNode.edge && collisionNode.collider.useEdge)
				{
					offsetX = collisionNode.edge.rectangle.right * ratioX;
					offsetY = collisionNode.edge.rectangle.bottom * ratioY;
				}
				
				for(index = 0; index < dist + 1; index++)
				{
					// increment the point we're testing as we move along the velocity vector.  The closest point to the origin that overlaps
					//   a valid 'hitColor' will be used as the hit.
					targetX = x + (ratioX * index) + offsetX;			
					targetY = y + (ratioY * index) + offsetY;
					
					// check for pixel color at target position
					hitColor = hitArea.getPixel(targetX * hitAreaSpatial.scale + hitAreaSpatial.x, targetY * hitAreaSpatial.scale + hitAreaSpatial.y);
					
				    if(canvas != null) { drawPoint(targetX, targetY); } 
					
					hitData = _bitmapHitData[hitColor];

					if(hitData != null)
					{
						isHit = true;
						
						if(collisionNode.validHit != null)
						{
							if(!collisionNode.validHit.hitIds[hitData.id] && !collisionNode.validHit.inverse
								|| collisionNode.validHit.hitIds[hitData.id] && collisionNode.validHit.inverse)
							{
								isHit = false;
							}
						}
						
						if(isHit)
						{
							collider.color = hitData.color;
							collider.hitX = targetX;
							collider.hitY = targetY;
							collider.ratioX = ratioX;
							collider.ratioY = ratioY;
						}
						
						return(true);
					}
				}
			}
			
			collider.lastX = x;
			collider.lastY = y;

			return(false);
		}
		
		// A way to visualize the hit vector for debugging.
		private function drawPoint(x:Number, y:Number):void
		{
			canvas.graphics.lineStyle(4, 0x0000ff);
			canvas.graphics.moveTo(x, y);
			canvas.graphics.lineTo(x + 1, y + 1);
		}
		
		private var _bitmapHitData:Dictionary;
		private var _hitAreaNode:BitmapHitAreaNode;
		private var _hitAreaNodes:NodeList;
		public var canvas:Sprite;
		private var _wrapX:uint;
	}
}
