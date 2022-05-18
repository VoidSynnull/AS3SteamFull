// Used by:
// Card 2647 using item limited_mixels_niksputbrick

package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.EntityUtils;

	// Set visibility property of an object or entity
	public class SetVisibleAction extends ActionCommand
	{
		public var object:*;
		public var visibility:Boolean;

		/**
		 * Set visibility property of an object or entity
		 * @param object		Object - can be entity
		 * @param visibility	Visibility flag
		 */
		public function SetVisibleAction( object:*, visibility:Boolean) 
		{
			this.object 		= object;
			this.visibility 	= visibility;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			// if object valid
			if ( object )
			{
				// if entity
				if (object is Entity)
				{
					EntityUtils.visible(object, visibility,true);
				}
				else
				{
					// if not entity
					object.visible = visibility;
				}
			}
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
}