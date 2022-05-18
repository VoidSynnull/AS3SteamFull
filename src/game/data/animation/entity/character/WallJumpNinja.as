package game.data.animation.entity.character 
{
	public class WallJumpNinja extends Default
	{
		private const LABEL_START_JUMP:String = "startJump";
		private const LABEL_STOP_JUMP:String = "stopJump";
		
		public function WallJumpNinja()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "wallJumpNinja" + ".xml";
		}
	}
}