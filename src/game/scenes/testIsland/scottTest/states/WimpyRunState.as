package game.scenes.testIsland.scottTest.states
{
	import game.components.motion.MotionTarget;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class WimpyRunState extends MovieclipState
	{
		public function WimpyRunState()
		{
			super.type = MovieclipState.RUN;
		}
		
		override public function start():void
		{
			super.setLabel("run");
		}
		
		override public function update( time:Number ):void
		{
			var motionTarget:MotionTarget = node.motionTarget;
			motionTarget.useSpatial = true;
			
			trace(motionTarget.targetDeltaX);
		}
	}
}