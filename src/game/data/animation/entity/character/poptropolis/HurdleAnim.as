package game.data.animation.entity.character.poptropolis 
{
	import game.data.animation.entity.character.Default;

	public class HurdleAnim extends Default
	{		
		private const LABEL_RUN:String = "run";
		private const LABEL_JUMP:String = "jump";
		private const LABEL_STOP:String = "stop";
		
		public function HurdleAnim()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "poptropolis/hurdles" + ".xml";
		}
	}
}