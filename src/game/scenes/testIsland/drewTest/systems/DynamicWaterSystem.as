package game.scenes.testIsland.drewTest.systems
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.testIsland.drewTest.classes.SurfacePoint;
	import game.scenes.testIsland.drewTest.nodes.DynamicWaterNode;
	import game.scenes.testIsland.drewTest.nodes.SplasherNode;
	
	public class DynamicWaterSystem extends System
	{
		private var waters:NodeList;
		private var splashers:NodeList;
		
		public function DynamicWaterSystem()
		{
			
		}
		
		override public function update(time:Number):void
		{
			for(var water:DynamicWaterNode = waters.head; water; water = water.next)
			{
				this.updateWater(water, time);
				
				for(var splasher:SplasherNode = splashers.head; splasher; splasher = splasher.next)
				{
					if(Math.abs(splasher.motion.velocity.y) < 5) continue;
					
					if(!splasher.splash.hasSplashed &&
						splasher.display.displayObject.hitTestObject(water.display.displayObject))
					{
						splasher.splash.hasSplashed = true;
						
						this.createWave(water, splasher);
						
						trace("In!");
					}
					else if(splasher.splash.hasSplashed &&
						!splasher.display.displayObject.hitTestObject(water.display.displayObject))
					{
						splasher.splash.hasSplashed = false;
						
						trace("Out!");
					}
				}
			}
		}
		
		private function createWave(water:DynamicWaterNode, splasher:SplasherNode):void
		{
			water.water.resetSurface = true;
			
			var magnitude:Point = new Point();
			magnitude.x = water.water.magnitudeFactor * splasher.motion.velocity.x;
			magnitude.y = water.water.magnitudeFactor * splasher.motion.velocity.y;
			
			
			var speed:Number = water.water.speedFactor * splasher.motion.velocity.y;
			
			var velocityY:Number = splasher.motion.velocity.y;
			
			for(var i:uint = 0; i < water.water.points.size; i++)
			{
				var surface:SurfacePoint = water.water.points.itemAt(i);
				surface.isMoving = true;
				
				var value:Number = 1000;
				
				var distance:Number = Math.abs(splasher.spatial.x - surface.point.x);
				if(distance > value) distance = value;
				
				surface.magnitude.y += magnitude.y * ((distance - value) / -value);
				//surface.magnitude.x += -magnitude.x * ((distance - value) / -value) / 2;
				surface.speed = speed * ((distance - value) / -value);
			}
			/**
			 * Do some Math.abs() distance calculations for surface points around the contanct point.
			 */
			
			
			/*for(var i:uint = 0; i < water.water.points.size; i++)
			{
				var surface:SurfacePoint = water.water.points.itemAt(i);
				surface.isMoving = true;
				
				surface.magnitude = water.water.magnitudeFactor * splasher.motion.velocity.y;
				//if(surface.magnitude > water.water.maxMagnitude) surface.magnitude = water.water.maxMagnitude;
				
				surface.speed = water.water.speedFactor * splasher.motion.velocity.y;
				//if(surface.speed > water.water.maxSpeed) surface.speed = water.water.maxSpeed;
			}*/
		}
		
		private function updateWater(water:DynamicWaterNode, time:Number):void
		{
			this.resetSurfacePoints(water);
			
			this.updateSurfacePoints(water, time);
			
			this.drawWater(water);
		}
		
		private function updateSurfacePoints(water:DynamicWaterNode, time:Number):void
		{
			if(!water.water.resetSurface) return;
			
			water.water.resetSurface = false;
			
			for(var i:uint = 0; i < water.water.points.size; i++)
			{
				var surface:SurfacePoint = water.water.points.itemAt(i);
				
				if(updateSurfaceDecay(surface, time, water))
				{
					water.water.resetSurface = true;
					
					this.updateSurfaceTime(surface, time);
					
					this.updateSurfacePoint(surface, water);
				}
			}
		}
		
		private function updateSurfaceDecay(surface:SurfacePoint, time:Number, water:DynamicWaterNode):Boolean
		{
			
			surface.magnitude.y -= water.water.magnitudeDecay * time;
			if(surface.magnitude.y < water.water.minMagnitude) surface.magnitude.y = water.water.minMagnitude;
			
			//surface.speed -= water.water.speedDecay * time;
			//if(surface.speed < water.water.minSpeed) surface.speed = water.water.minSpeed;
			
			if(surface.magnitude.y == water.water.minMagnitude /*&& surface.speed == water.water.minSpeed*/ &&
				Math.abs(surface.point.y - surface.center.y) < 1)
			{
				surface.isMoving = false;
				//surface.speed = 0;
				surface.magnitude.x = 0;
				surface.magnitude.y = 0;;
				surface.time = 0;
				surface.point.y = surface.center.y;
			}
			
			return surface.isMoving;
		}
		
		private function updateSurfaceTime(surface:SurfacePoint, time:Number):void
		{
			surface.time += time * surface.speed;
			
			while(surface.time >= Math.PI * 2)
				surface.time -= Math.PI * 2;
		}
		
		private function updateSurfacePoint(surface:SurfacePoint, water:DynamicWaterNode):void
		{
			surface.point.y = surface.center.y + Math.sin(surface.time) * surface.magnitude.y;
			surface.point.x = surface.center.x + Math.cos(surface.time) * surface.magnitude.x;
		}
		
		private function resetSurfacePoints(water:DynamicWaterNode):void
		{
			if(!water.water.resetPoints) return;
			
			/**
			 * The reason this needs to be done...
			 * In order to curve to the final point to make up numPoints, the curved line needs to draw to a point,
			 * but that point isn't actually
			 */
			var offsetX:Number = water.water.box.width / (Number(water.water.numPoints) - 1);
			//offsetX = (water.water.box.width + (offsetX * 0.5)) / (Number(node.water.numPoints) - 1);
			
			for(var i:uint = 0; i < water.water.numPoints; i++)
			{
				var x:Number = water.water.box.left + offsetX * i;
				var y:Number = water.water.box.bottom - water.water.height;
				
				var surface:SurfacePoint = new SurfacePoint(x, y);
				water.water.points.add(surface);
			}
			
			water.water.resetPoints = false;
			this.drawWater(water);
		}
		
		private function drawWater(water:DynamicWaterNode):void
		{
			if(!water.water.resetSurface) return;
			//trace("Draw");
			
			var graphics:Graphics = Sprite(water.display.displayObject).graphics;
			
			graphics.clear();
			graphics.beginFill(0x0066FF, 0.35);
			
			var first:SurfacePoint = water.water.points.first;
			
			graphics.moveTo(first.point.x, first.point.y);
			
			for(var i:uint = 0; i < water.water.points.size - 1; i++)
			{
				var current:SurfacePoint = water.water.points.itemAt(i);
				
				var next:SurfacePoint = water.water.points.itemAt(i + 1);
				
				
				var mX:Number = (current.point.x + next.point.x) / 2;
				var mY:Number = (current.point.y + next.point.y) / 2;
				graphics.curveTo(current.point.x, current.point.y, mX, mY);
				
				
				//graphics.lineTo(next.point.x, next.point.y);
			}
			
			graphics.lineTo(water.water.box.right, water.water.box.bottom);
			graphics.lineTo(water.water.box.left, water.water.box.bottom);
			
			graphics.lineTo(first.point.x, first.point.y);
			graphics.endFill();
		}
		
		override public function addToEngine(system:Engine):void
		{
			this.waters = system.getNodeList(DynamicWaterNode);
			this.splashers = system.getNodeList(SplasherNode);
		}
		
		override public function removeFromEngine(system:Engine):void
		{
			system.releaseNodeList(DynamicWaterNode);
			system.releaseNodeList(SplasherNode);
			this.waters = null;
			this.splashers = null;
		}
	}
}