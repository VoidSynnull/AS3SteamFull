package game.data.photobooth
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.ExpressionData;
	import game.data.character.LookData;
	import game.util.DataUtils;
	import game.util.SkinUtils;

	public class StickerAssetData
	{
		public var asset:*;// display object or url
		public var url:String;//needs to be saved so it is no longer dependant on the photobooth for external uses
		public var id:String;
		public var tab:String;
		public var index:int;
		public var alpha:Number = 1;
		public var pose:int;
		public var look:LookData;
		public var expression:ExpressionData;
		public var text:StickerTextData;
		
		public function StickerAssetData(xml:XML = null)
		{
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			if(xml == null)
				return;
			if(xml.hasOwnProperty("asset"))
			{
				asset = DataUtils.getString(xml.child("asset")[0]);
				url = asset;
			}
			
			if(xml.hasOwnProperty("alpha"))
				alpha = DataUtils.getNumber(xml.child("alpha")[0]);
			
			if(xml.hasOwnProperty("@id"))
				id = DataUtils.getString(xml.attribute("id")[0]);
			
			if(xml.hasOwnProperty("tab"))
				tab = DataUtils.getString( xml.child("tab")[0]);
			
			if(xml.hasOwnProperty("index"))
				index = DataUtils.getNumber(xml.child("index")[0]);
			
			if(xml.hasOwnProperty("skin"))
			{
				if(xml.hasOwnProperty("pose"))
					pose = DataUtils.getNumber(xml.child("pose")[0]);
				else
					pose = 0;
				look = new LookData(xml.child("skin")[0]);
				look.fillWithEmpty();
				if(xml.hasOwnProperty("expression"))
					expression = new ExpressionData(xml.child("expression")[0]);
			}
			
			if(xml.hasOwnProperty("text"))
			{
				text = new StickerTextData(xml.child("text")[0]);
			}
		}
		
		public function toXML():XML
		{
			var xml:XML = <asset/>;
			var property:String;
			var xmlChild:XML;
			var xmlProperties:XML;
			
			xml.@id = id;
			xml.appendChild(new XML("<tab>"+tab+"</tab>"));
			xml.appendChild(new XML("<index>"+index+"</index>"));
			xml.appendChild(new XML("<alpha>"+alpha+"</alpha>"));
			xml.appendChild(new XML("<asset>"+url+"</asset>"));
			
			if(look != null)
			{
				xml.appendChild(new XML("<pose>"+pose+"</pose>"));
				xml.appendChild(new XML(<skin/>));
				xmlChild = xml.child("skin")[0];
				
				for ( var i:int = 0; i < SkinUtils.LOOK_ASPECTS.length; i++)
				{
					property = SkinUtils.LOOK_ASPECTS[i];
					if(look.getValue(property) != null)
						xmlChild.appendChild(new XML("<"+property+">"+look.getValue(property)+"</"+property+">"));
				}
				
				if(expression != null)
					xml.appendChild(expression.toXML());
			}
			if(text != null)
				xml.appendChild(text.toXML());
			return xml;
		}
		
		public function duplicate():StickerAssetData
		{
			var assetData:StickerAssetData = new StickerAssetData();
			
			assetData.asset = asset;
			assetData.url = url;
			assetData.id = id;
			assetData.tab = tab;
			assetData.index = index;
			assetData.pose = pose;
			assetData.alpha = alpha;
			if(look != null)
			{
				assetData.look = look.duplicate();
				if(expression != null)
					assetData.expression = expression.duplicate();
			}
			if(text != null)
				assetData.text = text.duplicate();
			return assetData;
		}
		
		public function destroy():void
		{
			if(asset is DisplayObjectContainer)
			{
				var bitmap:Bitmap = asset.getChildAt(0);
				if(bitmap)
					bitmap.bitmapData.dispose();
			}
			asset = null;
			url = null;
			id = null;
			tab = null;
			look = null;
			expression = null;
			text = null;
		}
	}
}