package game.data.photobooth
{
	import game.util.DataUtils;

	public class HeaderData
	{
		public var type:String;
		public var asset:*;
		public var button:String;// if button name is null will assume entire asset is button
		public var popup:DialogBoxData;
		public function HeaderData(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@type"))
				type = DataUtils.getString(xml.attribute("type")[0]);
			
			if(xml.hasOwnProperty("popup"))
			{
				popup = new DialogBoxData();
				if(type != null)
					popup.type = type;
				popup.parse( xml.child("popup")[0]);
			}
			
			asset = DataUtils.getString(xml.child("asset")[0]);
			
			if(xml.hasOwnProperty("button"))
				button = DataUtils.getString(xml.child("button")[0]);
		}
	}
}