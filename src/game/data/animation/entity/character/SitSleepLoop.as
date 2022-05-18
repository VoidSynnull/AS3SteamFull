package game.data.animation.entity.character 
{
	public class SitSleepLoop extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function SitSleepLoop()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "sitSleepLoop" + ".xml";
		}
	}
}