package game.scenes.con1.roofRace.Timer
{
	import game.systems.GameSystem;
	
	public class TimerSystem extends GameSystem
	{
		public function TimerSystem()
		{
			super(TimerNode, updateNode);
		}
		
		private const SECONDS_PER_MIN:uint = 60;
		private const NOON:uint = 12;
		
		public function updateNode(node:TimerNode, time:Number):void
		{
			if(!node.timer.active)
			{
				if(node.timer.invalidate)
					node.timer.display.text = node.timer.toString();
				node.timer.invalidate = false;
				return;
			}
			node.timer.invalidate = false;
			var timeData:TimeData = node.timer.time;
			var endTime:TimeData = node.timer.endTime;
			
			timeData.miliseconds += time * node.timer.scale;
			
			var seconds:Number = Math.floor(timeData.miliseconds);
			
			if(node.timer.format == Timer.TIMER && node.timer.scale < 0)// need to perform a check that would make the timer go negative (it doesnt like doing that)
			{
				if(timeData.minutes == 0 && timeData.hours == 0 && Math.abs(seconds)> Math.abs(timeData.seconds))
				{
					timesUp(node, new TimeData());
					node.timer.display.text = node.timer.toString();
					return;
				}
			}
			
			timeData.seconds += seconds;
			timeData.miliseconds -= seconds;
			
			var mins:Number = Math.floor(timeData.seconds / SECONDS_PER_MIN);
			
			timeData.minutes += mins;
			timeData.seconds -= mins * SECONDS_PER_MIN;
			
			var hours:Number = Math.floor(timeData.minutes / SECONDS_PER_MIN);
			
			timeData.hours += hours;
			timeData.minutes -= hours * SECONDS_PER_MIN;
			
			if(node.timer.format == Timer.CLOCK)
			{
				if(timeData.hours > NOON)
					timeData.hours -= NOON;
				if(timeData.hours <= 0)
					timeData.hours += NOON;
			}
			
			if(endTime != null)
			{
				if(timeData.reachedTime(endTime, node.timer.scale > 0))
					timesUp(node, endTime);
			}
			
			node.timer.display.text = node.timer.toString();
		}
		
		private function timesUp(node:TimerNode, time:TimeData):void
		{
			node.timer.active = false;
			node.timer.time.setTimeFromData(time);
			node.timer.timesUp.dispatch(node.timer);
		}
	}
}