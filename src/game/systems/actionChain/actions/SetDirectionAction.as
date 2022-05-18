package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.util.CharUtils;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;
	
	// Set direction of entity
	public class SetDirectionAction extends ActionCommand
	{
		private var faceRight:Boolean;
		
		/**
		 * Set direction of entity 
		 * @param target		Entity whose direction we are changing
		 * @param faceRight		Boolean flag for facing right
		 */
		public function SetDirectionAction(target:Entity, faceRight:Boolean = true) 
		{
			this.entity = target;
			this.faceRight = faceRight;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			CharUtils.setDirection(this.entity, faceRight);
			
			if(callback)
				callback();
		}		
	}
}