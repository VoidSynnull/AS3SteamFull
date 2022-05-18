package game.scenes.testIsland.drewTest.systems
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import game.scenes.testIsland.drewTest.classes.WindLine;
	import game.scenes.testIsland.drewTest.nodes.WindNode;
	import game.systems.GameSystem;
	import game.util.Utils;
	
	public class WindSystem extends GameSystem
	{
		public function WindSystem()
		{
			super(WindNode, updateNode);
		}
		
		public function updateNode(node:WindNode, time:Number):void
		{
			this.updateWindLines(node, time);
			
			this.drawWind(node);
		}
		
		private function updateWindLines(node:WindNode, time:Number):void
		{
			this.initializeWindLines(node);
			this.updateWindLineCount(node);
			
			for(var i:uint = 0; i < node.wind.windLines.size; i++)
			{
				var line:WindLine = node.wind.windLines.itemAt(i);
				
				switch(line.state)
				{
					case WindLine.INIT_STATE: this.initializeWindLine(line, node); 			break;
					case WindLine.MOVE_STATE: this.updateWindLineMove(line, time, node); 	break;
					case WindLine.SPIN_STATE: this.updateWindLineSpin(line, time, node);	break;
				}
			}
		}
		
		private function initializeWindLines(node:WindNode):void
		{
			if(!node.wind.initializeWindLines) return;
			
			while(node.wind.windLines.size < node.wind.numWindLines)
				this.createWindLine(node, null);
			
			node.wind.initializeWindLines = false;
		}
		
		private function updateWindLineCount(node:WindNode):void
		{
			while(node.wind.dead.length > 0)
			{
				var line:WindLine = node.wind.dead.pop();
				
				if(node.wind.windLines.size > node.wind.numWindLines)
					node.wind.windLines.remove(line);
				else this.createWindLine(node, line);
			}
			
			while(node.wind.windLines.size < node.wind.numWindLines)
				this.createWindLine(node, null);
		}
		
		private function initializeWindLine(line:WindLine, node:WindNode):void
		{
			/**
			 * Fix this later, since the Wind might be coming from the left or right. Might
			 * do up and down later if it makes sense.
			 */
			var x:Number = node.wind.box.left;
			var y:Number = Utils.randNumInRange(node.wind.box.top, node.wind.box.bottom);
			
			if(line.points.size > line.numPoints)
			{
				while(line.points.size > line.numPoints)
					line.points.removeAt(line.numPoints);
			}
			else if(line.points.size < line.numPoints)
			{
				while(line.points.size < line.numPoints)
					line.points.add(new Point());
			}
			
			for(var i:uint = 0; i < line.points.size; i++)
			{
				var point:Point = line.points.itemAt(i);
				point.x = x;
				point.y = y;
			}
			
			line.state = WindLine.MOVE_STATE;
		}
		
		private function updateWindLineMove(line:WindLine, time:Number, node:WindNode):void
		{
			var front:Point;
			var back:Point;
			
			for(var i:uint = line.points.size - 1; i > 0; i--)
			{
				front = line.points.itemAt(i - 1);
				back = line.points.itemAt(i);
				
				back.x = front.x;
				back.y = front.y;
			}
			
			front = line.points.first;
			front.x += line.speed * time;
			
			front.y += line.offsetY;
			
			line.time += time;
			if(line.time > 0.1)
			{
				line.offsetY = (Math.random() - 0.5) * 5;
				line.time = 0;
			}
			
			back = line.points.last;
			if(back.x >= node.wind.box.right)
				node.wind.dead.push(line);
		}
		
		private function updateWindLineSpin(line:WindLine, time:Number, node:WindNode):void
		{
			
		}
		
		private function createWindLine(node:WindNode, line:WindLine):void
		{
			var numPoints:int = Utils.randInRange(node.wind.minWindLinePoints, node.wind.maxWindLinePoints);
			var speed:Number = Utils.randNumInRange(node.wind.minSpeed, node.wind.maxSpeed);
			
			if(line)
			{
				line.numPoints = numPoints;
				line.speed = speed;
				line.state = WindLine.INIT_STATE;
			}
			else
			{
				line = new WindLine(numPoints, speed);
				node.wind.windLines.add(line);
			}
		}
		
		private function drawWind(node:WindNode):void
		{
			var graphics:Graphics = Sprite(node.display.displayObject).graphics;
			graphics.clear();
			graphics.lineStyle(15, 0xFFFFFF, 0.05);
			
			for(var i:uint = 0; i < node.wind.windLines.size; i++)
			{
				var line:WindLine = node.wind.windLines.itemAt(i);
				
				var current:Point = line.points.first;
				graphics.moveTo(current.x, current.y);
				
				for(var j:uint = 1; j < line.points.size; j++)
				{
					current = line.points.itemAt(j);
					graphics.lineTo(current.x, current.y);
				}
			}
		}
	}
}