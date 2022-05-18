package game.scenes.deepDive3.shared.drone.states
{
	public class DroneIdleState extends DroneState
	{
		public function DroneIdleState()
		{
			super.type = "idle";
		}
		
		override public function start():void
		{
			node.motionControl.moveToTarget = false;
			flashLight();
			node.drone.stateChange.dispatch(super.type);
			node.motion.zeroAcceleration();
			node.motion.zeroMotion();
		}
		
		override public function update(time:Number):void
		{
			//trace("idle");
		}
	}
}