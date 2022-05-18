package game.scenes.timmy.chase.trashTruck
{
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.scenes.arab3.treasureKeep.FallingRock;
	import game.scenes.arab3.treasureKeep.FallingRockNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	
	public class TrashTruckSystem extends GameSystem
	{
		public function TrashTruckSystem()
		{
			super(TrashTruckNode,nodeUpdate,nodeAdded,nodeRemoved);
		}
		
		public function nodeUpdate(node:TrashTruckNode,time:Number=0):void
		{
			// truck waits for delay, moves to random target Y position, sets new delay, moves again, 
			switch(node.trashTruck.state)
			{
				case TrashTruck.WAIT:
				{
					waitUpdate(node, time);
					break;
				}
				case TrashTruck.MOVE:
				{
					moveUpdate(node,time);
					break;
				}	
				case TrashTruck.STOP:
				{
					stopUpdate(node,time);	
					break;
				}
				default:
				{
					node.trashTruck.setState(TrashTruck.STOP);
					break;
				}
			}			
		}
		
		private function waitUpdate(node:TrashTruckNode, time:Number):void
		{
			var trashTruck:TrashTruck = node.trashTruck;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			if(trashTruck.stateChanged){
				trashTruck.timer = 0;
				trashTruck.stateChanged = false;
			}
			if(trashTruck.timer < trashTruck.moveDelay){
				trashTruck.timer += time;
			}
			else{
				moveTruck(node);
			}		
		}
		
		// zero motions and go to move state
		private function moveTruck(node:TrashTruckNode):void
		{
			var truck:TrashTruck = node.trashTruck;
			truck.nextTargetY = GeomUtils.randomInRange(truck.topLimit, truck.bottomLimit);
			if(node.spatial.y < truck.nextTargetY){
				truck.targetDirection = 1;
			}else{
				truck.targetDirection = -1;
			}
						
			node.motion.zeroAcceleration();
			node.motion.zeroMotion();
			
			truck.setState(TrashTruck.MOVE);
		}
		
		private function moveUpdate(node:TrashTruckNode, time:Number):void
		{
			var trashTruck:TrashTruck = node.trashTruck;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			if(trashTruck.stateChanged){
				node.motion.velocity.y = trashTruck.speed * trashTruck.targetDirection;
				trashTruck.stateChanged = false;
			}
			if(trashTruck.targetDirection == 1){
				if(node.spatial.y >= trashTruck.nextTargetY){
					node.motion.zeroAcceleration();
					node.motion.zeroMotion();
					trashTruck.setState(TrashTruck.WAIT);
				}
			}
			else if(trashTruck.targetDirection == -1){
				if(node.spatial.y <= trashTruck.nextTargetY){
					node.motion.zeroAcceleration();
					node.motion.zeroMotion();
					trashTruck.setState(TrashTruck.WAIT);
				}
			}
		}
		
		private function stopUpdate(node:TrashTruckNode, time:Number):void
		{
			var trashTruck:TrashTruck = node.trashTruck;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			if(trashTruck.stateChanged){
				motion.zeroAcceleration();
				motion.zeroMotion();
				trashTruck.stateChanged = false;
			}	
		}
		
		public function nodeAdded(node:TrashTruckNode):void
		{
			
		}
		
		public function nodeRemoved(node:TrashTruckNode):void
		{
			if(node.motion){
				node.motion.zeroMotion();
				node.motion.zeroAcceleration();
			}
		}
		
		private function updateLocked(node:FallingRockNode, time:Number):void
		{
			var rock:FallingRock = node.rock;
			if(rock.stateChanged){
				rock.timer = 0;
				node.spatial.y = rock.startY;
				node.motion.zeroAcceleration();
				node.motion.zeroMotion();
				rock.stateChanged = false;
				node.display.visible = false;
			}
		}
		
		
		
		
		
		
		
		

	}
}