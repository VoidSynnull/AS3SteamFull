package game.data.display
{
	import engine.components.Spatial;
	
	import game.util.DataUtils;

	public class SpatialData
	{
		public var x:Number = 0;
		public var y:Number = 0;
		public var rotation:Number = 0;
		public var scale:Number = 1;
		public var scaleX:Number = 1;
		public var scaleY:Number = 1;
		
		public static const SPATIAL_PROPERTIES:Array = ["x","y","rotation","scaleX","scaleY","scale"];
		
		public function SpatialData(data:* = null)
		{
			if(data == null)
				return;
			if(data is Spatial)
				formDataFromSpatial(data);
			else if(data is XML)
				parse(data);
		}
		
		public function parse(xml:XML):void
		{
			for each (var property:String in SPATIAL_PROPERTIES)
			{
				this[property] = DataUtils.getNumber(xml.child(property)[0]);
			}
		}
		
		public function toXML():XML
		{
			var xml:XML = <spatial/>;
			var property:String;
			
			for each (property in SpatialData.SPATIAL_PROPERTIES)
			{
				xml.appendChild(new XML("<"+property+">"+this[property]+"</"+property+">"));
			}
			return xml;
		}
		
		public function formDataFromSpatial(spatial:Spatial):void
		{
			for each (var property:String in SPATIAL_PROPERTIES)
			{
				this[property] = spatial[property];
			}
		}
		
		public function positionSpatial(spatial:Spatial):void
		{
			for each (var property:String in SPATIAL_PROPERTIES)
			{
				spatial[property] = this[property];
			}
		}
		
		public function duplicate():SpatialData
		{
			var spatialData:SpatialData = new SpatialData();
			for each (var property:String in SPATIAL_PROPERTIES)
			{
				spatialData[property] = this[property];
			}
			return spatialData;
		}
	}
}