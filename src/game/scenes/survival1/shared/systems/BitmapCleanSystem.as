package game.scenes.survival1.shared.systems
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import game.scenes.survival1.shared.components.BitmapClean;
	import game.scenes.survival1.shared.nodes.BitmapCleanNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class BitmapCleanSystem extends GameSystem
	{
		public function BitmapCleanSystem()
		{
			super(BitmapCleanNode, updateNode, nodeAdded, nodeRemoved);
			
			this._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:BitmapCleanNode, time:Number):void
		{
			if(node.clean.locked) return;
			
			var clean:BitmapClean 	= node.clean;
			var bitmap:Bitmap 		= node.display.displayObject.getChildAt(0);
			
			if(clean.cleaning && !clean.clean)
			{	
				if(clean.checked)
				{
					clean.checked = false;
					clean.startCleaning.dispatch(node.entity);
				}
				
				clean.elapsedTime += time;
				if(clean.elapsedTime >= clean.waitTime)
				{
					clean.elapsedTime = 0;
					
					this.makeCircle(bitmap, clean);
				}
			}
			else if(!clean.checked)
			{
				clean.stopCleaning.dispatch(node.entity);
				this.checkPixels(clean, bitmap.bitmapData, node.entity);
			}
		}
		
		private function makeCircle(bitmap:Bitmap, clean:BitmapClean):void
		{
			var mouseX:int 		= bitmap.mouseX;
			var mouseY:int 		= bitmap.mouseY;
			var radius:int 		= clean.radius;
			var data:BitmapData = bitmap.bitmapData;
			
			for(var x:int = mouseX - radius; x <= mouseX + radius; x++)
			{
				for(var y:int = mouseY - radius; y <= mouseY + radius; y++)
				{
					if(GeomUtils.distSquared(mouseX, mouseY, x, y) < radius * radius)
					{
						data.setPixel32(x, y, 0);
					}
				}
			}
		}
		
		private function checkPixels(clean:BitmapClean, data:BitmapData, entity:Entity):void
		{
			var width:int 	= data.width;
			var height:int 	= data.height;
			var total:int	= 0;
			
			for(var x:int = 0; x < width; ++x)
			{
				for(var y:int = 0; y < height; ++y)
				{
					if(data.getPixel(x, y) == 0)
					{
						++total;
					}
				}
			}
			
			clean.percent = total / (width * height);
			
			if(clean.percent >= clean.minPercent)
			{
				clean.clean = true;
				clean.cleaned.dispatch(entity);
			}
			
			clean.checked = true;
		}
		
		private function nodeAdded(node:BitmapCleanNode):void
		{
			this.checkPixels(node.clean, node.display.displayObject.getChildAt(0).bitmapData, node.entity);
			
			node.interaction.down.add(node.clean.onDown);
			node.interaction.up.add(node.clean.onUp);
			node.interaction.releaseOutside.add(node.clean.onUp);
		}
		
		private function nodeRemoved(node:BitmapCleanNode):void
		{
			node.interaction.down.remove(node.clean.onDown);
			node.interaction.up.remove(node.clean.onUp);
			node.interaction.releaseOutside.remove(node.clean.onUp);
		}
	}
}