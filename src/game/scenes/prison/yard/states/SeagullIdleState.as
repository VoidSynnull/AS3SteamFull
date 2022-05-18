package game.scenes.prison.yard.states
{
	import flash.geom.Point;
	
	import game.components.motion.MotionTarget;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class SeagullIdleState extends MovieclipState
	{
		public function SeagullIdleState()
		{
			this.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{
			this.setLabel("idle");
			angryInterrupt = false;
			
			var target:MotionTarget = node.motionTarget;			
			node.motion.velocity = new Point(0,0);
			node.motion.acceleration = new Point(0,0);
		}
		
		override public function update(time:Number):void
		{
			if(angryInterrupt)
			{
				node.fsmControl.setState("sitAngry");
				return;
			}
			
			var target:MotionTarget = node.motionTarget;
			
			node.motion.velocity = new Point(0,0);
			node.motion.acceleration = new Point(0,0);
			
			if(Math.abs(target.targetDeltaX) > 50)
			{
				node.fsmControl.setState("beginFlight");
			}
		}
		
		public var angryInterrupt:Boolean;
	}
}