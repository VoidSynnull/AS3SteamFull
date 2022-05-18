package game.systems.entity.character.states.movieClip 
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.FrameData;
	import game.systems.entity.character.states.CharacterState;
	import game.util.Utils;
	
	public class MCLandState extends MCState 
	{
		public var landLabel:String = "land";
		public var spinLabel:String = "spin";
		public var landSpinLabel:String = "landSpin";
		public var swimLandLabel:String = "swimLand";
		public var swimLandSpinLabel:String = "swimLandSpin";
		
		private var _transitionTo:String = "";
		
		public function MCLandState()
		{
			super.type = CharacterState.LAND;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			
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
						this.setLabel(this.spinLabel);
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
						this.setLabel(this.landLabel);
						super.updateStage = this.updateAnimEnd;		// wait for end of Land animation
					}
				}
			}
			else if ( node.fsmControl.check( CharacterState.SWIM ) )	// if not landing on platform, must be in water
			{
				if ( charControl.spinning )
				{
					this.setLabel(this.spinLabel);
					charControl.spinSpeed = charControl.spinLandRotation * Utils.getCharge( charControl.spinSpeed ) ;
					charControl.spinEnd = true;
					super.updateStage = this.updateSpin;
				}
				else
				{
					this.setLabel(this.swimLandLabel);
					super.updateStage = this.updateAnimEnd;
				}
			}
			
			charControl.ignoreVelocityDirection = true;
			// SkinUtils.setEyeStates( node.entity, EyeSystem.BLINK, null, false );	// this needs more testing, blink is still a little unstable called outside out the EyeSystem. - Bard
			node.charMovement.state = CharacterMovement.NONE;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void 
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			
			//trace(node
			if ( node.fsmControl.check( CharacterState.HURT ) )		// check for hazard collision				
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if (!node.platformCollider.isHit && !node.fsmControl.check( CharacterState.SWIM ))	// check for platform & water collision				
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
		
		private function updateAnimEnd( node:MCStateNode ):void
		{
			if(true)
			{
				//MovieClip timelines don't have functionality for checking an animation ending currently...
				node.charMotionControl.animEnded = false;
				
				// determine current animation, transition to appropriate state
				var currentFrame:FrameData = node.timeline.data.getPreviousLabel(node.timeline.currentIndex);
				if(currentFrame)
				{
					if ( currentFrame.label == this.swimLandLabel || currentFrame.label == this.swimLandSpinLabel )
					{
						node.fsmControl.setState( CharacterState.SWIM );
						return;		
					}
					else
					{
						node.fsmControl.setState( CharacterState.STAND );
						return;	
					}
				}
			}
		}
		
		private function updateSpin( node:MCStateNode ):void
		{
			if ( node.charMotionControl.spinStopped )
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
					this.setLabel(this.landSpinLabel);
					super.updateStage = updateAnimEnd;
				}
				else if ( node.fsmControl.check(CharacterState.SWIM) )
				{
					this.setLabel(this.swimLandSpinLabel);
					super.updateStage = updateAnimEnd;
				}
			}
		}
	}
}