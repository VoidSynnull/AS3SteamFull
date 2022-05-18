package game.scenes.backlot.postProduction.ScrollingSystem
{
	import flash.geom.Rectangle;
	
	import game.scenes.backlot.postProduction.ScrollingSystem.ScrollNode;
	import game.systems.GameSystem;
	
	public class ScrollSystem extends GameSystem
	{
		public function ScrollSystem()
		{
			super(ScrollNode, updateNode);
		}
		
		private function updateNode(node:ScrollNode, time:Number):void
		{
			if(!node.scroll.scroll || node.scroll.speed.x == 0 && node.scroll.speed.y == 0)
				return;
			
			node.spatial.x += node.scroll.speed.x;
			node.spatial.y += node.scroll.speed.y;
			
			var rect:Rectangle = new Rectangle(node.spatial.x, node.spatial.y,node.display.displayObject.width,node.display.displayObject.height);
			var bounds:Rectangle = node.scroll.bounds;
			
			var over:Number = 0;
			
			if(rect.x - rect.width / 2 > bounds.x + bounds.width && node.scroll.speed.x > 0)
			{
				over = (rect.x - rect.width / 2) - (bounds.x + bounds.width);
				node.spatial.x = bounds.x - rect.width / 2 + over;
			}
			if(rect.x + rect.width / 2 < bounds.x && node.scroll.speed.x < 0)
			{
				over = (rect.x + rect.width / 2) - bounds.x;
				node.spatial.x = bounds.x + bounds.width + rect.width / 2 + over;
			}
			if(rect.y - rect.height / 2 > bounds.y + bounds.height && node.scroll.speed.y > 0)
			{
				over = (rect.y - rect.height / 2) - (bounds.y + bounds.height);
				node.spatial.y = bounds.y - rect.height / 2 + over;
			}
			if(rect.y + rect.height / 2 < bounds.y && node.scroll.speed.y < 0)
			{
				over = (rect.y + rect.height / 2) - (bounds.y);
				node.spatial.y = bounds.y + bounds.height + rect.height / 2 + over;
			}
		}
	}
}