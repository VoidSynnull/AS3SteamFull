package game.data.animation.entity.character 
{
	public class Throw extends Default
	{
		private const LABEL_STOP:String = "stop";
		
		public function Throw()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "throw" + ".xml";
		}
	}

}