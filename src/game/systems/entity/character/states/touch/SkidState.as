package game.systems.entity.character.states.touch 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.Skid;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.SkidState;
	import game.util.CharUtils;

	public class SkidState extends game.systems.entity.character.states.SkidState 
	{
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			
			if ( fsmControl.check(CharacterState.HURT) )
			{
				fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if (  fsmControl.check(CharacterState.FALL)  )	
			{
				fsmControl.setState( CharacterState.FALL );
				return;
			} 
			else if ( node.motionControl.moveToTarget )
			{
				if ( fsmControl.check(CharacterState.JUMP) )
				{
					fsmControl.setState( CharacterState.JUMP );
					return;
				}
				
				fsmControl.setState( CharacterState.WALK );
				return;
			}
			/*
			else if ( charControl.directionChanged )	// if direction changes, interrupt skid	// TODO :: What if friction is involved?
			{
				charControl.directionChanged = false;	// set back to false
				fsmControl.setState( CharacterState.WALK );
				return;
			}
			*/
			else if ( CharUtils.getFriction(node.entity) != null )	// if friction is applied, wait until velocity zeroes before exiting skid
			{
				if( node.motion.velocity.x == 0 )
				{
					fsmControl.setState( CharacterState.STAND );
				}
			}
			else if ( CharUtils.animAtLastFrame( node.entity, Skid ) )
			{
				node.motion.velocity.x = 0;
				fsmControl.setState( CharacterState.STAND );
				return;
			}
		}
	}
}