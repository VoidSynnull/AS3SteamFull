package game.systems.actionChain.actions
{
	import engine.ShellApi;
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;

	// Trigger an event
	// When executed, this action immediately triggers the triggerEvent (if defined.)
	// Then, if waitEvent is defined, it waits for waitEvent to complete the action.
	// if waitEvent is not defined, the action completes immediately.

	// Note: this class is sort of the reverse of WaitEvent, which waits for an event
	// and THEN optionally triggers an event, then completes.
	// Maybe later I'll combine an entire list of waits/triggers into a single class.
	public class EventAction extends ActionCommand 
	{
		private var api:ShellApi;
		private var triggerEvent:String;
		private var waitEvent:String;
		
		public var saveEvent:Boolean = false;
		
		private var _callback:Function;

		/**
		 * Trigger an event 
		 * @param shellApi			ShellApi
		 * @param triggerEvent		Event name to trigger
		 * @param waitEvent			Event to wait for
		 */
		public function EventAction( shellApi:ShellApi, triggerEvent:String=null, waitEvent:String=null, saveEvent:Boolean = false ) 
		{
			this.api = shellApi;
			this.triggerEvent = triggerEvent;
			this.waitEvent = waitEvent;
			this.saveEvent = saveEvent;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if ( this.triggerEvent != null ) 
			{
				this.api.triggerEvent( triggerEvent, saveEvent );
			}

			if ( waitEvent != null ) 
			{
				this._callback = callback;
				api.eventTriggered.add( this.eventComplete );
			} 
			else 
			{
				callback();
			}
		}

		private function eventComplete( event:String, save:Boolean, init:Boolean=false, removeEvent:String=null ):void
		{
			if ( event == waitEvent ) 
			{
				api.eventTriggered.remove( this.eventComplete );
				_callback(); // might want to copy this local and set cb() to null.
			}
		}
	}
}