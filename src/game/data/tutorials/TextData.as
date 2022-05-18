package game.data.tutorials
{
	import flash.geom.Point;

	public class TextData
	{
		public function TextData(txt:String, style:String, loc:Point, width:Number = 300)
		{
			this.text = txt;
			this.styleId = style;
			this.location = loc;
			this.width = width;
		}
		
		public var text:String;
		public var styleId:String;
		public var location:Point;
		public var width:Number;
	}
}