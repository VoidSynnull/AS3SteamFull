package game.scenes.shrink.shared.Systems.WalkToTurnTimeline
{
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class WalkToTurnTimelineSystem extends GameSystem
	{
		public function WalkToTurnTimelineSystem()
		{
			super(WalkToTurnTimelineNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.checkCollisions;
		}
		public function updateNode(node:WalkToTurnTimelineNode, time:Number):void
		{
			var difference:Number = node.turn.dial.value - node.turn.lastValue;
			
			if(difference == 0)
			{
				node.turn.time += time;
				if(node.turn.time > node.turn.stopTurnTime)
				{
					node.timeline.stop();
					return;
				}
			}
			else
				node.turn.time = 0;
			
			node.timeline.play();
			
			if(difference > 0 && !node.turn.turningRight)
			{
				node.timeline.gotoAndPlay(node.turn.right);
				node.turn.turningRight = true;
			}
			
			if(difference < 0 && node.turn.turningRight)
			{
				node.timeline.gotoAndPlay(node.turn.left);
				node.turn.turningRight = false;
			}
			
			node.turn.lastValue = node.turn.dial.value;
		}
	}
}