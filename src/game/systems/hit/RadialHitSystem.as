/**
 * A hit system that scans a bitmap hitArea on collision to determine the angle of impact.  Applys a rebound to the velocity of the entity hitting the surface.
 */

package game.systems.hit
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.BitmapHitArea;
	import game.components.hit.Radial;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.RadialCollisionNode;
	import game.nodes.hit.BitmapHitAreaNode;
	import game.nodes.hit.RadialBitmapHitNode;
	import game.nodes.hit.RadialHitNode;
	import game.systems.GameSystem;
	import game.util.ColorUtil;
	import game.util.EntityUtils;

	/**
	 * Hit system for irregular surface collisions in which the collider can approach the hit them from any direction.	
	 * System tests the collider's movement vector against the hit's bitmap contour at point of collision. 
	 * An approximate plane is calculated from the bitmap's contour at point of intersection with the collider's vector.
	 * This approximate plane is used to determines the angle to repel the collider.
	 */
	public class RadialHitSystem extends GameSystem
	{
		public function RadialHitSystem()
		{
			super(RadialCollisionNode, updateNode, nodeAdded, null);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function nodeAdded(node:RadialCollisionNode):void
		{
			node.bitmapCollider.lastRadialX = node.motion.x;
			node.bitmapCollider.lastRadialY = node.motion.y;
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
		
		private function updateNode(collisionNode:RadialCollisionNode, time:Number):void
		{			
			var motion:Motion = collisionNode.motion;
			var bitmapCollider:BitmapCollider = collisionNode.bitmapCollider;
			var bitmapHitNode:RadialBitmapHitNode;
			var hitNode:RadialHitNode;
			var hitDisplay:Display;
			var hit:Boolean = false;

			collisionNode.collider.isHit = true;
			
			if(bitmapCollider.color != 0)
			{
				for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
				{					
					if(bitmapCollider.color == bitmapHitNode.bitmapHit.color)
					{
						reactToBitmapCollision(collisionNode, bitmapHitNode, time);
						collisionNode.currentHit.hit = bitmapHitNode.entity;
						EntityUtils.playAudioAction(collisionNode.hitAudio, bitmapHitNode.hitAudioData);
						hit = true;
						return;
					}
				}
			}

			bitmapCollider.lastRadialX = collisionNode.motion.x;
			bitmapCollider.lastRadialY = collisionNode.motion.y;
			
			for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				if (EntityUtils.sleeping(hitNode.entity))
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
				
				hitDisplay = hitNode.display;
				
				if (hitDisplay.displayObject.hitTestPoint(_shellApi.offsetX(collisionNode.motion.x), _shellApi.offsetY(collisionNode.motion.y), true))
				{
					reactToCollision(collisionNode, hitNode);
					collisionNode.currentHit.hit = hitNode.entity;
					EntityUtils.playAudioAction(collisionNode.hitAudio, hitNode.hitAudioData);
					return;
				}
			}
			
			collisionNode.collider.isHit = false;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_bitmapHits = systemManager.getNodeList(RadialBitmapHitNode);
			_hits = systemManager.getNodeList(RadialHitNode);
			_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			_hitAreaNode = _hitAreaNodes.head;
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			_hitAreaNode = null;
			_hitAreaNodes = null;
			_bitmapHits = null;
			_hits = null;
			
			systemManager.releaseNodeList(RadialCollisionNode);
			systemManager.releaseNodeList(RadialBitmapHitNode);
			systemManager.releaseNodeList(RadialHitNode);
			systemManager.releaseNodeList(BitmapHitAreaNode);

			super.removeFromEngine(systemManager);
		}
		
		/**
		 * This hittest checks for a 'ray' of pixels extending from the characters center in the direction and length of their velocity.
		 * @param collisionNode
		 * @param hitNode
		 * @param hitArea
		 * @param time
		 */
		private function reactToBitmapCollision(collisionNode:RadialCollisionNode, hitNode:RadialBitmapHitNode, time:Number):void
		{										
			var motion:Motion = collisionNode.motion;
			var bitmapCollider:BitmapCollider = collisionNode.bitmapCollider;
			var hit:Radial = hitNode.hit;	
			var velocity:Point = motion.velocity;
			var negativeIndex:Number = -1;
			var newTargetX:Number = bitmapCollider.hitX + (bitmapCollider.ratioX * negativeIndex);			
			var newTargetY:Number = bitmapCollider.hitY + (bitmapCollider.ratioY * negativeIndex);
			var newTargetX2:Number = bitmapCollider.hitX + (bitmapCollider.ratioX * -negativeIndex);			
			var newTargetY2:Number = bitmapCollider.hitY + (bitmapCollider.ratioY * -negativeIndex);
			var isHit:Boolean = true;
			var forceBack:Boolean = false;
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			
			while(isHit)
			{
				if(negativeIndex < -10)
				{
					forceBack = true;
					break;
				}
				
				negativeIndex--;
				
				isHit = true;
				
				if(hitArea.getPixel(newTargetX * hitAreaSpatial.scale + hitAreaSpatial.x, newTargetY * hitAreaSpatial.scale + hitAreaSpatial.y) == bitmapCollider.color)
				{
					newTargetX = bitmapCollider.hitX + (bitmapCollider.ratioX * negativeIndex);			
					newTargetY = bitmapCollider.hitY + (bitmapCollider.ratioY * negativeIndex);
				}
				else
				{
					isHit = false;
				}
				
				if(isHit)
				{
					if(hitArea.getPixel(newTargetX2 * hitAreaSpatial.scale + hitAreaSpatial.x, newTargetY2 * hitAreaSpatial.scale + hitAreaSpatial.y) == bitmapCollider.color)
					{
						newTargetX2 = bitmapCollider.hitX + (bitmapCollider.ratioX * -negativeIndex);			
						newTargetY2 = bitmapCollider.hitY + (bitmapCollider.ratioY * -negativeIndex);
					}
					else
					{
						isHit = false;
						newTargetX = newTargetX2;
						newTargetY = newTargetY2;
					}
				}
			}

			if(forceBack)
			{
				motion.zeroAcceleration();
				motion.x = bitmapCollider.lastRadialX;
				motion.y = bitmapCollider.lastRadialY;
			}
			else
			{
				var targetDeltaX:Number = newTargetX - bitmapCollider.hitX;
				var targetDeltaY:Number = newTargetY - bitmapCollider.hitY;
				
				bitmapCollider.hitX = newTargetX;
				bitmapCollider.hitY = newTargetY;
				
				motion.x += targetDeltaX;
				motion.y += targetDeltaY;
				
				bitmapCollider.lastRadialX = motion.x;
				bitmapCollider.lastRadialY = motion.y;
			}
			
			var collisionAngle:Number = getCollisionAngle(bitmapCollider.hitX, bitmapCollider.hitY, hitArea, bitmapCollider.color);
			var colCos:Number = Math.cos(collisionAngle);
			var colSin:Number = Math.sin(collisionAngle);
			var velX:Number = velocity.x;
			var velY:Number = velocity.y;
						
			//rotate velocity vector
			var vx1:Number = colCos * velX + colSin * velY;
			var vy1:Number = colCos * velY - colSin * velX;
			
			//_rebound with rotated vector
			vy1 *= -(hit.rebound + collisionNode.collider.rebound);
			
			//rotate back
			velocity.x = colCos*vx1 - colSin*vy1;
			velocity.y = colCos*vy1 + colSin*vx1;
			
			collisionNode.collider.angle = collisionAngle;

			if(canvas != null) { drawLine(bitmapCollider.hitX, bitmapCollider.hitY, 180 * collisionAngle/Math.PI); }
		}

		private function getCollisionAngle(x:Number, y:Number, hitArea:BitmapData, color:uint):Number 
		{
			var scanAngle:Number = 0;
			var bitmapHitArea:BitmapHitArea = _hitAreaNode.bitmapHitArea;
			var bx:Number = x + bitmapHitArea.hitTestRadius * Math.cos(scanAngle);
			var by:Number = y + bitmapHitArea.hitTestRadius * Math.sin(scanAngle);
			var hitting:Boolean = isRadialHit(bx, by);
			var numHits:Number = 0;
			var px1:Number = 0;
			var py1:Number = 0;
			var px2:Number = 0;
			var py2:Number = 0;
			
			while (scanAngle < 2*Math.PI) 
			{
				scanAngle += 2*Math.PI / bitmapHitArea.hitTestRadialSteps;
				bx = x + bitmapHitArea.hitTestRadius * Math.cos(scanAngle);
				by = y + bitmapHitArea.hitTestRadius * Math.sin(scanAngle);
				
				if (hitting != isRadialHit(bx, by)) 
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
		
		private function reactToCollision(collisionNode:RadialCollisionNode, hitNode:RadialHitNode):void
		{
			var angle:Number = hitNode.spatial.rotation * Math.PI / 180;
			var cos:Number = Math.cos(angle);
			var sin:Number = Math.sin(angle);
			var velocity:Point = collisionNode.motion.velocity;
			var x1:Number = collisionNode.motion.x - hitNode.spatial.x;
			var y1:Number = collisionNode.motion.y - hitNode.spatial.y;
			
			// Apply advanced coordinate rotation equation to find y position relative to a line with an angle of 0.
			var rotatedPosition:Point = new Point();
			rotate(rotatedPosition, x1, y1, sin, cos, true);

			var rotatedVelocity:Point = new Point();
			rotate(rotatedVelocity, velocity.x, velocity.y, sin, cos, true);
			var hitHeight:Number = hitNode.hit.height;
			
			//_rebound with rotated vector
			if(rotatedPosition.y < 0 && rotatedVelocity.y >= 0)
			{
				rotatedPosition.y = -hitHeight;
			}
			else if(rotatedPosition.y > 0 && rotatedVelocity.y <= 0)
			{
				rotatedPosition.y = hitHeight;
			}
			else
			{
				return;
			}

			rotatedVelocity.y *= -(hitNode.hit.rebound + collisionNode.collider.rebound);
			
			rotate(velocity, rotatedVelocity.x, rotatedVelocity.y, sin, cos);
			
			// Apply inverse of coordinate rotation to get the correct x/y and velocity with the angled line.
			x1 = cos * rotatedPosition.x - sin * rotatedPosition.y;
			y1 = cos * rotatedPosition.y + sin * rotatedPosition.x;
			
			collisionNode.motion.x = hitNode.spatial.x + x1;
			collisionNode.motion.y = hitNode.spatial.y + y1;
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
		
		private function drawLine(x:Number, y:Number, rotation:Number):void
		{
			if(_lines == null) { _lines = new Array(); }
			
			if(_lines[_lineCounter])
			{
				canvas.removeChild(_lines[_lineCounter]);
			}
			
			var spr:Sprite = new Sprite();
			spr.x = x;
			spr.y = y;
			spr.rotation = rotation;
			
			spr.graphics.lineStyle(2,0xff0000);
			spr.graphics.moveTo(-10, 0);
			spr.graphics.lineTo(10, 0);
			
			canvas.addChild(spr);
			
			_lines[_lineCounter] = spr;
			
			_lineCounter++;
			
			if(_lineCounter > 10)
			{
				_lineCounter = 0;
			}
		}
		
		// A way to visualize the hit vector for debugging.
		private function drawPoint(x:Number, y:Number):void
		{
			canvas.graphics.lineStyle(4, 0x0000ff);
			canvas.graphics.moveTo(x, y);
			canvas.graphics.lineTo(x + 1, y + 1);
		}
						
		private function isRadialHit(x:Number, y:Number):Boolean
		{
			var bitmapHitNode:RadialBitmapHitNode;
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			var hitColor:uint = hitArea.getPixel(x * hitAreaSpatial.scale + hitAreaSpatial.x, y * hitAreaSpatial.scale + hitAreaSpatial.y);
			var closestColor:uint;
			
			if(hitColor != 0)
			{
				if(this.colors)
				{
					closestColor = ColorUtil.rgbVectorToHex(ColorUtil.getClosestColor(ColorUtil.hexToRgb(hitColor), this.colors));
				}
				else
				{
					closestColor = hitColor;
				}
				
				for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next)
				{					
					if(closestColor == bitmapHitNode.bitmapHit.color)
					{
						return(true);
					}
				}
			}
			
			return(false);
		}
		
		public var canvas:Sprite;
		public var colors:Vector.<Vector.<uint>>;
		private var _hitAreaNode:BitmapHitAreaNode;
		private var _hitAreaNodes:NodeList;
		private var _bitmapHits:NodeList;
		private var _lineCounter:int = 0;
		private var _lines:Array;
		private var _hits:NodeList;
		[Inject]
		public var _shellApi:ShellApi;
	}
}
