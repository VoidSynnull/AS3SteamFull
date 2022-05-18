package game.systems.actionChain.actions 
{		
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.util.MotionUtils;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Zeros all motion for entity
	public class ZeroMotionAction extends ActionCommand 
	{
		/**
		 * Zeros all motion for entity 
		 * @param entity		Entity affected
		 */
		public function ZeroMotionAction( entity:Entity ) 
		{
			this.entity = entity;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			MotionUtils.zeroMotion( entity );
			callback();
		}
	}
}