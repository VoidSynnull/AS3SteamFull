package game.scenes.examples.customCharacter.states
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.scenes.examples.customCharacter.CustomCharacterNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.Utils;

	public class LandState extends CustomCharacterState
	{
		private var _transitionTo:String = "";
		
		public function LandState()
		{
			super.type = CharacterState.LAND;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			
			if ( node.platformCollider.isHit )	// if landing on platform
			{
				if ( node.fsmControl.check( CharacterState.DUCK ) )		// check for direct transition to duck
				{
					node.fsmControl.setState( CharacterState.DUCK );
					return;
				}
				else
				{
					if ( charControl.spinning )
					{
						if ( !node.motionControl.moveToTarget )
						{
							node.motion.friction.x = charControl.frictionStop;
						}
						//super.setAnim( Spin );
						charControl.spinSpeed = charControl.spinLandRotation * Utils.getCharge( charControl.spinSpeed ) ;
						charControl.spinEnd = true;
						super.updateStage = this.updateSpin;		// wait for end of spin
					}
					else
					{
						if( !node.fsmControl.check( CharacterState.JUMP ) )	// believe this is the culprit...
						{
							if( node.fsmControl.check( CharacterState.RUN )  )
							{
								node.fsmControl.setState( CharacterState.RUN ); 
								return;
							}
							else if ( node.fsmControl.check( CharacterState.WALK )  )
							{
								node.fsmControl.setState( CharacterState.WALK ); 
								return;
							}
						}
						
						node.motion.friction.x = charControl.frictionStop;
						//setAnim( Land, true );
						super.updateStage = this.updateAnimEnd;		// wait for end of Land animation
					}
				}
			}
			else if ( node.fsmControl.check( CharacterState.SWIM ) )	// if not landing on platform, must be in water
			{
				if ( charControl.spinning )
				{
					//setAnim( Spin );
					charControl.spinSpeed = charControl.spinLandRotation * Utils.getCharge( charControl.spinSpeed ) ;
					charControl.spinEnd = true;
					super.updateStage = this.updateSpin;
				}
				else
				{
					//setAnim( SwimLand, true);
					super.updateStage = this.updateAnimEnd;
				}
			}
			
			charControl.ignoreVelocityDirection = true;
			// SkinUtils.setEyeStates( node.entity, EyeSystem.BLINK, null, false );	// this needs more testing, blink is still a little unstable called outside out the EyeSystem. - Bard
			node.characterMovement.state = CharacterMovement.NONE;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void 
		{
			var charControl:CharacterMotionControl = node.characterMotionControl;
			
			if ( node.fsmControl.check( CharacterState.HURT ) )		// check for hazard collision				
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( !node.platformCollider.isHit && !node.fsmControl.check( CharacterState.SWIM ) )	// check for platform & water collision				
			{
				node.fsmControl.setState( CharacterState.FALL );
				return;
			}
			else
			{
				super.updateStage( node );
			}
		}
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// UPDATE STAGES ////////////////////////
		/////////////////////////////////////////////////////////////////
		
		private function updateAnimEnd( node:CustomCharacterNode ):void
		{
			/*
			if ( node.characterMotionControl.animEnded )	// if animation has ended
			{
				// determine current animation, transition to appropriate state
				var currentClass:Class = Utils.getClass(node.primary.current);
				if ( currentClass == Land || currentClass == LandSpin )
				{
					node.fsmControl.setState( CharacterState.STAND );
					return;	
				}
				else if ( currentClass == SwimLand || currentClass == SwimLandSpin )
				{
					node.fsmControl.setState( CharacterState.SWIM );
					return;		
				}
			}
			*/
			
			if(node.waterCollider && node.waterCollider.isHit)
			{
				node.fsmControl.setState( CharacterState.SWIM );
			}
			else
			{
				node.fsmControl.setState( CharacterState.STAND );
			}
		}
		
		private function updateSpin( node:CustomCharacterNode ):void
		{
			if ( node.characterMotionControl.spinStopped )
			{
				if ( node.platformCollider.isHit )
				{
					if ( node.motionControl.moveToTarget )
					{
						if ( node.fsmControl.check(CharacterState.DUCK) )
						{
							node.fsmControl.setState( CharacterState.DUCK );
							return;	
						}
						
						if( node.fsmControl.check(CharacterState.RUN)  )
						{
							node.fsmControl.setState( CharacterState.RUN ); 
							return;
						}
						else if ( node.fsmControl.check(CharacterState.WALK)  )
						{
							node.fsmControl.setState( CharacterState.WALK ); 
							return;
						}
					}
					//super.setAnim( LandSpin, true );
					super.updateStage = updateAnimEnd;
				}
				else if ( node.fsmControl.check(CharacterState.SWIM) )
				{
					//super.setAnim( SwimLandSpin, true );
					super.updateStage = updateAnimEnd;
				}
			}
		}
	}
}