package game.systems.entity.character.states.touch
{
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.systems.animation.FSMState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.DiveState;
	import game.systems.entity.character.states.SwimState;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	
	public class SwimState extends game.systems.entity.character.states.SwimState 
	{	
		private var _clickCounter:Number = 0;
		
		/**
		 * Manage the state
		 */
		override public function start():void
		{
			_clickCounter = 0;
			super.start();
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			charControl.waitingForRelease = false;
			
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
					if ( node.platformCollider.isHit )	// check platform hit
					{	
						transitionToPlatform();
						return;
					}
					else if ( node.motionControl.moveToTarget )	// if click down
					{
						if( node.motionControl.forceTarget )	// if force target don't wait on click
						{
							if ( fsmControl.check(CharacterState.JUMP) )			// check for jump
							{
								fsmControl.setState( CharacterState.JUMP ); 
								return;
							}
						}
						else
						{
							// need to check time determine is active inout is a click
							_clickCounter += time;
							charControl.waitingForRelease = true;
							
							// if counter passes click duration treat normally
							if( _clickCounter >= CLICK_DELAY )	
							{
								node.charMotionControl.waitingForRelease = false;
								
								// check for jump
								if ( node.fsmControl.check(CharacterState.JUMP) )
								{		
									node.fsmControl.setState( CharacterState.JUMP ); 
									return;
								}
							}
						}
					}
					else
					{
						if( _clickCounter > 0 && _clickCounter < CLICK_DELAY )
						{
							_clickCounter = 0;
							
							
							if ( node.fsmControl.check(CharacterState.JUMP) )
							{	
								node.charMotionControl.jumpTargetTrigger = true;	// makes CharacterJumpAssistSystem active
								node.fsmControl.setState( CharacterState.JUMP ); 
								return;
							}
						}
					}
				}
				
				// if pet then align vertically with player if player is swimming or diving
				if (isPet)
				{
					var playerState:FSMState = FSMControl(fsmControl.shellApi.player.get(FSMControl)).state;
					if ((playerState is game.systems.entity.character.states.touch.SwimState) || (playerState is game.systems.entity.character.states.touch.DiveState))
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
	}
}