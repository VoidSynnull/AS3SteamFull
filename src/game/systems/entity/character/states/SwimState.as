package game.systems.entity.character.states 
{
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Swim;
	import game.data.animation.entity.character.SwimTread;
	import game.data.character.CharacterData;
	import game.systems.animation.FSMState;
	import game.util.CharUtils;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class SwimState extends CharacterState 
	{
		private var speedThreshold:Number;
		protected var isPet:Boolean = false;
		// if you adjust PET_OFFSET, you may want to adjust the WaterCollider surfaceOffset in CharacterGroup.as
		protected const PET_OFFSET:Number = 42;

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
			isPet = (Character(node.entity.get(Character)).currentCharData.variant == CharacterData.VARIANT_PET_BABYQUAD);
			speedThreshold = node.charMotionControl.swimSpeed;
			if (isPet)
			{
				speedThreshold = node.charMotionControl.petSwimSpeed;
			}
			// if not pet
			else
			{
				// pets don't have dive state
				if ( CharUtils.DENSITY > node.waterCollider.densityHit )
				{
					node.fsmControl.setState( CharacterState.DIVE );
					return;
				}
			}
			
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
			
			// update swim speed
			if ( Math.abs(node.motion.velocity.x) >= speedThreshold)
			{
				super.setAnim( Swim );
				super.updateStage = updateSwimming;
				
			}
			else
			{
				super.setAnim( SwimTread );
				super.updateStage = updateTreading;
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			
			if ( fsmControl.check(CharacterState.HURT) )			// check for platform collision
			{
				if (!isPet)
				{
					fsmControl.setState( CharacterState.HURT );
					return;
				}
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
				// if on surface
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
				
				// if pet then align vertically with player if player is swimming or diving
				if (isPet)
				{
					var playerState:FSMState = FSMControl(fsmControl.shellApi.player.get(FSMControl)).state;
					if ((playerState is SwimState) || (playerState is DiveState))
					{
						// align pet with player with offset
						node.spatial.y = fsmControl.shellApi.player.get(Spatial).y + PET_OFFSET;
					}
				}
				
				if( !node.waterCollider.float )
				{
					if (!isPet)
					{
						fsmControl.setState( CharacterState.DIVE );
						return;
					}
				}

				// update
				super.updateStage();
			}
		}

		public function updateSwimming():void
		{
			if ( node.waterCollider.surface )
			{
				if ( Math.abs(node.motion.velocity.x) < speedThreshold)
				{
					if ( node.timeline.looped )		
					{
						super.setAnim( SwimTread );
						super.updateStage = updateTreading;
					}
				}
			}
		}
		
		public function updateTreading():void
		{
			if ( node.waterCollider.surface )
			{	
				if ( Math.abs(node.motion.velocity.x) >= speedThreshold)
				{
					if ( node.timeline.looped )		
					{
						super.setAnim( Swim );
						super.updateStage = updateSwimming;
					}
				}
			}
			else
			{
				if ( node.timeline.looped )		
				{
					super.setAnim( Swim );
					super.updateStage = updateSwimming;
				}
			}
		}
		
		public function transitionToPlatform():void
		{
			// TODO :: should we check accelerate (click down) for Run and Walk?
			var velXAbs:Number = Math.abs(node.motion.velocity.x);
			if ( velXAbs >= node.charMotionControl.runSpeed)		// check walk
			{
				node.fsmControl.setState( CharacterState.RUN ); 
			}
			else if ( velXAbs >= node.charMotionControl.walkSpeed )
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