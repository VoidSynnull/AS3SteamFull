package game.scenes.survival1.woods.states
{
	import flash.geom.Point;
	
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class WoodPeckerLandState extends MovieclipState
	{
		public function WoodPeckerLandState()
		{
			super.type = MovieclipState.LAND;
		}
		
		override public function start():void
		{
			this.setLabel("landing");
			
			if(node.motionTarget.targetDeltaX > 0)
				node.spatial.scaleX = 1;
			else
				node.spatial.scaleX = -1;			
		}
		
		override public function update(time:Number):void
		{
			node.motion.acceleration = new Point(0,0);
			node.motion.velocity.x = 0;
			
			if(node.motionTarget.targetY > node.spatial.y + 5)
			{
				node.motion.velocity.y = 100;
			}
			else
			{
				node.motion.velocity.y = 0;
				node.fsmControl.setState(MovieclipState.STAND);
			}
		}
	}
}