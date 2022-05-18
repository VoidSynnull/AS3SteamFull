package game.systems.actionChain {

	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.actionChain.ActionExecutor;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.SystemPriorities;
	import game.util.SceneUtil;

	// Class executes a sequence of Say commands, pans, character animations, and move commands.
	public class ActionChain {

		static public const NO_INDEX:int = -1;

		private var _actions:Vector.<ActionCommand>;		// All the things we gots to do, in order.
		private var _curAction:ActionCommand;				// The thing that is right now a-happening.
		private var _curIndex:int;							// current action index.
		private var _curState:int;

		public var lockInput:Boolean = false;			// Lock input while sequence occurs.
		public var lockPosition:Boolean = false;		// lock position of player, according to SceneUtils.lockControl()

		public var autoUnlock:Boolean = true;			// automatically unlock input when done.

		// chain complete notification. Format: function onComplete( actionChain:ActionChain ):void
		public var onComplete:Function;

		// Action about to start / Action ended notifications.
		// Format: function onActionStart( action:ActionCommand )
		public var onActionStart:Function;					// Called after an action start time completes, right before action starts.
		public var onActionEnd:Function;					// Called when the action is completely done.


		// ActionCommands might need access to the current group in order to provide functionality.
		// Also an entity with an executionList is automatically added to the group.
		private var _scene:Group;

		// The executionList is attached to this entity so it will be picked up by the execution system. It's shoddy but
		// it saves users the trouble of dealing with the actionChain's entity/system setup.
		private var _executionEntity:Entity;

		private var _executing:Boolean;
		private var _executor:ActionExecutor;
		
		// In case their are multiple actions saved and someone needs to access them by their id
		public var id:String;

		public function ActionChain( scene:Group, actions:Vector.<ActionCommand>=null )
		{
			this._scene = scene;

			if ( actions != null ) {
				this._actions = actions;
			} else {
				this._actions = new Vector.<ActionCommand>();
			}

			//player = group.getEntityById( "player" );

			// Automatically add an ActionChainSystem
			if ( scene.getSystem( ActionExecutionSystem ) == null ) {
				scene.addSystem( new ActionExecutionSystem(), SystemPriorities.update );
			}

			_executor = new ActionExecutor( this._scene );
			_executionEntity = new Entity();
			scene.addEntity( _executionEntity );

		} // ActionSequence()

		public function execute( onDone:Function=null, node:SpecialAbilityNode = null ):void {

			if ( onDone != null ) {
				onComplete = onDone;
			}
			if ( lockInput == true ) {
				SceneUtil.lockInput( _scene, true, lockPosition );
			} //

			this._executing = true;
			this._curIndex = NO_INDEX;

			_executor.start(node);

			if ( this._executionEntity.get( ActionExecutor ) == null ) {
				_executionEntity.add( _executor );
			} //

			nextAction();

		} //

		public function nextAction():void {

			if ( (++_curIndex) == _actions.length ) {
				endSequence();
				return;
			}

			_curAction = _actions[ _curIndex ];
			startAction();

		} //

		public function startAction():void {

			if ( onActionStart != null ) {
				onActionStart( _curAction );
			}

			if ( _curAction.noWait == true ) {

				_executor.addAction( _curAction, endNoWaitAction );
				nextAction();

			} else {

				_executor.addAction( _curAction, endAction );

			} //

		} //

		// A noWait action already passed beyond its place in the execution list.
		public function endNoWaitAction( action:ActionCommand ):void {

			if ( onActionEnd != null ) {
				onActionEnd( action );
			}

		} //

		public function endAction( action:ActionCommand ):void {

			if ( onActionEnd != null ) {
				onActionEnd( action );
			}

			// nextAction will set waiting and curState.
			nextAction();

		} //

		public function addAction( action:ActionCommand ):ActionCommand {

			_actions.push( action );
			return action;
		} //

		public function setActions( actions:Vector.<ActionCommand> ):void {

			_actions = actions;

		} //

		public function addActions( actions:Vector.<ActionCommand> ):void {
			_actions.concat( actions );
		} //

		public function clearActions():void 
		{

			_actions.length = 0;
			_curAction = null;

			this._executing = false;
			this._curIndex = NO_INDEX;

			_executor.stop();
			_executionEntity.remove( ActionExecutor );

			// No end sequence notification ( for now. )

		} //

		private function endSequence():void {

			_curAction = null;
			_curIndex = NO_INDEX;
			_executing = false;

			_executor.stop();
			_executionEntity.remove( ActionExecutor );

			if ( lockInput && autoUnlock ) {
				SceneUtil.lockInput( _scene, false );
			} //

			if ( onComplete != null ) {
				onComplete( this );
			}

		} //

		// Call destroy after use to remove entity and get rid of references.
		public function destroy():void {

			_executor.stop();

			_scene.removeEntity( _executionEntity );
			_executionEntity.remove( ActionExecutor );

			_executor = null;
			_executionEntity = null;
			_scene = null;
			
			_actions = null;

		} //	
		
		public function revokeActions():void
		{
			for each(var action:ActionCommand in _actions)
			{
				action.revert(group);
			}
		}

		public function get executor():ActionExecutor { return _executor }

		public function get group():Group { return _scene; }
		public function get executing():Boolean { return _executing; }
		public function get actionIndex():int { return _curIndex; }
		public function get currentAction():ActionCommand { return _curAction; }
		public function get currentState():int { return _curState; }

	} // End ActionSequence

} // End package