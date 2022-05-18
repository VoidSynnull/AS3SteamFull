// Used by:
// Card 2694 using hair limited_mh_gooliope
// Card 2696 using hair limited_mh_mobile_gooliope
// Card 2437 using ability limited/grow_with_timer

package game.systems.actionChain.actions
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.motion.ScaleTarget;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.systems.motion.ScaleSystem;
	import game.util.CharUtils;

	// Set scaleTarget property so the entity scales up/down to target scale
	public class SetScaleTargetAction extends ActionCommand
	{
		public var scaleTarget:Number = 0.18;

		/**
		 * Set scaleTarget property so the entity scales up/down to target scale
		 * @param entity		Entity whose scaleTarget component to modify
		 * @param scaleTarget	Target scale (default is half size)
		 */
		public function SetScaleTargetAction( entity:Entity, scaleTarget:Number = 0.18) 
		{
			this.entity 		= entity;
			this.scaleTarget 	= scaleTarget;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if (!group.hasSystem(ScaleSystem))
				group.addSystem(new ScaleSystem());
			
			// add component if missing
			if (!entity.has(ScaleTarget))
			{
				var component:Component = new ScaleTarget(scaleTarget);
				entity.add(component);
			}
			else
			{
				entity.get(ScaleTarget).target = scaleTarget;
			}

			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
		
		override public function revert( group:Group ):void
		{
			// set single entity scale to standard
			if (entity)
			{
				entity.remove(ScaleTarget);
				CharUtils.setScale(entity, 0.36);
			}
		}
	}
}