package game.data.animation.entity.character 
{
	public class KeyboardTyping extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function KeyboardTyping()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "keyboardTyping" + ".xml";
		}
	}
}