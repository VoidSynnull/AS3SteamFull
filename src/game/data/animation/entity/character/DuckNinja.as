package game.data.animation.entity.character 
{
	public class DuckNinja extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function DuckNinja()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "duckNinja" + ".xml";
		}
	}
}