package game.data.animation.entity.character 
{
	public class Sleep extends Default
	{	
		public function Sleep()
		{
			//No Sleep animation for humans, unless this can be bunched with SitSleepLoop
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "sleep" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "sleep" + ".xml";
		}
	}
}