package game.scenes.mocktropica.shared.petStates
{
	import game.components.motion.MotionTarget;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class PetRunState extends MovieclipState
	{
		public function PetRunState()
		{
			super.type = MovieclipState.RUN;
		}
		
		override public function start():void
		{
			super.setLabel("run");
			
			var target:MotionTarget = node.motionTarget;
			var narf:Narf = node.entity.get(Narf);
			
			if(target.targetDeltaX < 0)
			{
				node.spatial.scaleX = 1;
				node.motion.velocity.x = -narf.runSpeed;
			}
			else
			{
				node.spatial.scaleX = -1;
				node.motion.velocity.x = narf.runSpeed;
			}
		}
		
		override public function update( time:Number ):void
		{
			var target:MotionTarget = node.motionTarget;
			var narf:Narf = node.entity.get(Narf);
			node.motion.acceleration.y = 700;
			
			if(Math.abs(target.targetDeltaX) < narf.walkSpeed - 50)
			{
				node.fsmControl.setState(MovieclipState.WALK);
			}
		}
	}
}