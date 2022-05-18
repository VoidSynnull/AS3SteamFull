package game.data.animation.entity.character 
{
	public class Read extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function Read()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "read" + ".xml";
		}
	}
}