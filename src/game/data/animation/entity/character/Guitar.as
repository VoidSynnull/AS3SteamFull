package game.data.animation.entity.character 
{
	public class Guitar extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function Guitar()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "guitar" + ".xml";
		}
	}
}