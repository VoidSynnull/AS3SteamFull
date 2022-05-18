package game.scenes.con3.shared.rayRender
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class RayRenderSystem extends GameSystem
	{
		public function RayRenderSystem()
		{
			super(RayRenderNode, updateNode, nodeAdded, nodeRemoved);
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			this._defaultPriority = SystemPriorities.render;
		}
		
		private function updateNode(node:RayRenderNode, time:Number):void
		{
			if(node.render._redraw)
			{
				this.redraw(node);
			}
			else if(node.render._resize)
			{
				this.resize(node);
			}
		}
		
		private function redraw(node:RayRenderNode):void
		{
			node.render._redraw = false;
			
			var bitmapData:BitmapData = node.render._bitmap.bitmapData;
			
			if(!bitmapData)
			{
				bitmapData = new BitmapData(5, node.render._thickness, false, node.render._color);
			}
			else if(bitmapData.height != node.render._thickness)
			{
				bitmapData.dispose();
				bitmapData = new BitmapData(5, node.render._thickness, false, node.render._color);
			}
			else
			{
				bitmapData.floodFill(0, 0, node.render._color);
			}
			
			node.render._bitmap.bitmapData = bitmapData;
			node.render._bitmap.y = -node.render._thickness/2;
			
			this.resize(node);
		}
		
		private function resize(node:RayRenderNode):void
		{
			if(node.render._length > node.ray.length)
			{
				node.render._length = node.ray.length;
			}
			
			node.render._bitmap.width = node.render._length;
			node.render._resize = false;
		}
		
		private function nodeAdded(node:RayRenderNode):void
		{
			node.display.displayObject.addChild(node.render._bitmap);
			this.redraw(node);
		}
		
		private function nodeRemoved(node:RayRenderNode):void
		{
			node.display.displayObject.removeChild(node.render._bitmap);
			node.render._bitmap.bitmapData.dispose();
		}
	}
}