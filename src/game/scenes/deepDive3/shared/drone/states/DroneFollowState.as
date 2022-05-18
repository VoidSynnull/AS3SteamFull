package game.scenes.deepDive3.shared.drone.states
{
	public class DroneFollowState extends DroneState
	{
		public function DroneFollowState()
		{
			super.type = "follow";
		}
		
		override public function start():void
		{
			node.motionControlBase.freeMovement = false;
			node.motionControlBase.acceleration = 300;
			node.motionControlBase.stoppingFriction = 300;
			node.motionControlBase.accelerationFriction = 400;
			node.motionControlBase.maxVelocityByTargetDistance = 500;
			
			node.motionTarget.targetSpatial = node.drone.targetSpatial;
			node.motionControl.moveToTarget = true;
			
			scan();
		}
		
		override public function update(time:Number):void
		{
			// watch follow target
			faceTargetSpatial();
			
			// randomly flash light
			if(count >= randNum){
				scan();
			} else {
				count++;
			}
		}
		
		private function scan():void{
			flashLight();
			randNum = Math.round(Math.random()*randNumMAX);
			count = 0;
		}
		
		private var count:int = 0;
		private var randNum:int;
		private var randNumMAX:int = 300;
	}
}