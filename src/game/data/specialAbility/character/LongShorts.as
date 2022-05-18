// Used by:
// Card 2672 using overpants limited_tb2_brady

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;

	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.SkinUtils;

	/**
	 * Set overpants as pants
	 */
	public class LongShorts extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			
			var container:DisplayObjectContainer = null;
			var pants:Entity = SkinUtils.getSkinPartEntity(node.entity,SkinUtils.OVERPANTS);
			if(pants)
			{
				var disp:Display = pants.get(Display);
				disp.displayObject.parent.setChildIndex(disp.displayObject,disp.displayObject.parent.numChildren - 4);
			}
			super.setActive(true);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			super.setActive(true);
			var pants:Entity = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.OVERPANTS);
			var disp:Display = pants.get(Display);
			disp.displayObject.parent.setChildIndex(disp.displayObject, disp.displayObject.parent.numChildren - 4);
		}

		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.setActive( false );
		}	
	}
}