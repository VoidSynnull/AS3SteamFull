package game.scenes.con3.shared.laserPulse
{
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class LaserPulseSystem extends GameSystem
	{
		public function LaserPulseSystem()
		{
			super(LaserPulseNode, updateNode);
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.preRender;
		}
		
		private function updateNode(node:LaserPulseNode, time:Number):void
		{	
			node.pulse.time += time;
			
			if(node.pulse._on)
			{
				if(node.pulse.time >= node.pulse.timeOn)
				{
					node.pulse.time = 0;
					node.pulse._on = false;
					node.timeline.gotoAndPlay("off");
				}
			}
			else
			{
				if(node.pulse.time >= node.pulse.timeOff)
				{
					node.pulse.time = 0;
					node.pulse._on = true;
					node.timeline.gotoAndPlay("on");
				}
			}
		}
	}
}