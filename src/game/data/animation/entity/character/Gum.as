package game.data.animation.entity.character 
{
	import ash.core.Entity;
	
	public class Gum extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function Gum()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "gum" + ".xml";
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			if ( label == LABEL_TRIGGER )
			{
				//Do a wave?
			}
		}
	}
}

