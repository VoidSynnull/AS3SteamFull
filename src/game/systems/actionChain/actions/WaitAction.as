package game.systems.actionChain.actions
{
	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Execute a delay
	// For any multi-action chain, you shouldn't really need this class, but it might help
	public class WaitAction extends ActionCommand 
	{
		/**
		 * Execute a delay 
		 * @param waitTime		Amount of delay
		 */
		public function WaitAction( waitTime:Number ):void
		{
			this.startDelay = waitTime;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
}