package game.data.animation.entity.character 
{
	
	/**
	 * ...
	 * @author Bard
	 */
	public class Drink extends Default
	{		
		private const LABEL_SET_COLOR:String = "setColor";
		
		public function Drink()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "drink" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "drink" + ".xml";
		}
	}
}