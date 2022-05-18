package game.data.animation.entity.character 
{
	public class JumpSwordSwish extends Default
	{
		private const LABEL_SPIN:String = "spin";
		private const LABEL_LAND:String = "land";
		
		public function JumpSwordSwish()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "jumpSwordSwish" + ".xml";
		}
	}
}