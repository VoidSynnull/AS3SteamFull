package game.scenes.testIsland.drewTest.systems
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import engine.managers.SoundManager;
	
	import game.scenes.testIsland.drewTest.classes.LightningBolt;
	import game.scenes.testIsland.drewTest.nodes.LightningNode;
	import game.systems.GameSystem;
	import game.util.Utils;
	
	public class LightningSystem extends GameSystem
	{
		public function LightningSystem()
		{
			super(LightningNode, updateNode);
		}
		
		public function updateNode(node:LightningNode, time:Number):void
		{
			if(this.updateTime(node, time))
			{
				this.playAudio(node);
				this.createBolts(node);
			}
			
			this.updateBolts(node, time);
		}
		
		private function updateTime(node:LightningNode, time:Number):Boolean
		{
			node.lightning.time -= time;
			
			if(node.lightning.time <= 0)
			{
				node.lightning.time = Utils.randNumInRange(node.lightning.minWait, node.lightning.maxWait);
				return true;
			}
			return false;
		}
		
		private function playAudio(node:LightningNode):void
		{
			if(node.lightning.audioChance > Math.random())
			{
				var array:Array = [1, 3];
				var number:int = array[Utils.randInRange(0, array.length - 1)];
				var thunder:String = "thunder_clap_0" + number + ".mp3";
				node.audio.play(SoundManager.EFFECTS_PATH + thunder);
			}
		}
		
		private function updateBolts(node:LightningNode, time:Number):void
		{
			this.updateBoltCount(node);
			
			for(var i:uint = 0; i < node.lightning.bolts.size; i++)
			{
				var bolt:LightningBolt = node.lightning.bolts.itemAt(i);
				
				switch(bolt.state)
				{
					case LightningBolt.INIT_STATE:		this.createBolt(node, bolt);				break;
					case LightningBolt.STRIKE_STATE:	this.updateBoltStrike(bolt, time);			break;
					case LightningBolt.FLASH_STATE:		this.updateBoltFlash(bolt, time, node);		break;
				}
			}
		}
		
		private function updateBoltStrike(bolt:LightningBolt, time:Number):void
		{
			bolt.time += time;
			
			if(bolt.time >= 0.03)
			{
				bolt.time = 0;
				bolt.numPoints += 2;
				bolt.shape.graphics.clear();
				
				if(bolt.numPoints > bolt.points.size)
				{
					bolt.numPoints = bolt.points.size;
					bolt.state = LightningBolt.FLASH_STATE;
				}
				
				this.drawBolt(bolt);
			}
		}
		
		private function updateBoltFlash(bolt:LightningBolt, time:Number, node:LightningNode):void
		{
			bolt.time += time;
			
			if(bolt.time >= 0.07)
			{
				bolt.time = 0;
				bolt.numPoints = bolt.points.size;
				
				if(bolt.canFlash)
				{
					bolt.canFlash = false;
					bolt.shape.graphics.clear();
					
					if(bolt.numFlashes <= 0)
						node.lightning.dead.push(bolt);
					
					bolt.numFlashes--;
				}
				else
				{
					bolt.canFlash = true;
					bolt.points.clear();
					
					this.resetBoltPoints(bolt, node);
					this.drawBolt(bolt);
				}
			}
		}
		
		private function updateBoltCount(node:LightningNode):void
		{
			while(node.lightning.dead.length > 0)
			{
				var bolt:LightningBolt = node.lightning.dead.pop();
				
				node.lightning.bolts.remove(bolt);
				node.display.displayObject.removeChild(bolt.shape);
			}
		}
		
		private function createBolts(node:LightningNode):void
		{
			var numBolts:uint = Utils.randInRange(node.lightning.minBolts, node.lightning.maxBolts);
			
			for(var i:uint = 0; i < numBolts; i++)
			{
				var shape:Shape = new Shape();
				shape.x = Utils.randNumInRange(node.lightning.box.left, node.lightning.box.right);
				shape.y = node.lightning.box.top;
				
				var numPoints:uint = Utils.randInRange(node.lightning.minBoltPoints, node.lightning.maxBoltPoints);
				var numFlashes:int = Utils.randInRange(node.lightning.minFlashes, node.lightning.maxFlashes);
				var bolt:LightningBolt = new LightningBolt(shape, numPoints, numFlashes);
				
				node.lightning.bolts.add(bolt);
				node.display.displayObject.addChild(bolt.shape);
			}
		}
		
		private function createBolt(node:LightningNode, bolt:LightningBolt):void
		{
			this.resetBoltPoints(bolt, node);
			
			bolt.numPoints = 0;
			bolt.state = LightningBolt.STRIKE_STATE;
		}
		
		private function resetBoltPoints(bolt:LightningBolt, node:LightningNode):void
		{
			/**
			 * Need to subtract 1 from numPoints because lines are drawn "between" points,
			 * so there needs to be one less point to equal the number of lines to make a
			 * line's length!
			 */
			var offsetY:Number = node.lightning.box.bottom / (bolt.numPoints - 1);
			var offsetX:Number = Utils.randNumInRange(-20, 20);
			
			for(var i:uint = 0; i < bolt.numPoints; i++)
			{
				var x:Number = Utils.randNumInRange(-40, 40) + (offsetX * i);
				var y:Number = offsetY * i;
				var point:Point = new Point(x, y);
				bolt.points.add(point);
			}
		}
		
		private function drawBolt(bolt:LightningBolt):void
		{
			this.drawBoltLine(bolt, 15, 0x0066FF, 0.5);
			this.drawBoltLine(bolt, 10, 0x00CCFF, 0.5);
			this.drawBoltLine(bolt, 5, 0xFFFFFF, 1);
		}
		
		private function drawBoltLine(bolt:LightningBolt, thickness:Number, color:uint, alpha:Number):void
		{
			var graphics:Graphics = bolt.shape.graphics;
			graphics.lineStyle(thickness, color, alpha);
			
			for(var i:uint = 1; i < bolt.numPoints; i++)
			{
				var previous:Point = bolt.points.itemAt(i - 1);
				var current:Point = bolt.points.itemAt(i);
				
				graphics.moveTo(previous.x, previous.y);
				graphics.lineTo(current.x, current.y);
			}
		}
	}
}