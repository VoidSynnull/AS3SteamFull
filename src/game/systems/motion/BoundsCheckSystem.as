package game.systems.motion
{
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	
	import engine.components.MotionBounds;
	
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.BoundsCheckNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class BoundsCheckSystem extends GameSystem
	{
		public function BoundsCheckSystem()
		{
			super(BoundsCheckNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(BoundsCheckNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:BoundsCheckNode, time:Number):void
		{			
			var bounds:MotionBounds = node.bounds;
			var box:Rectangle = bounds.box;
			var spatial:* = node.spatial;
			var top:Number = 0;
			var bottom:Number = 0;
			var left:Number = 0;
			var right:Number = 0;
			
			var edge:Edge = node.edge;
			
			// if entity has a motion component, it should be repositioned using it rather than the spatial directly
			if( node.motion )
			{
				spatial = node.motion;
			}
			
			if(edge != null)
			{
				top = edge.rectangle.top;
				bottom = edge.rectangle.bottom;
				left = edge.rectangle.left;
				right = edge.rectangle.right;
			}
			
			bounds.right = false;
			bounds.left = false;
			bounds.bottom = false;
			bounds.top = false;
			
			if (spatial.x + right >= box.right)
			{
				if(bounds.reposition)
				{
					spatial.x = box.right - right;
				}
				
				bounds.right = true;
			}
			else if (spatial.x + left <= box.x)
			{
				if(bounds.reposition)
				{
					spatial.x = box.left - left;
				}
				
				bounds.left = true;
			}
			
			if (spatial.y + bottom >= box.bottom)
			{
				if(bounds.reposition)
				{
					spatial.y = box.bottom - bottom;
				}
				
				bounds.bottom = true;
			}
			else if (spatial.y + top <= box.y)
			{
				if(bounds.reposition)
				{
					spatial.y = box.top - top;
				}
				
				bounds.top = true;
			}
		}
	}
}