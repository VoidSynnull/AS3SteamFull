package game.scenes.prison.yard.states
{
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class SeagullBeginFlightState extends MovieclipState
	{
		public function SeagullBeginFlightState()
		{
			super.type = "beginFlight";
		}
		
		override public function start():void
		{
			this.setLabel("takeoff");			
			node.timeline.handleLabel("flying", flying);
			
			node.motion.acceleration.y = -120;
		}
		
		private function flying():void
		{
			node.fsmControl.setState("fly");
		}
	}
}