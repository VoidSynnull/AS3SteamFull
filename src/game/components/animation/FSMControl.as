package game.components.animation
{	
	import ash.core.Component;
	
	import engine.ShellApi;
	
	import game.systems.animation.FSMState;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;

		
	public class FSMControl extends Component
	{
		public var shellApi:ShellApi;
		
		public function FSMControl(shellApi:ShellApi)
		{
			this.shellApi = shellApi;
			_states = new Vector.<FSMState>();
		}

		private var _active:Boolean = true;
		public function get active():Boolean	{ return _active; }
		public function set active(bool:Boolean):void	
		{ 
			if( bool && !_active )
			{
				_invalidate = true;
			}
			_active = bool;
		}

		public var _invalidate:Boolean = false;
		private var _states:Vector.<FSMState>;	
		private var _currentState:FSMState;
		public function get state():FSMState	{ return _currentState; }
		
		public var stateChange:Signal; 				// signal that is only set off if you create it. Dispatched on state change
		
		/**
		 * Determines if a state with the given type has been added to the FSMControl.
		 * @param	stateType
		 */
		public function hasType( stateType:String ):Boolean
		{
			for ( var i:uint = 0; i < _states.length; i++ )
			{
				if( _states[i].type == stateType )
				{
					return true;
				}
			}
			return false;
		}

		/**
		 * Set the current state by type.
		 * @param	stateType
		 */
		public function setState( stateType:String = "" ):void
		{
			if ( _currentState )
			{
				if ( _currentState.type == stateType )
				{
					return;
				}
			}	
			var fsmState:FSMState = getState( stateType );
			if ( fsmState )
			{
				if( _currentState != null )	{ _currentState.exit(); }
				_currentState = fsmState;
				_invalidate = true;
			}
		}

		/**
		 * Add CharacterState, will replace any existing CharacterState with same type.
		 * @param	specialAbilityData
		 * @return
		 */
		public function addState( fsmState:FSMState, type:String = "" ):FSMState
		{
			if ( DataUtils.validString( type ) ) 
			{ 
				fsmState.type = type; 
			}

			// check for same type, but not same instance
			var index:int = getStateIndex( fsmState.type );
			if ( index == -1 )	// if index not found, create new state
			{
				//charState.control = this;
				_states.push( fsmState );
				return fsmState;
				
			}
			else	// if index found, replace state
			{
				_states[index] = fsmState;
				return fsmState;
			}
		}
		
		/**
		 * Get CharacterState by type.
		 * @param	type
		 * @return
		 */
		public function getState( type:String ):FSMState
		{
			if ( _currentState )
			{
				if( _currentState.type == type )
				{
					return _currentState;
				}
			}
	
			var fsmState:FSMState;
			for ( var i:uint = 0; i < _states.length; i++ )
			{
				fsmState = _states[i];
				if( fsmState.type == type )
				{
					return fsmState;
				}
			}
			
			return null;
		}
		
		/**
		 * Get index of state, used for replacement.
		 * @param	type
		 * @return
		 */
		private function getStateIndex( type:String ):int
		{
			var fsmState:FSMState;
			for ( var i:uint = 0; i < _states.length; i++ )
			{
				fsmState = _states[i];
				if( fsmState.type == type )
				{
					return i;
				}
			}
			return -1;
		}
		
		/**
		 * Remove CharacterState by type
		 * NOTE :: Removing essential states will cause errors.
		 * @param	type
		 */
		public function removeState( type:String ):void
		{
			var fsmState:FSMState;
			for ( var i:uint = 0; i < _states.length; i++ )
			{
				fsmState = _states[i];
				if( fsmState.type == type )
				{
					fsmState.destroy();
					_states.splice( i, 1 )
					return;
					// TODO :: May need to do further removal steps?
				}
			}
		}
		
		public function removeAll():void
		{
			var fsmState:FSMState;
			for ( var i:uint = 0; i < _states.length; i++ )
			{
				fsmState = _states[i];
				fsmState.destroy();
			}
			_states.length = 0;
		}
		
		/**
		 * Check for state, and state's check method.
		 * NOTE :: Removing essential states will cause errors.
		 * @param	type
		 */
		public function check( type:String ):Boolean
		{
			var fsmState:FSMState = getState(type)
			if( fsmState )
			{
				return fsmState.check();
			}
			else
			{
				return false;
			}
		}
	}
}