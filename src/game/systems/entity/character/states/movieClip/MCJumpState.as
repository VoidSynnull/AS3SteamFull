package game.systems.entity.character.states.movieClip
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Creature;
	import game.data.animation.FrameData;
	import game.systems.entity.character.states.CharacterState;
	
	public class MCJumpState extends MCState
	{
		private var _minXDistanceJumpSpin:Number;	// minimum distance for jump spin
		protected var _jumpFactorX:Number;
		protected var _jumpFactorY:Number;
		private const TRIGGER_LABEL:String = "trigger";
		protected const SLOPE_RANGE:Number = .5;
		
		public var jumpLabel:String = "jump";
		public var jumpSpinLabel:String = "jumpSpin";

		public function MCJumpState()
		{
			super.type = CharacterState.JUMP;
		}
		
		/*override public function setViewport( viewPort:Viewport  ):void 
		{
			_minXDistanceJumpSpin = viewPort.width * .1;
			_jumpFactorX = viewPort.width * .5;
			_jumpFactorY = viewPort.height * .2;
		}*/

		override public function check():Boolean
		{
			if ( node.motionControl.moveToTarget )
			{
				// use the slope to determine how far away the click happens from the player.
				if( checkRange() )
				{
					return true;
				}
			}
			return false;
		}
		
		public function checkRange():Boolean
		{
			return (-node.motionTarget.targetDeltaY > node.charMotionControl.inputDeadzoneY && Math.abs(-node.motionTarget.targetDeltaY / node.motionTarget.targetDeltaX) > SLOPE_RANGE)
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{
			node.charMotionControl.ignoreVelocityDirection = false;
			
			super.updateStage = this.updateCheckTrigger;
			
			// check for dampeners
			if ( node.fsmControl.check(CharacterState.SWIM) )
			{
				// TODO :: should only dampen if in water (not active for puddles)
				node.charMotionControl.jumpDampener = node.charMotionControl.jumpDampenerWater;
				//node.charMotionControl.jumpDampener = node.waterCollider.viscosity;
				
				if( !node.waterCollider.surface )	// if not on surface, then is jumping underwater, apply velocity & switch to DIVE state
				{
					applyJumpVelocity( node, node.charMotionControl.jumpDampener );	
					node.fsmControl.setState( CharacterState.DIVE );
					return;
				}
			}
			else
			{
				node.charMotionControl.jumpDampener = 1;
			}
			
			// update direction based on input
			this.directionByInput();
			node.charMovement.state = CharacterMovement.NONE;
			
			// determine whether jump should be a spin jump
			if ( !node.entity.get(Creature) )	// creatures don't spin when jumping
			{
				if ( Math.abs( node.motionTarget.targetDeltaX ) > _minXDistanceJumpSpin )
				{
					this.setLabel(jumpSpinLabel);
					return;
				}
			}
			
			this.setLabel(jumpLabel);
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{			
			if ( node.fsmControl.check(CharacterState.HURT) )		// check for hazard collision
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.CLIMB) )	// check for climb collision
			{
				node.fsmControl.setState( CharacterState.CLIMB );
				return;
			}
			else
			{
				super.updateStage();
			}
		}
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// UPDATE STAGES ////////////////////////
		/////////////////////////////////////////////////////////////////
		
		protected function updateCheckTrigger():void
		{	
			var charState:CharacterMotionControl = node.charMotionControl;
			var currentFrame:FrameData = node.timeline.data.getPreviousLabel(node.timeline.currentIndex);
			
			/*if( currentFrame.label == this.jumpLabel || currentFrame.label == this.jumpSpinLabel )
			{
				if ( !(node.timeline.currentIndex < node.primary.getLabelIndex(TRIGGER_LABEL)) )				
				{
					node.charMotionControl.ignoreVelocityDirection = true;

					super.updateStage = this.updateCheckFall;
					
					// if jump spin, apply rotation	
					if ( super.getCurrentAnim() == JumpSpin )	
					{
						charState.spinSpeed = charState.spinJumpRotation;
						charState.spinning = true;
						charState.spinEnd = false;
					}
					
					applyJumpVelocity( node, charState.jumpDampener );
					node.charMovement.state = CharacterMovement.AIR;
				}
			}*/
		}
		
		protected function applyJumpVelocity( node:MCStateNode, dampener:Number = 1 ):void
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
			
			super.directionByVelocity();
		}
		
		private function updateCheckFall():void
		{
			if ( node.motion.velocity.y >= 0 )	// once moving down, check for collision with surfaces
			{
				super.updateStage = this.updateCheckLand;
				updateCheckLand();
				return;
			}
			
			move();
		}
		
		protected function updateCheckLand():void
		{
			if ( node.platformCollider.isHit )		// check for platform collision
			{
				// if velocity is greater than run speed, update player's direction to face velocity
				if ( Math.abs(node.motion.velocity.x) > node.charMotionControl.runSpeed )
				{
					super.directionByVelocity();
				}
				
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.SWIM)  )	// check for water collision
			{
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.motion.velocity.y < 0 && node.fsmControl.check(CharacterState.FALL) )
			{
				// if velocity has reversed (if you start moving upwards) change state to fall
				node.fsmControl.setState( CharacterState.FALL );
				return;
			}
			
			move();
		}
		
		
		protected function move():void
		{
		}
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// HELPER METHODS ///////////////////////
		/////////////////////////////////////////////////////////////////
		
		/**
		 * Update facing direction by input
		 * @param	node
		 * @return
		 */
		private function directionByInput():void
		{
			if ( node.motionTarget.targetDeltaX > 0 )
			{
				node.spatial.scaleX = -node.spatial.scale;
			}
			else if( node.motionTarget.targetDeltaX < 0 )
			{
				node.spatial.scaleX = node.spatial.scale;
			}
		}
	}
}