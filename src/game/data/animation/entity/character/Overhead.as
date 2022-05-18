package game.data.animation.entity.character 
{
	public class Overhead extends Default
	{
		private const LABEL_END:String = "end";
		
		public function Overhead()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "overhead" + ".xml";
		}
	}
}