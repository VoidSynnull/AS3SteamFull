package game.systems.entity.character.states 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Skid;
	import game.util.CharUtils;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class SkidState extends CharacterState 
	{
		protected var _previousDirection:int = 0;
		
		public function SkidState()
		{
			super.type = CharacterState.SKID;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim( Skid );
			node.charMotionControl.ignoreVelocityDirection = false;
			_previousDirection = ( node.spatial.scaleX > 0 ) ? 0 : 1;
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var fsmControl:FSMControl = node.fsmControl;
			var directionChanged:Boolean = checkDirection();
			
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
			// TODO :: shoudln't jump on release
			else if ( fsmControl.check(CharacterState.JUMP) )
			{
				fsmControl.setState( CharacterState.JUMP );
				return;
			}
			else if ( directionChanged )	// if direction changes, interrupt skid	// TODO :: What if friction is involved?
			{
				//charControl.directionChanged = false;	// set back to false
				fsmControl.setState( CharacterState.WALK );
				return;
			}
			else if ( CharUtils.getFriction(node.entity) != null )	// if friction is applied, wait until velocity zeroes before to exiting skid
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
		
		private function checkDirection():Boolean
		{
			var currentDirection:int = ( node.spatial.scaleX > 0 ) ? 0 : 1;
			var directionChanged:Boolean = _previousDirection != currentDirection;
			_previousDirection = currentDirection;
			return directionChanged;
		}
	}
}