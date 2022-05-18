package game.data.animation.entity.character.custom
{
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.entity.character.Default;
	
	public class WaspFly extends Default
	{
		public function WaspFly()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + AdvertisingConstants.AD_PATH_KEYWORD + "/waspFly" + ".xml";
		}
	}
}