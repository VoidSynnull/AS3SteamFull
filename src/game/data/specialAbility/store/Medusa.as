// Used by:
// Card 3033 using marks medusa

package game.data.specialAbility.store
{	
	import ash.core.Entity;
	
	import game.components.entity.character.part.PartLayer;
	import game.components.specialAbility.character.Medusa;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.specialAbility.character.MedusaSystem;
	import game.util.CharUtils;

	/**
	 * Add Medusa system to marks part
	 */
	public class Medusa extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{	
			super.init(node);
			
			// Add the Medusa Sytem if it's not there already
			if( !medusaSystem )
			{
				medusaSystem = new MedusaSystem();
				node.entity.group.addSystem( medusaSystem );
			}
			partEntity = CharUtils.getPart(node.entity, "marks");
			
			var partLayer:PartLayer = partEntity.get(PartLayer);
			partLayer.layer = 0;
			
			partEntity.add(new game.components.specialAbility.character.Medusa() );
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			partEntity = CharUtils.getPart(node.entity, "marks");
			partEntity.remove(game.components.specialAbility.character.Medusa);
			var partLayer:PartLayer = partEntity.get(PartLayer);
			if (partLayer != null)
			{
				partLayer.layer = 16;
			}
		}
		
		private var medusaSystem:MedusaSystem;
		private var partEntity:Entity;
	}
}