package game.systems.actionChain.actions
{
	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Wait for signal to be dispatched
	
	// The problem is there are both Ash signals, and OSFlash signals
	// Since the add() and addOnce() interfaces are the same, this class can use either
	
	// Note that (currently) the arguments of the completed signal are lost.
	// Later this could be edited to return them in an action callback or something
	public class WaitSignalAction extends ActionCommand
	{
		private var waitSignal:Object;
		
		private var _callback:Function;

		/**
		 * Wait for signal to be dispatched
		 * @param signal		Signal to wait for
		 */
		public function WaitSignalAction( signal:Object )
		{
			this.waitSignal = signal;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			this._callback = callback;

			if ( this.waitSignal != null ) {
				this.waitSignal.addOnce( this.endAction );
			}
		}

		public function endAction( ...args ):void {

			var cb:Function = this._callback;
			if ( cb == null ) {
				return;
			}

			// we need to do this in case the callback leads to endAction()
			// being called again, and looping indefinitely.
			this._callback = null;

			cb();
		}
	}
}