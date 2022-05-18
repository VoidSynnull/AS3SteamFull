package game.scenes.mocktropica.shared.petStates
{
	import game.components.motion.MotionTarget;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class PetWalkState extends MovieclipState
	{
		public function PetWalkState()
		{
			super.type = MovieclipState.WALK;
		}
		
		override public function start():void
		{
			super.setLabel("walk");
			
			var target:MotionTarget = node.motionTarget;
			var narf:Narf = node.entity.get(Narf);
			if(target.targetDeltaX < 0)
			{
				node.spatial.scaleX = 1;
				node.motion.velocity.x = -narf.walkSpeed;
			}
			else
			{
				node.spatial.scaleX = -1;				
				node.motion.velocity.x = narf.walkSpeed;
			}	
		}
		
		override public function update( time:Number ):void
		{
			var target:MotionTarget = node.motionTarget;
			var narf:Narf = node.entity.get(Narf);
			node.motion.acceleration.y = 700;
				
			if(Math.abs(target.targetDeltaX) <= Math.abs(narf.randDist) && !narf.targetCurd)
			{
				if(target.targetDeltaX <= 0 && narf.randDist <= 0)
				{
					node.fsmControl.setState(MovieclipState.STAND);
				}
				else if(target.targetDeltaX > 0 && narf.randDist > 0)
				{
					node.fsmControl.setState(MovieclipState.STAND);
				}
			}
			
			if(Math.abs(target.targetDeltaX) < 10 && narf.targetCurd)
			{
				node.fsmControl.setState(MovieclipState.STAND);
			}
			
			if(Math.abs(target.targetDeltaX) > narf.walkSpeed)
			{
				node.fsmControl.setState(MovieclipState.RUN);
			}
		}
	}
}