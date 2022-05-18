package game.scene.template.ads
{
	public class SceneAdHotSpotParser
	{
		public function SceneAdHotSpotParser():void
		{
		}
		
		static public function parse(xml:XML):Object
		{
			if (xml == null)
				return {};
			var vHotSpotNode:XMLList = xml.children();
			var vHotSpotSubNode:XMLList;
			var vHotSpotXML:XML;
			var vID:String;
			var vType:String;
			var vHotSpotSubXML:XML;
			var vData:Object = {};
			var vSubObject:Object;
			
			for (var i:uint = 0; i < vHotSpotNode.length(); i++)
			{	
				vHotSpotXML = vHotSpotNode[i];
				vID = String(vHotSpotXML.attribute("id"));				
				vType = String(vHotSpotXML.attribute("type"));
				// if not type then show alert
				if ((vType == null) || (vType == ""))
					trace("SceneAdHotSpotParser :: Missing Hot Spot Type Value!");
				vHotSpotSubNode = vHotSpotXML.children();
				vSubObject = {};
				vSubObject.type = vType;
				
				// get width and height for video, if any
				var vWidth:String = vHotSpotXML.attribute("width");
				if ((vWidth != null) && (vWidth != ""))
					vSubObject.width = vWidth;
				var vHeight:String = vHotSpotXML.attribute("height");
				if ((vHeight != null) && (vHeight != ""))
					vSubObject.height = vHeight;
				
				for (var j:uint = 0; j < vHotSpotSubNode.length(); j++)
				{	
					vHotSpotSubXML = vHotSpotSubNode[j];
					vSubObject[String(vHotSpotSubXML.attribute("type"))] = String(vHotSpotSubXML.valueOf());
				}
				vData[vID] = vSubObject;
			}
			return(vData);
		}
	}
}