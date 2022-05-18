package game.data.animation.entity.character 
{
	public class SwordSwish extends Default
	{
		private const LABEL_SWING_1:String = "swing1";
		private const LABEL_SWING_2:String = "swing2";
		private const LABEL_SWING_3:String = "swing3";
		private const LABEL_SWING_4:String = "swing4";
		
		public function SwordSwish()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "swordSwish" + ".xml";
		}
	}
}