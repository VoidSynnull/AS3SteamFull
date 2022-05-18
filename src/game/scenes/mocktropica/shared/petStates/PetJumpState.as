package game.scenes.mocktropica.shared.petStates
{
	import game.components.motion.MotionTarget;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class PetJumpState extends MovieclipState
	{
		public function PetJumpState()
		{
			super.type = MovieclipState.JUMP;
		}
		
		override public function start():void
		{
			super.setLabel("jump");
			var narf:Narf = node.entity.get(Narf);	
			
			var target:MotionTarget = node.motionTarget;
			node.motion.velocity.x = target.targetDeltaX - narf.randDist;
			if(target.targetDeltaX < 0)
				node.spatial.scaleX = 1;
			else
				node.spatial.scaleX = -1;
			
			node.motion.velocity.y = narf.jumpHeight;
			node.motion.acceleration.y = 800;
			
			
		}
		
		override public function update( time:Number ):void
		{
			node.motion.acceleration.y = 700;
			if(node.motion.velocity.y >= 0)
			{
				if(node.platformCollider.isHit)
				{
					node.fsmControl.setState(MovieclipState.LAND);
				}
			}
		}
	}
}