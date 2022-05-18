package game.scenes.examples.customCharacter.states
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionControl;
	import game.scenes.examples.customCharacter.CustomCharacterNode;
	import game.systems.entity.character.states.CharacterState;

	public class HurtState extends CustomCharacterState
	{
		public function HurtState()
		{
			super.type = CharacterState.HURT;
		}
		
		override public function check():Boolean
		{
			return node.hazardCollider.isHit;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			var motionControl:MotionControl = node.motionControl;
			
			// unflag hazardCollider isHit, allowing coolDown to define isHit, otherwise isHit can carry over to other states
			node.hazardCollider.isHit = false;
			
			// start spin
			charControl.spinSpeed 	= charControl.spinJumpRotation;	// TODO :: Should this speed should be set within HazardHit component?
			charControl.spinning 	= true;
			charControl.spinEnd 	= false;
			
			// apply animation & direction
			//setAnim( Hurt );
			charControl.ignoreVelocityDirection = true;
			motionControl.lockInput = true;
			motionControl.moveToTarget = false;	// NOTE :: set moveToTarget to false, so an active moveToTarget doesn't carry across while input is locked.
			node.characterMovement.state = CharacterMovement.NONE;
			
			if ( node.fsmControl.check( CharacterState.SWIM) )		// if in water when hit requires different update
			{
				// set hurt interval hasn't been specified, set to default
				if( node.hazardCollider.interval <= 0 )
				{
					node.hazardCollider.interval = this.HAZARD_INTERVAL_WATER;
				}
				super.updateStage = updateWater;
			}
			else
			{
				super.updateStage = updateAir;
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			super.updateStage( node );
		}
		
		override public function exit():void
		{
			node.motionControl.lockInput = false;
		}
		
		private function updateWater( node:CustomCharacterNode ):void
		{
			// while in water check for collision with platform or hurt interval to run out
			if ( node.waterCollider.isHit )	
			{
				// once falling, check for platform/water hit to end hurt state
				if ( node.motion.velocity.y >= 0 )	
				{
					if ( node.platformCollider.isHit )				
					{
						node.fsmControl.setState( CharacterState.LAND );
						return;
					}
				}
				
				// if interval is up, return to swim
				if( node.hazardCollider.interval <= 0 )	
				{
					node.characterMotionControl.spinEnd = true;
					node.fsmControl.setState( CharacterState.SWIM );
					//node.entity.get(Skin).getSkinPartEntity("eyes").get(Eyes).state = "squint";
					return;
				}
			}
			else
			{
				super.updateStage = updateAir;
				super.updateStage( node );
			}
		}
		
		private function updateAir( node:CustomCharacterNode ):void
		{
			node.characterMovement.state = CharacterMovement.AIR;
			// once falling, check for platform/water hit to end hurt state
			if ( node.motion.velocity.y >= 0 )	
			{
				if ( node.platformCollider.isHit || node.fsmControl.check( CharacterState.SWIM) )				
				{
					node.fsmControl.setState( CharacterState.LAND );
					return;
				}
			}
		}
		
		private const HAZARD_INTERVAL_WATER:Number = 1;	// 1 second interval of hurt state when in the water by default
	}
}