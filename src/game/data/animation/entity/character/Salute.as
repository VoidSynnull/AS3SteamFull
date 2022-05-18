package game.data.animation.entity.character 
{
	public class Salute extends Default
	{
		private const LABEL_STOP:String = "stop";
		
		public function Salute()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "salute" + ".xml";
		}
	}
}