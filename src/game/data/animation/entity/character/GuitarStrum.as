package game.data.animation.entity.character 
{
	public class GuitarStrum extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function GuitarStrum()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "guitarStrum" + ".xml";
		}
	}
}