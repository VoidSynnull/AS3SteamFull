package game.scenes.mocktropica.shared.petStates
{
	import flash.geom.Point;
	
	import game.components.motion.MotionTarget;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class PetStandState extends MovieclipState
	{
		public function PetStandState()
		{
			super.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{
			super.setLabel("stand");
			node.motion.velocity.x = 0;
			node.motion.acceleration = new Point(0, 700);
			var target:MotionTarget = node.motionTarget;
			if(target.targetDeltaX < 0)
				node.spatial.scaleX = 1;
			else
				node.spatial.scaleX = -1;
		}
		
		override public function update( time:Number ):void
		{
			var target:MotionTarget = node.motionTarget;
			var narf:Narf = node.entity.get(Narf);
			
			if(Math.abs(target.targetDeltaX) > Math.abs(narf.randDist))
			{
				node.fsmControl.setState(MovieclipState.WALK);
				return;
			}
			else if(narf.targetCurd)
			{
				node.fsmControl.setState("eat");
				return;
			}
			
			if(target.targetDeltaY < -(node.spatial.height + 30))
			{
				node.fsmControl.setState(MovieclipState.JUMP);
			}
		}
	}
}