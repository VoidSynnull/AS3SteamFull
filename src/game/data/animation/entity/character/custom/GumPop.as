package  game.data.animation.entity.character.custom
{
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.entity.character.Default;

	public class GumPop extends Default
	{
		// used for putting gum in mouth and chewing and blowing bubble whick pops
		public function GumPop()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + AdvertisingConstants.AD_PATH_KEYWORD + "/gumPop" + ".xml";
		}
	}
}