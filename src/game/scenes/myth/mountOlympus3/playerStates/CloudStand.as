package game.scenes.myth.mountOlympus3.playerStates
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.Stand;
	
	public class CloudStand extends CloudCharacterState
	{
		public static const TYPE:String = "cloudStand";
		private var _clickCounter:Number = 0;
		private var _checkForClick:Boolean;
		private const FIRE_DELAY:Number	= .2;
		
		public function CloudStand()
		{
			super.type = CloudStand.TYPE;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			_clickCounter = 0;
			_checkForClick = true;
			super.setAnim( Stand );
			node.charMotionControl.ignoreVelocityDirection = true;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var fsmControl:FSMControl = node.fsmControl;
			var charControl:CharacterMotionControl = node.charMotionControl;

			if ( fsmControl.check( CloudHurt.TYPE ) )			// check for hurt
			{
				fsmControl.setState( CloudHurt.TYPE );
				return;
			}
			else if ( node.motionControl.moveToTarget )		// input is active & outside of input deadzone
			{
				if( _checkForClick )
				{
					node.flight.move = false;
					_clickCounter += time;
					if( _clickCounter >= FIRE_DELAY )	
					{
						_checkForClick = false;
					}
					else
					{
						return;
					}
				}
			}
			else
			{
				// if counter is still in range of click delay
				if( _checkForClick && _clickCounter > 0 && _clickCounter < FIRE_DELAY )
				{
					node.flight.move = false;
					node.motion.zeroMotion();
					fsmControl.setState( CloudAttack.TYPE );
					return;
				}
				
				_checkForClick = true;
				_clickCounter = 0;
			}
			node.flight.move = true;
		}
	}
}