package game.systems.entity.character.states.movieClip 
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	
	public class MCFallState extends MCState 
	{
		public var fallLabel:String = "fall";
		
		public function MCFallState()
		{
			super.type = CharacterState.FALL;
		}
		
		override public function check():Boolean
		{
			return !node.platformCollider.isHit;
		}

		/**
		 * Start the state
		 */
		override public function start():void
		{
			if( !node.charMotionControl.spinning )
			{
				this.setLabel(fallLabel);
			}
			node.charMotionControl.ignoreVelocityDirection = true;
			node.charMovement.state = CharacterMovement.AIR;
		}

		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			
			if ( node.fsmControl.check(CharacterState.HURT) )		// check for hazard collision
			{
				node.motionControl.moveToTarget = false;
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.CLIMB) )	// check for climb collision
			{
				node.motionControl.moveToTarget = false;
				node.fsmControl.setState( CharacterState.CLIMB );
				return;
			}
			else if ( node.platformCollider.isHit )	// check for platform collision
			{
				if ( Math.abs(node.motion.velocity.x) > node.charMotionControl.runSpeed )
				{
					super.directionByVelocity();
				}
				
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.SWIM) )	// check for platform collision
			{
				// TODO :: Go right to Swim, and let swim handle landing?
				node.motionControl.moveToTarget = false;	
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
		
			// check to see if velocity has reversed, if restart Fall anim
		}
		/*
		private function updateFallingUp():void
		{
			
		}
		
		private function updateFallingDown():void
		{
			
		}
		*/
	}
}