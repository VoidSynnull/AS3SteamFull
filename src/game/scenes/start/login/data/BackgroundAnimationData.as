package game.scenes.start.login.data
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import game.util.DataUtils;
	
	public class BackgroundAnimationData
	{
		public static const LEFT:String 	= "left";
		public static const RIGHT:String 	= "right";
		public static const TOP:String		= "top";
		public static const BOTTOM:String	= "bottom";
		
		public static const EASE_IN:String 		= "in";
		public static const EASE_OUT:String 	= "out";
		public static const EASE_IN_OUT:String 	= "inout";
		
		public var prefix:String;
		public var asset:*;
		private var _url:String
		public function get Url():String
		{
			return _url;
		}
		public var type:String;
		public var time:Number;
		public var ease:Function;
		// allows to be fully parsed via xml, or can also be partially assigned from shared group data
		public function BackgroundAnimationData(xml:XML = null, prefix:String = "", type:String = "")
		{
			this.type = type;
			this.prefix = prefix;
			parse(xml);
			if(isNaN(time))
			{
				time = 1;
			}
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@prefix") && !DataUtils.validString(prefix))
			{
				prefix = DataUtils.getString(xml.attribute("prefix")[0]);
			}
			
			asset = DataUtils.getString(xml);
			
			_url = prefix + asset;
			
			if(xml.hasOwnProperty("@type") && !DataUtils.validString(type))
			{
				type = DataUtils.getString(xml.attribute("type")[0]);
				if(type != LEFT && type != RIGHT && type != TOP && type != BOTTOM)
				{
					trace("WARNING! " + type + " is not a valid type.");
				}
			}
			
			if(xml.hasOwnProperty("@time"))
			{
				time = DataUtils.getNumber(xml.attribute("time")[0]);
			}
			if(xml.hasOwnProperty("@ease"))
			{
				var easeMethod:String = DataUtils.getString(xml.attribute("ease")[0]);
				switch(easeMethod.toLowerCase())
				{
					case EASE_IN:
					{
						ease = Quad.easeIn;
						break;
					}
					case EASE_IN_OUT:
					{
						ease = Quad.easeInOut;
						break;
					}
					case EASE_OUT:
					{
						ease = Quad.easeOut;
						break;
					}
					default:
					{
						ease = Linear.easeNone;
						break;
					}
				}
			}
		}
	}
}