package game.scenes.ftue.beach.crabStates
{
	import game.scenes.ftue.beach.components.Crab;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class CrabGrabWrenchState extends MovieclipState
	{
		public function CrabGrabWrenchState()
		{
			super.type = "grab";
		}
		
		override public function start():void
		{
			var crab:Crab = node.entity.get(Crab);
			crab.hasWrench = true;
			super.setLabel("grabWrench");
			node.motion.velocity.x = 0;
			node.timeline.handleLabel("grabbedWrench", grabbedWrench);
		}
		
		private function grabbedWrench():void
		{
			node.fsmControl.setState(MovieclipState.WALK);
		}
	}
}