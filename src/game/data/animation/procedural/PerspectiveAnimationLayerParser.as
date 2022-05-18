package game.data.animation.procedural
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.data.animation.procedural.PerspectiveAnimationLayerData;
	import game.util.DataUtils;

	public class PerspectiveAnimationLayerParser
	{
		public function PerspectiveAnimationLayerParser()
		{
		}
		
		public function parse(xml:XML, displayObject:DisplayObjectContainer):Vector.<PerspectiveAnimationLayerData>
		{
			var layers:Vector.<PerspectiveAnimationLayerData> = new Vector.<PerspectiveAnimationLayerData>();
			var layerXMLs:XMLList = xml.children() as XMLList;
			var layerXML:XML;
			var layerData:PerspectiveAnimationLayerData;
			
			for (var i:uint = 0; i < layerXMLs.length(); i++)
			{	
				layerXML = layerXMLs[i];
				
				layerData = new PerspectiveAnimationLayerData();
				layerData.id = DataUtils.getString(layerXML.attribute("id"));
				layerData.displayObject = getChild(displayObject, DataUtils.getString(layerXML.displayObject));
				layerData.property = DataUtils.getString(layerXML.property);
				layerData.offset = getValueFromProperty(DataUtils.getString(layerXML.offset), displayObject);
				layerData.multiplier = DataUtils.getNumber(layerXML.multiplier);
				layerData.operation = Math[DataUtils.getString(layerXML.operation)];
	
				layers.push(layerData);
			}
			
			return(layers);
		}
		
		public function getChild(parent:DisplayObjectContainer, childPath:String):DisplayObjectContainer
		{
			var parts:Array = childPath.split(".");
			var child:MovieClip = parent as MovieClip;
			
			for(var n:int = 0; n < parts.length; n++)
			{
				child = child[parts[n]];
			}
			
			return(child);
		}
		
		public function getChildProperty(parent:DisplayObjectContainer, childPath:String):*
		{
			var parts:Array = childPath.split(".");
			var child:* = parent as MovieClip;
			
			for(var n:int = 0; n < parts.length; n++)
			{
				child = child[parts[n]];
				
				if(!(child is MovieClip))
				{
					return(child);
				}
			}
			
			return(null);
		}
		
		private function getValueFromProperty(property:*, displayObject:DisplayObjectContainer):Number
		{
			if(!isNaN(property))
			{
				return(Number(property));
			}
			else
			{
				return(getChildProperty(displayObject, property));
			}
		}
	}
}