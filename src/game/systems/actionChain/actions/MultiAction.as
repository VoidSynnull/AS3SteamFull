package game.systems.actionChain.actions {

	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Runs several actions simultaneously and calls its callback function once all are complete.
	// NOTE: don't try to add and remove actions from the MultiAction while it's _executing.
	// This could be accomodated, but I don't think it's worth the effort at the moment.
	public class MultiAction extends ActionCommand
	{
		// NOTE: These actions run SIMULTANEOUSLY and are not guaranteed to run in any particular order.
		private var actions:Vector.<ActionCommand>;
		
		private var _callback:Function;
		private var _completeCount:int; // number of actions which have completed _executing.
		private var _executing:Boolean = false;

		/**
		 * Runs several actions simultaneously and calls its callback function once all are complete. 
		 * @param actionList		List of actions
		 */
		public function MultiAction( actionList:Vector.<ActionCommand> = null )
		{
			if ( actionList == null )
				actions = new Vector.<ActionCommand>();
			else
				actions = actionList;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			if ( actions.length == 0 )
			{
				callback();
				return;
			}

			this._callback = callback;
			_completeCount = 0;

			_executing = true;
			DefaultExecutor.addActions( actions, actionComplete );
		}

		public function addAction( a:ActionCommand ):void
		{
			if ( _executing )
				return;

			actions.push( a );
		}

		public function removeAction( a:ActionCommand ):void
		{
			// this would screw everything up.
			if ( _executing )
				return;

			for( var i:int = actions.length-1; i >= 0; i-- )
			{
				// order isn't preserved.
				if ( actions[i] == a ) {
					actions[i] = actions[actions.length-1];
					actions.pop();
				}
			}
		}

		// Called when one of the actions _executing has completed.
		private function actionComplete( action:ActionCommand ):void
		{
			if ( ++_completeCount == actions.length )
			{
				_executing = false;
				_callback(); // done.
			}
		}
	}
}