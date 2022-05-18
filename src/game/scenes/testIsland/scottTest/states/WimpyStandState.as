package game.scenes.testIsland.scottTest.states
{
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class WimpyStandState extends MovieclipState
	{
		public function WimpyStandState()
		{
			super.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{
			super.setLabel("stand");
		}
		
		override public function update( time:Number ):void
		{
			if(node.motionTarget.targetDeltaY < -80)
			{
				node.fsmControl.setState(MovieclipState.JUMP);
			}
		}
		
		private var _time:Number = 0;
	}
}