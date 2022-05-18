package game.data.ads
{
	import game.util.DataUtils;

	public class MessageData
	{
		public var layer:String;
		public var date:String;
		
		public function MessageData(xml:XML = null)
		{
			parse(xml);
		}
		
		public function parse(xml:XML):void {
			if(xml == null) {
				return;
			}
			date = "";
			if(xml.hasOwnProperty("@date")) {
				date = DataUtils.getString(xml.attribute("date")[0]);
			}
			layer = DataUtils.getString(xml.attribute("layer")[0]);
			trace(layer);
		}
	}
}