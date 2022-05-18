package game.scenes.survival1.woods.states
{
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class WoodPeckerBeginFlightState extends MovieclipState
	{
		public function WoodPeckerBeginFlightState()
		{
			super.type = "beginFlight";
		}
		
		override public function start():void
		{
			this.setLabel("takeoff");
			
			node.timeline.handleLabel("flying", flying);
			
			if(node.motionTarget.targetDeltaX > 0)
				node.spatial.scaleX = 1;
			else
				node.spatial.scaleX = -1;
			
			node.motion.acceleration.y = -120;
		}
		
		private function flying():void
		{
			node.fsmControl.setState("fly");
		}
	}
}