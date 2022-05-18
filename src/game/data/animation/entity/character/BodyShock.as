package game.data.animation.entity.character 
{
	public class BodyShock extends Default
	{
		public function BodyShock()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "bodyShock" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "bodyShock" + ".xml";
		}
	}
}