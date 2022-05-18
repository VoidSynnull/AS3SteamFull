package game.data.animation.entity.character 
{
	public class FrontAimFire extends Default
	{
		private const LABEL_FRONT_FIRE:String = "frontFire";
		
		public function FrontAimFire()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "frontAimFire" + ".xml";
		}
	}
}