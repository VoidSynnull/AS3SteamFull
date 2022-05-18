package game.systems.actionChain {

	import engine.group.Group;
	import game.components.actionChain.ActionExecutor;
	import game.nodes.specialAbility.SpecialAbilityNode;
	

	// Runs several actions simultaneously and calls its callback function once all are complete.

	// Whereas MultiAction will execute a vector of actions simultaneously, ListOfActions
	// will execute a vector of actions in order, one after the other.
	// This can be useful for a list in a MultiAction, or to branch off a parallel action list
	// using the action.noWait = true parameter.
	// NOTE: ListOfActions with noWait=true may terminate early if the container ActionChain
	// completes before the list is finished. I need to work on this.
	public class ActionList extends ActionCommand {

		private var callback:Function;

		// NOTE: These actions run SIMULTANEOUSLY and are not guaranteed to run in any particular order.
		private var actions:Vector.<ActionCommand>;

		private var curIndex:int;

		private var executing:Boolean = false;
		private var executor:ActionExecutor;

		public function ActionList( actionList:Vector.<ActionCommand>=null ) {

			if ( actionList == null ) {
				actions = new Vector.<ActionCommand>();
			} else {
				actions = actionList;
			} //

		} //

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void {

			if ( actions.length == 0 ) {
				callback();
				return;
			}

			this.callback = callback;
			curIndex = 0;

			executing = true;

			var execSystem:ActionExecutionSystem = group.getSystem( ActionExecutionSystem ) as ActionExecutionSystem;
			if ( execSystem == null ) {
				execSystem = group.addSystem( new ActionExecutionSystem() ) as ActionExecutionSystem;
			}
			executor = execSystem.getDefaultExecutor();
			executor.addAction( actions[0], actionComplete );

		} //

		public function addAction( a:ActionCommand ):void {

			if ( executing ) {
				return;
			}

			actions.push( a );

		} //

		public function removeAction( a:ActionCommand ):void {

			if ( executing ) {			// this would screw everything up.
				return;
			}

			for( var i:int = actions.length-1; i >= 0; i-- ) {

				// order isn't preserved.
				if ( actions[i] == a ) {
					actions[i] = actions[actions.length-1];
					actions.pop();
				}

			} //

		} //

		// Called when one of the actions executing has completed.
		private function actionComplete( action:ActionCommand ):void {

			if ( ++curIndex >= actions.length ) {

				executing = false;
				callback();									// done.

			} else {

				executor.addAction( actions[curIndex], actionComplete );

			} //

		} //

	} // End MoveAction

} // End package