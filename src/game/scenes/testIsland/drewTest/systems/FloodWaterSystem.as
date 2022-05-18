package game.scenes.testIsland.drewTest.systems
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	import game.scenes.testIsland.drewTest.classes.WaterPoint;
	import game.scenes.testIsland.drewTest.nodes.FloodWaterNode;
	import game.systems.GameSystem;
	import game.util.Utils;
	
	public class FloodWaterSystem extends GameSystem
	{
		public function FloodWaterSystem()
		{
			super(FloodWaterNode, updateNode);
		}
		
		public function updateNode(node:FloodWaterNode, time:Number):void
		{
			this.updateTime(node, time);
			
			this.updateHeight(node);
			
			this.updatePoints(node, time);
		}
		
		private function updateTime(node:FloodWaterNode, time:Number):void
		{
			node.water.time += time * node.water.speed;
			
			while(node.water.time >= Math.PI * 2)
				node.water.time -= Math.PI * 2;
		}
		
		private function updateHeight(node:FloodWaterNode):void
		{
			var height:Number = Math.sin(node.water.time) * node.water.magnitude;
			node.water.height += height;
		}
		
		private function updatePoints(node:FloodWaterNode, time:Number):void
		{
			this.resetPoints(node);
			
			var waterHeight:Number = node.water.box.bottom - node.water.height;
			
			for(var i:uint = 0; i < node.water.points.size; i++)
			{
				var water:WaterPoint = node.water.points.itemAt(i);
				
				this.updateWaterTime(water, time);
				
				this.updateWaterHeight(water, waterHeight);
			}
			
			this.drawWater(node);
		}
		
		private function updateWaterTime(water:WaterPoint, time:Number):void
		{
			water.time += time * Utils.randInRange(2, 10);
				
			while(water.time >= Math.PI * 2)
				water.time -= Math.PI * 2;
		}
		
		private function updateWaterHeight(water:WaterPoint, waterHeight:Number):void
		{
			water.point.y = waterHeight + Math.sin(water.time) * water.magnitude;
		}
		
		private function resetPoints(node:FloodWaterNode):void
		{
			if(!node.water.resetPoints) return;
			
			/**
			 * The reason this needs to be done...
			 * In order to curve to the final point to make up numPoints, the curved line needs to draw to a point,
			 * but that point isn't actually
			 */
			var offsetX:Number = node.water.box.width / (Number(node.water.numPoints) - 1);
			offsetX = (node.water.box.width + (offsetX * 0.5)) / (Number(node.water.numPoints) - 1);
			
			for(var i:uint = 0; i < node.water.numPoints; i++)
			{
				var x:Number = node.water.box.left + offsetX * i;
				var y:Number = node.water.box.bottom - node.water.height;
				
				var water:WaterPoint = new WaterPoint(x, y);
				//water.time = i * ((Math.PI * 2) / node.flood.numPoints);
				node.water.points.add(water);
			}
			
			node.water.resetPoints = false;
		}
		
		private function drawWater(node:FloodWaterNode):void
		{
			var graphics:Graphics = Sprite(node.display.displayObject).graphics;
			
			graphics.clear();
			graphics.beginFill(0x0066FF, 0.5);
			
			var first:WaterPoint = node.water.points.first;
			var current:WaterPoint = node.water.points.first;
			var next:WaterPoint;
			graphics.moveTo(first.point.x, first.point.y);
			
			for(var i:uint = 0; i < node.water.points.size - 1; i++)
			{
				current = node.water.points.itemAt(i);
				next = node.water.points.itemAt(i + 1);
				
				var mX:Number = (current.point.x + next.point.x) / 2;
				var mY:Number = (current.point.y + next.point.y) / 2;
				graphics.curveTo(current.point.x, current.point.y, mX, mY);
				//graphics.lineTo(current.x, current.y);
			}
			
			graphics.lineTo(node.water.box.right, node.water.box.bottom);
			graphics.lineTo(node.water.box.left, node.water.box.bottom);
			
			current = node.water.points.first;
			graphics.lineTo(first.point.x, first.point.y);
			graphics.endFill();
		}
	}
}