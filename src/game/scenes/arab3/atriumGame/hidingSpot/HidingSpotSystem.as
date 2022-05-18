package game.scenes.arab3.atriumGame.hidingSpot
{
	import game.systems.GameSystem;
	import game.util.Utils;
	
	public class HidingSpotSystem extends GameSystem
	{
		public function HidingSpotSystem()
		{
			super(HidingSpotNode, updateNode, nodeAdded, nodeRemoved);
		}
		
		private function updateNode(node:HidingSpotNode, time:Number):void
		{
			node.hidingSpot.wait -= time;
			
			if(node.hidingSpot.wait <= 0)
			{
				node.hidingSpot.wait = Utils.randNumInRange(node.hidingSpot.minWait, node.hidingSpot.maxWait);
				node.timeline.gotoAndPlay(0);
			}	
		}
		
		private function nodeAdded(node:HidingSpotNode):void
		{
			node.hidingSpot.wait = Utils.randNumInRange(node.hidingSpot.minWait, node.hidingSpot.maxWait);
			node.timeline.gotoAndPlay(0);
		}
		
		private function nodeRemoved(node:HidingSpotNode):void
		{
			node.timeline.gotoAndStop(0);
		}
	}
}