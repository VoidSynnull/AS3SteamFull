package game.systems.entity.character.states
{
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Jump;
	import game.nodes.entity.character.CharacterStateNode;
	import game.util.CharUtils;

	public class ControlJumpState extends JumpState
	{
		public var faceRight:Boolean;
		
		public function ControlJumpState(jumpRight:Boolean = true)
		{
			super.type = "controlJump";
			faceRight = jumpRight;
		}
		
		override public function start():void
		{
			node.charMotionControl.ignoreVelocityDirection = true;
			CharUtils.setDirection(node.entity, faceRight);
			super.updateStage = this.updateCheckTrigger;
			node.charMotionControl.jumpDampener = 1;
			node.charMovement.state = CharacterMovement.NONE;
			setAnim(Jump);			
		}
		
		override protected function applyJumpVelocity(node:CharacterStateNode, dampener:Number=1):void
		{
			// cap factors
			var xFactor:Number = node.motionTarget.targetDeltaX / _jumpFactorX;
			var yFactor:Number = node.motionTarget.targetDeltaY / _jumpFactorY;
			
			if(Math.abs(xFactor) > Math.abs(yFactor))
			{
				yFactor = -Math.abs(xFactor);
			}
			
			if (xFactor > .365) 		{ xFactor = .365; } 
			else if (xFactor < -.365)	{ xFactor = -.365; }
			if (yFactor < -1)			{ yFactor = -1; }
			else if (yFactor > -.33)	{ yFactor = -.33; }
			
			// apply jump velocity
			node.motion.velocity.x = node.charMotionControl.jumpVelocity * -xFactor * dampener;
			node.motion.velocity.y = node.charMotionControl.jumpVelocity * -yFactor * dampener;
		}
		
		override protected function updateCheckLand():void
		{
			CharUtils.setDirection(node.entity, faceRight);
			
			if ( node.platformCollider.isHit )		// check for platform collision
			{
				node.motion.zeroMotion();
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.SWIM)  )	// check for water collision
			{
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			
			move();
		}
	}
}