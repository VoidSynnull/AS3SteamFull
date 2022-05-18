package game.data.animation.entity.character 
{
	/**
	 * ...
	 * @author Bard
	 */
	public class Hurt extends Default
	{		
		public function Hurt()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/hurt" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/hurt" + ".xml";
		}
	}

}