package game.data.animation.entity.character 
{
	public class SwimTread extends Default
	{		
		public function SwimTread()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/swimTread" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/swimTread" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/swimTread" + ".xml";
		}
	}
}