package engine.systems 
{
	import ash.core.Engine;
	
	import engine.nodes.TweenNode;
	
	import game.systems.GameSystem;
	
	public class TweenSystem extends GameSystem 
	{
		public function TweenSystem()
		{
			super(TweenNode, updateNode);
		}
		
		private function updateNode(node:TweenNode, time:Number):void
		{
			node.tween.updateDelta(time);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{	
			
			systemManager.releaseNodeList(TweenNode);
			super.removeFromEngine(systemManager);
		}
	}
}