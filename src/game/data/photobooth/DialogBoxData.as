package game.data.photobooth
{
	import game.util.DataUtils;

	public class DialogBoxData
	{
		public var type:String;
		public var asset:String;
		public var prefix:String;
		public var text:String;
		public var alternateText:String;
		public var confirmText:String;
		public var cancelText:String;
		
		public var numBtns:uint = 2;
		
		public function DialogBoxData(xml:XML = null)
		{
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(type == null)
				type = DataUtils.getString(xml.attribute("type")[0]);
			if(!DataUtils.validString(type))
				type = DEFAULT;
			
			if(xml.hasOwnProperty("asset"))
				asset = DataUtils.getString(xml.child("asset")[0]);
			if(xml.hasOwnProperty("prefix"))
				prefix = DataUtils.getString(xml.child("prefix")[0]);
			
			if(xml.hasOwnProperty("confirmText"))
				confirmText = DataUtils.getString(xml.child("confirmText")[0]);
			if(xml.hasOwnProperty("cancelText"))
				cancelText = DataUtils.getString(xml.child("cancelText")[0]);
			
			if(xml.hasOwnProperty("numBtns"))
				numBtns = DataUtils.getUint(xml.child("numBtns")[0]);
			
			if(xml.hasOwnProperty("alternate"))
				alternateText = DataUtils.getString(xml.child("alternate")[0]);
			
			if(xml.hasOwnProperty("warning"))
				text = DataUtils.getString(xml.child("warning")[0]);
			else
			{
				switch(type)
				{
					case AD:
					{
						text = AD_WARNING_GENERIC;
						break;
					}
						
					case CONTEST:
					{
						text = CONTEST_WARNING_GENERIC;
						break;
					}
						
					case DEV:
					{
						text = DEV_WARNING_GENERIC;
						break;
					}
						
					case DEFAULT:
					{
						text = DEFAULT_WARNING;
						break;
					}
				}
			}
		}
		
		public static const AD:String			= "ad";// ads will probably ask if the player wants to visit their site
		public static const CONTEST:String  	= "contest";// contests will ask if the player wants to save their pic to the server
		public static const DEV:String			= "dev";// for saving xml
		public static const DEFAULT:String		= "default";// for saving to profile
		
		public static const CONTEST_WARNING_GENERIC:String 	=  "If you win, your Poptropican will be added to the Photo Booth for a limited time. We may also share your creation on social media!";
		public static const AD_WARNING_GENERIC:String 		=  "You are now leaving Poptropica.";
		public static const DEV_WARNING_GENERIC:String 		=  "Save this scene to xml?";
		public static const DEFAULT_WARNING:String			=  "Save this scene to your profile?";
	}
}