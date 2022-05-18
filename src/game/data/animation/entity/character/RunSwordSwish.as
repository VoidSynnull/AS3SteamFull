package game.data.animation.entity.character 
{
	public class RunSwordSwish extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function RunSwordSwish()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "runSwordSwish" + ".xml";
		}
	}
}