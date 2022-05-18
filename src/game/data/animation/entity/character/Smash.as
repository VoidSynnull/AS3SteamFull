package game.data.animation.entity.character 
{
	public class Smash extends Default
	{
		private const LABEL_STOP:String = "stop";
		
		public function Smash()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "smash" + ".xml";
		}
	}
}