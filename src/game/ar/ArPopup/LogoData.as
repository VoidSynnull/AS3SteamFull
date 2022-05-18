package game.ar.ArPopup
{
	import flash.geom.Point;
	
	import game.util.DataUtils;
	
	public class LogoData
	{
		public var asset:*;
		public var position:Point = new Point();
		public var percent:Boolean = false;
		public function LogoData(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			asset = DataUtils.getString(xml.child("asset")[0]);
			
			if(xml.hasOwnProperty("position"))
				position = DataUtils.getPoint(xml.child("position")[0]);
			
			if(xml.hasOwnProperty("percent"))
				percent = DataUtils.getBoolean(xml.child("percent")[0]);
		}
	}
}