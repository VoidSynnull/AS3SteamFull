package game.scenes.prison.yard.states
{
	import flash.geom.Point;
	
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class SeagullHopState extends MovieclipState
	{
		public function SeagullHopState()
		{
			this.type = "hop";
		}
		
		override public function start():void
		{
			this.setLabel("takeoff");
			
			node.motion.velocity.x = -50;
			node.motion.velocity.y = -70;
			node.timeline.handleLabel("flying", flyingLabel);
		}
		
		private function flyingLabel():void
		{
			node.motion.velocity.x = 0;
			node.motion.velocity.y = 115;
			node.timeline.gotoAndPlay("ground");
			node.timeline.handleLabel("land", landed);
		}
		
		private function landed():void
		{
			node.motion.velocity = new Point(0,0);
			node.fsmControl.setState("eating");
		}
	}
}