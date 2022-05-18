package game.scenes.examples.entitySleep
{
	import game.systems.GameSystem;
	
	public class TimeCounterSystem extends GameSystem
	{
		public function TimeCounterSystem()
		{
			super(TimeCounterNode, updateNode);
		}
		
		private function updateNode(node:TimeCounterNode, time:Number):void
		{
			node.timeCounter.time += time;
			node.display.displayObject["time"].text = node.timeCounter.time;
		}
	}
}