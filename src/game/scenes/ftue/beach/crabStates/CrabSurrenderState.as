package game.scenes.ftue.beach.crabStates
{
	import game.components.motion.MotionTarget;
	import game.scenes.ftue.beach.components.Crab;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class CrabSurrenderState extends MovieclipState
	{
		public function CrabSurrenderState()
		{
			super.type = "surrender";
		}
		
		override public function start():void
		{
			super.setLabel("startleWrench");
			node.motion.velocity.x = 0;
			node.timeline.handleLabel("startledWrench", animComplete);
			//SceneUtil.delay(node.entity.group, 1, animComplete);
			trace("hide");
		}
		
		private function animComplete():void
		{
			var crab:Crab = node.entity.get(Crab);
			var target:MotionTarget = node.motionTarget;
			crab.startScurrying = true;
			if(Math.abs(crab.scurry) <= crab.scurryDistance / 4)
			{
				trace("burry");
				node.fsmControl.setState(MovieclipState.RUN);
				return;
			}
			target.targetX -= crab.scurry * 2;
			crab.scurry /= -2;
			
			target.targetDeltaX = target.targetX - node.spatial.x;
			
			node.fsmControl.setState(MovieclipState.WALK);
		}
	}
}