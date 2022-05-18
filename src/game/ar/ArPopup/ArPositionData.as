package game.ar.ArPopup
{
	import flash.geom.Point;
	
	import game.util.DataUtils;

	public class ArPositionData
	{
		public var node:int = ArEffectSysytem.NOSE_TOP;//node to follow 0-67
		public var rotation:Number = 0;
		public var scale:Number = 1;
		public var offset:Point = new Point();
		public var flipped:Boolean = false;//between rotation and vertically flipped you can achieve both flipX and flipY
		
		public function ArPositionData(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("node"))
				node = DataUtils.getUint(xml.child("node")[0]);
			
			if(xml.hasOwnProperty("rotation"))
				rotation = DataUtils.getNumber(xml.child("rotation")[0]);
			
			if(xml.hasOwnProperty("scale"))
				scale = DataUtils.getNumber(xml.child("scale")[0]);
			
			if(xml.hasOwnProperty("offset"))
				offset = DataUtils.getPoint(xml.child("offset")[0]);
			
			if(xml.hasOwnProperty("flipped"))
				flipped = DataUtils.getBoolean(xml.child("flipped")[0]);
		}
	}
}