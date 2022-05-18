package game.data.animation.entity.character 
{
	import ash.core.Entity;
	/**
	 * ...
	 * @author Bard
	 */
	public class Wave extends Default
	{		
		public function Wave()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "wave" + ".xml";
		}
	}

}