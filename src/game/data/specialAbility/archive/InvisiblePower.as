// Status: new and unused
// Usage: none

package game.data.specialAbility.character
{
	import flash.filters.GlowFilter;
	
	import engine.components.Display;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	
	/**
	 * Make avatar inivisble (web only since it uses glow filter) 
	 * @author uhockri
	 */
	public class InvisiblePower extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			node.entity.get(Display).displayObject.filters = [new GlowFilter(0x000000, 1, 4, 4, 1, 1, false, true)];
		}
	}
}