package game.data.animation.entity.character.poptropolis 
{
	import game.data.animation.entity.character.Default;

	public class DiveAnim extends Default
	{		
		private const LABEL_START_ROTATION:String = "startRotation";
		private const LABEL_DIVING_EXTENDED:String = "divingExtended";
		private const LABEL_DIVING_CURL:String = "divingCurl";
		private const LABEL_DIVING_CURLING:String = "divingCurling";
		private const LABEL_START_UNCURLING:String = "startUncurling";
		
		public function DiveAnim()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "poptropolis/diving" + ".xml";
		}
	}
}