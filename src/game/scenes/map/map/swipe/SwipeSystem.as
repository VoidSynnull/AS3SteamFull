package game.scenes.map.map.swipe
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	import ash.tools.ListIteratingSystem;
	
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class SwipeSystem extends ListIteratingSystem
	{
		public function SwipeSystem()
		{
			super(SwipeNode, updateNode, nodeAdded, nodeRemoved);
			
			this._defaultPriority = SystemPriorities.postUpdate;
		}
		
		private function updateNode(node:SwipeNode, time:Number):void
		{
			var swipe:Swipe 			= node.swipe;
			var display:DisplayObject 	= node.display.displayObject;
			
			if(!EntityUtils.sleeping(node.entity))
			{
				if(swipe._invalidate)
				{
					swipe._invalidate = false;
					
					var mouseX:int = display.mouseX;
					var mouseY:int = display.mouseY;
					
					if(swipe._swiping)
					{
						for each(var rectangle:Rectangle in swipe.rectangles)
						{
							if(rectangle.contains(mouseX, mouseY))
							{
								swipe._swiping = false;
								return;
							}
						}
						
						swipe._active	= true;
						swipe._time		= 0;
						swipe._startX 	= mouseX;
						swipe._startY 	= mouseY;
						swipe._stopX	= mouseX;
						swipe._stopY	= mouseY;
						
						swipe.start.dispatch(node.entity);
					}
					else
					{
						swipe._stopX = mouseX;
						swipe._stopY = mouseY;
						
						swipe.stop.dispatch(node.entity);
					}
				}
			}
			
			if(swipe._active)
			{
				swipe._time += time;
				
				if(swipe._time >= swipe.swipeTime)
				{
					swipe._active 	= false;
					swipe._swiping 	= false;
				}
			}
		}
		
		private function nodeAdded(node:SwipeNode):void
		{
			node.interaction.down.add(node.swipe.onDown);
			node.interaction.up.add(node.swipe.onUp);
			node.interaction.out.add(node.swipe.onOut);
		}
		
		private function nodeRemoved(node:SwipeNode):void
		{
			node.interaction.down.remove(node.swipe.onDown);
			node.interaction.up.remove(node.swipe.onUp);
			node.interaction.out.remove(node.swipe.onOut);
		}
	}
}