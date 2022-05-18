package game.data.animation.entity.character 
{
	public class Pull extends Default
	{
		private const LABEL_LOOP:String = "loop";
		private const LABEL_STOP:String = "stop";
		
		public function Pull()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/pull" + ".xml";
		}
	}
}