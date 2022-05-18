package game.systems.ui
{
	import flash.geom.Rectangle;
	
	import game.components.ui.ScrollBox;
	import game.nodes.ui.ScrollBoxNode;
	import game.systems.GameSystem;
	
	/**
	 * Manages rectangular areas, or ScrollBox, where moving the cursor to the edge of the area will cause its contents to scroll.
	 * System checks for mouse position to see if it has entered the areas that will trigger scrolling.
	 * The speed of the scroll is proportionate to the depth of the mouse position within the scroll areas.
	 * 
	 * ScrollBox can only scroll along a single axis, the axis is determined by the ScrollBox.isHorizontal variable.
	 * 
	 * @author umckiba
	 * 
	 */
	public class ScrollBoxSystem extends GameSystem
	{
		public function ScrollBoxSystem()
		{
			super(ScrollBoxNode, updateNode);
		}
		
		private function updateNode(node:ScrollBoxNode, time:Number):void
		{
			var scroll:ScrollBox = node.scrollBox;
			
			if( !scroll.disable )
			{
				var min:Rectangle = scroll.min;
				var max:Rectangle = scroll.max;
				//var box:Rectangle = node.bounds.box;
				// box needs to be size of total grid
				
				// mouse position in relation to container
				var mouseX:Number = scroll.container.mouseX;
				var mouseY:Number = scroll.container.mouseY;
				
				var rate:Number = scroll.reverse ? -scroll.rate : scroll.rate;
				var percent:Number;
	
				//TODO :: Adjust velocity given time? - Bard
				if( scroll.isHorizontal )
				{
					if( min.contains(mouseX, mouseY))
					{
						percent = 1 - (mouseX - min.x)/ min.width;
						scroll.velocity = -rate * percent;
					}
					else if(max.contains(mouseX, mouseY))
					{
						percent = (mouseX - max.x)/ max.width;
						scroll.velocity = rate * percent;
					}
					else
					{
						scroll.velocity = 0;
					}	
				}
				else
				{
					if(min.contains(mouseX, mouseY))
					{
						percent = 1 - (mouseY - min.y)/ min.height;
						scroll.velocity = -rate * percent;
					}
					else if(max.contains(mouseX, mouseY))
					{
						percent = (mouseY - max.y)/ max.height;
						scroll.velocity = rate * percent;
					}
					else
					{
						scroll.velocity = 0;
					}
				}
			}
			else
			{
				scroll.velocity = 0;
			}
		}
	}
}