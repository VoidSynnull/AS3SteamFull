package game.data.specialAbility.store 
{
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import game.components.render.DisplayFilter;
	import game.data.specialAbility.character.MessWithNpcPower;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.render.DisplayFilterSystem;
	
	public class Midas extends MessWithNpcPower
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			node.entity.group.addSystem(new DisplayFilterSystem());
		}
		
		override protected function messWithNpc(npc:Entity):void
		{
			if(!npc.get(DisplayFilter))
			{
				var filter:DisplayFilter = new DisplayFilter();
				filter.inflate.setTo(20, 20);
				filter.filters.push(new GlowFilter(0xF7CA37, 1, 100, 100, 1.2, 1, true));
				filter.filters.push(new GlowFilter(0xF7CA37, 1, 20, 20, 1));
				filter.filters.push(new GlowFilter(0xFEF1C3, 1, 6, 6, 4, 1, true));
				npc.add(filter);
			}
			
			super.messWithNpc(npc);
		}
	}
}
