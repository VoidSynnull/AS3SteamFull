package game.systems.motion
{
	import game.nodes.motion.EdgeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class EdgeSystem extends GameSystem
	{
		public function EdgeSystem()
		{
			super(EdgeNode, updateNode, nodeAdded);
			this._defaultPriority = SystemPriorities.postRender;
		}
		
		private function updateNode(node:EdgeNode, time:Number):void
		{
			this.setScaledEdge(node);
		}
		
		private function nodeAdded(node:EdgeNode):void
		{
			this.setScaledEdge(node);
		}
		
		private function setScaledEdge(node:EdgeNode):void
		{
			if(node.display.displayObject)
			{
				node.edge.scaleX = node.display.displayObject.scaleX;
				node.edge.scaleY = node.display.displayObject.scaleY;
			}
		}
	}
}