package game.scenes.ftue.beach.crabStates
{
	import game.scenes.ftue.beach.components.Crab;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class CrabIdleState extends MovieclipState
	{
		public function CrabIdleState()
		{
			super.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{
			var crab:Crab = node.entity.get(Crab);
			var label:String = crab.hasWrench?"idleWrench":"idle";
			super.setLabel(label);
			node.motion.velocity.x = 0;
		}
	}
}