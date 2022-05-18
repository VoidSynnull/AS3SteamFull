package game.data.scene
{
	import flash.utils.Dictionary;
	
	import game.data.PlatformType;
	import game.data.game.GameEvent;
	import game.util.DataUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	
	public class CameraLayerParser
	{
		public function CameraLayerParser()
		{
		}
		
		public function parse(xml:XMLList, assets:Array, absoluteFilePaths:Array):Dictionary
		{
			var layersXML:XMLList = xml.children();
			var layerXML:XML;
			var layers:Dictionary = new Dictionary();
			var layerData:CameraLayerData;
			var zIndex:Number;
			var nextZIndex:Number = 0;
			var asset:String;
			var id:String;
			
			for (var n:uint = 0; n < layersXML.length(); n++)
			{
				layerXML = layersXML[n];
				asset = DataUtils.getString(layerXML.asset);
				id = DataUtils.getString(layerXML.attribute("id"));
				
				if(id == null && asset != null)
				{
					// use the asset name without the file suffix.
					id = asset.slice(0, asset.length - 4);
				}
				
				layerData = new CameraLayerData();
				layerData.asset = asset;
				layerData.rate = DataUtils.getNumber(layerXML.rate);
				layerData.id = id; 
				layerData.hit = DataUtils.useBoolean(layerXML.attribute("hit"), false);
				layerData.autoScale = DataUtils.useBoolean(layerXML.attribute("autoScale"), true);
				layerData.matchViewportSize = DataUtils.useBoolean(layerXML.attribute("matchViewportSize"), false);
				layerData.bitmap = DataUtils.useBoolean(layerXML.attribute("bitmap"), !layerData.hit);
				layerData.offsetX = DataUtils.useNumber(layerXML.offsetX, 0);
				layerData.offsetY = DataUtils.useNumber(layerXML.offsetY, 0);
				layerData.width = DataUtils.useNumber(layerXML.width, NaN);  
				layerData.height = DataUtils.useNumber(layerXML.height, NaN);
				layerData.wrapX = DataUtils.useNumber(layerXML.wrapX, 0); 
				layerData.wrapY = DataUtils.useNumber(layerXML.wrapY, 0); 
				layerData.event = DataUtils.useString(layerXML.attribute("event"), GameEvent.DEFAULT);
				layerData.elementsToBitmap = DataUtils.getArray(layerXML.elementsToBitmap);
				layerData.absoluteFilePaths = DataUtils.useBoolean(layerXML.asset.attribute("absoluteFilePaths"), false);
				layerData.tileSize = DataUtils.useNumber(layerXML.tileSize, 512);
				layerData.condition = DataUtils.getString(layerXML.condition.attribute("type"));
				layerData.conditionValue = DataUtils.getString(layerXML.condition);
				// MOTION WRAP VARIABLES
				layerData.autoStart = DataUtils.useBoolean( layerXML.autoStart, false );
				layerData.subGroup = DataUtils.useString( layerXML.subGroup, null );
				layerData.align = DataUtils.useBoolean( layerXML.align, true );
				layerData.motionRate = DataUtils.useNumber( layerXML.motionRate, 0 );
				
				if(layerData.conditionValue != null)
				{
					if(layerData.conditionValue.indexOf(",") > -1)
					{
						layerData.conditionValue = layerData.conditionValue.split(",");
					}
				}
				
				zIndex = DataUtils.getNumber(layerXML.zIndex);
				
				//proactively remove layers to avoid conflicts later
				if(layerData.condition == "platform" || layerData.condition == "hide")
				{
					var removeLayer:Boolean = false;
					var condition:String = layerData.condition;
					var value:String = layerData.conditionValue;
					if(condition == "hide")
					{
						var currentQuality:int = PerformanceUtils.qualityLevel;
						var operator:String = value.substring(0, 1);
						var quality:int = int(value.substring(1));
						
						if(operator == "-")
						{
							if(currentQuality < quality)
							{
								removeLayer = true;
							}
						}
						else if(operator == "+")
						{
							if(currentQuality > quality)
							{
								removeLayer = true;
							}
						}
						else
						{
							if(currentQuality != quality)
							{
								removeLayer = true;
							}
						}
					}
					else
					{
						if((((value == PlatformType.MOBILE || value == PlatformType.TABLET) && !PlatformUtils.isMobileOS)) || (value == PlatformType.DESKTOP && PlatformUtils.isMobileOS))
						{
							removeLayer = true;
						}
					}
					if(removeLayer)
					{
						//instead of removing we are just not adding
						//orderedLayers.splice(orderedLayers.indexOf(layerData), 1);
						//nextZIndex = zIndex + 1;
						continue;
					}
				}
				
				// if the zIndex is undefined, set it to the layer order in the xml -or- the layer order of another layer with the same id.
				if(layers[layerData.id] == null)
				{
					layers[layerData.id] = new Dictionary();
					if(isNaN(zIndex)) { zIndex = nextZIndex; }
				}
				else
				{
					for(var nextEvent:String in layers[layerData.id])
					{
						zIndex = CameraLayerData(layers[layerData.id][nextEvent]).zIndex;
						break;
					}
				}
				
				layerData.zIndex = zIndex;
				
				nextZIndex = zIndex + 1;
				
				layers[layerData.id][layerData.event] = layerData;
				
				if(layerData.asset != null)
				{
					if(layerData.absoluteFilePaths)
					{
						absoluteFilePaths.push(layerData.asset); 
					}
					else
					{
						assets.push(layerData.asset); 
					}
				}
			}
			
			return(layers);
		}
	}
}


