package game.systems.actionChain.actions
{
	import ash.core.Entity;
	import engine.group.Group;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Remove component from entity
	public class RemoveComponentAction extends ActionCommand
	{
		public var component:Class;

		/**
		 * Remove component from entity 
		 * @param entity			Entity whose component to remove
		 * @param component			Component to remove
		 */
		public function RemoveComponentAction( entity:Entity, component:Class )
		{
			this.entity = entity;
			this.component = component;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			this.entity.remove( this.component );
		}
	}
}