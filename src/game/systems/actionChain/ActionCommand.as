package game.systems.actionChain {

	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.actionChain.ActionExecutor;
	import game.nodes.specialAbility.SpecialAbilityNode;

	public class ActionCommand 
	{
		/**
		 * The problem with the default executor is that subgroups will use the executor from a (possibly paused) parent group.
		 * DefaultExecutor shouldn't be used at all really, but there are a few cases where it's hard to get around.
		 */
		static public var DefaultExecutor:ActionExecutor;

		public var name:String;		// Users can set this to test the name of a completed action.

		// Entity to which the action refers. (npc moving, talking, panning, etc.)
		// May be null for some subclasses, but it's so ubiquitous that I'll leave it.
		public var entity:Entity;

		public var lockInput:Boolean = false;		// If true, player can't move while this action is occuring.
		public var startDelay:Number = 0;			// Time to wait before action starts.
		public var endDelay:Number = 0;				// Time to wait after action ends.

		// If noWait == true, the next action in the action sequence will execute immediately without waiting
		// for this one to complete. waitStart will still apply, but waitEnd will not. notifications for the action still occur.
		public var noWait:Boolean = false;

		// Subclasses can point this at an update function that will update with a time variable.
		// This could be used for example, to check if a pan clip has been centered on screen.
		public var update:Function;

		public function ActionCommand() 
		{
		}

		// AS3 access modifier limitations prevents making this internal like it should be. (subpackages have no acces)
		// A custom namespace would be a hassle.
		// This is the function that actually performs the Action (timers, callbacks be damned.) It should only be
		// called by the ActionExecutor.
		// Don't call this. Why are you calling this?
		public function preExecute( _pcallback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
		}

		/**
		 * Run the action within the context of a given group. An action executor will be added automatically if necessary.
		 */
		public function run( group:Group, callback:Function ):void
		{
			var execSystem:ActionExecutionSystem = group.getSystem( ActionExecutionSystem ) as ActionExecutionSystem;
			if ( execSystem == null ) {
				execSystem = group.addSystem( new ActionExecutionSystem() ) as ActionExecutionSystem;
			}
			execSystem.getDefaultExecutor().addAction( this, callback );
		}

		public function execute( callback:Function, executor:ActionExecutor=null ):void
		{
			if ( executor ) {
				executor.addAction( this, callback );
			} else {
				DefaultExecutor.addAction( this, callback );
			}
		}

		/**
		 * Subclasses can add their own cancellation code in override.
		 */
		public function cancel():void
		{
		}

		/**
		 * Subclasses can add their own revert code in override.
		 */
		public function revert( group:Group ):void
		{
		}
		
	} // End ActionCommand

} // End package