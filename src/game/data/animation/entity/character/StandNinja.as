package game.data.animation.entity.character 
{
	public class StandNinja extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function StandNinja()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "standNinja" + ".xml";
		}
	}
}