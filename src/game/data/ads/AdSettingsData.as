package game.data.ads
{
	import game.util.DataUtils;
	
	public class AdSettingsData
	{
		public var forceMSinBB:Boolean = false; // force MainStreet ad in Billboard scene on browser
		public var forceMSinBBMobile:Boolean = false; // force MainStreet ad in Billboard scene on mobile
		public var carouselDelay:int = 10; // home scene billboard carousel delay
		public var minibillboardDelay:int = 10; // home scene billboard carousel delay
		public var bumperDelay:Number = 3.0; // mobile bumper delay when leaving app
		public var brandingDelay:Number = 15.0; // bradning timer delay in minutes
		public var networkAdsMobile:Boolean = true; // enable network ads on mobile
		public var custom1:String;
		public var custom2:String;
		public var custom3:String;
		public var custom4:String;
		
		// Apple and Google Play store URLs (wanted to keep these values outside of the core)
		public static const AppleStoreURL:String = "https://itunes.apple.com/us/app/poptropica/id818709874?mt=8";
		public static const GooglePlayStoreURL:String = "https://play.google.com/store/apps/details?id=air.com.pearsoned.poptropica";
		
		/**
		 * Constructor 
		 */
		public function AdSettingsData():void
		{
		}
		
		/**
		 * parse xml to fill data properties (currently only one) 
		 * @param xml
		 * @return AdSettingsData object
		 * 
		 */
		static public function parse(xml:XML):AdSettingsData
		{
			var data:AdSettingsData = new AdSettingsData();
			// if xml
			if (xml != null)
			{
				// get force main street in billboard value from xml (browser)
				data.forceMSinBB = DataUtils.getBoolean(xml.forceMSinBB);
				// get force main street in billboard value from xml (mobile)
				data.forceMSinBBMobile = DataUtils.getBoolean(xml.forceMSinBBMobile);
				// get carousel delay
				var delay:Number = DataUtils.getNumber(xml.carouselDelay);
				if (!isNaN(delay))
					data.carouselDelay = int(delay);
				// get carousel delay
				var bdelay:Number = DataUtils.getNumber(xml.minibillboardDelay);
				if (!isNaN(bdelay))
					data.minibillboardDelay = int(bdelay);
				// get bumper delay
				delay = DataUtils.getNumber(xml.bumperDelay);
				if (!isNaN(delay))
					data.bumperDelay = delay;
				// get branding delay
				delay = DataUtils.getNumber(xml.brandingDelay);
				if (!isNaN(delay))
					data.brandingDelay = delay;
				// get network ads for mobile
				if (xml.networkAdsMobile)
					data.networkAdsMobile = DataUtils.getBoolean(xml.networkAdsMobile);
				// get custom fields
				data.custom1 = String(xml.custom1);
				data.custom2 = String(xml.custom2);
				data.custom3 = String(xml.custom3);
				data.custom4 = String(xml.custom4);
			}
			return data;
		}
	}
}
