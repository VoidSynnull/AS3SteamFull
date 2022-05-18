package game.data.animation.entity.character 
{
	/**
	 * ...
	 * @author billy
	 */
	public class JumpSpin extends Default
	{		
		public function JumpSpin()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/jumpSpin" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/jump" + ".xml";
		}
	}
}