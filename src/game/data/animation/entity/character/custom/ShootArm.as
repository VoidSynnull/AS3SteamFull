package game.data.animation.entity.character.custom 
{
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.entity.character.Default;

	public class ShootArm extends Default
	{
		public function ShootArm()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + AdvertisingConstants.AD_PATH_KEYWORD + "/shootArm" + ".xml";
		}
	}
}