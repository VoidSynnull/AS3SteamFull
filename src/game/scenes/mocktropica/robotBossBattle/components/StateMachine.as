package game.scenes.mocktropica.robotBossBattle.components {

	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.scenes.mocktropica.robotBossBattle.classes.State;
	
	import org.osflash.signals.Signal;

	/**
	 * 
	 * Edit this to automate state transitions based on actions/events?
	 * Plus states with automatic next-states.
	 * string id indicates what transition occured.
	 * 
	 */
	public class StateMachine extends Component {

		/**
		 * Default state when popping empty stack.
		 */
		private var _defaultState:State;

		/**
		 * Might need to transition to a new state while still remembering the previous state:
		 * For example, you might Dodge while attacking or while running. The state stack
		 * allows restoration of the previous state.
		 */
		private var stateStack:Vector.<State>;

		private var _currentState:State;
		private var states:Dictionary;

		/**
		 * Entity that the state machine refers to, or null.
		 */
		private var entity:Entity;

		/**
		 * Signal provides: Entity, NewState
		 */
		public var onStateChanged:Signal;

		public function StateMachine( targetEntity:Entity=null ) {

			super();

			this.entity = targetEntity;

			this.states = new Dictionary();
			this.onStateChanged = new Signal( Entity, State );

			this.stateStack = new Vector.<State>();

		} //

		/**
		 * Pushes the current state onto the state stack and makes the state
		 * with the given id the new current state.
		 */
		public function pushState( id:String ):void {

			this.stateStack.push( this._currentState );
			this.setState( id );

		} //

		/**
		 * Pops last state from the state stack and makes it the current state.
		 * If the stack is empty, defaultState becomes the current state.
		 */
		public function popState():void {

			if ( this.stateStack.length == 0 ) {
				this._currentState = this._defaultState;
			} else {
				this._currentState = this.stateStack.pop();
			}

		} //

		public function emptyStack():void {

			this.stateStack.length = 0;

		} //

		public function setDefaultState( id:String ):void {

			this._defaultState = this.states[ id ];

		} //

		public function addState( state:State ):void {

			this.states[ state.id ] = state;

		} //

		public function setState( id:String ):void {

			var s:State = this.states[ id ];
			if ( s ) {

				this._currentState = s;

				if ( s.onEnter != null ) {
					s.onEnter();
				}

				this.onStateChanged.dispatch( this.entity, s );

			} //

		} //

		public function setEntity( e:Entity ):void {
			this.entity = e;
		}

		public function getEntity():Entity {
			return this.entity;
		}

		public function getState( id:String ):State {

			return this.states[id];

		} //

		public function get currentState():State {

			return this._currentState;

		} //

		// this doesn't make sense because the state they might not be in the set dictionary.
		/*public function set currentState( state:State ):void {

			this._currentState = state;

		} //*/

	} // End StateMachine

} // End package