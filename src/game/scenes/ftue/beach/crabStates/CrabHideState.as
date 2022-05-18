package game.scenes.ftue.beach.crabStates
{
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class CrabHideState extends MovieclipState
	{
		public function CrabHideState()
		{
			super.type = MovieclipState.RUN;
		}
		
		override public function start():void
		{
			super.setLabel("throwWrench");
			
			node.motion.velocity.x = 0;
		}
	}
}