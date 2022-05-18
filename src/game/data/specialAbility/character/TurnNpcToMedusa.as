package game.data.specialAbility.character
{
	import ash.core.Entity;
	
	import game.components.entity.character.part.SkinPart;
	import game.components.specialAbility.character.Medusa;
	import game.util.SkinUtils;
	
	public class TurnNpcToMedusa extends MessWithNpcPower
	{
		override protected function messWithNpc(npc:Entity):void
		{
			var partEntity:Entity = SkinUtils.getSkinPartEntity(npc, "marks");
			var part:SkinPart = partEntity.get(SkinPart);
			if(part.value == "medusa")// if you've already turned them revert them
			{
				// need to remove the component before the display object is switched
				// because the system makes assumptions about its display object
				partEntity.remove(game.components.specialAbility.character.Medusa);
				part.revertValue();
			}
			else//else let em have it
			{
				SkinUtils.setSkinPart(npc, "marks", "medusa",false);// don't think you can revert if it is permanent
			}
			
			super.messWithNpc(npc);
		}
	}
}