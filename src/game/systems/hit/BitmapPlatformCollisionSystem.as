/**
 * A hit system that checks bitmap data for overlap with points that extend in a vertical line starting at an x away from the entity's x position + x velocity and
 *    extending vertically based on the entity's total velocity.
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
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitData;
	import game.nodes.entity.collider.BitmapPlatformCollisionNode;
	import game.nodes.hit.BitmapHitAreaNode;
	import game.systems.GameSystem;

	public class BitmapPlatformCollisionSystem extends GameSystem
	{
		public function BitmapPlatformCollisionSystem(bitmapHitData:Dictionary, wrapX:uint)
		{
			super(BitmapPlatformCollisionNode, updateNode);
			_bitmapHitData = bitmapHitData;
			_wrapX = wrapX; // RLH: for wrapping bitmap hits
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
		
		private function updateNode(collisionNode:BitmapPlatformCollisionNode, time:Number):void
		{			
			// TEMP - this check insures that an entity has either a bounce or standard platform collider.  A cleaner solution would be to do this check once 
			//   when adding to the nodelist in ash.
			if(collisionNode.bouncePlatformCollider || collisionNode.platformCollider)
			{
				collisionNode.bitmapCollider.platformColor = 0;
				collisionNode.bitmapCollider.platformHitX = NaN;
				collisionNode.bitmapCollider.platformHitY = NaN;
				
				var motion:Motion;
				var offsetX:Number = 0;
				var offsetY:Number = 0;
				var hitY:Number;
				var edge:Edge = collisionNode.edge;
				
				motion = collisionNode.motion;
				
				// RLH: wrapping for bitmaps
				if (_wrapX != 0)
					offsetX -= (Math.floor(motion.x/_wrapX)*_wrapX);
				
				if(edge != null)
				{
					offsetY = edge.rectangle.bottom;
				}
				//if(motion.velocity.length > 0) { drawPoint(spatial.x, spatial.y); } 
				checkHits(motion.x, motion.y, motion.totalVelocity.x * time, motion.totalVelocity.y * time, collisionNode, offsetX, offsetY);
			}
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			_hitAreaNode = _hitAreaNodes.head;
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(gameSystems:Engine) : void
		{
			_hitAreaNode = null;
			_hitAreaNodes = null;
			_bitmapHitData = null;
			canvas = null;
			systemManager.releaseNodeList(BitmapHitAreaNode);
			gameSystems.releaseNodeList(BitmapPlatformCollisionNode);
			super.removeFromEngine(gameSystems);
		}
		
		private function checkHits(x:Number, y:Number, velocityX:Number, velocityY:Number, collisionNode:BitmapPlatformCollisionNode, offsetX:Number = 0, offsetY:Number = 0):void
		{							
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			// Add a distance above a platform that the player will be pulled onto it.  This prevents 'bobbing' along the surface.
			var paddingY:uint = 10;
			// The minimum distance to check for hits along the y-axis
			var minimumRange:uint = 5 + paddingY;
			// origin point of the vector to test for hits
			var originX:Number = x + offsetX;
			var originY:Number = y + offsetY + paddingY;
			// target point of hit tests
			var targetY:Number;
			// total distance to test for hits
			var range:Number = minimumRange + (Math.abs(velocityX) + velocityY);
			var hitColor:uint = 0;
			var hitData:HitData;
			var index:int;
			var collider:BitmapCollider = collisionNode.bitmapCollider;
			var isHit:Boolean = false;
									
			for(index = range; index > -1; index--)
			{
				targetY = originY - index;
				// check for the color of a 'platform'.  Apply the scale of the data to the x,y position.
				hitColor = hitArea.getPixel(originX * hitAreaSpatial.scale + hitAreaSpatial.x, targetY * hitAreaSpatial.scale + hitAreaSpatial.y);
				
				if(canvas != null) { drawPoint(originX, targetY, hitColor); } 
				
				if(hitColor != 0)
				{
					hitData = _bitmapHitData[hitColor];
					
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
							collider.platformColor = hitColor;
							collider.platformHitX = originX - offsetX;
							collider.platformHitY = targetY - offsetY;
							return;
						}
					}
				}
			}
		}
		
		// A way to visualize the hit vector for debugging.
		private function drawPoint(x:Number, y:Number, color:uint = 0xff0000):void
		{
			canvas.graphics.lineStyle(4, color);
			canvas.graphics.moveTo(x, y);
			canvas.graphics.lineTo(x + 1, y + 1);
		}
				
		private var _hitAreaNode:BitmapHitAreaNode;
		private var _hitAreaNodes:NodeList;
		private var _bitmapHitData:Dictionary;
		private var _wrapX:uint;
		public var canvas:Sprite;  // for debug
	}
}
