package game.scenes.testIsland.drewTest.systems
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import game.scenes.testIsland.drewTest.components.PerlinNoise;
	import game.scenes.testIsland.drewTest.nodes.PerlinNoiseNode;
	import game.systems.GameSystem;
	
	public class PerlinNoiseSystem extends GameSystem
	{
		public function PerlinNoiseSystem()
		{
			super(PerlinNoiseNode, updateNode);
		}
		
		public function updateNode(node:PerlinNoiseNode, time:Number):void
		{
			this.initialize(node);
			
			this.updatePerlinNoise(node, time);	
		}
		
		private function updatePerlinNoise(node:PerlinNoiseNode, time:Number):void
		{
			/**
			 * Check to see if there are less octaves or speeds. This way, excess speeds won't be checked,
			 * but it'll avoid out of bounds errors if there aren't enough speeds for octaves.
			 */
			var numOctaves:int = Math.min(node.noise.numOctaves, node.noise.speeds.size);
			
			for(var i:int = 0; i < numOctaves; i++)
			{
				var offset:Point = node.noise.offsets.itemAt(i);
				var speed:Point = node.noise.speeds.itemAt(i);
				
				offset.x += speed.x * time;
				offset.y += speed.y * time;
			}
			
			var noise:PerlinNoise = node.noise;
			var data:BitmapData = node.noise.bitmap.bitmapData;
			
			data.perlinNoise(noise.baseX, noise.baseY, noise.numOctaves, noise.seed, noise.useStitch, noise.useFractalNoise, noise.channels, noise.useGrayScale, noise.offsets.toArray());
		}
		
		private function initialize(node:PerlinNoiseNode):void
		{
			if(!node.noise.initialize) return;
			
			//If the display doesn't have the bitmap as a child, add it.
			var container:DisplayObjectContainer = node.display.displayObject;
			if(!container.contains(node.noise.bitmap)) container.addChild(node.noise.bitmap);
			
			//Reinitialize the bitmap data and set the bitmap's data as it.
			var data:BitmapData = new BitmapData(node.noise.sizeX, node.noise.sizeY, true, 0x00000000);
			node.noise.bitmap.bitmapData = data;
			
			//Currently centering the bitmap in the center of the display. Might want to change this later.
			node.noise.bitmap.x = -node.noise.bitmap.width * 0.5;
			node.noise.bitmap.y = -node.noise.bitmap.height * 0.5;
			
			//If the number of octaves has changed, add/remove offset points.
			if(node.noise.offsets.size < node.noise.numOctaves)
			{
				while(node.noise.offsets.size < node.noise.numOctaves)
					node.noise.offsets.add(new Point(0, 0));
			}
			else
			{
				while(node.noise.offsets.size > node.noise.numOctaves)
					node.noise.offsets.removeLast();
			}
			
			//Set initialize back to false so this isn't done on the next update.
			node.noise.initialize = false;
		}
	}
}