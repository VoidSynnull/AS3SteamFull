package game.data.photobooth
{
	import game.util.DataUtils;

	public class StickerSheet
	{
		public var stickers:Vector.<StickerAssetData>;
		public var title:String;
		public var columns:uint;
		public function StickerSheet(xml:XML = null)
		{
			title = "";
			columns = 1;
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			stickers = new Vector.<StickerAssetData>();
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("@title"))
				title = DataUtils.getString(xml.attribute("title")[0]);
			
			if(xml.hasOwnProperty("@columns"))
				columns = DataUtils.getUint(xml.attribute("columns")[0]);
			
			for(var i:int = 0; i < xml.children().length(); ++i)
			{
				stickers.push(new StickerAssetData(xml.children()[i]));
			}
		}
		
		public function getStickerById(id:String):StickerAssetData
		{
			for(var i:int = 0; i < stickers.length; ++i)
			{
				if(stickers[i].id == id)
					return stickers[i];
			}
			
			return null;
		}
		
		public function destroy():void
		{
			while(stickers.length > 0)
			{
				stickers.pop().destroy();
			}
			stickers = null;
			title = null;
		}
	}
}