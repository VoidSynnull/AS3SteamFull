package game.systems.actionChain.actions
{
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	
	public class RemoveEntityAction extends ActionCommand
	{
		private var entityToRemove:*;
		public function RemoveEntityAction(entityToRemove:*)
		{
			this.entityToRemove = entityToRemove;
		}
		
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode=null):void
		{
			if( entityToRemove is String)
				entityToRemove = group.getEntityById(entityToRemove);
			if(entityToRemove)
				group.removeEntity(entityToRemove);
			
			_pcallback();
		}
	}
}