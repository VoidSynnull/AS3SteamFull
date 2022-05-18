package game.scenes.examples.customCharacter
{
	import game.components.entity.character.CharacterMovement;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	
	public class CustomCharacterAnimationSystem extends GameSystem
	{
		public function CustomCharacterAnimationSystem()
		{
			super(CustomCharacterNode, updateNode);
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		private function updateNode(node:CustomCharacterNode, time:Number):void
		{
			setColliderState(node);
			
			if (node.characterMovement.state == CharacterMovement.GROUND && node.motionControl.moveToTarget)
			{
				if(checkJumpRange(node))
				{
					applyJumpVelocity(node, 1);
				}
			}
		}
		
		private function applyJumpVelocity(node:CustomCharacterNode, dampener:Number = 1):void
		{
			// cap factors
			var jumpFactorX:Number = super.group.shellApi.viewportWidth * .5;
			var jumpFactorY:Number = super.group.shellApi.viewportHeight * .2;
			var minXJumpSpinRange:Number = super.group.shellApi.viewportWidth * .1;
			var xFactor:Number = node.motionTarget.targetDeltaX / jumpFactorX;
			var yFactor:Number = node.motionTarget.targetDeltaY / jumpFactorY;
			
			if(Math.abs(xFactor) > Math.abs(yFactor))
			{
				yFactor = -Math.abs(xFactor);
			}
			
			if (xFactor > .365) 		{ xFactor = .365; } 
			else if (xFactor < -.365)	{ xFactor = -.365; }
			if (yFactor < -1)			{ yFactor = -1; }
			else if (yFactor > -.33)	{ yFactor = -.33; }
			
			// apply jump velocity
			node.motion.velocity.x = node.characterMotionControl.jumpVelocity * -xFactor * dampener;
			node.motion.velocity.y = node.characterMotionControl.jumpVelocity * -yFactor * dampener;
			
			if(Math.abs(node.motionTarget.targetDeltaX) > minXJumpSpinRange)
			{
				node.characterMotionControl.spinSpeed = node.characterMotionControl.spinJumpRotation;
				node.characterMotionControl.spinning = true;
				node.characterMotionControl.spinEnd = false;
				node.characterMotionControl.spinCount = 1;
			}
		}
				
		private function setColliderState(node:CustomCharacterNode):void
		{
			if(node.platformCollider != null && node.platformCollider.isHit)
			{
				node.characterMovement.state = CharacterMovement.GROUND;
				node.characterMovement.active = true;
			}
			else if(node.waterCollider != null && node.waterCollider.isHit)
			{
				if(CharUtils.DENSITY > node.waterCollider.densityHit)
				{
					node.characterMovement.state = CharacterMovement.DIVE;
				}
				else
				{
					node.characterMovement.state = CharacterMovement.GROUND;
				}
				node.characterMovement.active = true;
			}
			else if(node.climbCollider != null && node.climbCollider.isHit)
			{
				node.characterMovement.state = CharacterMovement.CLIMB;
				node.characterMovement.active = true;
			}
			else
			{
				node.characterMovement.state = CharacterMovement.AIR;
				node.characterMovement.active = true;
			}
		}
		
		private function checkJumpRange(node:CustomCharacterNode):Boolean
		{
			return (-node.motionTarget.targetDeltaY > node.characterMotionControl.inputDeadzoneY && Math.abs(-node.motionTarget.targetDeltaY / node.motionTarget.targetDeltaX) > JUMP_SLOPE_RANGE)
		}
		
		protected const JUMP_SLOPE_RANGE:Number = .5;
	}
}