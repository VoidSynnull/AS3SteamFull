package game.data.animation.entity.character 
{
	public class Fall extends Default
	{	
		public function Fall()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/fall" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/fall" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/fall" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/fall" + ".xml";
		}
	}
}