package game.systems.entity.character.states.movieClip
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	
	public class MCDiveState extends MCState 
	{
		public var swimLabel:String = "swim";
		
		public function MCDiveState()
		{
			super.type = CharacterState.DIVE;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			node.motion.acceleration.x = 0;
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			this.setLabel(this.swimLabel);
			node.charMovement.state = CharacterMovement.DIVE;
		}
		
		private function end():void
		{
			node.spatial.rotation = 0;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			
			if ( node.fsmControl.check(CharacterState.HURT) )			// check for platform collision
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( !node.waterCollider.isHit )		// if no longer in contact with water
			{
				if ( node.platformCollider.isHit )
				{
					end();
					node.fsmControl.setState( CharacterState.LAND );
					return;
				} 
				else if( !node.wallCollider.isHit )
				{
					end();
					node.fsmControl.setState( CharacterState.FALL );
					return;
				}
			}
			else	// while in contact with water
			{
				if ( node.waterCollider.surface )		// if in contact with water surface
				{
					if ( node.platformCollider.isHit )		// check for platform
					{	
						end();
						node.fsmControl.setState( CharacterState.LAND );
						return;
					}
					else if ( node.fsmControl.check( CharacterState.JUMP) )		// check for jump
					{
						end();
						node.fsmControl.setState( CharacterState.JUMP );
						return;
					}
				}
				else								
				{		
					if( node.motion.velocity.y >= 0 )			// if moving downward, check for platform
					{
						if ( node.platformCollider.isHit )
						{	
							end();
							node.fsmControl.setState( CharacterState.LAND );
							return;
						}
					}
				}
			}
		}
	}
}