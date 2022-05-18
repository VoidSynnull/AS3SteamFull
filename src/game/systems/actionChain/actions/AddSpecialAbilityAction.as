
package game.systems.actionChain.actions
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;

	public class AddSpecialAbilityAction extends ActionCommand 
	{
		private var _entity:Entity;
		private var _power:String;
		
		public function AddSpecialAbilityAction(entity:Entity, ability:String)
		{
			_entity = entity;
			_power = ability;
			
		}
		
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			node.owning.group.shellApi.specialAbilityManager.addSpecialAbilityById(_entity, _power, true);
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
	
}