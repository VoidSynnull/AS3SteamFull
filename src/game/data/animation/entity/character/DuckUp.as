package game.data.animation.entity.character 
{
	public class DuckUp extends Default
	{		
		public function DuckUp()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/duckDown" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/duckDown" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/duckUp" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/duckUp" + ".xml";
		}
	}
}