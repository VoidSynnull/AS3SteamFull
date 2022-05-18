package game.scenes.arab1.shared.camelStates
{
	import flash.geom.Point;
	
	import engine.components.Motion;
	
	import game.components.motion.MotionTarget;
	import game.scenes.arab1.shared.components.Camel;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.MotionUtils;
	
	public class CamelPulledState extends MovieclipState
	{
		public function CamelPulledState()
		{
			super.type = Camel.PULL;
		}
		
		override public function start():void
		{
			super.setLabel("pull");
			node.motion.velocity.x = 0;
			node.motion.acceleration = new Point(0, MotionUtils.GRAVITY);
		}
		
		override public function update( time:Number ):void
		{
			var target:MotionTarget = node.motionTarget;
			var camel:Camel = node.entity.get(Camel);
			
			if(Math.abs(target.targetDeltaX) <= camel.leashLength - camel.walkPullPadding)
			{
				node.fsmControl.setState(MovieclipState.WALK);
			}
			
			if(camel.handler != null)
			{
				var handlerMotion:Motion = camel.handler.get(Motion);
				
				if(handlerMotion == null)
					return;
				
				if(handlerMotion.velocity.x > 0 && target.targetDeltaX > 0 || handlerMotion.velocity.x < 0 && target.targetDeltaX < 0)
				{
					handlerMotion.x = handlerMotion.previousX;
					handlerMotion.zeroMotion("x");
				}
				
				if(handlerMotion.velocity.y < 0 && target.targetDeltaY < -camel.leashLength)
				{
					handlerMotion.velocity.y = Math.abs(handlerMotion.velocity.y);
				}
			}
		}
	}
}