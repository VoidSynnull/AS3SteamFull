package game.data.animation.entity.character 
{
	public class Tossup extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function Tossup()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "tossup" + ".xml";
		}
	}
}