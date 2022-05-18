package game.data.animation.entity.character 
{
	import ash.core.Entity;
	/**
	 * ...
	 * @author Bard
	 */
	public class Think extends Default
	{		
		public function Think()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "think" + ".xml";
		}
	}

}