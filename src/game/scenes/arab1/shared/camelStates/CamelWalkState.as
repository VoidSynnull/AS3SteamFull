package game.scenes.arab1.shared.camelStates
{
	import engine.components.Motion;
	
	import game.components.motion.MotionTarget;
	import game.scenes.arab1.shared.components.Camel;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.MotionUtils;
	
	public class CamelWalkState extends MovieclipState
	{
		public function CamelWalkState()
		{
			super.type = MovieclipState.WALK;
		}
		
		override public function start():void
		{
			super.setLabel("walk");
			
			var target:MotionTarget = node.motionTarget;
			var camel:Camel = node.entity.get(Camel);
			if(target.targetDeltaX < 0)
			{
				node.spatial.scaleX = -Math.abs(node.spatial.scaleX);
				node.motion.velocity.x = -camel.walkSpeed;
			}
			else
			{
				node.spatial.scaleX = Math.abs(node.spatial.scaleX);				
				node.motion.velocity.x = camel.walkSpeed;
			}	
		}
		
		override public function update( time:Number ):void
		{
			var target:MotionTarget = node.motionTarget;
			var camel:Camel = node.entity.get(Camel);
			node.motion.acceleration.y = MotionUtils.GRAVITY;
			
			if(Math.abs(target.targetDeltaX) <= camel.walkDistance - camel.walkPullPadding / 2)
			{
				node.fsmControl.setState(MovieclipState.STAND);
			}
			
			if(Math.abs(target.targetDeltaX) > camel.leashLength)
			{
				node.fsmControl.setState(Camel.PULL);
			}
			
			if(camel.handler != null)
			{
				var handlerMotion:Motion = camel.handler.get(Motion);
				
				if(handlerMotion == null)
					return;
				
				if(handlerMotion.velocity.y < 0 && target.targetDeltaY < -camel.leashLength)
				{
					handlerMotion.velocity.y = Math.abs(handlerMotion.velocity.y);
				}
			}
		}
	}
}