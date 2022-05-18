package game.comicViewer.systems
{
	import flash.geom.Rectangle;
	
	import engine.components.Motion;
	
	import game.components.motion.Edge;
	import game.comicViewer.nodes.StayInBoundsNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class CheckInBoundsSystem extends GameSystem
	{
		public function CheckInBoundsSystem()
		{
			super(StayInBoundsNode, updateNode);
			this._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private function updateNode(node:StayInBoundsNode, time:Number):void
		{
			var bounds:Rectangle = node.stayInBounds.bounds;
			var edge:Edge = node.edge;
			var motion:Motion = node.entity.get(Motion);
			node.stayInBounds.hitEdge = false;
			
			if(node.spatial.x + edge.rectangle.right < bounds.right)
			{
				node.spatial.x = bounds.right - edge.rectangle.right;
				node.stayInBounds.hitEdge = true;
			}
			
			if(node.spatial.x + edge.rectangle.left > bounds.left)
			{
				node.spatial.x = bounds.left - edge.rectangle.left;
				node.stayInBounds.hitEdge = true;
			}
			
			if(node.spatial.y + edge.rectangle.top > bounds.top)
			{
				node.spatial.y = bounds.top - edge.rectangle.top;
				node.stayInBounds.hitEdge = true;
			}
			
			if(node.spatial.y + edge.rectangle.bottom < bounds.bottom)
			{
				node.spatial.y = bounds.bottom - edge.rectangle.bottom;
				node.stayInBounds.hitEdge = true;
			}
			
			if(motion && node.stayInBounds.hitEdge)
				motion.zeroMotion();				
				
		}
	}
}