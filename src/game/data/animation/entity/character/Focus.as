package game.data.animation.entity.character 
{
	import ash.core.Entity;

	public class Focus extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function Focus()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "focus" + ".xml";
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