package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.data.animation.Animation;

	public class Fishing extends Default
	{
		public function Fishing()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "fishing" + ".xml";
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void 
		{
			if(label == Animation.LABEL_BEGINNING)
			{
				super.turnOffItemMotion( entity, true );
			}
			else if (label == Animation.LABEL_ENDING)
			{
				super.turnOffItemMotion( entity, false );
			}
		}
	}
}