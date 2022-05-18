package game.data.animation.entity.character 
{
	public class Disco extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function Disco()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "disco" + ".xml";
		}
	}
}