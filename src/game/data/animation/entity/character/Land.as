package game.data.animation.entity.character 
{
	public class Land extends Default
	{		
		public function Land()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/land" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/land" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/land" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/land" + ".xml";
		}
	}
}