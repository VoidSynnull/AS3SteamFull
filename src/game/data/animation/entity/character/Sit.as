package game.data.animation.entity.character 
{
	/**
	 * ...
	 * @author Bard
	 */
	public class Sit extends Default
	{
		private const LABEL_loop:String = "loop";
		
		public function Sit()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "sit" + ".xml";
		}
	}

}