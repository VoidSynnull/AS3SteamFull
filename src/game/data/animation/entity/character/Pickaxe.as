package game.data.animation.entity.character 
{
	public class Pickaxe extends Default
	{
		private const LABEL_LOOP:String = "loop";
		
		public function Pickaxe()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "pickaxe" + ".xml";
		}
	}
}