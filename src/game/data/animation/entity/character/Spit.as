package game.data.animation.entity.character 
{
	public class Spit extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function Spit()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "spit" + ".xml";
		}
	}
}