package game.scenes.mocktropica.shared.petStates
{
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.TimelineUtils;
	
	public class PetLandState extends MovieclipState
	{
		public function PetLandState()
		{
			super.type = MovieclipState.LAND;
		}
		
		override public function start():void
		{
			super.setLabel("land");
			node.motion.velocity.x = 0;
			node.motion.acceleration.y = 700;
			TimelineUtils.onLabel(node.entity, "end", landDone, true);
		}
		
		private function landDone():void
		{
			node.fsmControl.setState(MovieclipState.STAND);
		}
	}
}