package game.scenes.con3.shared.rayReflect
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Id;
	
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.con3.shared.Ray;
	import game.scenes.con3.shared.Vector2D;
	import game.scenes.con3.shared.rayCollision.RayCollision;
	import game.scenes.con3.shared.rayRender.RayRender;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.Utils;
	
	public class RayReflectSystem extends System
	{
		private var _rays:NodeList;
		private var _reflects:NodeList;
		
		public function RayReflectSystem()
		{
			super();
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function update(time:Number):void
		{
			for(var rayNode:RayToReflectCollisionNode = this._rays.head; rayNode; rayNode = rayNode.next)
			{
				var rayDisplay:DisplayObject = rayNode.display.displayObject;
				
				//Thanks to AS3's variable "hoisting", this must be set to null on every loop, even though technically it should be a "new" variable every loop.
				var closestReflectNode:ReflectToRayCollisionNode = null;
				
				if(rayNode.ray.length != 0)
				{
					for(var reflectNode:ReflectToRayCollisionNode = this._reflects.head; reflectNode; reflectNode = reflectNode.next)
					{
						//Don't do collision detection on the ray's source reflector.
						if(rayNode.rayToReflectCollision._childReflect == reflectNode) continue;
						
						var rectangle:Rectangle = collisionRect(rayNode.rayCollision.shape, reflectNode.reflectoToRay._shape, true);
						
						if(!rectangle.isEmpty())
						{
							var point:Point = new Point(rectangle.x + rectangle.width/2, rectangle.y + rectangle.height/2);
							point = DisplayUtils.localToLocalPoint(point, rayDisplay.stage, rayDisplay.parent);
							
							var distance:Number = Utils.distance(rayDisplay.x, rayDisplay.y, point.x, point.y);
							
							if(distance < rayNode.rayCollision.length)
							{
								rayNode.rayCollision.length = distance;
								closestReflectNode = reflectNode;
							}
						}
					}
				}
				
				var previousParentReflect:ReflectToRayCollisionNode = rayNode.rayToReflectCollision._parentReflect;
				rayNode.rayToReflectCollision._parentReflect = closestReflectNode;
				
				if(closestReflectNode)
				{
					if(rayNode.entityIdList.entities.indexOf(closestReflectNode.id.id) == -1)
					{
						rayNode.entityIdList.entities.push(closestReflectNode.id.id);
					}
					
					if(closestReflectNode.entityIdList.entities.indexOf(rayNode.id.id) == -1)
					{
						closestReflectNode.entityIdList.entities.push(rayNode.id.id);
					}
					
					if(rayNode.rayToReflectCollision._parentReflect != previousParentReflect)
					{
						const sprite:Sprite = new Sprite();
						sprite.mouseChildren = false;
						sprite.mouseEnabled = false;
						rayDisplay.parent.addChild(sprite);
						var entity:Entity = EntityUtils.createSpatialEntity(rayNode.entity.group, sprite);
						
						entity.add(new Ray());
						entity.add(new RayRender(1000, rayNode.render.color, rayNode.render.thickness));
						entity.add(new RayCollision());
						entity.add(new EntityIdList());
						entity.add(new Id(entity.name));
						
						var collision:RayToReflectCollision = new RayToReflectCollision();
						collision._parent = rayNode;
						collision._childReflect = closestReflectNode;
						entity.add(collision);
					}
				}
				
				if(rayNode.rayToReflectCollision._parent)
				{
					if(rayNode.rayToReflectCollision._parent.rayToReflectCollision._parentReflect == rayNode.rayToReflectCollision._childReflect)
					{
						var parentCollision:RayCollision = rayNode.rayToReflectCollision._parent.rayCollision;
						var parentDisplay:DisplayObject = rayNode.rayToReflectCollision._parent.display.displayObject;
						
						var parentRadians:Number = GeomUtils.degreeToRadian(parentDisplay.rotation);
						
						rayNode.spatial.x = parentDisplay.x + Math.cos(parentRadians) * parentCollision.length;
						rayNode.spatial.y = parentDisplay.y + Math.sin(parentRadians) * parentCollision.length;
						
						//Thanks kirupa forums! http://www.kirupa.com/forum/showthread.php?304518-How-to-retrieve-global-rotation
						var reflectDisplay:DisplayObject = rayNode.rayToReflectCollision._childReflect.display.displayObject;
						var point1:Point = DisplayUtils.localToLocalPoint(new Point(), reflectDisplay, parentDisplay.parent);
						var point2:Point = DisplayUtils.localToLocalPoint(new Point(0, 100), reflectDisplay, parentDisplay.parent);
						var reflectRadians:Number = -Math.atan2(point1.x - point2.x, point1.y - point2.y);
						
						var reflectVector:Vector2D = new Vector2D(1, 0);
						var rayVector:Vector2D = new Vector2D(1, 0);
						
						reflectVector.setRadians(reflectRadians/* + Math.PI/2*/);
						rayVector.setRadians(parentRadians + Math.PI);
						
						rayNode.spatial.rotation = rayVector.reflect(reflectVector.normalize()).degrees;
					}
					else
					{
						rayNode.entity.group.removeEntity(rayNode.entity);
						return;
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
			this._rays = systemManager.getNodeList(RayToReflectCollisionNode);
			this._rays.nodeRemoved.add(this.rayCollisionNodeRemoved);
			
			this._reflects = systemManager.getNodeList(ReflectToRayCollisionNode);
			for(var reflectCollisionNode:ReflectToRayCollisionNode = this._reflects.head; reflectCollisionNode; reflectCollisionNode = reflectCollisionNode.next)
			{
				this.reflectCollisionNodeAdded(reflectCollisionNode);
			}
			this._reflects.nodeAdded.add(reflectCollisionNodeAdded);
			this._reflects.nodeRemoved.add(reflectCollisionNodeRemoved);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(RayToReflectCollisionNode);
			systemManager.releaseNodeList(ReflectToRayCollisionNode);
			
			this._rays = null;
			this._reflects = null;
		}
		
		private function reflectCollisionNodeAdded(node:ReflectToRayCollisionNode):void
		{
			node.reflectoToRay._shape.visible = false;
			node.display.displayObject.addChild(node.reflectoToRay._shape);
		}
		
		private function reflectCollisionNodeRemoved(node:ReflectToRayCollisionNode):void
		{
			if(node.reflectoToRay._shape.parent)
			{
				node.reflectoToRay._shape.parent.removeChild(node.reflectoToRay._shape);
			}
		}
		
		private function rayCollisionNodeRemoved(node:RayToReflectCollisionNode):void
		{
			for(var rayNode:RayToReflectCollisionNode = this._rays.head; rayNode; rayNode = rayNode.next)
			{
				if(rayNode.rayToReflectCollision._parent == node)
				{
					rayNode.entity.group.removeEntity(rayNode.entity);
				}
			}
			
			node.rayToReflectCollision._childReflect = null;
			node.rayToReflectCollision._parent = null;
			node.rayToReflectCollision._parentReflect = null;
		}
	}
}