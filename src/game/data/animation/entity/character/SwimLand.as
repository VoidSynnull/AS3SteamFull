package game.data.animation.entity.character 
{
	public class SwimLand extends Default
	{		
		public function SwimLand()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/swimLand" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/swimLand" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/swimLand" + ".xml";
		}
	}
}