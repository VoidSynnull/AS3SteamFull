package game.scenes.carnival.shared.states
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionTarget;
	import game.data.animation.entity.character.Run;
	import game.systems.entity.character.states.CharacterState;
	
	public class MonsterHitRetreatState extends CharacterState
	{
		public function MonsterHitRetreatState()
		{
			super.type = "hit_retreat";
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(Run);
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var target:MotionTarget = node.entity.get(MotionTarget);
			
			target.useSpatial = false;
			
			// back at the original location
			if(Math.abs(target.targetX - node.spatial.x) < 10)
			{
				node.fsmControl.setState("stand");
				return;
			}
		}
	}
}


