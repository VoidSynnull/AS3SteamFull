// Used by:
// Card 3034 using ability phantom_power_35

package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Set alpha property of an object or entity
	public class SetAlphaAction extends ActionCommand
	{
		public var object:*;
		public var alpha:Number;

		/**
		 * Set alpha property of an object or entity
		 * @param object		Object - can be entity
		 * @param alpha			Alpha value
		 */
		public function SetAlphaAction( object:*, alpha:Number ) 
		{
			this.object 	= object;
			this.alpha 		= alpha;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			// if object valid
			if ( object )
			{
				// if entity
				if (object is Entity)
				{
					Entity(object).get(Display).alpha = alpha;
				}
				else
				{
					// if not entity
					object.alpha = alpha;
				}
			}
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
		
		override public function revert( group:Group ):void
		{
			// set alpha to 100 percent
			// if object valid
			if ( object )
			{
				// if entity
				if (object is Entity)
				{
					Entity(object).get(Display).alpha = 1;
				}
				else
				{
					// if not entity
					object.alpha = 1;
				}
			}
		}
	}
}