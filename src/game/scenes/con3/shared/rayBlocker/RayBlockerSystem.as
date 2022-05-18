package game.scenes.con3.shared.rayBlocker
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.con3.shared.rayCollision.RayCollisionNode;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	import game.util.Utils;
	
	public class RayBlockerSystem extends System
	{
		private var _rays:NodeList;
		private var _blockers:NodeList;
		
		public function RayBlockerSystem()
		{
			super();
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function update(time:Number):void
		{
			var blockerNode:RayBlockerNode;
			
			for(blockerNode = this._blockers.head; blockerNode; blockerNode = blockerNode.next)
			{
				if(blockerNode.blocker.particles)
				{
					Display(blockerNode.blocker.particles.get(Display)).visible = false;
				}
			}
			
			for(var rayNode:RayCollisionNode = this._rays.head; rayNode; rayNode = rayNode.next)
			{
				var rayDisplay:DisplayObject = rayNode.display.displayObject;
				
				var closestBlockerNode:RayBlockerNode = null;
				var burnPoint:Point = null;
				
				if(rayNode.ray.length == 0) continue;
				
				for(blockerNode = this._blockers.head; blockerNode; blockerNode = blockerNode.next)
				{
					var rectangle:Rectangle = collisionRect(rayNode.rayCollision.shape, blockerNode.blocker._shape, true);
					
					if(!rectangle.isEmpty())
					{
						var point:Point = new Point(rectangle.x + rectangle.width/2, rectangle.y + rectangle.height/2);
						point = DisplayUtils.localToLocalPoint(point, rayDisplay.stage, rayDisplay.parent);
						
						var distance:Number = Utils.distance(rayDisplay.x, rayDisplay.y, point.x, point.y);
						
						if(distance < rayNode.rayCollision.length)
						{
							rayNode.rayCollision.length = distance;
							closestBlockerNode = blockerNode;
							
							burnPoint = DisplayUtils.localToLocalPoint(point, rayDisplay.parent, blockerNode.display.displayObject.parent);
						}
					}
				}
				
				if(closestBlockerNode)
				{
					if(closestBlockerNode.blocker.particles)
					{
						var laserSpatial:Spatial = closestBlockerNode.blocker.particles.get(Spatial);
						laserSpatial.x = burnPoint.x;
						laserSpatial.y = burnPoint.y;
						
						Display(closestBlockerNode.blocker.particles.get(Display)).visible = true;
					}
					
					if(rayNode.entityIdList.entities.indexOf(closestBlockerNode.id.id) == -1)
					{
						rayNode.entityIdList.entities.push(closestBlockerNode.id.id);
					}
					
					if(closestBlockerNode.entityIdList.entities.indexOf(rayNode.id.id) == -1)
					{
						closestBlockerNode.entityIdList.entities.push(rayNode.id.id);
					}
				}
			}
		}
		
		private function collisionRect(display1:DisplayObject, display2:DisplayObject, precise:Boolean = false, tolerance:int = 255):Rectangle
		{
			const rect1:Rectangle = display1.getBounds(display1.stage);
			const rect2:Rectangle = display2.getBounds(display2.stage);
			
			const intersection:Rectangle = rect1.intersection(rect2);
			
			if(!precise) return intersection;
			
			intersection.x 		= Math.floor(intersection.x);
			intersection.y 		= Math.floor(intersection.y);
			intersection.width 	= Math.ceil(intersection.width);
			intersection.height = Math.ceil(intersection.height);
			
			if(intersection.isEmpty()) return intersection;
			
			const data:BitmapData = new BitmapData(intersection.width, intersection.height, false);
			
			var matrix:Matrix = display1.transform.concatenatedMatrix;
			matrix.translate(-intersection.left, -intersection.top);
			
			data.draw(display1, matrix, new ColorTransform(1, 1, 1, 1, 255, -255, -255, tolerance), BlendMode.NORMAL);
			
			matrix = display2.transform.concatenatedMatrix;
			matrix.translate(-intersection.left, -intersection.top);
			
			data.draw(display2, matrix, new ColorTransform(1, 1, 1, 1, 255, 255, 255, tolerance), BlendMode.DIFFERENCE);
			
			const overlap:Rectangle = data.getColorBoundsRect(0xFFFFFFFF, 0xFF00FFFF);
			overlap.offset(intersection.left, intersection.top);
			
			data.dispose();
			
			return overlap;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this._rays = systemManager.getNodeList(RayCollisionNode);
			
			this._blockers = systemManager.getNodeList(RayBlockerNode);
			for(var blockerNode:RayBlockerNode = this._blockers.head; blockerNode; blockerNode = blockerNode.next)
			{
				this.blockerNodeAdded(blockerNode);
			}
			this._blockers.nodeAdded.add(this.blockerNodeAdded);
			this._blockers.nodeRemoved.add(this.blockerNodeRemoved);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(RayBlockerNode);
			
			this._rays = null;
			this._blockers = null;
		}
		
		private function blockerNodeAdded(node:RayBlockerNode):void
		{
			node.display.displayObject.addChild(node.blocker._shape);
		}
		
		private function blockerNodeRemoved(node:RayBlockerNode):void
		{
			node.display.displayObject.removeChild(node.blocker._shape);
		}
	}
}