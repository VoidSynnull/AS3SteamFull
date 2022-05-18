package game.systems.actionChain.actions {
		
	import ash.core.Entity;

	import engine.group.Group;
	import game.components.motion.MotionControl;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Unlock/lock motion control for entity
	public class UnlockControlAction extends ActionCommand {

		public var unlockControl:Boolean;

		/**
		 * Unlock/lock motion control for entity 
		 * @param entity		Entity affect
		 * @param unlock		Unlock flag
		 * 
		 */
		public function UnlockControlAction( entity:Entity, unlock:Boolean = true ) 
		{
			super();
			this.entity = entity;
			this.unlockControl = unlock;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			var motionControl:MotionControl;
			if ( unlockControl ) 
			{
				motionControl = entity.get( MotionControl );
				if ( motionControl ) {
					motionControl.lockInput = false;
					motionControl.moveToTarget = false;
				}
			} 
			else 
			{
				motionControl = entity.get( MotionControl );
				if ( motionControl ) {
					motionControl.lockInput = true;
					motionControl.moveToTarget = false;
				}
			}
			callback();
		}
	}
}