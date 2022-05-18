package game.data.animation.entity.character 
{
	public class UpperCutSlash extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function UpperCutSlash()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "upperCutSlash" + ".xml";
		}
	}
}