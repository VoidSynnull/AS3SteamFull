package game.data.animation.entity.character 
{
	public class Float extends Default
	{	
		public function Float()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "float" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "float" + ".xml";
		}
	}
}