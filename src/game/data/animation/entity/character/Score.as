package game.data.animation.entity.character 
{
	import ash.core.Entity;
	/**
	 * ...
	 * @author Bard
	 */
	public class Score extends Default
	{		
		public function Score()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "score" + ".xml";
		}
	}

}