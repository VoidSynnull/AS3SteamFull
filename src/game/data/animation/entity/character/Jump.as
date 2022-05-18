package game.data.animation.entity.character 
{
	public class Jump extends Default
	{		
		public function Jump()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/jump" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/jump" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/jump" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/jump" + ".xml";
		}
	}
}