package game.systems.render
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.render.Reflection;
	import game.components.render.Reflective;
	import game.nodes.render.ReflectionNode;
	import game.nodes.render.ReflectiveNode;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.systems.SystemPriorities;
	
	/**
	 * Author: Drew Martin
	 */
	public class ReflectionSystem extends System
	{
		private var reflections:NodeList;
		private var reflectives:NodeList;
		
		public var sortWaitTime:Number;
		private var sortElapsedTime:Number = 0;
		
		public function ReflectionSystem(sortWaitTime:Number = 0.5)
		{
			this.sortWaitTime = sortWaitTime;
			this._defaultPriority = SystemPriorities.postRender;
		}
		
		override public function update(time:Number):void
		{
			/**
			 * SortByIndex() is used to sort what Display Objects are in front/back of others so they can be drawn to
			 * the Reflective surface in order of depth. We don't want to be doing this all the time though.
			 */
			this.sortElapsedTime += time;
			if(this.sortElapsedTime >= this.sortWaitTime)
			{
				this.sortElapsedTime -= this.sortWaitTime;
				this.reflections.insertionSort(this.sortByIndex);
			}
			
			for(var reflectiveNode:ReflectiveNode = this.reflectives.head; reflectiveNode; reflectiveNode = reflectiveNode.next)
			{
				if(EntityUtils.sleeping(reflectiveNode.entity)) continue;
				
				var reflective:Reflective = reflectiveNode.reflective;
				
				//Acts as a "refresh time" so reflections aren't updated on EVERY system update loop.
				reflective.elapsedTime += time;
				if(reflective.elapsedTime < reflective.waitTime) continue;
				reflective.elapsedTime = 0;
				
				//Clear the bitmap data to redraw reflections again.
				var bitmap:Bitmap = reflectiveNode.display.displayObject;
				var data:BitmapData = bitmap.bitmapData;
				data.fillRect(data.rect, 0);
				
				var x:Number = reflective.offsetX;
				var y:Number = reflective.offsetY;
				
				var reflectionNode:ReflectionNode;
				var reflection:Reflection;
				var display:DisplayObject;
				var point:Point;
				
				switch(reflective.surface)
				{
					case Reflective.SURFACE_BACK:
						/**
						 * Reflections will happen directly behind Entities. These are "back wall" reflections where
						 * moving in any direction causes the reflection to follow the Entity. These typically get an
						 * offset to move reflections slightly away from Entities.
						 */
						for(reflectionNode = this.reflections.tail; reflectionNode; reflectionNode = reflectionNode.previous)
						{
							reflection = reflectionNode.reflection;
							if(!canDraw(reflectionNode.entity, reflection, reflective)) continue;
							
							display = reflectionNode.display.displayObject;
							point = DisplayUtils.localToLocal(display, bitmap.parent);
							
							this.draw(display, reflection, data, 1, 1, (point.x - bitmap.x) + x, (point.y - bitmap.y) + y);
						}
						break;
					
					case Reflective.SURFACE_UP:
						/**
						 * Reflections will happen above Entities. These are "ceiling" reflections where moving
						 * up moves the reflection closer to the Entity, and moving down moves the reflection
						 * farther away from the Entity.
						 */
						for(reflectionNode = this.reflections.head; reflectionNode; reflectionNode = reflectionNode.next)
						{
							reflection = reflectionNode.reflection;
							if(!canDraw(reflectionNode.entity, reflection, reflective)) continue;
							
							display = reflectionNode.display.displayObject;
							point = DisplayUtils.localToLocal(display, bitmap.parent);
							
							this.draw(display, reflection, data, 1, -1, (point.x - bitmap.x) + x, (data.height * 2) + (bitmap.y - point.y) + y);
						}
						break;
					
					case Reflective.SURFACE_DOWN:
						/**
						 * Reflections will happen below Entities. These are "floor" reflections where moving
						 * down moves the reflection closer to the Entity, and moving up moves the reflection
						 * farther away from the Entity.
						 */
						for(reflectionNode = this.reflections.head; reflectionNode; reflectionNode = reflectionNode.next)
						{
							reflection = reflectionNode.reflection;
							if(!canDraw(reflectionNode.entity, reflection, reflective)) continue;
							
							display = reflectionNode.display.displayObject;
							point = DisplayUtils.localToLocal(display, bitmap.parent);
							
							this.draw(display, reflection, data, 1, -1, (point.x - bitmap.x) + x, (bitmap.y - point.y) + y);
						}
						break;
					
					case Reflective.SURFACE_LEFT:
						/**
						 * Reflections will happen to the left of Entities. These are "left wall" reflections where moving
						 * to the left moves the reflection closer to the Entity, and moving right moves the reflection
						 * farther away from the Entity.
						 */
						for(reflectionNode = this.reflections.tail; reflectionNode; reflectionNode = reflectionNode.previous)
						{
							reflection = reflectionNode.reflection;
							if(!canDraw(reflectionNode.entity, reflection, reflective)) continue;
							
							display = reflectionNode.display.displayObject;
							point = DisplayUtils.localToLocal(display, bitmap.parent);
							
							this.draw(display, reflection, data, -1, 1, (data.width * 2) - (point.x - bitmap.x) + x, (point.y - bitmap.y) + y);
						}
						break;
					
					case Reflective.SURFACE_RIGHT:
						/**
						 * Reflections will happen to the right of Entities. These are "right wall" reflections where moving
						 * to the right moves the reflection closer to the Entity, and moving left moves the reflection
						 * farther away from the Entity.
						 */
						for(reflectionNode = this.reflections.tail; reflectionNode; reflectionNode = reflectionNode.previous)
						{
							reflection = reflectionNode.reflection;
							if(!this.canDraw(reflectionNode.entity, reflection, reflective)) continue;
							
							display = reflectionNode.display.displayObject;
							point = DisplayUtils.localToLocal(display, bitmap.parent);
							
							this.draw(display, reflection, data, -1, 1, (bitmap.x - point.x) + x, (point.y - bitmap.y) + y);
						}
						break;
				}
			}
		}
		
		/**
		 * Determines whether an Entity can be drawn to a Reflective surface. If the Entity is asleep or the Reflection
		 * types does not contain the Reflective's type, it is not drawn.
		 */
		private function canDraw(entity:Entity, reflection:Reflection, reflective:Reflective):Boolean
		{
			if(EntityUtils.sleeping(entity)) 		return false;
			if(!reflection.types[reflective.type]) 	return false;
			return true;
		}
		
		/**
		 * Draws an Entity's Display Object to a Reflective Bitmap.
		 */
		private function draw(display:DisplayObject, reflection:Reflection, data:BitmapData, scaleX:int, scaleY:int, tx:Number, ty:Number):void
		{
			var matrix:Matrix = display.transform.matrix;
			matrix.scale(scaleX, scaleY);
			matrix.tx = tx;
			matrix.ty = ty;
			
			data.draw(display, matrix, reflection.colorTransform, reflection.blendMode, reflection.clipRect);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.reflections = systemManager.getNodeList(ReflectionNode);
			this.reflectives = systemManager.getNodeList(ReflectiveNode);
			
			this.reflections.insertionSort(this.sortByIndex);
			this.reflections.nodeAdded.add(this.reflectionNodeAdded);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(ReflectionNode);
			systemManager.releaseNodeList(ReflectiveNode);
			
			this.reflections = null;
			this.reflectives = null;
		}
		
		private function reflectionNodeAdded(node:ReflectionNode):void
		{
			this.reflections.insertionSort(this.sortByIndex);
		}
		
		/**
		 * Currently this system assumes that all Reflection Nodes are in the same Display Object Container.
		 * Will need to fix this later.
		 */
		private function sortByIndex(node1:ReflectionNode, node2:ReflectionNode):Number
		{
			var index1:int = node1.display.displayObject.parent.getChildIndex(node1.display.displayObject);
			var index2:int = node2.display.displayObject.parent.getChildIndex(node2.display.displayObject);
			
			return (index1 > index2) ? -1 : 1;
		}
	}
}