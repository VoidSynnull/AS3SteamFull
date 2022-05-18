package game.scenes.backlot.postProduction.ScrollingSystem
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.systems.GameSystem;
	
	public class ScrollControlSystem extends GameSystem
	{
		public function ScrollControlSystem()
		{
			super(ScrollControlNode, updateNode);
		}
		
		private function updateNode(node:ScrollControlNode, time:Number):void
		{
			for each(var clips:Entity in node.scrollControls.scrollingObjects)
			{
				var scroll:Scroll = clips.get(Scroll);
				if(node.scrollControls.swapXandY)
					scroll.speed = new Point(node.slider.value.y, node.slider.value.x);
				else
					scroll.speed = node.slider.value;
				
				if(node.scrollControls.scrolling)
				{
					scroll.speed.x *= node.scrollControls.scrollSpeed;
					scroll.speed.y *= node.scrollControls.scrollSpeed;
				}
				else
					scroll.speed = new Point();
			}
		}
	}
}