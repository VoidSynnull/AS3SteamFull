package game.data.animation.entity.character 
{
	public class RunNinja extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function RunNinja()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "runNinja" + ".xml";
		}
	}
}