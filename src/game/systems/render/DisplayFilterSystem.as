package game.systems.render
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filters.BitmapFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import game.nodes.render.DisplayFilterNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.BitmapUtils;
	
	public class DisplayFilterSystem extends GameSystem
	{
		public function DisplayFilterSystem()
		{
			super(DisplayFilterNode, updateNode, null, nodeRemoved);
			this._defaultPriority = SystemPriorities.postRender;
		}
		
		private function updateNode(node:DisplayFilterNode, time:Number):void
		{
			this.disposeBitmap(node);
			
			var display:DisplayObject = node.display.displayObject;
			
			var bounds:Rectangle = display.getBounds(display.parent);
			bounds.inflate(node.filter.inflate.x, node.filter.inflate.y);
			node.filter.bitmap = BitmapUtils.createBitmap(display, 1, bounds);
			node.filter.bitmap.x = bounds.x;
			node.filter.bitmap.y = bounds.y;
			
			var bitmapData:BitmapData = node.filter.bitmap.bitmapData;
			for each(var filter:BitmapFilter in node.filter.filters)
			{
				bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), filter);
			}
			
			display.parent.addChildAt(node.filter.bitmap, display.parent.getChildIndex(display) + 1);
		}
		
		private function nodeRemoved(node:DisplayFilterNode):void
		{
			this.disposeBitmap(node);
		}
		
		private function disposeBitmap(node:DisplayFilterNode):void
		{
			if(node.filter.bitmap)
			{
				node.filter.bitmap.parent.removeChild(node.filter.bitmap);
				node.filter.bitmap.bitmapData.dispose();
				node.filter.bitmap.bitmapData = null;
			}
		}
	}
}