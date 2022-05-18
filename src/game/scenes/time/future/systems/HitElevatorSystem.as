package game.scenes.time.future.systems
{	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.CurrentHit;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.time.future.components.HitElevator;
	import game.scenes.time.future.nodes.HitElevatorNode;
	import game.systems.GameSystem;
	
	public class HitElevatorSystem extends GameSystem
	{
		public function HitElevatorSystem()
		{
			super(HitElevatorNode, updateNode);
			//this.fixedTimestep = FixedTimestep.MOTION_TIME;
			//this.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(node:HitElevatorNode, time:Number):void
		{
			var hitElevator:HitElevator = node.hitElevator;
			var liftMotion:Motion = node.entity.get(Motion);
			var elevatorSpatial:Spatial = node.entity.get(Spatial);
			var playerHit:CurrentHit = super.group.shellApi.player.get(CurrentHit);
			
			if(playerHit.hit == node.entity && !_waiting)
			{
				if(elevatorSpatial.y > hitElevator.endPoints.x)
				{
					if(liftMotion.velocity.y > 0)
					{
						_waiting = true;
						liftMotion.velocity.y = 0;
					}
					
					if(liftMotion.velocity.y != -hitElevator.velocity)
					{
						liftMotion.velocity.y = -hitElevator.velocity;
						group.shellApi.triggerEvent("lift_activated"); 
					}
				}
				else if(liftMotion.velocity.y != 0)
				{
					liftMotion.velocity.y = 0;
					group.shellApi.triggerEvent("lift_deactivated");
				}
			}
			else if(_waiting) 
			{
				// wait a little to catch the character
				_timer += time;
				liftMotion.velocity.y = 0;
				
				if(_timer > .1)
				{
					_timer = 0;
					_waiting = false;
				}
			}
			else
			{
				if(elevatorSpatial.y < hitElevator.endPoints.y)
				{
					if(liftMotion.velocity.y != hitElevator.velocity)
					{
						liftMotion.velocity.y = hitElevator.velocity;
						group.shellApi.triggerEvent("lift_activated"); 
					}
				}
				else if(liftMotion.velocity.y != 0)
				{
					liftMotion.velocity.y = 0;
					group.shellApi.triggerEvent("lift_deactivated");
				}
			}
		}
		
		private var _waiting:Boolean = false;
		private var _timer:Number = 0;
	}
}