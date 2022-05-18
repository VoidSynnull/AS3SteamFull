package game.systems.entity.character.states.movieClip 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	
	public class MCSwimState extends MCState 
	{
		public var swimLabel:String = "swim";
		public var swimTreadLabel:String = "swimTread";
		
		public function MCSwimState()
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
			
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
			
			// update swim speed
			if ( Math.abs(node.motion.velocity.x) >= node.charMotionControl.swimSpeed)
			{
				this.setLabel(this.swimLabel);
				super.updateStage = updateSwimming;
				
			}
			else
			{
				this.setLabel(this.swimTreadLabel);
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
				if ( Math.abs(node.motion.velocity.x) < node.charMotionControl.swimSpeed)
				{
					if ( node.timeline.looped )		
					{
						this.setLabel(this.swimTreadLabel);
						super.updateStage = updateTreading;
					}
				}
			}
		}
		
		public function updateTreading():void
		{
			if ( node.waterCollider.surface )
			{	
				if ( Math.abs(node.motion.velocity.x) >= node.charMotionControl.swimSpeed)
				{
					if ( node.timeline.looped )		
					{
						this.setLabel(this.swimLabel);
						super.updateStage = updateSwimming;
					}
				}
			}
			else
			{
				if ( node.timeline.looped )		
				{
					this.setLabel(this.swimLabel);
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