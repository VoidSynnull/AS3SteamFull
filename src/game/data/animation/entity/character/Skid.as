package game.data.animation.entity.character 
{
	/**
	 * ...
	 * @author billy
	 */
	public class Skid extends Default
	{		
		public function Skid()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/skid" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/skid" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/skid" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/skid" + ".xml";
		}
	}
}