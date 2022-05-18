package game.data.photobooth
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	import game.data.display.SpatialData;

	public class StickerData extends Component
	{
		public var position:SpatialData;
		public var asset:StickerAssetData;
		
		public function StickerData(spatialData:SpatialData, assetData:StickerAssetData)
		{
			position = spatialData;
			asset = assetData;
		}
		
		public function updatePosition(spatial:Spatial):void
		{
			position.formDataFromSpatial(spatial);
		}
		
		public static function parse(xml:XML):StickerData
		{
			var spatialData:SpatialData = new SpatialData(xml.child("spatial")[0]);
			
			var assetData:StickerAssetData = new StickerAssetData(xml.child("asset")[0]);
			
			return new StickerData(spatialData, assetData);
		}
		
		public function toXML():XML
		{
			var xml:XML = <sticker/>;
			
			xml.appendChild(position.toXML());
			
			xml.appendChild(asset.toXML());
			
			return xml;
		}
		
		public function duplicate():StickerData
		{
			return new StickerData(position.duplicate(), asset.duplicate());
		}
	}
}