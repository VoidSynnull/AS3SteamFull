package game.data.animation.entity.character 
{
	public class SuperSlash extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function SuperSlash()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "superSlash" + ".xml";
		}
	}
}