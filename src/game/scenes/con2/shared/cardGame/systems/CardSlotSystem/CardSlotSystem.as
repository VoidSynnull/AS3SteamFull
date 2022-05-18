package game.scenes.con2.shared.cardGame.systems.CardSlotSystem
{
	import game.systems.GameSystem;
	
	public class CardSlotSystem extends GameSystem
	{
		public function CardSlotSystem()
		{
			super(CardSlotNode, updateNode);
		}
		
		public function updateNode(node:CardSlotNode, time:Number):void
		{
			if(node.cardSlot.highLight)
			{
				node.cardSlot.highLightValue += time * node.cardSlot.highLightSpeed;
				if(node.cardSlot.highLightValue > node.cardSlot.maxHihgLight || node.cardSlot.highLightValue < 0)
				{
					node.cardSlot.highLightSpeed *= -1;
					node.cardSlot.highLightValue += time * node.cardSlot.highLightSpeed;
				}
			}
			else
				node.cardSlot.highLightValue = 0;
			
			if(node.cardSlot.display == null)
				node.display.alpha = node.cardSlot.highLightValue;
			else
				node.cardSlot.display.alpha = node.cardSlot.highLightValue;
		}
	}
}