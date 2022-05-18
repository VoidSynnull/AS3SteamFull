package game.scenes.arab3.atriumGame.searchTimer
{
	import flash.text.TextField;
	
	import game.systems.GameSystem;
	
	public class SearchTimerSystem extends GameSystem
	{
		public function SearchTimerSystem()
		{
			super(SearchTimerNode, updateNode);
		}
		
		private function updateNode(node:SearchTimerNode, time:Number):void
		{
			if(node.searchTimer._running)
			{
				node.searchTimer._remainingTime -= time;
				
				if(node.searchTimer._remainingTime <= 0)
				{
					node.searchTimer._remainingTime = 0;
					node.searchTimer._running = false;
				}
				
				TextField(node.display.displayObject).text = Math.ceil(node.searchTimer._remainingTime).toFixed();
				
				if(!node.searchTimer._running)
				{
					node.searchTimer.finished.dispatch(node.entity);
				}
			}
		}
	}
}