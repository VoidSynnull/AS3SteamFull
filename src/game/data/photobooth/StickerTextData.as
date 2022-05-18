package game.data.photobooth
{
	import game.util.DataUtils;

	public class StickerTextData
	{
		public var text:String;
		public var font:String;
		public var size:Number;
		public var color:Number;
		public function StickerTextData(xml:XML = null)
		{
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			if(xml == null)
				return;
			if(xml.hasOwnProperty("text"))
				text = DataUtils.getString(xml.child("text")[0]);
			
			if(xml.hasOwnProperty("size"))
				size = DataUtils.getNumber(xml.child("size")[0]);
			
			if(xml.hasOwnProperty("font"))
				font = DataUtils.getString( xml.child("font")[0]);
			
			if(xml.hasOwnProperty("color"))
				color = DataUtils.getNumber(xml.child("color")[0]);
		}
		
		public function toXML():XML
		{
			var xml:XML = <text/>;
			var property:String;
			var xmlChild:XML;
			var xmlProperties:XML;
			
			xml.appendChild(new XML("<text>"+text+"</text>"));
			xml.appendChild(new XML("<size>"+size+"</size>"));
			xml.appendChild(new XML("<font>"+font+"</font>"));
			xml.appendChild(new XML("<color>"+color+"</color>"));
			
			return xml;
		}
		
		public function duplicate():StickerTextData
		{
			var text:StickerTextData = new StickerTextData();
			
			text.text = this.text;
			text.font = font;
			text.size = size;
			text.color = color;
			
			return text;
		}
	}
}