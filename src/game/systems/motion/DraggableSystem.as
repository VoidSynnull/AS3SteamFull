package game.systems.motion
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.components.motion.Draggable;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.DraggableNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	
	public class DraggableSystem extends GameSystem
	{
		public function DraggableSystem()
		{
			super(DraggableNode, updateNode, nodeAdded, nodeRemoved);
			this.fixedTimestep = FixedTimestep.MOTION_TIME;
			this.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:DraggableNode, time:Number):void
		{
			var draggable:Draggable		= node.draggable;
			var spatial:Spatial			= node.spatial;
			var display:DisplayObject	= node.display.displayObject;
			
			if( !draggable.disable )
			{
				if(draggable._invalidate)
				{
					draggable._invalidate = false;
					
					if(draggable._active)
					{
						/*
						DisplayObject.mouseX/Y don't account for rotation or scale, so we have to find the
						angle of DisplayObject.mouseX/Y in radians, calculate the radius before the
						rotation, then add the current DisplayObject rotation in radians.
						*/
						var point:Point = DisplayUtils.mouseXY(display);
						
						/*
						You can optionally set offsetX/Y before manually calling onDrag()/onDrop().
						Otherwise it'll be set to wherever the mouseX/Y currently is.
						*/
						if(!draggable.forceOffset)
						{
							if(isNaN(draggable.offsetX)) draggable.offsetX = point.x;
							if(isNaN(draggable.offsetY)) draggable.offsetY = point.y;
						}
						
						if(draggable.forward) DisplayUtils.moveToTop(display);
						
						drag(node);
						draggable.drag.dispatch(node.entity);
					}
					else
					{
						if(!draggable.forceOffset)
						{
							draggable.offsetX = NaN;
							draggable.offsetY = NaN;
						}
						draggable.drop.dispatch(node.entity);
					}
				}
				else
				{
					if(draggable._active)
					{
						drag(node);
						draggable.dragging.dispatch(node.entity);
					}
				}
			}
		}
		
		private function drag(node:DraggableNode):void
		{
			var draggable:Draggable		= node.draggable;
			var spatial:Spatial			= node.spatial;
			var display:DisplayObject	= node.display.displayObject;
			
			switch(draggable.axis)
			{
				case "x":
					spatial.x = display.parent.mouseX + draggable.offsetX;
					break;
				
				case "y":
					spatial.y = display.parent.mouseY + draggable.offsetY;
					break;
				
				default:
					spatial.x = display.parent.mouseX + draggable.offsetX;
					spatial.y = display.parent.mouseY + draggable.offsetY;
					break;
			}
		}
		
		private function nodeAdded(node:DraggableNode):void
		{
			node.interaction.down.add(node.draggable.onDrag);
			node.interaction.up.add(node.draggable.onDrop);
			node.interaction.releaseOutside.add(node.draggable.onDrop);
		}
		
		private function nodeRemoved(node:DraggableNode):void
		{
			node.interaction.down.remove(node.draggable.onDrag);
			node.interaction.up.remove(node.draggable.onDrop);
			node.interaction.releaseOutside.remove(node.draggable.onDrop);
		}
	}
}