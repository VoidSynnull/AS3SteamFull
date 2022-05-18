package game.data.animation.entity.character 
{
	public class Attack extends Default
	{
		public static const TRIGGER:String =	"trigger";
		
		public function Attack()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "attack" + ".xml";
		}
	}
}