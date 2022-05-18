package game.data.animation.entity.character 
{
	public class TakePhoto extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function TakePhoto()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "takePhoto" + ".xml";
		}
	}
}