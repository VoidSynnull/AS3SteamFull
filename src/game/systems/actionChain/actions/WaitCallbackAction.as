package game.systems.actionChain.actions
{
	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Wait for callback from function 
	
	// This action calls an optional startFunction, which will be sent a reference to the endAction()
	// function, which can be called at any time to complete the WaitCallbackAction.

	// For example: I have a door object, with an openDoor( onDoorComplete ) command, which takes as a parameter
	// the function to call when the door is done opening:
	// door.openDoor( onDoorComplete:Function )
	// WaitCallbackAction( door.openDoor ) executes the openDoor function, setting onDoorComplete to
	// the endAction() function.
	// Alternatively, the action can be completed by calling endAction() directly.
	public class WaitCallbackAction extends ActionCommand
	{
		private var startFunction:Function;
		
		private var _callback:Function;

		/**
		 * Wait for callback from function 
		 * @param startFunction		Function whose callback to wait for
		 */
		public function WaitCallbackAction( startFunction:Function ) 
		{
			this.startFunction = startFunction;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			this._callback = callback;

			if ( startFunction != null ) {
				startFunction( endAction );
			}
		}

		public function endAction( ...args ):void 
		{
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