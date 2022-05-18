package game.components.actionChain {
	import game.systems.actionChain.ActionCommand;


	public class ExecutionItem {

		//static public const IDLE:int = 0;
		static public const PREACTION:int = 1;
		static public const ACTING:int = 2;
		static public const COMPLETE:int = 3;		// Complete indicates action was completed - postAction wait still has to happen.
		static public const POSTACTION:int = 4;

		public var action:ActionCommand;		// action to execute.
		public var timer:Number;				// preaction or postaction wait timer.

		// callback to whatever object first requested the action ( ActionChain or MultiAction, or ListOfActions )
		public var callback:Function;

		public var state:int;					// state of the action being executed.

		// execution batch id. An action may trigger a callback even after its execution
		// has been cancelled. By testing the batchId, the ExecutionList can
		// tell if an action was from an earlier batch.
		public var batchId:int;

		internal var prev:ExecutionItem;
		internal var next:ExecutionItem;

		public function ExecutionItem( action:ActionCommand, callback:Function, curBatch:int ) {

			this.action = action;
			this.callback = callback;

			this.batchId = curBatch;

		} //

		// Callback from the action itself.
		public function actionDone( ... args ):void {

			// Unfortunately this is just a marker for the ExecutionList.
			// We might lose one frame waiting for it to pick up the change. (depends on System execution order)
			state = COMPLETE;

		} //

	} // End ExecutionState

} // End package