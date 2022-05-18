package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	import game.data.animation.Animation;

	public class SledgeHammer extends Default
	{
		private const LABEL_STOP:String = "stop";
		
		public function SledgeHammer()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "sledgeHammer" + ".xml";
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