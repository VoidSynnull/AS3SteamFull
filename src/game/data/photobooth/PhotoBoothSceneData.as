package game.data.photobooth
{
	import game.data.photobooth.StickerData;

	public class PhotoBoothSceneData
	{
		public var sceneStickers:Vector.<StickerData>;
		public var bg:StickerData;
		public var stickerNumber:int = 0;
		public function PhotoBoothSceneData(xml:XML = null)
		{
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			sceneStickers = new Vector.<StickerData>();
			var xmlChild:XML = xml.child("stickers")[0];
			for(var i:int = 0; i < xmlChild.children().length(); ++i)
			{
				sceneStickers.push(StickerData.parse(xmlChild.children()[i]));
			}
			if(xml.hasOwnProperty("bg"))
			{
				bg = StickerData.parse(xml.child("bg")[0].child("sticker")[0]);
			}
		}
		
		public function toXML():XML
		{
			var xml:XML = new XML(<scene/>);
			
			var xmlChild:XML = new XML(<stickers/>);
			xml.appendChild(xmlChild);
			
			var stickerData:StickerData;
			for each (stickerData in sceneStickers)
			{
				xmlChild.appendChild(stickerData.toXML());
			}
			
			if(bg != null)
			{
				xmlChild = new XML(<bg/>);
				xmlChild.appendChild(bg.toXML());
				xml.appendChild(xmlChild);
			}
			return xml;
		}
		
		public function duplicate():PhotoBoothSceneData
		{
			var sceneData:PhotoBoothSceneData = new PhotoBoothSceneData();
			if(bg != null)
				sceneData.bg = bg.duplicate();
			sceneData.sceneStickers = new Vector.<StickerData>();
			for(var i:int = 0; i < sceneStickers.length; ++i)
			{
				sceneData.sceneStickers.push(sceneStickers[i].duplicate());
			}
			return sceneData;
		}
	}
}