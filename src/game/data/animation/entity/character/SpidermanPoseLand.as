package game.data.animation.entity.character 
{
	public class SpidermanPoseLand extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		private const LABEL_LAND:String = "land";
		
		public function SpidermanPoseLand()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "spidermanPoseLand" + ".xml";
		}
	}
}