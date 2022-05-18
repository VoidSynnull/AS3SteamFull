package game.data.animation.entity.character 
{
	public class AttackRun extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function AttackRun()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "attackRun" + ".xml";
		}
	}
}