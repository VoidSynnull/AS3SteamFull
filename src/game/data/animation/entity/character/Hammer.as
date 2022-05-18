package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.components.entity.character.part.item.ItemMotion;
	import game.data.animation.Animation;
	import game.util.CharUtils;
	
	/**
	 * ...
	 * @author Bard
	 */
	public class Hammer extends Default
	{		
		public function Hammer()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "hammer" + ".xml";
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			if(label == Animation.LABEL_BEGINNING)
			{
				turnOffItemMotion( entity, true );
			}
			else if (label == Animation.LABEL_BEGINNING)
			{
				turnOffItemMotion( entity, false );
			}
		}
		
		override protected function turnOffItemMotion( entity:Entity, turnOff:Boolean = true ):void
		{
			var itemPart:Entity = CharUtils.getPart( entity, CharUtils.ITEM );
			if( itemPart )
			{
				var itemMotion:ItemMotion = itemPart.get(ItemMotion); 
				if( itemMotion )
				{
					if( turnOff )
					{
						itemMotion.state = ItemMotion.NONE;
					}
					else
					{
						itemMotion.state = ItemMotion.ROTATE_TO_SHOULDER;
					}
				}
			}
		}
	}

}