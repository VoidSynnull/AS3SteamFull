package game.data.animation.entity.character 
{
	/**
	 * ...
	 * @author Bard
	 */
	public class Pop extends Default
	{		
		public function Pop()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "pop" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "pop" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "pop" + ".xml";
		}
	}
}