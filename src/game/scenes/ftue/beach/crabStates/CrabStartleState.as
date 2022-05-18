package game.scenes.ftue.beach.crabStates
{
	import game.components.motion.MotionTarget;
	import game.scenes.ftue.beach.components.Crab;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class CrabStartleState extends MovieclipState
	{
		public function CrabStartleState()
		{
			super.type = MovieclipState.JUMP;
		}
		
		override public function start():void
		{
			var crab:Crab = node.entity.get(Crab);
			var label:String = crab.hasWrench?"startleWrench":"startle";
			
			super.setLabel(label);
			
			var target:MotionTarget = node.motionTarget;
			
			crab.hidingLeft = !crab.hidingLeft;
			
			if(crab.leftBlocked && crab.rightBlocked)
			{
				target.targetX = (crab.leftHole.x + crab.rightHole.x) / 2;
				if(crab.hidingLeft)
					target.targetX -= crab.scurry;
				else
					target.targetX += crab.scurry;
			}
			else
				target.targetX = crab.hidingLeft?crab.leftHole.x:crab.rightHole.x;
			
				
			
			target.targetDeltaX = target.targetX - node.spatial.x;
			
			if(target.targetX < node.spatial.x)
				node.motion.velocity.x = -crab.speed / 2;
			else				
				node.motion.velocity.x = crab.speed / 2;
			//SceneUtil.delay(node.entity.group, .25, run);// may add back later but not sure if this mechancially fits
			label = crab.hasWrench?"startledWrench":"startled";
			node.timeline.handleLabel(label, run);
		}
		
		private function run():void
		{
			node.fsmControl.setState(MovieclipState.WALK);
		}
	}
}