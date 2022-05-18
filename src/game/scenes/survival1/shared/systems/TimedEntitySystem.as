package game.scenes.survival1.shared.systems
{
	import game.systems.GameSystem;
	import game.scenes.survival1.shared.nodes.TimedEntityNode;
	
	public class TimedEntitySystem extends GameSystem
	{
		public function TimedEntitySystem()
		{
			super(TimedEntityNode, updateNode);
		}
		
		public function updateNode(node:TimedEntityNode, time:Number):void
		{
			if(node.timedEntity.paused || node.timedEntity.cycle > node.timedEntity.cycles && node.timedEntity.cycles != 0)
				return;
			
			node.timedEntity.time += time;
			if(node.timedEntity.time > node.timedEntity.eventTime)
			{
				node.timedEntity.time -= node.timedEntity.eventTime;
				node.timedEntity.eventTime = node.timedEntity.baseTime + Math.random() * node.timedEntity.variation;
				node.timedEntity.cycle ++;
				node.timedEntity.timesUp.dispatch(node.entity);
			}
		}
	}
}