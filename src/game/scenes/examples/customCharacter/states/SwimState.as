package game.scenes.examples.customCharacter.states
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Swim;
	import game.data.animation.entity.character.SwimTread;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;

	public class SwimState extends CustomCharacterState
	{
		public function SwimState()
		{
			super.type = CharacterState.SWIM;
		}
		
		override public function check():Boolean
		{
			return node.waterCollider.isHit;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			if( CharUtils.DENSITY > node.waterCollider.densityHit )
			{
				node.fsmControl.setState( CharacterState.DIVE );
				return;
			}
			
			node.characterMotionControl.ignoreVelocityDirection = false;
			node.characterMotionControl.directionByVelocity = true;
			node.characterMovement.state = CharacterMovement.GROUND;
			
			// update swim speed
			if ( Math.abs(node.motion.velocity.x) >= node.characterMotionControl.swimSpeed)
			{
				//super.setAnim( Swim );
				super.updateStage = updateSwimming;
				
			}
			else
			{
				//super.setAnim( SwimTread );
				super.updateStage = updateTreading;
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			
			if ( fsmControl.check(CharacterState.HURT) )			// check for platform collision
			{
				fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( !node.waterCollider.isHit )
			{
				if ( node.platformCollider.isHit )
				{
					transitionToPlatform()
					return;
				} 
				else if( !node.wallCollider.isHit )
				{
					fsmControl.setState( CharacterState.FALL );
					return;
				}
			}
			else
			{
				if ( node.waterCollider.surface )
				{
					if ( node.platformCollider.isHit )					// check platform hit
					{	
						transitionToPlatform();
						return;
					}
					else if ( fsmControl.check(CharacterState.JUMP) )	// check for jump
					{
						fsmControl.setState( CharacterState.JUMP );
						return;
					}
				}
				
				if( !node.waterCollider.float )
				{
					fsmControl.setState( CharacterState.DIVE );
					return;
				}
				
				// update
				super.updateStage();
			}
		}
		
		public function updateSwimming():void
		{
			if ( node.waterCollider.surface )
			{
				if ( Math.abs(node.motion.velocity.x) < node.characterMotionControl.swimSpeed)
				{
					//if ( node.timeline.looped )		
					//{
						//super.setAnim( SwimTread );
						super.updateStage = updateTreading;
					//}
				}
			}
		}
		
		public function updateTreading():void
		{
			if ( node.waterCollider.surface )
			{	
				if ( Math.abs(node.motion.velocity.x) >= node.characterMotionControl.swimSpeed)
				{
					//if ( node.timeline.looped )		
					//{
						//super.setAnim( Swim );
						super.updateStage = updateSwimming;
					//}
				}
			}
			else
			{
				//if ( node.timeline.looped )		
				//{
					//super.setAnim( Swim );
					super.updateStage = updateSwimming;
				//}
			}
		}
		
		public function transitionToPlatform():void
		{
			// TODO :: should we check accelerate (click down) for Run and Walk?
			var velXAbs:Number = Math.abs(node.motion.velocity.x);
			if ( velXAbs >= node.characterMotionControl.runSpeed)		// check walk
			{
				node.fsmControl.setState( CharacterState.RUN ); 
			}
			else if ( velXAbs >= node.characterMotionControl.walkSpeed )
			{
				node.fsmControl.setState( CharacterState.WALK ); 
			}
			else
			{
				node.fsmControl.setState( CharacterState.STAND );
			}
		}
	}
}