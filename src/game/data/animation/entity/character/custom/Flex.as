package game.data.animation.entity.character.custom 
{
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.entity.character.Default;

	public class Flex extends Default
	{
		private const LABEL_TRIGGER:String = "trigger";
		
		public function Flex()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + AdvertisingConstants.AD_PATH_KEYWORD + "/flex" + ".xml";
		}
	}
}